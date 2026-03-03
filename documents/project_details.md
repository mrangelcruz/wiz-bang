# wiz-bang — Project Details

This document covers everything **outside** `wiz-test-project/`. See `CLAUDE.md` for the full session state including `wiz-test-project/` specifics.

---

## What This Repo Is

`wiz-bang` is a central GitOps repository for managing **Wiz CSPM (Cloud Security Posture Management)** configuration as code for GEICO's cloud security team. It uses the official Wiz Terraform provider (`tf.app.wiz.io/wizsec/wiz`) to manage the production Wiz tenant and automate security operations.

The repo has two conceptually separate areas:

| Area | Purpose | Status |
|------|---------|--------|
| `terraform/` | Production Wiz IaC — SSO, cloud connectors, integrations, automation rules | Active; PD env is the real one |
| `wiz-test-project/` | Experimental sandbox — GraphQL introspection + import of a specific project | In-progress (see CLAUDE.md) |

---

## Repository Structure (outside wiz-test-project)

```
wiz-bang/
├── .github/workflows/
│   ├── deploy-wiz-tf.yml        # Main CI/CD: plan/apply for terraform/ environments
│   └── wiz-graphql-debug.yml    # One-off: GraphQL introspection via Python script
├── terraform/
│   ├── environments/
│   │   ├── DV/                  # Dev — pipeline testing only (null/random/local resources)
│   │   ├── UT/                  # User Testing — same structure as DV
│   │   └── PD/                  # Production — real Wiz resources
│   │       ├── geico-sso.tf     # SAML IdP + AAD group mappings
│   │       ├── geico-aws.tf     # AWS Organizations connector
│   │       ├── geico-gcp.tf     # GCP Organization connector
│   │       ├── geico-integrations.tf  # Slack Bot + Azure DevOps webhook
│   │       ├── geico-automations.tf   # Automation rules (critical issue Slack alerts)
│   │       ├── providers.tf     # Wiz provider + S3 backend config
│   │       ├── variables.tf     # All variable definitions
│   │       └── terraform.tfvars # Non-sensitive variable values
│   └── scripts/
│       └── import.sh            # One-time import script for first-time setup
├── scripts/python/              # Placeholder; no scripts yet (README only)
├── queries/wql/                 # Placeholder for saved WQL queries (README only)
└── documents/                   # This file
```

---

## Terraform Environments

### DV (Development) — `terraform/environments/DV/`

Not a real Wiz environment. Used purely for **pipeline testing** — it exercises the CI workflow without touching Wiz. Resources created:
- `null_resource.pipeline_test` — forces state changes on timestamp changes
- `random_string.test_suffix`, `random_uuid.test_id` — generate state entries
- `time_static.deployment_time` — captures deployment timestamp
- `local_file.test_config` — writes a JSON file to verify plan/apply works end-to-end

AWS account: `938436319834` (gw-cybersec-sbx-001)

### UT (User Testing) — `terraform/environments/UT/`

Same structure as DV. AWS account: `132634713021` (gw-cybersec-sbx-002). Likely another pipeline validation environment before promoting to PD.

### PD (Production) — `terraform/environments/PD/`

The real deal. Manages the live GEICO Wiz tenant. Resources:

#### SSO (`geico-sso.tf`)
- `wiz_saml_idp.geico` — Azure AD SAML IdP for GEICO SSO
  - Tenant: `7389d8c0-3607-465c-a69f-7d4426502912`
  - Uses provider-managed roles; no manual role override
- `wiz_saml_group_mapping.geico_group_mappings` — Maps AAD ASGs to Wiz roles:
  - `AAD-ASG-WIZ-PD-USER` → `GLOBAL_READER`
  - `AAD-ASG-WIZ-PD-ADMIN` → `GLOBAL_ADMIN`
  - `AAD-ASG-WIZ_AWS-PD-USER` → `PROJECT_READER` (scoped to "GEICO AWS" project)

#### Cloud Connectors
- `wiz_aws_connector.geico` (`geico-aws.tf`) — Scans all AWS accounts in Organizations
  - Assumes role: `arn:aws:iam::343497816152:role/WizAccess-Role`
- `wiz_gcp_connector.geico` (`geico-gcp.tf`) — Scans all GCP projects in Organization `735813871839`
  - Uses managed identity auth

> **Note:** No Azure connector is managed here yet. That gap is why `wiz-test-project/` exists — to reverse-engineer the Azure connector GraphQL API and eventually build an Azure Terraform resource.

#### Integrations (`geico-integrations.tf`)
- `wiz_integration.slack` — Slack Bot integration (token via `TF_VAR_slack_bot_token`)
- `wiz_integration.ado` — Azure DevOps webhook integration (`https://dev.azure.com/GEICO/...`)

#### Automation Rules (`geico-automations.tf`)
- `wiz_automation_rule.slack_critical_issues` — Fires when a Critical severity issue is created; sends Slack message to `#team-cloudsec` with `@cloud-security` mention

