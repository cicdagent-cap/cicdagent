# View Build Status Flow

## Objective

Return a concise but complete status report for recent CI/CD runs.

---

## Step 1: Run status preflight

Run:

```bash
./scripts/preflight_validate.sh \
  --action view-build-status \
  --workflow-url <workflow-url> \
  --branch <branch-name>
```

Default branch: `main`.

---

## Step 2: Gather status details

Collect:
1. Latest build status
2. Build duration
3. Failure reason (if failed)
4. Artifact links
5. Suggested fixes

If failed, include root cause category and remediation.

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
