# wiz-bang Project Memory

## Key Facts
- Sandbox repo: `github.com/mrangelcruz/wiz-bang` (Ubuntu laptop)
- Work repo: `github.com/geico-private/wiz` (MacBook)
- Go module path: `github.com/geico-private/wiz/provider`
- Wiz provider source: `tf.app.wiz.io/wizsec/wiz` (official, AWS/GCP only)
- Target project for import: `GEICO Cyber Prod` (UUID: `41554e20-68eb-5986-a86e-d27233e3c752`)

## Branch Strategy
- `main` — clean baseline
- `feature/wiz-azure-provider` — Task A: Go provider (nighttime work)
- `feature/wiz-test-project` — Task B: Terraform import (daytime work)

## Conventions
- tfvars files use `.tfvars.example` extension — NOT `.tfvars`
- `WIZ_API_URL` = `https://api.us9.app.wiz.io/graphql` (us9 datacenter)
- GEICO runner: `group: "k8s-default-runner"` — NOT `ubuntu-latest`
- GOPROXY: `https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all`
- GONOSUMDB: `github.com/geico-private,dev.azure.com`
- Multi-proxy fallback required for public modules (hashicorp/*)
- End session: "end session" → Claude updates CLAUDE.md + MEMORY.md + git add/commit/push

## Go Provider Structure (`provider/`)
- `internal/client/auth.go` — OAuth2 token manager (functional)
- `internal/client/client.go` — GraphQL HTTP client (functional)
- `internal/client/mutations.go` — stubs, needs `wiz_types_combined.json`
- `internal/resources/azure_connector/resource.go` — CRUD stubs
- `tools/introspect/main.go` — BFS GraphQL schema walker (Go, replaces Python)
- Provider address: `local/geico/wiz-azure`
- `.gitignore`: compiled binaries (`introspect`, `terraform-provider-wiz-azure`)

## Current Status
- Task A: Provider scaffold done, introspection tool written in Go, NOT yet run against real Wiz API
- Task B: `terraform import` NOT yet run — needs Wiz creds (cannot self-create service account)
- `documents/wiz_introspection_mutations.json` — mutations list only (not full type schema)
- `wiz_types_combined.json` — NOT yet generated

## Next Actions
- Task A: Copy provider/ to work repo → trigger wiz-graphql-debug.yml → get wiz_types_combined.json → fill mutations.go + resource.go
- Task B: Get creds from tenant admin → run terraform import locally → expand main.tf → terraform plan clean

## Important Notes
- No local Wiz creds on either machine — all real API calls via GitHub Actions
- Cannot create Wiz service account (insufficient permissions — need tenant admin)
- Python introspection script (`wiz_graphql_debug.py`) abandoned — Go tool replaces it
- `import.sh` has path bug: targets `environments/prod/` but dir is `environments/PD/`
- `terraform import` is ONE-TIME LOCAL operation — not in CI

## See CLAUDE.md for full detail
