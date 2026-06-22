#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-}"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required"
  exit 1
fi

if [[ -z "$REPO" ]]; then
  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ "$remote_url" =~ ^git@[^:]+:([^/]+/[^/]+)(\.git)?$ ]]; then
    REPO="${BASH_REMATCH[1]}"
  elif [[ "$remote_url" =~ ^https?://[^/]+/([^/]+/[^/]+)(\.git)?$ ]]; then
    REPO="${BASH_REMATCH[1]}"
  fi
fi

if [[ -z "$REPO" ]]; then
  echo "Usage: $0 <owner/repo>"
  exit 1
fi

read -r -p "Paste Teams Incoming Webhook URL: " WEBHOOK_URL

if [[ -z "$WEBHOOK_URL" ]]; then
  echo "Webhook URL cannot be empty"
  exit 1
fi

if [[ "$WEBHOOK_URL" != https://* ]]; then
  echo "Invalid webhook URL: must start with https://"
  exit 1
fi

if [[ "$WEBHOOK_URL" == *"teams.microsoft.com/l/channel"* ]]; then
  echo "This is a Teams channel URL, not an Incoming Webhook URL."
  echo "Create an Incoming Webhook in Teams and use that URL instead."
  exit 1
fi

echo -n "$WEBHOOK_URL" | gh secret set TEAM_WEBHOOK_URL --repo "$REPO"
echo -n "$WEBHOOK_URL" | gh secret set TEAMS_WEBHOOK_URL --repo "$REPO"

echo "Saved webhook permanently in GitHub Secrets for $REPO: TEAM_WEBHOOK_URL and TEAMS_WEBHOOK_URL"
