# Trigger Build Flow

## Step 1: Resolve workflow

Ask the user:
1. Workflow to trigger:
   - List workflows found in `.github/workflows/` (auto-detected)
   - Or: Custom URL
2. Branch name:
   - Current branch (default)
   - Or: Custom branch

---

## Step 2: Inspect workflow inputs

Run:

```bash
./scripts/inspect_workflow_inputs.sh <workflow-url> <branch>
```

Parse the output and show only the discovered inputs to the user.

---

## Step 3: Ask inputs dynamically

Render only inputs returned by the inspect script.

Common inputs example:

```
1. preset:
   - Debug-CICD (default)
   - Release-CICD

2. release_notes (optional, free text)
```

---

## Step 4: Trigger build

Check environment:

```bash
./scripts/trigger_existing_workflow.sh <workflow-url> <branch> [inputs...]
```

Show concise status:

```
Environment: Configured ✓
Triggering: <workflow> on <branch>
```

If `GH_TOKEN` is missing:

```
Missing env setup → add GH_TOKEN to .notification.local.env
```

---

## Step 5: Post-trigger

After a successful trigger, offer:
- View run: `gh run list --workflow=<name>`
- Open PR against `main` if build is from a feature branch

Show this when missing:

Missing env setup
Run: cp .env.example .notification.local.env

Run:

./scripts/trigger_existing_workflow.sh \
<workflow-url> \
<branch> \
preset=<value> \
config_Override=<value> \
Release_Notes="<value>"

---

## Step 5: Output

Build triggered successfully

Run URL: <github-run-url>

---

## Notifications

IF TEAM_WEBHOOK_URL exists in `.notification.local.env`, local shell env, or GitHub Secrets:
→ Notify team when build is triggered, then monitor build status in background and notify again on completion with:
  - Status (success, failure, cancelled, etc.)
  - Build run URL

The background monitor will automatically send team notifications for:
- Build success
- Build failure
- Build cancelled
- Any other terminal state

ELSE:
Show:

Missing env setup

To enable:
cp .env.example .notification.local.env

Then fill:

TEAM_WEBHOOK_URL=<webhook-url>
CICD_CHAT_PROVIDER=teams
