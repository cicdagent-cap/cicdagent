#!/usr/bin/env bash
set -euo pipefail

LOCAL_ENV_FILE="${CICD_LOCAL_ENV_FILE:-.notification.local.env}"
ACTION=""
WORKFLOW_URL=""
BRANCH="main"
REPO_INPUT=""
REQUIRE_SIGNING="auto"
ARTIFACT_PATH=""

STATUS="PASS"
NEXT_ACTION="Proceed with requested CI/CD action"

declare -a FINDINGS=()
declare -a MISSING=()
declare -a RECOMMENDED=()

action_requires_workflow() {
  case "$1" in
    trigger-build|validate-pipeline|view-build-status|fix-pipeline-issues) return 0 ;;
    *) return 1 ;;
  esac
}

has_real_token() {
  local tok="${1:-}"
  if [[ -z "$tok" ]]; then
    return 1
  fi
  if [[ "$tok" =~ ^\<.*\>$ ]] || [[ "$tok" =~ personal-access-token ]] || [[ "$tok" =~ example ]]; then
    return 1
  fi
  return 0
}

action_requires_firebase() {
  case "$1" in
    firebase-distribute) return 0 ;;
    *) return 1 ;;
  esac
}

action_requires_open_pr_checks() {
  case "$1" in
    open-pr) return 0 ;;
    *) return 1 ;;
  esac
}

action_requires_signing_checks() {
  case "$1" in
    configure-signing) return 0 ;;
    trigger-build)
      [[ "$REQUIRE_SIGNING" == "true" ]]
      return
      ;;
    *) return 1 ;;
  esac
}

add_finding() {
  FINDINGS+=("$1")
}

add_missing() {
  MISSING+=("$1")
  if [[ "$STATUS" != "BLOCKED" ]]; then
    STATUS="FAIL"
  fi
}

add_recommended() {
  RECOMMENDED+=("$1")
}

set_blocked() {
  STATUS="BLOCKED"
  NEXT_ACTION="$1"
}

load_local_env() {
  if [[ -x "./scripts/bootstrap_local_env.sh" ]]; then
    ./scripts/bootstrap_local_env.sh "$LOCAL_ENV_FILE" >/dev/null 2>&1 || true
  fi

  if [[ -f "$LOCAL_ENV_FILE" ]]; then
    while IFS= read -r line; do
      if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
        export "$line"
      fi
    done < "$LOCAL_ENV_FILE"
  fi
}

