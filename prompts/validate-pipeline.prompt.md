# Validate Pipeline Flow

## Objective

Run full validation for workflow correctness and release readiness.

---

## Step 1: Run required preflight

Run:

```bash
./scripts/preflight_validate.sh \
  --action validate-pipeline \
  --workflow-url <workflow-url> \
  --branch <branch-name>
```

Default branch: `main` if not provided.

If preflight is FAIL/BLOCKED:
- Continue validation checks
- Return exact remediation steps

---

## Step 2: Validate pipeline components

Check:
1. Workflow syntax and trigger model
2. Fastlane lanes used by workflow
3. Signing configuration
4. Required secrets/variables
5. Firebase configuration
6. Build configuration and runner compatibility
7. Branch protection compatibility

---

## Step 3: Return PASS/FAIL report

For every failure include:
- Root cause
- Impact
- Recommended fix

Never return only raw tool output.

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
