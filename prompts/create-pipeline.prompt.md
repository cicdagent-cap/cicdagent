# Create Pipeline Flow

## Step 0: Run required preflight

Run:

```bash
./scripts/preflight_validate.sh --action create-pipeline
```

If preflight is FAIL/BLOCKED:
- Do not stop at generic errors.
- Explain missing prerequisites and exact remediation.
- Continue with safe preparation steps where possible.

## Step 1: Infer project context

Before asking the user anything, scan the workspace:
- Find `*.xcodeproj` → use as `CICD_PROJECT_FILE` default
- Derive `CICD_DEFAULT_SCHEME` = xcodeproj name without extension
- Confirm with user only if multiple `.xcodeproj` files are found

---

## Step 2: Ask user (minimal)

Ask only:
1. Pipeline name (example: `my-app-ci`)
2. Output path (default: `.github/workflows/<pipeline-name>.yml`)
3. Firebase distribution? Yes / No

---

## Step 3: Resolve file path

IF user gives full file path → use as-is  
IF user gives folder only → generate: `<folder>/<pipeline-name>.yml`

Naming rules:
- lowercase
- replace spaces with `-`

Example: `My App CI` → `my-app-ci.yml`

---

## Step 4: Generate workflow YAML

Use template: `pipeline-templates/ios-fastlane-workflow.template.yml`

Substitute:

| Placeholder | Value |
|---|---|
| `__PIPELINE_NAME__` | user input |
| `__PROJECT_FILE__` | inferred `.xcodeproj` |
| `__SCHEME__` | inferred scheme |
| `__RUNNER_LABEL__` | `macos-latest` |
| `__RUBY_VERSION__` | `3.3` |

Defaults (do not ask user unless they want customisation):
- Configuration: `Debug`
- Test destination: `platform=iOS Simulator,name=iPhone 15,OS=latest`
- Firebase distribute: on push only, skip on PR

Always include:
- `FASTLANE_OPT_OUT_USAGE: "YES"` on every Fastlane step
- `concurrency` block to cancel stale runs

Avoid duplicating existing workflow components.

---

## Step 5: Auto-commit and open PR

After writing the file, offer:

```
Commit and open PR automatically? [Y/n]
```

If yes:
```bash
git checkout -b cicd/<pipeline-name>
git add .github/workflows/<pipeline-name>.yml
git commit -m "[CI/CD] Add <pipeline-name> workflow"
git push origin cicd/<pipeline-name>
gh pr create --title "[CI/CD] Add <pipeline-name> workflow" \
             --body "Auto-generated pipeline: <pipeline-name>\nProject: <xcodeproj>\nScheme: <scheme>"
```

Requires `GH_TOKEN` in environment. If missing, show manual push instructions.

## Step 4: Output

✅ Pipeline created

File path:
<resolved_path>

Next steps:
1. Commit & push file
2. Open GitHub Actions
3. Run pipeline

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

---

## Required Setup

Variables:
- CICD_PROJECT_FILE
- CICD_DEFAULT_SCHEME
- CICD_DEFAULT_CONFIGURATION
- CICD_TEST_DESTINATION
- CICD_CHAT_PROVIDER

Secrets:
- APP_STORE_CONNECT_API_KEY
- MATCH_PASSWORD
- TEAM_WEBHOOK_URL
``