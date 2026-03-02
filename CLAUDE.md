# wiz-bang — Session State

## Project Goals

1. **Task 1: Build a Wiz Azure Terraform provider**
   - Wiz publishes an official AWS provider (`tf.app.wiz.io/wizsec/wiz`) but has no Azure equivalent
   - We are reverse-engineering the Wiz GraphQL API to understand the Azure connector schema, then will build a custom Terraform provider

2. **Task 2: Import an existing Wiz project into Terraform**
   - Use `terraform import` to bring an existing Wiz Dashboard project under IaC management
   - The scaffold for this already exists in `wiz-test-project/`

---

## Current State (end of session)

### Task 1 — Azure provider: introspection phase

We identified that `createConnector` / `updateConnector` / `deleteConnector` are the key GraphQL mutations for cloud connectors.

**What was done this session:**
- `wiz-test-project/scripts/python/wiz_graphql_debug.py` was extended to deep-introspect `CreateConnectorInput` and `UpdateConnectorInput`, recursively following all nested `INPUT_OBJECT` and `ENUM` types via BFS
- Each discovered type is written to `wiz-test-project/build_artifacts/wiz_type_<TypeName>.json`
- A combined rollup is written to `wiz-test-project/build_artifacts/wiz_types_combined.json`
- `.github/workflows/deploy-wiz-project.yml` was updated:
  - New `wiz-introspect` job added (Python 3.12, installs requirements, runs script, uploads `build_artifacts/` as the `wiz-introspection` artifact)
  - `plan` job now `needs: [wiz-introspect]`
  - `WIZ_API_URL` secret reference added to the introspect job

**Artifacts not yet generated** — the workflow has not been run since the changes. The `build_artifacts/` directory currently only has the outputs from the previous run:
- `wiz_introspection_mutations.json`
- `wiz_mutations_filtered.txt`
- `wiz_typename.json`

**Immediate next step:** Run the workflow (or run the script locally) to generate `wiz_types_combined.json`. That file will reveal the full field schema for `CreateConnectorInput` — subscription ID, tenant ID, auth method, etc. — which becomes the blueprint for the Terraform resource schema.

### Task 2 — Terraform import of existing project

Not yet started. Scaffold exists at `wiz-test-project/` with `wiz_project.this` resource. Plan is to use `terraform import` once we have the project ID from the Wiz Dashboard.

---

## Key File Map

| Path | Purpose |
|------|---------|
| `wiz-test-project/scripts/python/wiz_graphql_debug.py` | GraphQL introspection script (extended this session) |
| `wiz-test-project/scripts/python/requirements.txt` | Python deps: `requests`, `python-dotenv` |
| `wiz-test-project/build_artifacts/` | Script output — JSON introspection data |
| `wiz-test-project/main.tf` | `wiz_project.this` resource |
| `wiz-test-project/versions.tf` | Requires `tf.app.wiz.io/wizsec/wiz` provider |
| `wiz-test-project/provider.tf` | Provider config (auth via env vars) |
| `wiz-test-project/tfvars/` | Per-env tfvars |
| `.github/workflows/deploy-wiz-project.yml` | CI: introspect → plan → apply |

## Required Secrets (GitHub + local env)

- `WIZ_CLIENT_ID`
- `WIZ_CLIENT_SECRET`
- `WIZ_API_URL` (Wiz GraphQL endpoint, e.g. `https://api.<tenant>.wiz.io/graphql`)

## GraphQL Mutations of Interest

- `createConnector` → `CreateConnectorInput`
- `updateConnector` → `UpdateConnectorInput`
- `deleteConnector` → `DeleteConnectorInput`

These are the mutations the future Azure provider resource will wrap.
