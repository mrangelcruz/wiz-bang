# wiz-bang — Session State

## Project Goals

1. **Task 1: Build a Wiz Azure Terraform provider**
   - Wiz publishes an official AWS provider (`tf.app.wiz.io/wizsec/wiz`) but has no Azure equivalent
   - We are reverse-engineering the Wiz GraphQL API to understand the Azure connector schema, then will build a custom Terraform provider

2. **Task 2: Import an existing Wiz project into Terraform**
   - Use `terraform import` to bring the existing `GEICO Cyber Prod` Wiz project under IaC management
   - Scaffold exists in `wiz-test-project/`

---

## Current State (end of session)

### Task 1 — Azure provider: introspection phase

We identified that `createConnector` / `updateConnector` / `deleteConnector` are the key GraphQL mutations for cloud connectors.

- `wiz-test-project/scripts/python/wiz_graphql_debug.py` deep-introspects `CreateConnectorInput` and `UpdateConnectorInput` via BFS, writing each type to `wiz-test-project/build_artifacts/wiz_type_<TypeName>.json` and a combined rollup to `wiz_types_combined.json`
- `.github/workflows/deploy-wiz-project.yml` has a `wiz-introspect` job that runs the script and uploads `build_artifacts/` as the `wiz-introspection` artifact

**Artifacts not yet generated** — workflow has not been run since the introspection changes. `build_artifacts/` only has outputs from prior run:
- `wiz_introspection_mutations.json`
- `wiz_mutations_filtered.txt`
- `wiz_typename.json`

**Next step for Task 1:** Run the workflow to generate `wiz_types_combined.json`, which reveals the full `CreateConnectorInput` schema (subscription ID, tenant ID, auth method, etc.) — the blueprint for the Terraform resource schema.

---

### Task 2 — Terraform import of GEICO Cyber Prod

**What was done this session:**
- Identified the target project: `GEICO Cyber Prod` (UUID: `41554e20-68eb-5986-a86e-d27233e3c752`)
- Located the project under Settings → Projects → GEICO (folder) → GEICO Cyber Prod (folder) → GEICO Cyber Prod
- Gathered the project's known config from the Wiz Dashboard:
  - Category: `Environment`
  - Parent folder: `GEICO Cyber`
  - Business Impact: `MBI` (Medium)
  - 11 linked cloud accounts (mix of AWS, Azure, GCP) — Wiz-internal UUIDs not yet known
  - Project Owner: listed but name not captured
- Created `wiz-test-project/tfvars/prod.tfvars.example` with:
  ```
  project_name        = "GEICO Cyber Prod"
  project_description = ""
  ```
- Added Wiz provider reference docs to `wiz-test-project/documents/`
- All changes committed and pushed to `main` on `github.com/mrangelcruz/wiz-bang`

**Import is NOT yet done** — the `terraform import` command has not been run yet.

**Next steps for Task 2 (in order):**

1. **Run `terraform import` locally** (one-time operation, not in CI):
   ```bash
   cd wiz-test-project
   export WIZ_CLIENT_ID=...
   export WIZ_CLIENT_SECRET=...
   terraform init
   terraform import \
     -var-file=tfvars/prod.tfvars.example \
     wiz_project.this \
     41554e20-68eb-5986-a86e-d27233e3c752
   ```

2. **Dump the full imported state** to discover all Wiz-internal UUIDs:
   ```bash
   terraform show -json | python3 -m json.tool > imported_state.json
   ```

3. **Expand `main.tf`** to match the full project config (risk_profile, cloud_account_links, parent_project_id, etc.) using `imported_state.json` as the source of truth

4. **Run `terraform plan`** until it shows no changes — that means IaC perfectly mirrors the live project

5. **Consider a remote state backend** — currently no backend is configured, so state is local only. For CI plan/apply to work long-term, state needs to be persisted (S3, Azure Blob, or Terraform Cloud)

---

## Key File Map

| Path | Purpose |
|------|---------|
| `wiz-test-project/scripts/python/wiz_graphql_debug.py` | GraphQL introspection script |
| `wiz-test-project/scripts/python/requirements.txt` | Python deps: `requests`, `python-dotenv` |
| `wiz-test-project/build_artifacts/` | Script output — JSON introspection data |
| `wiz-test-project/main.tf` | `wiz_project.this` resource (minimal — needs expansion post-import) |
| `wiz-test-project/versions.tf` | Requires `tf.app.wiz.io/wizsec/wiz` provider |
| `wiz-test-project/provider.tf` | Provider config (auth via env vars) |
| `wiz-test-project/tfvars/prod.tfvars.example` | Prod var values for GEICO Cyber Prod import |
| `wiz-test-project/documents/` | Wiz provider + wiz_project schema reference docs |
| `.github/workflows/deploy-wiz-project.yml` | CI: introspect → plan → apply |

## Key Facts

- **Target project UUID:** `41554e20-68eb-5986-a86e-d27233e3c752`
- **tfvars convention:** files use `.tfvars.example` extension (not `.tfvars`) — required by the CI runner
- **Triggering the workflow from a feature branch** (since workflow doesn't exist on default branch in the work repo):
  ```bash
  gh workflow run deploy-wiz-project.yml --ref <your-feature-branch> -f env=prod
  gh run watch
  ```
- **No `.gitignore` exists** in this repo

## Required Secrets (GitHub + local env)

- `WIZ_CLIENT_ID`
- `WIZ_CLIENT_SECRET`
- `WIZ_API_URL` (Wiz GraphQL endpoint, e.g. `https://api.<tenant>.wiz.io/graphql`)

## GraphQL Mutations of Interest

- `createConnector` → `CreateConnectorInput`
- `updateConnector` → `UpdateConnectorInput`
- `deleteConnector` → `DeleteConnectorInput`

These are the mutations the future Azure provider resource will wrap.
