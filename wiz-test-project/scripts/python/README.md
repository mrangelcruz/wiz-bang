

# Wiz GraphQL Introspection (POC)

⚠️ **Temporary / Proof-of-Concept tooling**

This directory contains Python scripts used **only** for reverse-engineering
and validating Wiz GraphQL APIs during proof-of-concept efforts.

These scripts are **not intended for long-term production use**.

---

## Purpose

- Discover available Wiz GraphQL mutations
- Identify Azure connector / deployment APIs
- Validate authentication from CI
- Support Terraform gap analysis

Once Azure connectors are supported by the official Wiz Terraform provider,
this directory can be deleted.

---

## Environment Variables

Expected environment variables (in CI):

- `WIZ_API_URL`
- `WIZ_TOKEN_URL` (default: https://auth.app.wiz.io/oauth/token)
- `WIZ_CLIENT_ID`
- `WIZ_CLIENT_SECRET`

---

## Scripts

### wiz_graphql_debug.py

- Performs GraphQL schema introspection
- Filters Azure / connector / deployment mutations
- Writes artifacts for offline inspection

Outputs:
- `wiz_typename.json`
- `wiz_introspection_mutations.json`
- `wiz_mutations_filtered.txt`

---

## Lifecycle

| Script | Expected Lifetime |
|------|------------------|
| `wiz_graphql_debug.py` | Short-lived |
| `ensure_azure_connector.py` | Temporary bridge |
| Terraform | Long-term |

Safe to delete this entire directory once the Terraform provider
supports Azure connectors. 

