# CI/CD Rules

## General

- Use GitHub Actions
- Keep workflows deterministic
- Never hardcode secrets
- Use workflow_dispatch for manual runs

---

## Pipeline Creation

- Always use template:
  .github/pipeline-templates/ios-fastlane-workflow.template.yml

- Do NOT copy from existing workflows
- Use defaults unless user asks customization

---

## iOS Rules

- Use macos-latest runner
- Use generic/platform=iOS

---

## Fastlane

- Use env variables
- Do not commit credentials

---

## Trigger Rules

- Always use workflow URL
- Never infer branch
- Always inspect inputs before triggering