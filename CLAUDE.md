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
- `.github/workflows/wiz-import.yml` — **TEMPORARILY REPURPOSED** to run introspection (see below)

**Go module path:** `github.com/geico-private/wiz/provider`
**Provider address:** `local/geico/wiz-azure`
**GEICO runner:** `group: "k8s-default-runner"`
**GOPROXY:** `https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all`

**Introspection workflow strategy:**
- GitHub Actions only recognizes `workflow_dispatch` workflows on the **default branch** (main)
- Workaround: repurpose `wiz-import.yml` (exists on main) on `wiz-azure-provider` branch
- GitHub runs the **branch's version** of the file when triggered via UI branch selector or `--ref`
- `wiz-import.yml` on this branch runs Go introspection tool instead of Terraform import
- To restore: replace contents with original Terraform import logic once provider PR is formalized
- Trigger: Actions UI → "Wiz Project Import" → Run workflow → branch: `wiz-azure-provider`

**Introspection lessons learned:**
- **k8s runner blocks external TLS** — `wiz-import.yml` uses `ubuntu-latest` (not k8s runner); GOPROXY removed
- **Wiz API ignores variables on `__type` queries** — query uses inline `fmt.Sprintf` instead of GraphQL variables
- **Rate limiting** — 200ms sleep between BFS requests to avoid HTTP 429
- Auth URL is `https://auth.app.wiz.io/oauth/token` (Wiz Commercial) — confirmed correct per docs

**Introspection status: COMPLETE**
- Ran successfully on work repo — 3500+ types discovered
- `documents/wiz_type_ConnectorConfigAzure.json` — read-side fields ✓
- `documents/wiz_type_CreateConnectorInput.json` — create mutation input ✓
- `documents/wiz_type_UpdateConnectorInput.json` — update mutation input ✓
- `documents/wiz_type_UpdateConnectorPatch.json` — NOT YET copied locally (needed next session)

**Key schema findings:**
- `CreateConnectorInput`: `name` (String!), `type` (ID!), `authParams` (JSON!), `enabled` (Bool), `extraConfig` (JSON)
- `authParams` is an opaque JSON blob — Azure config fields go here during create/update
- `ConnectorConfigAzure` read fields: `tenantId`, `clientId`, `clientSecret`, `isManagedIdentity`, `groupId`, `subscriptionId`, `excludedSubscriptions`, `includedSubscriptions`, `excludedManagementGroups`, `includedManagementGroups`, `includedRegions`, `excludedRegions`, `auditLogMonitorEnabled`, `networkLogMonitorEnabled`, `environment`, etc.

**Next steps (Task A):**
1. Copy `wiz_type_UpdateConnectorPatch.json` from artifact to `documents/`
2. Write `mutations.go` with createConnector / updateConnector / deleteConnector + read query
3. Write `resource.go` CRUD using the mutation structs
4. Wire `azure_connector.NewResource` into `provider.go` Resources()
5. Test via `build-wiz-provider.yml` workflow
6. Formalize with a proper PR + dedicated workflow file; restore `wiz-import.yml` to original

**No local Wiz creds** — all real API interaction must go through GitHub Actions on work repo.

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

**Target project:** `GEICO AWS`
**UUID:** `b044c7e1-bae8-5365-aa29-42a1a193dc1f`
**Wiz Dashboard path:** GEICO (folder) → GEICO AWS (project)

**What's done:**
- PR merged to `main` on work repo (`geico-private/wiz`)
- `wiz-projects/environments/PD/` — stub only, needs expansion post-import
- `.github/workflows/wiz-import.yml` — on main, runs terraform import for PD, uploads state JSON artifact
- `.github/workflows/deploy-wiz-project.yml` — on main, plan + apply for PD

**`terraform import` has NOT been run yet.**

**Next steps (Task B):**
1. On work repo: trigger import workflow from Actions UI:
   - Actions → "Wiz Project Import" → Run workflow → branch: `main` (or `wiz-test-project` if still exists)
   - Or: `gh workflow run "Wiz Project Import" --ref main`
2. Download artifact: `gh run download --name wiz-imported-state-PD --dir ./artifacts/`
3. Use `imported_state.json` to expand `PD/main.tf` with full attribute set
4. `terraform plan` until zero changes
5. Add remote state backend (Azure Blob or HCP Terraform) — none configured yet

---

## Key File Map

| Path | Purpose |
|------|---------|
| `wiz-projects/environments/PD/` | PD Terraform root — GEICO AWS (stub, post-import) |
| `wiz-projects/modules/wiz-project/` | Reusable wiz_project module stub |
| `wiz-projects/documents/` | Wiz provider + wiz_project schema reference docs |
| `.github/workflows/wiz-import.yml` | **On main**: Terraform import. **On wiz-azure-provider**: introspection tool (temp) |
| `.github/workflows/deploy-wiz-project.yml` | Plan + apply for PD environment |
| `provider/tools/introspect/main.go` | Go BFS introspection tool (Task A) |
| `provider/internal/client/` | Wiz OAuth2 + GraphQL client (Task A) |
| `documents/wiz_introspection_mutations.json` | First introspection run — mutations list only |
| `documents/queeno_wiz_provider_analysis.md` | queeno/wiz provider analysis — design justification reference |

## Key Facts & Conventions

- **GEICO AWS UUID:** `b044c7e1-bae8-5365-aa29-42a1a193dc1f`
- **tfvars convention:** `.tfvars.example` extension only
- **No `.gitignore`** in this repo
- **No local Wiz creds** — all real API interaction via GitHub Actions on work repo
- **GitHub Actions workflow_dispatch** only recognizes workflows on the default branch
  - Workaround: repurpose an existing workflow file; GitHub runs the branch's version via UI/`--ref`
- **Trigger workflows by NAME not file path:**
  ```bash
  gh workflow run "Wiz Project Import" --ref <branch>
  gh run watch
  gh run download --name wiz-introspection --dir ./artifacts/
  ```
- **`gh workflow run` with file path fails** if workflow not on default branch — use the `name:` field value instead
- **macOS case-rename bug:** `git mv dv DV` silently does nothing on macOS (case-insensitive FS). Use two-step: `git mv dv dv_tmp && git mv dv_tmp DV`

## Work Repo Secrets (geico-private/wiz)

- `WIZ_CLIENT_ID` / `WIZ_CLIENT_SECRET` — repo-level secrets, used by both workflows
- `WIZ_CLIENT_ID_PD` / `WIZ_CLIENT_SECRET_PD` — exist but NOT used (bad/unconfigured)
- `WIZ_API_URL` secret exists (not used in our provider.tf — provider resolves endpoint from creds)
- Wiz provider env vars: `WIZ_CLIENT_ID` + `WIZ_CLIENT_SECRET` (confirmed from provider docs)
- **`environment: PD`** on job required to access repo-level secrets
