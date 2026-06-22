# CI_CD_Project

This repository contains an iOS Swift project with GitHub Actions, Fastlane, local build-trigger scripts, and a workspace CICD agent flow.

## First Step For Any New Project

Before using CICD agent modes (`Create Pipeline` or `Trigger Build`) in a new repository, run the standard onboarding checklist in:

- `CICD_HOT_RUN_SETUP.md`

Fast path (recommended):

```bash
./scripts/bootstrap_new_ios_repo.sh <target-repo-path> <bundle-id>
```

Example:

```bash
./scripts/bootstrap_new_ios_repo.sh /Users/you/projects/MyiOSApp com.example.myiosapp
```

## Quick Start

For local setup, copy the example environment file:

```bash
cp .env.example .notification.local.env
```

Then fill the local values you need, such as:

```bash
TEAM_WEBHOOK_URL=<teams-or-slack-webhook-url>
FASTLANE_TEAM_ID=<apple-team-id>
MATCH_PASSWORD=<match-password>
```

Start the CICD agent in chat with:

```text
CI_CD
```

Choose one mode:

- `Create Pipeline`
- `Trigger Build`

Type `stop` to exit the CICD agent flow.

## Configuration Layers

Use three layers of configuration:

| Layer | File or location | Purpose |
| --- | --- | --- |
| Developer template | `.env.example` | Safe placeholder values for onboarding |
| Local machine | `.notification.local.env` | Real local values for local scripts, never committed |
| GitHub Actions | Repository Secrets and Variables | CI runtime configuration |

The local env file is ignored by git. Do not commit webhook URLs, Apple keys, tokens, certificates, or passwords.

## Local Environment Files

### `.env.example`

This file is committed and safe to share. It contains placeholder values for:

- app build settings
- Fastlane team and bundle settings
- Fastlane match settings
- notification settings

### `.notification.local.env`

This file is local-only and should be created from the template:

```bash
cp .env.example .notification.local.env
```

The trigger and notification scripts load this file automatically. They also support a custom path:

```bash
CICD_LOCAL_ENV_FILE=path/to/.notification.local.env ./scripts/trigger_existing_workflow.sh ...
```

## Central Config Files

| File | Purpose |
| --- | --- |
| `.github/cicd.config.yml` | Agent/runtime defaults, local env setup command, required GitHub Variables and Secrets |
| `.github/cicd.env.config.yml` | Human-readable environment defaults for app, Fastlane, match, and notifications |
| `.github/trigger-build-request.yml` | Example request shape for triggering an existing workflow |
| `.github/pipeline-request.yml` | Example request shape for creating a pipeline |

These config files must contain names, defaults, and placeholders only. Do not put real secret values in them.

## GitHub Actions Setup

Create these repository Variables in GitHub:

| Variable | Purpose |
| --- | --- |
| `CICD_PROJECT_FILE` | Xcode project file, for example `CI_CD_Project.xcodeproj` |
| `CICD_DEFAULT_SCHEME` | Default Xcode scheme |
| `CICD_DEFAULT_CONFIGURATION` | Build configuration, for example `Debug` |
| `CICD_TEST_DESTINATION` | Simulator destination used for tests |
| `FASTLANE_TEAM_ID` | Apple Developer team ID |
| `FASTLANE_ITC_TEAM_ID` | App Store Connect team ID |
| `FASTLANE_BUNDLE_IDENTIFIER` | iOS app bundle identifier |
| `MATCH_GIT_URL` | Git URL for the Fastlane match certificates repository |
| `CICD_CHAT_PROVIDER` | Notification provider: `teams`, `slack`, or `generic` |

Create these repository Secrets in GitHub:

| Secret | Purpose |
| --- | --- |
| `TEAM_WEBHOOK_URL` | Teams or Slack incoming webhook URL |
| `MATCH_PASSWORD` | Password for decrypting Fastlane match certificates/profiles |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Git basic auth token for the match repository, if needed |
| `APP_STORE_CONNECT_API_KEY` | App Store Connect API key content, if release lanes need it |

GitHub path:

1. Open the repository in GitHub.
2. Go to `Settings` > `Secrets and variables` > `Actions`.
3. Add secure values under `Secrets`.
4. Add non-sensitive values under `Variables`.

## Current Workflow

The current workflow file is:

- `.github/workflows/cicd-ios.yml`

It runs on:

- push to `main`
- pull request to `main`
- manual `workflow_dispatch`

The manual input is:

| Input | Values |
| --- | --- |
| `preset` | `Debug-CICD`, `Release-CICD` |

