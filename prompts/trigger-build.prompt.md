# Trigger Build Flow

## Step 1: Resolve workflow

Ask the user:
1. Workflow to trigger:
   - List workflows found in `.github/workflows/` (auto-detected)
   - Or: Custom URL
2. Branch name:
   - Ask for explicit consent on branch selection before trigger
   - Default: `main`
   - Or: Custom branch

Consent example:

```
Trigger this build on branch `main`? (yes/no)
```

Do not dispatch until branch consent is explicit.

---

## Step 1.5: Prerequisite checks (required)

Run shared preflight first:

```bash
./scripts/preflight_validate.sh \
   --action trigger-build \
   --workflow-url <workflow-url> \
   --branch <branch-name>
```

Then validate and report:
1. Workflow exists
2. Workflow is enabled/active
3. Caller has permission to dispatch
4. Required inputs are valid
5. Required secrets/variables for requested lane are present
6. Signing prerequisites for signed outputs are present

If any prerequisite is missing:
- Do not fail with a generic error.
- Explain what is missing and why it matters.
- Provide exact remediation steps.
- Offer alternatives when available, for example:
   1. Configure signing assets for signed IPA
   2. Run unsigned CI validation build
   3. Configure Fastlane Match

Only trigger after prerequisites pass (or user explicitly chooses an alternative path).

---

## Step 2: Inspect workflow inputs

Run:

```bash
./scripts/inspect_workflow_inputs.sh <workflow-url> [branch=main]
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
./scripts/trigger_existing_workflow.sh <workflow-url> [branch=main] [inputs...]
```

Show concise status:

```
Environment: Configured ✓
Triggering: <workflow> on <branch>
Teams: Build Started notification sent (if webhook configured)
```

Return:
- Workflow name
- Run ID
- Build URL
- Current status

If `GH_TOKEN` is missing:

```
Missing env setup → add GH_TOKEN to .notification.local.env
```

---

## Step 5: Post-trigger

After a successful trigger, offer:
- View run: `gh run list --workflow=<name>`
- Open PR against `main` if build is from a feature branch

Also include short monitoring guidance:
- Check live status
- Capture failure reason and failing job
- Provide immediate remediation recommendations

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

## Required Response Format

### Status
PASS / FAIL / BLOCKED

### Findings
- List findings with root cause + impact

### Missing Prerequisites
- Explicit list (or "None")

### Recommended Actions
1. Ordered by priority

### Next Action
- Single best next step

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
