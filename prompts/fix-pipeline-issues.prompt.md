# Fix Pipeline Issues Flow

## Objective

Diagnose pipeline failures, remediate root cause, and implement fixes whenever possible.

---

## Step 1: Run preflight with workflow context

Run:

```bash
./scripts/preflight_validate.sh \
  --action fix-pipeline-issues \
  --workflow-url <workflow-url> \
  --branch <branch-name>
```

---

## Step 2: Triage and classify failure

Always identify:
1. Root cause
2. Failure category:
   - Permissions
   - Signing
   - Secrets
   - Dependency issue
   - Build failure
   - Deployment failure
3. Impact

---

## Step 3: Remediate

Do not stop at reporting:
1. Propose exact fixes
2. Apply fixes when possible
3. Re-validate
4. Open PR if repository changes are required

For iOS signing failures (no provisioning profile):
- Determine if signed IPA is required
- If signed IPA required: recommend Match and signing setup
- If validation-only build is acceptable: use `skip_codesigning: true` and `CODE_SIGNING_ALLOWED=NO`
- Explain tradeoffs

---

## Required Response Format

### Status
PASS / FAIL / BLOCKED

### Findings
- Explicit findings with root cause and impact

### Missing Prerequisites
- Explicit list (or "None")

### Recommended Actions
1. Ordered by priority

### Next Action
- Single best next step
