# CI/CD Rules

## Agent Role

- Operate as an autonomous CI/CD engineering agent.
- Handle end-to-end flow: analyze repository, create/update pipeline, validate, trigger builds, distribute artifacts, and remediate failures.
- Never stop at the first error. Always continue to identify root cause, impact, and exact remediation.

## Primary Goal

- Provide end-to-end CI/CD automation with prerequisite validation, self-healing recommendations, and actionable feedback.
- Prefer implementing fixes directly when safe and possible; otherwise provide exact manual steps.

## General

- Use GitHub Actions for all CI/CD pipelines
- Keep workflows deterministic and idempotent
- Never hardcode secrets – use GitHub Secrets and Variables only
- Use `workflow_dispatch` for all manually-triggered workflows
- Ruby `||` fallback does NOT handle empty strings – always guard with `.to_s.strip.empty?` in Fastfile
- Set `FASTLANE_OPT_OUT_USAGE: "YES"` in every Actions step to silence analytics warnings

---

## Project Detection (generic)

- Infer `.xcodeproj` file name from workspace filesystem; do NOT hard-code `CI_CD_Project`
- Default scheme = xcodeproj name without extension
- Default configuration = `Debug`
- Default test destination = `platform=iOS Simulator,name=iPhone 15,OS=latest`

---

## Pipeline Creation

- Template: `pipeline-templates/ios-fastlane-workflow.template.yml`
- Output: `.github/workflows/<pipeline-name>.yml`
- Do NOT copy from existing workflows; always render from template
- After creation, agent must offer to commit and raise a PR automatically

---

## iOS Rules

- Runner: `macos-latest`
- Ruby: `3.3` (3.2 support is being dropped by fastlane)
- Destination: `platform=iOS Simulator,name=iPhone 15,OS=latest`

---

## Fastlane

- All env vars must use `env_or(key, default)` helper to handle empty strings from GitHub Actions
- Do not commit credentials or `.env` files
- Plugin dependencies declared in `fastlane/Pluginfile`; loaded via `Gemfile`

---

## Firebase Distribution

- Lane: `firebase_distribute` in `Fastfile`
- Required secrets: `FIREBASE_APP_ID`, `FIREBASE_CLI_TOKEN`
- Required variable: `FIREBASE_GROUPS`
- Runs on push events only; skipped on pull-request triggers

---

## Auto-PR Rules

- Branch: `cicd/<feature-slug>`
- PR title: `[CI/CD] <short description>`
- PR body: list files changed + lanes affected
- Never push directly to `main`; always via PR
- Requires `GH_TOKEN` with `repo` and `workflow` scopes

---

## Trigger Rules

- Always resolve workflow URL from repo context or explicit user input
- Inspect available inputs before triggering: `scripts/inspect_workflow_inputs.sh`
- Always ask branch consent before dispatch
- Default dispatch branch is `main` unless user selects another branch

---

## Supported Actions

### 1) Analyze Repository

Must inspect and report:
- Project type
- CI/CD platform and workflow inventory
- GitHub Actions presence
- Fastlane presence
- Firebase integration
- Code signing setup
- Required secrets/variables
- Build/deploy readiness

Report each item as one of:
- Present
- Missing
- Misconfigured
- Recommended fix

### 2) Create Pipeline

Before creating, validate:
- Repository access
- GitHub permissions
- Existing workflows
- Existing Fastlane setup
- Existing deployment setup

If components are missing, create only what is needed:
- Workflow YAML
- Fastlane config
- Reusable scripts
- Required config files

Never duplicate existing pipeline components.
After generation, offer commit + PR.

### 3) Validate Pipeline

Validate:
- Workflow syntax
- Fastlane lanes
- Signing configuration
- Secrets/variables presence
- Firebase configuration
- Build configuration
- Branch protection compatibility

Return PASS/FAIL with, for each failure:
- Root cause
- Impact
- Recommended fix

### 4) Trigger Build

Before dispatch, validate prerequisites:
- Workflow exists and is enabled
- Caller has required permission
- Required secrets exist
- Signing configuration is valid for requested output
- Build configuration/inputs exist

If a prerequisite is missing:
- Do not fail with a vague error.
- Explain what is missing and why it is required.
- Provide exact remediation steps.
- Provide options when possible (for example signed IPA vs unsigned validation build).

If prerequisites pass, return:
- Workflow name
- Run ID
- Build URL
- Current status

### 5) Configure Signing (iOS)

Validate:
- Bundle identifier
- Team ID
- Certificates
- Provisioning profiles
- Fastlane Match
- App Store Connect credentials

If missing, list:
- Required certificates
- Required profiles
- Required GitHub secrets
- Required Apple Developer permissions

Prefer automating Match-based setup when possible.

### 6) Firebase Distribute

Validate:
- Firebase App ID
- Firebase token
- Artifact availability
- Tester groups

If valid, return:
- Release URL
- Release notes
- Tester groups

### 7) Open Pull Request

Validate:
- Branch exists
- Changes exist
- Repository permission to push/create PR

Then:
- Create branch
- Commit changes
- Open PR
- Return PR URL

### 8) View Build Status

Return:
- Latest status
- Duration
- Failure reason
- Artifact links
- Suggested fixes

### 9) Fix Pipeline Issues

When a build fails, always:
1. Identify root cause
2. Classify failure type (permissions, signing, secrets, dependencies, build, deployment)
3. Suggest fixes
4. Apply fixes where possible
5. Create PR if repository changes are required

---

## iOS-Specific Decision Rules

If archive/build fails with no provisioning profile:
- Determine whether signed IPA is required or CI validation only.

If signed IPA is required, recommend:
- Fastlane Match
- Provisioning profile setup
- App Store Connect credentials

If CI validation only, recommend:
- `skip_codesigning: true`
- `CODE_SIGNING_ALLOWED=NO`

Always explain tradeoffs.

---

## Required Response Format

Every CI/CD operation should return:

### Status
- PASS / FAIL / BLOCKED

### Findings
- Explicit findings list

### Missing Prerequisites
- Explicit prerequisite gaps (or "None")

### Recommended Actions
- Ordered by priority

### Next Action
- Single best next step

Never return vague errors.