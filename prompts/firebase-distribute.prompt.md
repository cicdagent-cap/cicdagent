# Firebase Distribute Flow

## Objective

Distribute build artifacts to Firebase App Distribution with prerequisite checks.

---

## Step 1: Run Firebase preflight

Run:

```bash
./scripts/preflight_validate.sh \
  --action firebase-distribute \
  --artifact <path-to-ipa>
```

---

## Step 2: Validate requirements

Validate:
1. `FIREBASE_APP_ID` secret
2. `FIREBASE_CLI_TOKEN` secret
3. `FIREBASE_GROUPS` variable
4. Artifact availability

If any are missing, return exact setup instructions.

---

## Step 3: Execute distribution

Run:

```bash
bundle exec fastlane ios firebase_distribute
```

Return:
- Release URL
- Release notes
- Tester groups

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
