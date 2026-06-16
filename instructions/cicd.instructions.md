# CI/CD Rules

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
- Never infer branch name; always ask or use current branch