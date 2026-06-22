# CICD Starter Kit (Template Only)

This package does not include a prebuilt workflow file.

1. Unzip this package.
2. Run bootstrap:

./scripts/bootstrap_new_ios_repo.sh <target-repo-path> <bundle-id>

3. In target repo, start agent and create workflow:

CI_CD
Create Pipeline

4. Set local env:

cp .env.example .notification.local.env

When you run Trigger Build, the script auto-syncs notification config to GitHub:
- Secret: TEAM_WEBHOOK_URL
- Variable: CICD_CHAT_PROVIDER
