# Configure Signing Flow (iOS)

## Objective

Validate and remediate iOS signing prerequisites for CI/CD.

---

## Step 1: Run signing preflight

Run:

```bash
./scripts/preflight_validate.sh --action configure-signing
```

---

## Step 2: Validate signing prerequisites

Check:
1. Bundle identifier
2. Team ID
3. Certificates
4. Provisioning profiles
5. Fastlane Match configuration
6. App Store Connect credentials

---

## Step 3: Handle missing assets

If missing, provide:
- Required certificates
- Required provisioning profiles
- Required GitHub secrets
- Required Apple Developer permissions

If signed IPA is required:
- Recommend Fastlane Match + full signing setup

If CI validation only:
- Recommend `skip_codesigning: true`
- Recommend `CODE_SIGNING_ALLOWED=NO`
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
