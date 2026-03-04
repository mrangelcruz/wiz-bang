# Terraform + Wiz Concepts — Q&A Session 2026-03-04

## Terraform State & Import

**Q: If I run the deploy-wiz-project action (plan), what happens without a remote state backend?**

Terraform starts with a blank state each run. It won't know the resource was already imported — it will show "Plan: 1 to add" because it thinks the resource doesn't exist. You need a remote backend so state persists between workflow runs.

---

**Q: What does `terraform import` actually do?**

You hand it a UUID and it:
1. Calls the Wiz API with that UUID
2. Reads back all current attributes of the existing resource
3. Writes them into the Terraform state file

From that point on, Terraform knows the resource exists. It didn't create it — it just learned about it. The `wiz_project.this` in state now represents the manually-created project.

---

**Q: Does `terraform import` write state even if I never ran apply?**

Yes. `terraform import` writes directly to the state file, bypassing the plan/apply cycle entirely. The subsequent plan showed `wiz_project.this: Refreshing state... [id=b044c7e1...]` — that was Terraform reading the imported state from Azure Blob.

---

**Q: Where did `imported_state.json` come from?**

The `wiz-import.yml` workflow ran `terraform import`, then immediately ran `terraform show -json > imported_state.json` to capture what was pulled from the Wiz API, and uploaded it as the `wiz-imported-state-PD` artifact. You can download it from: Actions → "Wiz Project Import" → completed run → Artifacts section.

---

**Q: The plan showed "1 to change" with `archive_on_delete`, `creation_method`, `is_import_module_usage`. Will apply touch the existing GEICO project?**

Yes, but safely. It's an in-place update — not destroy and recreate. The Wiz project stays exactly as-is. Those three fields are provider metadata being written:
- `creation_method = "TERRAFORM"` — was blank (created in UI), provider marks it Terraform-managed
- `archive_on_delete = false` — provider default behavior on delete
- `is_import_module_usage = false` — import metadata flag

Think of it as Terraform stamping "I own this now." The actual Wiz project in the UI won't look different to users.

---

## JSON to Terraform Translation

**Q: How do you go from `imported_state.json` to `.tf` files?**

The JSON has two kinds of data:

**Terraform internals — ignore these:**
- `mode`, `address`, `schema_version`, `provider_name`, `id`

**Resource attributes — these become your `.tf` config:**
- `name`, `parent_project_id`, `cloud_organization_links`, `risk_profile`, etc.

Look only at the `values` block inside the resource. Skip anything that's null, empty string (`""`), or empty list (`[]`) — the provider defaults those anyway. Write what's left as HCL.

---

**Q: Why isn't `archive_on_delete` in `main.tf` if it's in the JSON?**

It's `null` in the JSON. The rule: omit if null, empty string, or empty list — the provider defaults them to those values anyway. Only attributes with actual meaningful values made it into `main.tf`:
- `name` → `"GEICO AWS"`
- `parent_project_id` → `"7e546d52-..."`
- `cloud_organization_links` → has a real entry
- `risk_profile` → has real values like `"MBI"`, `"UNKNOWN"`

---

**Q: Where is `mode: managed` in the `.tf` files?**

It isn't — `mode`, `address`, `schema_version`, `provider_name` are Terraform internal metadata. They describe how Terraform tracks the resource, not how you configure it. You never write them in `.tf` files.

---

**Q: How do I know which `risk_profile` keys are optional vs required?**

Three ways:
1. **`wiz-projects/documents/wiz_project.md`** — already in this repo, lists every argument with Required/Optional marked
2. **Wiz provider documentation** — official source at the provider registry
3. **`terraform validate` / `plan`** — if you omit a required field, it errors and tells you what's missing

---

**Q: If I want to create a new Wiz project from scratch (not import an existing one), what's the flow?**

No import needed for greenfield resources:
1. Write the `.tf` config with the attributes you want
2. Run plan — Terraform shows "1 to add"
3. Run apply — Terraform calls the Wiz API to create it

Wiz assigns the UUID automatically. Import only exists for resources that were manually created before Terraform was involved.

---

**Q: If I change only the name in `PD.tfvars.example`, won't there be a conflict reusing the existing `id` or `parent_project_id`?**

No conflict:
- **`id`** — not set in your config, it's computed. Wiz assigns a brand new UUID to the new project.
- **`parent_project_id`** — that's the UUID of the GEICO *folder* (parent container), not the project itself. Both old and new projects live under the same parent folder, like two files in the same directory.

---

## What Terraform Does in Wiz

**Q: How does Terraform accelerate Wiz configuration vs doing it manually?**

Terraform doesn't query Wiz data (e.g., "does org1 have good RDS security posture?") — that's a Wiz dashboard/API question. Terraform manages the *configuration* of Wiz itself.

| Without Terraform | With Terraform |
|---|---|
| Click through Wiz UI to create a project | `terraform apply` → project created |
| Manually replicate settings across envs | Same `.tf` file, different tfvars |
| No audit trail of config changes | Git history shows who changed what, when |
| Hard to recover if misconfigured | `terraform apply` restores known-good state |
| Onboarding a new AWS account = manual clicks | Add one block, apply |

The real accelerator is when you have many accounts/projects to onboard — instead of clicking through Wiz UI 50 times, you loop over a list in Terraform and apply once.

---

**Q: What Wiz resources can Terraform manage?**

- **Projects** — what you're doing now
- **Connectors** — which AWS/Azure accounts Wiz monitors
- **Automation rules** — what alerts trigger what actions
- **SAML/SSO settings**
- **User group mappings**

---

**Q: Is the Azure Connector (Task A Go provider) the same as Wiz Connectors?**

No — two different layers:

```
Task A (Go provider)            Task B (Wiz provider)
─────────────────────           ──────────────────────
Azure service principal    →    wiz_connector_azure
  + permissions                 (tells Wiz "use this SP
                                  to scan this subscription")
```

Task A creates the Azure-side plumbing. Task B tells Wiz to use that plumbing to scan Azure. Both are needed for full Azure connector coverage.

---

## Proving Equivalence

**Q: How do I prove my new TF-created project equals the existing GEICO AWS project?**

1. Run `terraform import` on the existing project → download `imported_state.json`
2. Read the `values` block — that's the ground truth of every attribute
3. Translate non-empty values into `main.tf`
4. Delete the state, change the name, run apply → creates a new project
5. Compare both projects side by side in the Wiz UI

**Your paper trail:** The `imported_state.json` artifact in the Actions run. Anyone can download it and verify the translation from JSON `values` → `main.tf` attributes.

---

## Recommended Learning Order

1. **Projects** ← current focus
2. **Automation rules** ← pure Wiz config, no custom provider needed
3. **SAML/SSO + group mappings** ← pure Wiz config
4. **Connectors** ← needs Task A (Azure Go provider) done first for Azure
