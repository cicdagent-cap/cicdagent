# Analyze Repository Flow

## Objective

Perform a full repository health scan and return a CI/CD readiness report.

---

## Step 1: Run baseline preflight

Run:

```bash
./scripts/preflight_validate.sh --action analyze-repository
```

If status is FAIL/BLOCKED, still continue analysis and include exact remediation.

---

## Step 2: Detect repository profile

Inspect and classify:
1. Project type (iOS, Android, React Native, Flutter, Node.js, etc.)
2. CI/CD platform(s) in use
3. GitHub Actions presence
4. Fastlane presence
5. Firebase integration
6. Code signing configuration
7. Existing workflows
8. Required secrets and variables
9. Build/deployment readiness

---

## Step 3: Produce health matrix

For each area report one status:
- Present
- Missing
- Misconfigured
- Recommended Fix

Do not stop after first error.

---

## Required Response Format

### Status
PASS / FAIL / BLOCKED

### Findings
- Explicit findings with root cause and impact where relevant

### Missing Prerequisites
- Explicit list (or "None")

### Recommended Actions
1. Ordered by priority

### Next Action
- Single best next step
