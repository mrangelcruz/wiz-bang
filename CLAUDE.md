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
   - Use `terraform import` to bring `GEICO Cyber Prod` under IaC management
   - Scaffold lives in `wiz-test-project/` on `feature/wiz-test-project`

---

## Branch Strategy

```
main                            ← clean baseline
├── feature/wiz-azure-provider  ← Task A (nighttime work)
└── feature/wiz-test-project    ← Task B (daytime work)
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
- Python script (`wiz_graphql_debug.py`) is abandoned — Go tool replaces it entirely

**Next steps (Task A):**
1. Copy `provider/` to work repo (`github.com/geico-private/wiz`)
2. Trigger `wiz-graphql-debug.yml` on work repo with real Wiz creds → download `wiz-introspection` artifact
3. Use `wiz_types_combined.json` to fill in `mutations.go` and `resource.go`
4. Wire `azure_connector.NewResource` into `provider.go` Resources()
5. Test via `build-wiz-provider.yml` workflow

**No local Wiz creds** — all real API interaction must go through GitHub Actions on work repo.

---

### Task B — Terraform Import (`feature/wiz-test-project`)

**Completed:**
- Target project: `GEICO Cyber Prod` (UUID: `41554e20-68eb-5986-a86e-d27233e3c752`)
- `wiz-test-project/tfvars/prod.tfvars.example` created
- `terraform/environments/PD/` — production Wiz IaC (SSO, AWS/GCP connectors, Slack, ADO)
- All committed to `feature/wiz-test-project`

**`terraform import` has NOT been run yet.**

**Next steps (Task B):**
1. Get Wiz service account creds (ask tenant admin — can't create own, insufficient permissions)
2. Run `terraform import` locally on MacBook (work repo):
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
3. `terraform show -json > imported_state.json` → expand `main.tf`
4. `terraform plan` until zero changes

---

## Key File Map

| Path | Purpose |
|------|---------|
| `provider/tools/introspect/main.go` | Go BFS introspection tool — queries Wiz GraphQL schema |
| `provider/internal/client/` | Wiz OAuth2 + GraphQL client (reused by all provider code) |
| `provider/internal/resources/azure_connector/resource.go` | CRUD stubs — fill from introspection output |
| `provider/dev/` | Local test Terraform config (dev_overrides) |
| `provider/GNUmakefile` | `make build`, `make install`, `make test` |
| `.github/workflows/build-wiz-provider.yml` | CI: build + unit test Go provider |
| `.github/workflows/wiz-graphql-debug.yml` | CI: run introspection tool, upload wiz-introspection artifact |
| `documents/wiz_introspection_mutations.json` | First introspection run — mutations list only |
| `documents/project_details.md` | Full repo architecture reference |
| `documents/go_application_workflows.md` | GEICO GitHub Actions patterns for Go (proxy config, runner) |
| `wiz-test-project/main.tf` | `wiz_project.this` resource (minimal — expand post-import) |
| `wiz-test-project/tfvars/prod.tfvars.example` | Prod var values for GEICO Cyber Prod import |
| `terraform/environments/PD/` | Production Wiz IaC — SSO, AWS/GCP connectors, integrations |

## Key Facts & Conventions

- **Target project UUID:** `41554e20-68eb-5986-a86e-d27233e3c752`
- **tfvars convention:** `.tfvars.example` extension only
- **Work repo:** `github.com/geico-private/wiz` (MacBook)
- **Sandbox repo:** `github.com/mrangelcruz/wiz-bang` (Ubuntu laptop)
- **No local Wiz creds** — cannot create service account (insufficient permissions)
- **Trigger workflows via:**
  ```bash
  gh workflow run <workflow>.yml --ref feature/wiz-azure-provider
  gh run watch
  gh run download --name wiz-introspection --dir ./artifacts/
  ```
- **`import.sh` bug:** targets `environments/prod/` but directory is `environments/PD/`

## Required Secrets

- `WIZ_CLIENT_ID`
- `WIZ_CLIENT_SECRET`
- `WIZ_API_URL` = `https://api.us9.app.wiz.io/graphql`