The workflow runs Fastlane:

- `Debug-CICD` -> `fastlane ios build`
- `Release-CICD` -> `fastlane ios release`

## Fastlane Setup

Fastlane reads configuration from environment variables:

| File | Uses |
| --- | --- |
| `fastlane/Appfile` | `FASTLANE_BUNDLE_IDENTIFIER`, `FASTLANE_TEAM_ID`, `FASTLANE_ITC_TEAM_ID` |
| `fastlane/Fastfile` | `CICD_PROJECT_FILE`, `CICD_DEFAULT_SCHEME`, `CICD_DEFAULT_CONFIGURATION`, `CICD_TEST_DESTINATION`, `RELEASE_NOTES` |
| `fastlane/Matchfile` | `MATCH_GIT_URL`, `FASTLANE_BUNDLE_IDENTIFIER`, `FASTLANE_TEAM_ID` |

Available lanes:

- `ios build`
- `ios test`
- `ios release`

## Trigger Build Locally

Prerequisites:

- GitHub CLI installed: `gh`
- GitHub CLI authenticated: `gh auth login`
- Local env file configured: `.notification.local.env`

Inspect workflow inputs before triggering:

```bash
./scripts/inspect_workflow_inputs.sh https://github.com/example-org/example-repo/actions/workflows/build.yml feature/example
```

Trigger an existing workflow:

```bash
./scripts/trigger_existing_workflow.sh \
  https://github.com/example-org/example-repo/actions/workflows/build.yml \
  feature/example \
  preset=Debug-CICD \
  config_Override=None \
  Release_Notes="Demo build"
```

The trigger script prints one of these environment statuses before dispatch:


or:

```text
Missing env setup
Run: cp .env.example .notification.local.env
```

After dispatch, the script extracts the exact GitHub Actions run URL, starts a background monitor for that run, and sends the final notification for that specific build only.

## Notifications

Notifications are sent by:

- `scripts/notify.sh`

The notification contains only:

- final status
- build/run link

Required local values:

```bash
TEAM_WEBHOOK_URL=<webhook-url>
CICD_CHAT_PROVIDER=teams
```

Supported providers:

- `teams`
- `slack`
- `generic`

If `TEAM_WEBHOOK_URL` is missing, the scripts skip notification without failing the build trigger.

## CICD Agent Behavior

The workspace CICD agent is defined in:

- `.github/agents/CICD.agent.md`
- `.github/prompts/create-pipeline.prompt.md`
- `.github/prompts/trigger-build.prompt.md`

Trigger Build flow:

1. Ask for workflow URL.
2. Ask for branch name.
3. Inspect workflow inputs with `scripts/inspect_workflow_inputs.sh`.
4. Ask only for inputs discovered in the workflow YAML.
5. Trigger with `scripts/trigger_existing_workflow.sh`.
6. Show the run URL.

The agent should not fetch branch lists and should not infer a branch.

## Create Pipeline Flow

Pipeline creation uses this template:

- `.github/pipeline-templates/ios-fastlane-workflow.template.yml`

The agent should use `.github/pipeline-request.yml` as the request example and should not copy values from existing generated workflows unless explicitly asked.

## File Map

| Path | Purpose |
| --- | --- |
| `.env.example` | Local setup template |
| `.notification.local.env` | Local secrets/config, ignored by git |
| `.github/workflows/cicd-ios.yml` | Current GitHub Actions iOS workflow |
| `.github/cicd.config.yml` | Agent/runtime config and required values |
| `.github/cicd.env.config.yml` | Environment defaults reference |
| `.github/trigger-build-request.yml` | Trigger request example |
| `.github/pipeline-request.yml` | Pipeline creation request example |
| `scripts/inspect_workflow_inputs.sh` | Reads workflow_dispatch inputs from a workflow URL |
| `scripts/trigger_existing_workflow.sh` | Triggers a workflow URL and monitors the exact run |
| `scripts/notify.sh` | Sends status and build link notification |
| `fastlane/Appfile` | Fastlane app/team config from env |
| `fastlane/Fastfile` | Fastlane lanes |
| `fastlane/Matchfile` | Fastlane match config from env |

## Security Rules

- Commit `.env.example` only with placeholders.
- Never commit `.notification.local.env`.
- Store local real values in `.notification.local.env` or shell env.
- Store CI real values in GitHub Secrets and Variables.
- Never hardcode webhook URLs, Apple API keys, tokens, certificates, provisioning profiles, or passwords.
