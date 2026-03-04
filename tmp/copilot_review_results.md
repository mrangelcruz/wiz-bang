# Copilot / Semgrep PR Review — Resolution Summary

## deploy-wiz-project.yml

### [FIXED] Wrong working directory and paths
- **Finding:** Workflow used `wiz-test-project` as working directory and path filter, which does not exist post-refactor.
- **Resolution:** Work repo had a stale version of this file. Local repo already has correct paths (`wiz-projects/environments/...`). Push updated file to work repo to resolve.

### [FIXED] Command injection via inputs.env (Semgrep)
- **Finding:** `${{ inputs.env }}` was interpolated directly into shell, allowing arbitrary command injection.
- **Resolution:** Fixed in local repo. Moved expression to an `env:` var (`TF_ENV`) and referenced it as `${TF_ENV}` in the shell script.

---

## wiz-graphql-debug.yml

### [DEFERRED — Task A] Token response logged in plaintext
- **Finding:** curl response (which includes access_token) printed to workflow logs; not masked by GitHub Actions.
- **Resolution:** Valid security concern. Deferred to Task A branch (`feature/wiz-azure-provider`). Fix: output only HTTP status code, not response body.

### [DEFERRED — Task A] Stale paths (wiz-test-project/scripts/python/...)
- **Finding:** Workflow references `wiz-test-project/scripts/python/requirements.txt` and `wiz_graphql_debug.py`, paths that no longer exist post-refactor.
- **Resolution:** Task A workflow, deferred. Will be corrected when Task A work resumes.

---

## wiz-projects/provider.tf

### [ACCEPTED AS-IS] Implicit env var auth
- **Finding:** Copilot suggests wiring `client_id`/`client_secret` as explicit Terraform variables instead of relying on env vars.
- **Resolution:** Not changing. Our design intentionally uses `WIZ_CLIENT_ID`/`WIZ_CLIENT_SECRET` env vars, consistent with the Wiz provider's documented env var support and how secrets are injected in CI.

---

## wiz-projects/modules/wiz-project/main.tf

### [ACCEPTED AS-IS] Unused module
- **Finding:** The `modules/wiz-project/` module is not referenced by any root or environment config.
- **Resolution:** Not removing. It is a scaffold for future use when environments are refactored to use a shared module. No functional impact.

---

## wiz-projects/outputs.tf

### [OUT OF SCOPE] try(..., null) masks errors
- **Finding:** `try(wiz_project.this.id, null)` silently returns null on failure.
- **Resolution:** This file exists in the work repo as pre-existing code, not introduced by this PR. Out of scope for this change.

---

## Summary

| Item | File | Status |
|------|------|--------|
| Wrong working-directory / paths | deploy-wiz-project.yml | FIXED (push to work repo) |
| Command injection (Semgrep) | deploy-wiz-project.yml | FIXED locally |
| Token logged in plaintext | wiz-graphql-debug.yml | DEFERRED (Task A) |
| Stale script paths | wiz-graphql-debug.yml | DEFERRED (Task A) |
| Implicit provider auth | wiz-projects/provider.tf | ACCEPTED AS-IS |
| Unused module | wiz-projects/modules/ | ACCEPTED AS-IS |
| try(..., null) in output | wiz-projects/outputs.tf | OUT OF SCOPE |

**Remaining action:** Push updated `deploy-wiz-project.yml` from local repo to work repo (`wiz-test-project` branch).
