# wiz-bang — Session State

## Session Convention

Say **"end session"** → Claude updates `CLAUDE.md` + `MEMORY.md`, then git add/commit/push automatically. User exits terminal manually afterward.

---

## Project Goals

1. **Task 1: Build a Wiz Azure Terraform provider**
   - Wiz publishes an official AWS provider (`tf.app.wiz.io/wizsec/wiz`) but has no Azure equivalent
   - We are reverse-engineering the Wiz GraphQL API to understand the Azure connector schema, then will build a custom Terraform provider

2. **Task 2: Import an existing Wiz project into Terraform**
   - Use `terraform import` to bring the existing `GEICO Cyber Prod` Wiz project under IaC management
   - Scaffold exists in `wiz-test-project/`

---

## Current State

### Task 1 — Azure provider: introspection phase

- `wiz-test-project/scripts/python/wiz_graphql_debug.py` deep-introspects `CreateConnectorInput` and `UpdateConnectorInput` via BFS, writing each type to `wiz-test-project/build_artifacts/wiz_type_<TypeName>.json` and a combined rollup to `wiz_types_combined.json`
- `.github/workflows/deploy-wiz-project.yml` has a `wiz-introspect` job that runs the script and uploads `build_artifacts/` as the `wiz-introspection` artifact

**Artifacts not yet generated** — workflow has not been run since the introspection changes. `build_artifacts/` only has outputs from prior run:
- `wiz_introspection_mutations.json`
- `wiz_mutations_filtered.txt`
- `wiz_typename.json`

**Next step:** Run the workflow to generate `wiz_types_combined.json` — the blueprint for the Terraform resource schema.

---

### Task 2 — Terraform import of GEICO Cyber Prod

**Completed:**
- Target project identified: `GEICO Cyber Prod` (UUID: `41554e20-68eb-5986-a86e-d27233e3c752`)
- Project located under: Settings → Projects → GEICO → GEICO Cyber Prod (folder) → GEICO Cyber Prod
- Known config from Wiz Dashboard:
  - Category: `Environment`, Parent folder: `GEICO Cyber`, Business Impact: `MBI`
  - 11 linked cloud accounts (AWS, Azure, GCP) — Wiz-internal UUIDs not yet known
- `wiz-test-project/tfvars/prod.tfvars.example` created with `project_name = "GEICO Cyber Prod"`
- Wiz provider reference docs added to `wiz-test-project/documents/`
- All committed and pushed to `main`

**`terraform import` has NOT been run yet.**

**Next steps (in order):**

1. **Add `WIZ_API_URL` GitHub secret** (if not already done):
   - Repo → Settings → Secrets and variables → Actions → New repository secret
   - Name: `WIZ_API_URL`, Value: `https://api.us9.app.wiz.io/graphql`
   - Workflow already references it on line 43 — no workflow changes needed

2. **Run `terraform import` locally** (one-time, not in CI):
   ```bash
   cd wiz-test-project
   export WIZ_CLIENT_ID=...
   export WIZ_CLIENT_SECRET=...
   export WIZ_API_URL=https://api.us9.app.wiz.io/graphql
   terraform init
   terraform import \
     -var-file=tfvars/prod.tfvars.example \
     wiz_project.this \
     41554e20-68eb-5986-a86e-d27233e3c752
   ```

3. **Dump full state** to get all Wiz-internal UUIDs:
   ```bash
   terraform show -json | python3 -m json.tool > imported_state.json
   ```

4. **Expand `main.tf`** using `imported_state.json` as source of truth (risk_profile, cloud_account_links, parent_project_id, etc.)

5. **Run `terraform plan`** until no changes — IaC mirrors live project

6. **Add remote state backend** (S3, Azure Blob, or Terraform Cloud) — no backend configured yet; required for CI plan/apply to work long-term

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

## Key Facts & Conventions

- **Target project UUID:** `41554e20-68eb-5986-a86e-d27233e3c752`
- **tfvars convention:** `.tfvars.example` extension only — `.tfvars` not allowed by CI runner
- **No `.gitignore`** in this repo
- **Workflow not on default branch at work** — trigger via:
  ```bash
  gh workflow run deploy-wiz-project.yml --ref <your-feature-branch> -f env=prod
  gh run watch
  ```

## Required Secrets (GitHub + local env)

- `WIZ_CLIENT_ID`
- `WIZ_CLIENT_SECRET`
- `WIZ_API_URL` = `https://api.us9.app.wiz.io/graphql` (confirmed via browser Network tab)

## GraphQL Mutations of Interest

- `createConnector` → `CreateConnectorInput`
- `updateConnector` → `UpdateConnectorInput`
- `deleteConnector` → `DeleteConnectorInput`
