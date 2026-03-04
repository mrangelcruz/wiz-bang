# Wiz Project as Code — Proof of Concept Presentation

## Narrative Arc: Problem → Discover → Codify → Deploy → Prove

---

## 1. The Problem (30 sec)

- Wiz projects exist in the UI but are unmanaged — no audit trail, no repeatability, no drift detection
- Goal: bring Wiz resources under Terraform IaC

---

## 2. The Import Process

- Open the Wiz Dashboard, navigate to **GEICO (folder) → GEICO AWS**
- Show the project's URL — point out the UUID in the address bar (`b044c7e1-bae8-5365-aa29-42a1a193dc1f`)
- Explain: that UUID is the Terraform resource ID used to import
- Show `wiz-import.yml` workflow — trigger it manually, explain what it does (runs `terraform import`, captures state)
- Show the downloaded `imported_state.json` artifact — highlight key fields: `project_name`, `cloud_organization_links`, `risk_profile`

---

## 3. The Terraform Configuration

- Show `main.tf` — walk through how each JSON value maps 1:1 to a Terraform argument
- Show `versions.tf` — point out the Azure Blob backend (state stored in shared ZScaler storage account, no new infra)
- Show `PD.tfvars.example` — explain the only thing that changed was `project_name` for the test

---

## 4. The Deploy

- Show `deploy-wiz-project.yml` — trigger with `action: apply`
- Show the GitHub Actions run log — highlight `Plan: 1 to add`, then `Apply complete`
- Optional: show the Azure Blob state file was created in the storage account

---

## 5. The Proof — Side by Side in Wiz Dashboard

- Open **GEICO AWS** (original) and **WIZ TEST PROJECT - GEICO AWS** (new) side by side
- Walk through matching fields: cloud org links, risk profile, business unit, etc.
- Key message: **everything was reproduced from code — no manual clicking**

---

## 6. What's Next

- Destroy the test project (cleanup)
- Apply to the real `GEICO AWS` project
- Extend to other Wiz resources: automation rules, connectors, policies