parse_repo_from_git_remote() {
  local remote_url
  remote_url="$(git remote get-url origin 2>/dev/null || true)"

  if [[ -z "$remote_url" ]]; then
    echo ""
    return
  fi

  if [[ "$remote_url" =~ ^git@[^:]+:([^/]+/[^/]+)(\.git)?$ ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi

  if [[ "$remote_url" =~ ^https?://[^/]+/([^/]+/[^/]+)(\.git)?$ ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi

  echo ""
}

trim_git_suffix() {
  local repo="$1"
  echo "$repo" | sed 's/\.git$//'
}

get_yaml_list() {
  local section="$1"
  local key="$2"

  ruby -ryaml -e '
cfg = YAML.safe_load(File.read(ARGV[0])) || {}
arr = cfg.dig(ARGV[1], ARGV[2]) || []
arr.each { |x| puts x }
' cicd.config.yml "$section" "$key" 2>/dev/null || true
}

list_repo_secrets() {
  local repo_spec="$1"
  gh secret list --repo "$repo_spec" --json name --jq '.[].name' 2>/dev/null || true
}

list_repo_variables() {
  local repo_spec="$1"
  gh variable list --repo "$repo_spec" --json name --jq '.[].name' 2>/dev/null || true
}

parse_workflow_url() {
  local url="$1"
  if [[ "$url" =~ ^https?://([^/]+)/([^/]+/[^/]+)/actions/workflows/([^/?#]+) ]]; then
    WORKFLOW_HOST="${BASH_REMATCH[1]}"
    WORKFLOW_REPO="${BASH_REMATCH[2]}"
    WORKFLOW_FILE="${BASH_REMATCH[3]}"
    return 0
  fi
  return 1
}

print_report() {
  echo "### Status"
  echo "$STATUS"
  echo

  echo "### Findings"
  if [[ ${#FINDINGS[@]} -eq 0 ]]; then
    echo "- No findings."
  else
    for item in "${FINDINGS[@]}"; do
      echo "- $item"
    done
  fi
  echo

  echo "### Missing Prerequisites"
  if [[ ${#MISSING[@]} -eq 0 ]]; then
    echo "- None"
  else
    for item in "${MISSING[@]}"; do
      echo "- $item"
    done
  fi
  echo

  echo "### Recommended Actions"
  if [[ ${#RECOMMENDED[@]} -eq 0 ]]; then
    echo "1. Continue with the requested action."
  else
    local i=1
    for item in "${RECOMMENDED[@]}"; do
      echo "$i. $item"
      i=$((i + 1))
    done
  fi
  echo

  echo "### Next Action"
  echo "$NEXT_ACTION"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action)
      ACTION="${2:-}"
      shift 2
      ;;
    --workflow-url)
      WORKFLOW_URL="${2:-}"
      shift 2
      ;;
    --branch)
      BRANCH="${2:-main}"
      shift 2
      ;;
    --repo)
      REPO_INPUT="${2:-}"
      shift 2
      ;;
    --require-signing)
      REQUIRE_SIGNING="${2:-auto}"
      shift 2
      ;;
    --artifact)
      ARTIFACT_PATH="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$ACTION" ]]; then
  echo "Usage: $0 --action <action-name> [--workflow-url <url>] [--branch <name>] [--repo <owner/repo>] [--require-signing true|false|auto] [--artifact <path>]"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  add_missing "GitHub CLI (gh) is not installed"
  add_recommended "Install GitHub CLI from https://cli.github.com/"
  NEXT_ACTION="Install gh and rerun preflight"
  set_blocked "$NEXT_ACTION"
  print_report
  exit 3
fi

load_local_env

# If placeholder token values are loaded, unset them so gh can use stored keychain auth.
if ! has_real_token "${GH_TOKEN:-}"; then
  unset GH_TOKEN || true
fi
if ! has_real_token "${GITHUB_TOKEN:-}"; then
  unset GITHUB_TOKEN || true
fi

REPO="${REPO_INPUT:-$(parse_repo_from_git_remote)}"
REPO="$(trim_git_suffix "$REPO")"

if [[ -z "$REPO" ]]; then
  add_missing "Repository could not be inferred from git remote"
  add_recommended "Pass --repo <owner/repo> explicitly"
  NEXT_ACTION="Provide --repo and rerun preflight"
  set_blocked "$NEXT_ACTION"
  print_report
  exit 3
fi

GH_HOST="github.com"
WORKFLOW_FILE=""

if [[ -n "$WORKFLOW_URL" ]]; then
  if parse_workflow_url "$WORKFLOW_URL"; then
    GH_HOST="$WORKFLOW_HOST"
    REPO="$WORKFLOW_REPO"
  else
    add_missing "Invalid workflow URL format"
    add_recommended "Provide a workflow URL like https://github.com/<owner>/<repo>/actions/workflows/<file>.yml"
  fi
fi

if ! gh auth status --hostname "$GH_HOST" >/dev/null 2>&1; then
  add_missing "GitHub authentication is not available for host $GH_HOST"
  add_recommended "Run: gh auth login --hostname $GH_HOST"
  NEXT_ACTION="Authenticate gh for the target host"
  set_blocked "$NEXT_ACTION"
fi

if [[ "$GH_HOST" == "github.com" ]]; then
  REPO_SPEC="$REPO"
else
  REPO_SPEC="$GH_HOST/$REPO"
fi

if ! gh repo view "$REPO_SPEC" >/dev/null 2>&1; then
  add_missing "Repository access check failed for $REPO_SPEC"
  add_recommended "Confirm repository visibility and token scopes (repo, workflow)"
  if [[ "$STATUS" != "BLOCKED" ]]; then
    set_blocked "Restore repository access and rerun preflight"
  fi
else
  add_finding "Repository access verified for $REPO_SPEC"
fi

if action_requires_workflow "$ACTION"; then
  if [[ -z "$WORKFLOW_URL" ]]; then
    add_missing "Workflow URL is required for action '$ACTION'"
    add_recommended "Provide --workflow-url <workflow-url>"
  elif [[ -z "$WORKFLOW_FILE" ]]; then
    add_missing "Workflow URL parsing failed"
  else
    if gh workflow view "$WORKFLOW_FILE" --repo "$REPO_SPEC" >/dev/null 2>&1; then
      state="$(gh workflow view "$WORKFLOW_FILE" --repo "$REPO_SPEC" --json state --jq '.state' 2>/dev/null || echo "unknown")"
      if [[ "$state" == "active" ]]; then
        add_finding "Workflow $WORKFLOW_FILE exists and is active"
      elif [[ "$state" == "unknown" || -z "$state" ]]; then
        add_finding "Workflow $WORKFLOW_FILE exists (state could not be determined by local gh version)"
        add_recommended "Optionally verify workflow state in GitHub Actions UI"
      else
        add_missing "Workflow $WORKFLOW_FILE is not active (state: $state)"
        add_recommended "Enable the workflow in GitHub Actions"
      fi
    else
      add_missing "Workflow $WORKFLOW_FILE was not found in $REPO_SPEC"
      add_recommended "Confirm workflow file path and branch"
    fi
  fi
fi

if [[ -n "$BRANCH" ]]; then
  if gh api --hostname "$GH_HOST" "repos/$REPO/branches/$BRANCH" >/dev/null 2>&1; then
    add_finding "Branch '$BRANCH' exists"
  else
    add_missing "Branch '$BRANCH' does not exist in $REPO"
    add_recommended "Use an existing branch or push the branch before triggering"
  fi
fi

if [[ ! -d "fastlane" ]]; then
  add_missing "fastlane directory is missing"
  add_recommended "Initialize fastlane for iOS and add required lanes"
else
  add_finding "Fastlane directory is present"
fi

if ls ./*.xcodeproj >/dev/null 2>&1; then
  add_finding "iOS project detected via .xcodeproj"
else
  add_missing "No .xcodeproj file found"
  add_recommended "Ensure this repository includes an iOS Xcode project"
fi

required_secrets="$(get_yaml_list required secrets)"
required_variables="$(get_yaml_list required variables)"

available_secrets="$(list_repo_secrets "$REPO_SPEC")"
available_variables="$(list_repo_variables "$REPO_SPEC")"

if [[ -z "$available_secrets" ]]; then
  add_finding "Could not verify repository secrets list automatically (permission or empty list)"
  add_recommended "Verify Actions secrets in repository settings"
fi

if [[ -z "$available_variables" ]]; then
  add_finding "Could not verify repository variables list automatically (permission or empty list)"
  add_recommended "Verify Actions variables in repository settings"
fi

if [[ -n "$required_secrets" && -n "$available_secrets" ]]; then
  while IFS= read -r secret_name; do
    [[ -z "$secret_name" ]] && continue
    if ! echo "$available_secrets" | grep -Fxq "$secret_name"; then
      add_missing "Missing required secret: $secret_name"
      add_recommended "Add secret '$secret_name' in GitHub repository settings"
    fi
  done <<< "$required_secrets"
fi

if [[ -n "$required_variables" && -n "$available_variables" ]]; then
  while IFS= read -r variable_name; do
    [[ -z "$variable_name" ]] && continue
    if ! echo "$available_variables" | grep -Fxq "$variable_name"; then
      add_missing "Missing required variable: $variable_name"
      add_recommended "Add variable '$variable_name' in GitHub repository settings"
    fi
  done <<< "$required_variables"
fi

if action_requires_signing_checks "$ACTION"; then
  if [[ ! -f "fastlane/Matchfile" ]]; then
    add_missing "fastlane/Matchfile is missing for signing automation"
    add_recommended "Add fastlane Match configuration in fastlane/Matchfile"
  else
    add_finding "fastlane Matchfile is present"
  fi

  if [[ ! -f "fastlane/Appfile" ]]; then
    add_missing "fastlane/Appfile is missing"
    add_recommended "Add Appfile with app_identifier and team_id"
  else
    add_finding "fastlane Appfile is present"
  fi

  add_recommended "If signed IPA is not required, run CI validation with skip_codesigning=true and CODE_SIGNING_ALLOWED=NO"
fi

if action_requires_firebase "$ACTION"; then
  for needed_secret in FIREBASE_APP_ID FIREBASE_CLI_TOKEN; do
    if [[ -n "$available_secrets" ]] && ! echo "$available_secrets" | grep -Fxq "$needed_secret"; then
      add_missing "Missing Firebase secret: $needed_secret"
      add_recommended "Add '$needed_secret' as a repository secret"
    fi
  done

  if [[ -n "$available_variables" ]] && ! echo "$available_variables" | grep -Fxq "FIREBASE_GROUPS"; then
    add_missing "Missing Firebase variable: FIREBASE_GROUPS"
    add_recommended "Add FIREBASE_GROUPS as a repository variable"
  fi

  if [[ -n "$ARTIFACT_PATH" ]]; then
    if [[ ! -f "$ARTIFACT_PATH" ]]; then
      add_missing "Artifact not found at $ARTIFACT_PATH"
      add_recommended "Build or download the IPA artifact before Firebase distribution"
    else
      add_finding "Artifact found at $ARTIFACT_PATH"
    fi
  fi
fi

if action_requires_open_pr_checks "$ACTION"; then
  current_branch="$(git branch --show-current 2>/dev/null || true)"
  if [[ -z "$current_branch" ]]; then
    add_missing "Current git branch could not be determined"
    add_recommended "Checkout a branch before opening PR"
  else
    add_finding "Current branch is $current_branch"
  fi

  if git diff --quiet && git diff --cached --quiet; then
    add_missing "No code changes detected for PR"
    add_recommended "Commit intended changes before creating PR"
  else
    add_finding "Uncommitted or staged changes detected"
  fi
fi

if [[ ${#MISSING[@]} -eq 0 && "$STATUS" != "BLOCKED" ]]; then
  STATUS="PASS"
  NEXT_ACTION="Proceed with $ACTION"
elif [[ "$STATUS" == "FAIL" ]]; then
  NEXT_ACTION="Resolve missing prerequisites and rerun preflight"
fi

print_report

case "$STATUS" in
  PASS) exit 0 ;;
  FAIL) exit 2 ;;
  BLOCKED) exit 3 ;;
  *) exit 1 ;;
esac