#### Remote State
S3 backend in `018139544949` (gw-cloudsec-pd-001):
- Bucket: `geico-cloudsec-tfstate`
- Key prefix: `wiz/` with workspace prefix `wiz`
- Role: `arn:aws:iam::018139544949:role/geico-cloudsec-tfstate-access`
- State locking via native S3 lock file (`use_lockfile = true`)

---

## CI/CD Workflows

### `deploy-wiz-tf.yml` — Main Deployment Workflow

**Trigger:** `workflow_dispatch` only (manual)

**Inputs:**
| Input | Options | Default |
|-------|---------|---------|
| `action` | `plan`, `apply` | `plan` |
| `environment` | `DV`, `UT`, `PD` | `DV` |
| `import_existing` | boolean | `false` |
| `confirm_critical_op` | string (must type `"apply"`) | — |

**Flow:**
1. Validate secrets for selected environment
2. Confirm `apply` typed (apply-only gate)
3. Assume AWS IAM role via OIDC (`gw-accountautomation-role`)
4. `terraform fmt -check` → `terraform init` → stale lock detection/cleanup
5. Optionally run `terraform import` for SAML IdP + group mappings (first-time setup)
6. `terraform validate` → `terraform plan -out=tfplan`
7. `terraform apply` (only if `action=apply` AND plan exit code = 2)
8. On failure: auto-cleanup stale locks

**Secrets pattern:** Environment-scoped secrets per environment:
- `WIZ_CLIENT_ID_DV` / `_UT` / `_PD`
- `WIZ_CLIENT_SECRET_DV` / `_UT` / `_PD`
- `SLACK_BOT_TOKEN_DV` / `_UT` / `_PD`

**Concurrency:** Single-run lock (`workflow-concurrency-lock`) — no parallel runs.

---

### `wiz-graphql-debug.yml` — GraphQL Introspection

**Trigger:** `workflow_dispatch` — takes `wiz_api_url` as input (default: `https://api.us9.app.wiz.io/graphql`)

**Purpose:** Runs `wiz-test-project/scripts/python/wiz_graphql_debug.py` to deep-introspect the Wiz GraphQL schema (specifically `CreateConnectorInput` and `UpdateConnectorInput`) and upload results as a GitHub artifact (`wiz-graphql-debug`).

**Steps:**
1. Load `WIZ_CLIENT_ID` / `WIZ_CLIENT_SECRET` from secrets
2. Probe token endpoint (`auth.app.wiz.io/oauth/token`) to verify connectivity
3. Install Python deps from `wiz-test-project/scripts/python/requirements.txt`
4. Run introspection script → output to `wiz-test-project/wiz_debug_out/`
5. Upload debug artifacts

**Note:** This workflow uses the generic `WIZ_CLIENT_ID` / `WIZ_CLIENT_SECRET` secrets (not environment-scoped), same as `deploy-wiz-project.yml`.

---

## Supporting Files

### `terraform/scripts/import.sh`

A one-time bash script that idempotently imports pre-existing Wiz resources into Terraform state. Checks `terraform state show` first to skip already-imported resources. Imports:
- `wiz_saml_idp.geico` ← `"GEICO"`
- `wiz_saml_group_mapping.geico_group_mappings` ← `"GEICO"`
- `wiz_aws_connector.geico` ← `"GEICO AWS"`
- `wiz_gcp_connector.geico` ← `"GEICO GCP"`
- `wiz_integration.slack` ← `"GEICO Slack"`
- `wiz_integration.ado` ← `"GEICO Azure DevOps"`
- `wiz_automation_rule.slack_critical_issues` ← `"RULE_ID"` (TODO: real ID needed)

Runs against `terraform/environments/prod/` (note: directory name in script is `prod`, not `PD` — may be a discrepancy to fix).

### `scripts/python/` (root-level)

Placeholder directory with a README stub. No scripts written yet. This is a future home for Python automation scripts that operate against the Wiz API (separate from the introspection script in `wiz-test-project/`).

### `queries/wql/`

Placeholder directory for saved Wiz Query Language (WQL) queries. Intended to be organized by category:
- `vulnerabilities/` — Critical CVE queries, internet-exposed resources
- `misconfigurations/` — Cloud misconfiguration detection
- `identities/` — IAM and identity queries
- `network/` — Network exposure queries
- `compliance/` — Compliance posture queries

No actual `.wql` files exist yet.

---

## What Is Not Yet Done (outside wiz-test-project)

1. **Azure connector** — No `wiz_azure_connector` resource exists in any environment. This is the primary motivation for the `wiz-test-project/` reverse-engineering work.
2. **`wiz_automation_rule` import ID** — `import.sh` has a `"RULE_ID"` placeholder. The real ID needs to be pulled from the Wiz console URL.
3. **`import.sh` path discrepancy** — Script targets `environments/prod/` but the actual directory is `environments/PD/`.
4. **UT environment** — Has the same skeleton as DV; no real Wiz resources configured yet.
5. **`scripts/python/` and `queries/wql/`** — Both are stub directories; no real content.
6. **`policies/custom/`** — Referenced in `README.md` but directory doesn't exist yet.
