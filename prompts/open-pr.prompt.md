# Open Pull Request Flow

## Objective

Create a branch, commit CI/CD changes, and open a PR with validation gates.

---

## Step 1: Run PR preflight

Run:

```bash
./scripts/preflight_validate.sh --action open-pr
```

Validate:
1. Branch exists
2. Changes exist
3. Repository permissions are sufficient

---

## Step 2: Create PR

Use conventions:
- Branch: `cicd/<feature-slug>`
- Title: `[CI/CD] <description>`
- Body: files changed + lanes affected

Commands:

```bash
git checkout -b cicd/<feature-slug>
git add <changed-files>
git commit -m "[CI/CD] <description>"
git push origin cicd/<feature-slug>
gh pr create --title "[CI/CD] <description>" --body "<summary>"
```

Return PR URL.

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
