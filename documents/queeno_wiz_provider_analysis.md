# Analysis: queeno/terraform-provider-wiz

**Purpose:** Reference analysis to justify design decisions in the GEICO custom Wiz Azure Terraform provider.
**Date:** 2026-03-04
**Source:** https://github.com/queeno/terraform-provider-wiz

---

## Executive Summary

The `queeno/terraform-provider-wiz` is the only known public community Terraform provider for Wiz. It implements AWS and GCP connectors but **has no Azure connector resource** — confirming that our work is novel and filling a real gap. It also uses the older Terraform Plugin SDK v2, not the modern Plugin Framework. We cannot lift-and-shift their code, but their GraphQL mutation structure and behavioral patterns are directly applicable and validated by a real working implementation.

---

## 1. Azure Connector: Not Implemented in the Wild

The queeno provider contains:

- `resource_connector_aws.go` — fully implemented
- `resource_connector_gcp.go` — fully implemented
- **No `resource_connector_azure.go`**

No other public Terraform provider for Wiz with Azure support was found. The GEICO implementation will be the first.

---

## 2. SDK Version: Plugin SDK v2 (Older)

queeno uses **HashiCorp Terraform Plugin SDK v2**:

```go
import "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
import "github.com/hashicorp/terraform-plugin-sdk/v2/diag"
```

Resources are defined as `*schema.Resource` with top-level CRUD functions.

**Our provider targets the modern Terraform Plugin Framework** (`resource.Resource` interface with `Schema()`, `Create()`, `Read()`, `Update()`, `Delete()` methods). The two SDKs are architecturally incompatible — queeno code cannot be copied directly. However, their GraphQL layer and behavioral patterns translate cleanly.

---

## 3. GraphQL Mutations: Confirmed Structure

All three mutations are connector-type-agnostic. The `Type` field on the input distinguishes AWS vs GCP vs Azure.

### Create

```graphql
mutation CreateConnector($input: CreateConnectorInput!) {
  createConnector(input: $input) {
    connector {
      id
    }
  }
}
```

Go input struct:
```go
type CreateConnectorInput struct {
    Name        string          `json:"name"`
    Type        string          `json:"type"`         // "azure" for us
    Enabled     *bool           `json:"enabled,omitempty"`
    AuthParams  json.RawMessage `json:"authParams"`
    ExtraConfig json.RawMessage `json:"extraConfig,omitempty"`
}
```

### Update

```graphql
mutation UpdateConnector($input: UpdateConnectorInput!) {
  updateConnector(input: $input) {
    connector {
      id
      name
      enabled
      extraConfig
    }
  }
}
```

Go input struct:
```go
type UpdateConnectorInput struct {
    ID    string `json:"id"`
    Patch struct {
        Name        string          `json:"name,omitempty"`
        Enabled     *bool           `json:"enabled,omitempty"`
        ExtraConfig json.RawMessage `json:"extraConfig,omitempty"`
        // AuthParams intentionally excluded — requires ForceNew
    } `json:"patch"`
}
```

### Delete

```graphql
mutation DeleteConnector($input: DeleteConnectorInput!) {
  deleteConnector(input: $input) {
    _stub
  }
}
```

Go input struct:
```go
type DeleteConnectorInput struct {
    ID string `json:"id"`
}
```

---

## 4. Read Query: Inline Fragment Pattern

The connector read query uses inline fragments to retrieve cloud-specific config fields:

```graphql
query GetConnector($id: ID!) {
  connector(id: $id) {
    id
    name
    enabled
    authParams
    extraConfig
    config {
      ... on ConnectorConfigAWS {
        region
        customerRoleARN
        excludedAccounts
        excludedOUs
        optedInRegions
        externalIdNonce
        auditLogMonitorEnabled
        diskAnalyzerInFlightDisabled
        skipOrganizationScan
      }
    }
    type {
      id
      name
      authorizeUrls
    }
  }
}
```

For our provider, the inline fragment becomes `... on ConnectorConfigAzure`. The exact fields available under `ConnectorConfigAzure` will be determined by the introspection run (`wiz_types_combined.json`).

---

## 5. Authentication Handling: ForceNew Pattern

Wiz obscures `authParams` on read — the API does not return the original secret values. This causes a perpetual plan diff if the provider naively compares stored state against the API response.

queeno's solution: **mark `auth_params` as ForceNew via CustomizeDiff**, so any change to auth credentials destroys and recreates the connector rather than attempting an in-place update.

```go
CustomizeDiff: func(ctx context.Context, d *schema.ResourceDiff, meta interface{}) error {
    if d.HasChange("auth_params") {
        d.ForceNew("auth_params")
    }
    return nil
}
```

This pattern must be replicated in our Plugin Framework implementation using `PlanModifiers`:

```go
// In schema definition
"auth_params": schema.StringAttribute{
    PlanModifiers: []planmodifier.String{
        stringplanmodifier.RequiresReplace(),
    },
},
```

