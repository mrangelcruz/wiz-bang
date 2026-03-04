# wiz-bang — Session State

## Session Convention

Say **"end session"** → Claude updates `CLAUDE.md` + `MEMORY.md`, then git add/commit/push automatically. User exits terminal manually afterward.

---

## Project Goals

1. **Task A: Build a Wiz Azure Terraform provider (Go)**
   - Wiz publishes an official AWS/GCP provider but has no Azure equivalent
   - Building a custom Go Terraform provider wrapping the Wiz GraphQL API
   - Provider lives in `provider/` on `feature/wiz-azure-provider`

2. **Task B: Import an existing Wiz project into Terraform**
   - Use `terraform import` (via CI) to bring `GEICO AWS` under IaC management
   - Terraform code lives in `wiz-projects/` on `feature/wiz-test-project`

---

## Branch Strategy

```
main                            ← clean baseline
├── feature/wiz-azure-provider  ← Task A (Go provider)
└── feature/wiz-test-project    ← Task B (Wiz project IaC)
```

Both branches pushed to `origin/mrangelcruz/wiz-bang`.
Work repo: `github.com/geico-private/wiz`

---

## Current State

### Task A — Go Provider (`feature/wiz-azure-provider`)

**What exists:**
- `provider/internal/client/auth.go` — OAuth2 token manager (functional)
- `provider/internal/client/client.go` — GraphQL HTTP client (functional)
- `provider/internal/client/mutations.go` — stubs (needs introspection output)
- `provider/internal/provider/provider.go` — provider schema + auth wiring
- `provider/internal/resources/azure_connector/resource.go` — CRUD stubs
- `provider/tools/introspect/main.go` — Go BFS introspection tool
- `provider/dev/` — local test Terraform config for dev_overrides
- `.github/workflows/build-wiz-provider.yml` — CI build on GEICO runner
- `.github/workflows/wiz-graphql-debug.yml` — runs introspection tool, uploads artifacts

**Go module path:** `github.com/geico-private/wiz/provider`
**Provider address:** `local/geico/wiz-azure`
**GEICO runner:** `group: "k8s-default-runner"`
**GOPROXY:** `https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all`

**Introspection status:**
- `documents/wiz_introspection_mutations.json` — mutations list only (confirms createConnector/updateConnector/deleteConnector exist)
- `wiz_types_combined.json` — NOT YET GENERATED (needs Go tool run with real Wiz creds)

**Next steps (Task A):**
1. Copy `provider/` to work repo
2. Trigger `wiz-graphql-debug.yml` on work repo with real Wiz creds → download `wiz-introspection` artifact
3. Use `wiz_types_combined.json` to fill in `mutations.go` and `resource.go`
4. Wire `azure_connector.NewResource` into `provider.go` Resources()
5. Test via `build-wiz-provider.yml` workflow

---

### Task B — Wiz Project IaC (`feature/wiz-test-project`)

**Folder structure:**
```
wiz-projects/
├── environments/
│   └── PD/          ← GEICO AWS stub (fill after import artifact)
├── modules/
│   └── wiz-project/ ← reusable module stub
└── documents/       ← Wiz provider + wiz_project schema docs
```

**Note:** DV environment removed — team goes straight to PD. DV secrets not properly configured in work repo.

**Target project:** `GEICO AWS`
**UUID:** `b044c7e1-bae8-5365-aa29-42a1a193dc1f`
**Wiz Dashboard path:** GEICO (folder) → GEICO AWS (project)

**What's done:**
- `wiz-projects/environments/PD/` — stub only, needs expansion post-import
- `.github/workflows/wiz-import.yml` — PD only, runs `terraform import` + uploads artifact
- `.github/workflows/deploy-wiz-project.yml` — PD only, aligned with deploy-wiz-tf.yml patterns
  - Single job, `environment: PD` (accesses PD GitHub Environment secrets)
  - `action` input (plan/apply), `confirm_critical_op` gate, `-detailed-exitcode`, Plan Summary
  - Credentials: `WIZ_CLIENT_ID_PD` / `WIZ_CLIENT_SECRET_PD`
- PR open on work repo (`geico-private/wiz`) — multiple Copilot review rounds addressed
- macOS case-rename gotcha: use two-step `git mv dv dv_tmp && git mv dv_tmp DV` for case-only renames

**`terraform import` has NOT been run yet.**

**Next steps (Task B):**
1. Verify PR plan passes with PD credentials
2. Trigger import workflow (workflow_dispatch, no inputs needed beyond UUID default):
   ```bash
   gh workflow run "Wiz Project Import" --ref wiz-test-project
   gh run watch
   gh run download --name wiz-imported-state-PD --dir ./artifacts/
   ```
3. Use `imported_state.json` artifact to expand `PD/main.tf` with full attribute set
4. `terraform plan` until zero changes
5. Add remote state backend (Azure Blob or HCP Terraform) — none configured yet

---

## Key File Map

| Path | Purpose |
|------|---------|
| `wiz-projects/environments/PD/` | PD Terraform root — GEICO AWS (stub, post-import) |
| `wiz-projects/environments/PD/tfvars/PD.tfvars.example` | `project_name = "GEICO AWS"` |
| `wiz-projects/modules/wiz-project/` | Reusable wiz_project module stub |
| `wiz-projects/documents/` | Wiz provider + wiz_project schema reference docs |
| `.github/workflows/wiz-import.yml` | Runs terraform import for PD, uploads state JSON artifact |
| `.github/workflows/deploy-wiz-project.yml` | Plan + apply for PD environment |
| `provider/tools/introspect/main.go` | Go BFS introspection tool (Task A) |
| `provider/internal/client/` | Wiz OAuth2 + GraphQL client (Task A) |

## Key Facts & Conventions

- **GEICO AWS UUID:** `b044c7e1-bae8-5365-aa29-42a1a193dc1f`
- **tfvars convention:** `.tfvars.example` extension only
- **No `.gitignore`** in this repo
- **No local Wiz creds** — all real API interaction via GitHub Actions on work repo
- **import runs in CI** (wiz-import.yml), not locally — state captured as artifact
- **Trigger workflows by NAME not file path:**
  ```bash
  gh workflow run "Wiz Project Import" --ref wiz-test-project
  gh run watch
  gh run download --name wiz-imported-state-PD --dir ./artifacts/
  ```
- **`gh workflow run` with file path fails** if workflow not on default branch — use the `name:` field value instead
- **macOS case-rename bug:** `git mv dv DV` silently does nothing on macOS (case-insensitive FS). Use two-step: `git mv dv dv_tmp && git mv dv_tmp DV`

## Work Repo Secrets (geico-private/wiz)

Secrets stored as GitHub Environment secrets under the "PD" environment:
- `WIZ_CLIENT_ID` / `WIZ_CLIENT_SECRET` — repo-level secrets, used by both workflows
- `WIZ_CLIENT_ID_PD` / `WIZ_CLIENT_SECRET_PD` — exist but NOT used (bad/unconfigured)
- `WIZ_CLIENT_ID_DV` / `WIZ_CLIENT_SECRET_DV` — exist but not properly configured; DV removed
- `WIZ_API_URL` secret exists (not used in our provider.tf — provider resolves endpoint from creds)
- Wiz provider env vars: `WIZ_CLIENT_ID` + `WIZ_CLIENT_SECRET` (confirmed from provider docs)