---

## 6. Resource Schema: Confirmed Field Set

Fields common to all connectors (AWS and GCP both use this structure):

| Field | Type | Required | Sensitive | Notes |
|-------|------|----------|-----------|-------|
| `name` | string | yes | no | Display name |
| `auth_params` | JSON string | yes | yes | Cloud credentials (opaque on read) |
| `enabled` | bool | no | no | Defaults to true |
| `extra_config` | JSON string | no | no | Cloud-specific advanced settings |
| `id` | string | computed | no | Set by Wiz on create |

Additional computed fields (AWS example — Azure equivalents TBD from introspection):
- `audit_log_monitor_enabled`
- `disk_analyzer_inflight_disabled`
- `cloud_account_count`
- `excluded_accounts`, `excluded_ous` (Azure equivalent: subscriptions, management groups)

---

## 7. GraphQL Client Architecture

Their client follows a simple request/response wrapper pattern:

```go
type GraphQLRequest struct {
    Query     string      `json:"query"`
    Variables interface{} `json:"variables"`
}

type GraphQLError struct {
    Message   string
    Path      []string
    Exception struct {
        Message string
    }
}
```

Mutations wrap input under a top-level `input` key:
```go
Variables: map[string]interface{}{
    "input": connectorInput,
}
```

Our `provider/internal/client/client.go` already implements an equivalent pattern — no changes needed there.

---

## 8. Null/Empty Value Cleanup

After a Read, queeno calls a `RemoveNullAndEmptyValues()` helper before setting state. This prevents perpetual drift when the Wiz API returns null JSON fields that Terraform would otherwise flag as removals.

Our implementation should apply the same cleanup — either via a helper or by using `types.StringNull()` correctly in the Plugin Framework.

---

## 9. Pagination

queeno implements cursor-based pagination for list queries via reflection, extracting `EndCursor` and `HasNextPage` from nested response data. This is relevant if we ever implement data sources (e.g., listing all connectors). Single-connector reads by ID do not require pagination.

---

## 10. Provider Registration

queeno registers connectors in `provider.go`:

```go
ResourcesMap: map[string]*schema.Resource{
    "wiz_connector_aws": resourceWizConnectorAws(),
    "wiz_connector_gcp": resourceWizConnectorGcp(),
}
```

Our Plugin Framework equivalent in `provider/internal/provider/provider.go`:

```go
func (p *WizAzureProvider) Resources(ctx context.Context) []func() resource.Resource {
    return []func() resource.Resource{
        azure_connector.NewResource,
    }
}
```

This is already stubbed — just needs `azure_connector.NewResource` filled in.

---

## What We Take from queeno

| Pattern | Action |
|---------|--------|
| Mutation names and input shapes | Use directly in `mutations.go` |
| `auth_params` as raw JSON, sensitive, ForceNew | Mirror via `RequiresReplace()` plan modifier |
| Inline fragment `... on ConnectorConfigAzure` on read | Fields discovered automatically via updated BFS introspection tool |
| `RemoveNullAndEmptyValues` after read | Implement equivalent null-handling |
| Basic schema fields (name, enabled, extra_config) | Confirmed — implement these first |

## What We Do Not Take from queeno

| Item | Reason |
|------|--------|
| `*schema.Resource` CRUD functions | Plugin SDK v2 — incompatible with Plugin Framework |
| `helper/schema` imports | Wrong SDK generation |
| Azure-specific config fields | Does not exist — must come from introspection |

---

## Remaining Dependency

The exact fields under `ConnectorConfigAzure` (subscriptions, tenant ID, managed identity config, audit log settings, etc.) are **not determinable from queeno** because their Azure implementation does not exist.

The introspection tool (`provider/tools/introspect/main.go`) has been updated to close this gap. In addition to the original mutation input seeds (`CreateConnectorInput`, `UpdateConnectorInput`, `DeleteConnectorInput`), the BFS now:

- Seeds from `Connector` (the read-side return type)
- Fetches `fields` on OBJECT types in addition to `inputFields` on INPUT_OBJECT types
- Follows `possibleTypes` on UNION/INTERFACE types to reach concrete cloud config types

This traversal path will automatically discover `ConnectorConfigAzure` and all its fields:

```
Connector (OBJECT)
  └─ fields → config (UNION or INTERFACE)
       └─ possibleTypes → ConnectorConfigAzure, ConnectorConfigAWS, ...
            └─ fields → subscriptionId, tenantId, managedIdentity, ...
```

The remaining step is to trigger the workflow and download the artifact:

1. Run `wiz-graphql-debug.yml` on the work repo with real Wiz credentials
2. Download: `gh run download --name wiz-introspection --dir ./artifacts/`
3. Use `wiz_types_combined.json` → `ConnectorConfigAzure` entry to fill in `mutations.go` and `resource.go`
