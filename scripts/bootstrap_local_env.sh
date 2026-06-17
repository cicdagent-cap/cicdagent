#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-.notification.local.env}"

is_placeholder() {
  local v="${1:-}"
  if [[ -z "$v" ]]; then
    return 0
  fi
  if [[ "$v" =~ ^\<.*\>$ ]]; then
    return 0
  fi
  if [[ "$v" =~ xxxxxxxx ]] || [[ "$v" =~ example ]] || [[ "$v" =~ your-org ]] || [[ "$v" =~ personal-access-token ]] || [[ "$v" =~ firebase-ci-token ]] || [[ "$v" =~ match-encryption-password ]]; then
    return 0
  fi
  return 1
}

read_existing() {
  if [[ -f "$ENV_FILE" ]]; then
    while IFS= read -r line; do
      if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        val="${BASH_REMATCH[2]}"
        EXISTING["$key"]="$val"
      fi
    done < "$ENV_FILE"
  fi
}

set_inferred() {
  local key="$1"
  local val="$2"
  local current="${EXISTING[$key]:-}"

  local invalid=1
  if [[ "$key" == "FASTLANE_BUNDLE_IDENTIFIER" ]]; then
    if [[ "$current" =~ ^[A-Za-z0-9.-]+\.[A-Za-z0-9.-]+ ]]; then
      invalid=0
    fi
  elif [[ "$key" == "FASTLANE_TEAM_ID" ]]; then
    if [[ "$current" =~ ^[A-Z0-9]{10}$ ]]; then
      invalid=0
    fi
  else
    if ! is_placeholder "$current"; then
      invalid=0
    fi
  fi

  if [[ $invalid -eq 1 ]]; then
    EXISTING["$key"]="$val"
  fi
}

find_project_file() {
  find . -maxdepth 3 -name "*.xcodeproj" \
    ! -path "*/Pods/*" \
    ! -path "*/.build/*" \
    | head -n1 | sed 's#^./##'
}

infer_scheme() {
  local project="$1"
  local detected=""

  if command -v xcodebuild >/dev/null 2>&1; then
    detected="$(xcodebuild -list -project "$project" 2>/dev/null | awk '
      /^    Schemes:/{in_schemes=1; next}
      in_schemes && /^    [^[:space:]].*:/{exit}
      in_schemes && /^        /{gsub(/^ +/, "", $0); print; exit}
    ')"
  fi

  if [[ -n "$detected" ]]; then
    echo "$detected"
  else
    basename "$project" .xcodeproj
  fi
}

infer_build_setting() {
  local project="$1"
  local scheme="$2"
  local key="$3"

  if ! command -v xcodebuild >/dev/null 2>&1; then
    return 0
  fi

  xcodebuild -showBuildSettings -project "$project" -scheme "$scheme" 2>/dev/null \
    | awk -F' = ' -v k="$key" '$1 ~ "^[[:space:]]*" k "[[:space:]]*$" {print $2; exit}'
}

infer_firebase_app_id() {
  local plist=""

  plist="$(find . -maxdepth 5 -name "GoogleService-Info.plist" | head -n1 || true)"
  if [[ -z "$plist" ]]; then
    return 0
  fi

  if command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Print :GOOGLE_APP_ID" "$plist" 2>/dev/null || true
    return 0
  fi

  if command -v plutil >/dev/null 2>&1; then
    plutil -extract GOOGLE_APP_ID raw -o - "$plist" 2>/dev/null || true
  fi
}

infer_match_git_url() {
  git remote get-url origin 2>/dev/null || true
}

write_env_file() {
  cat > "$ENV_FILE" <<EOF
# CI/CD local environment (auto-generated and safe to edit)
# This file is local only. Never commit secrets.

CICD_PROJECT_FILE=${EXISTING[CICD_PROJECT_FILE]:-cicd.xcodeproj}
CICD_DEFAULT_SCHEME=${EXISTING[CICD_DEFAULT_SCHEME]:-cicd}
CICD_DEFAULT_CONFIGURATION=${EXISTING[CICD_DEFAULT_CONFIGURATION]:-Debug}
CICD_TEST_DESTINATION=${EXISTING[CICD_TEST_DESTINATION]:-platform=iOS Simulator,name=iPhone 15,OS=latest}

TEAM_WEBHOOK_URL=${EXISTING[TEAM_WEBHOOK_URL]:-<teams-or-slack-webhook-url>}

FASTLANE_TEAM_ID=${EXISTING[FASTLANE_TEAM_ID]:-<apple-developer-team-id>}
FASTLANE_ITC_TEAM_ID=${EXISTING[FASTLANE_ITC_TEAM_ID]:-<app-store-connect-team-id>}
FASTLANE_BUNDLE_IDENTIFIER=${EXISTING[FASTLANE_BUNDLE_IDENTIFIER]:-com.example.app}

MATCH_GIT_URL=${EXISTING[MATCH_GIT_URL]:-git@github.com:your-org/certificates.git}
MATCH_PASSWORD=${EXISTING[MATCH_PASSWORD]:-<match-encryption-password>}
MATCH_GIT_BASIC_AUTHORIZATION=${EXISTING[MATCH_GIT_BASIC_AUTHORIZATION]:-<base64-user-colon-token>}

FIREBASE_APP_ID=${EXISTING[FIREBASE_APP_ID]:-1:000000000000:ios:xxxxxxxxxxxxxxxx}
FIREBASE_CLI_TOKEN=${EXISTING[FIREBASE_CLI_TOKEN]:-<firebase-ci-token>}
FIREBASE_GROUPS=${EXISTING[FIREBASE_GROUPS]:-testers}

GH_TOKEN=${EXISTING[GH_TOKEN]:-<github-personal-access-token>}
EOF
}

print_fetch_steps_for_missing() {
  local missing=0
  local keys=(
    FIREBASE_APP_ID
    FIREBASE_CLI_TOKEN
    FIREBASE_GROUPS
    FASTLANE_TEAM_ID
    FASTLANE_ITC_TEAM_ID
    FASTLANE_BUNDLE_IDENTIFIER
    MATCH_GIT_URL
    MATCH_PASSWORD
    MATCH_GIT_BASIC_AUTHORIZATION
    GH_TOKEN
  )

  for key in "${keys[@]}"; do
    if is_placeholder "${EXISTING[$key]:-}"; then
      missing=1
      break
    fi
  done

  if [[ $missing -eq 0 ]]; then
    echo "All required values are set or inferred."
    return 0
  fi

  echo
  echo "Missing or placeholder values detected. How to get them:"

  if is_placeholder "${EXISTING[FIREBASE_APP_ID]:-}"; then
    echo "- FIREBASE_APP_ID: Firebase Console -> Project Settings -> Your iOS app -> App ID"
  fi
  if is_placeholder "${EXISTING[FIREBASE_CLI_TOKEN]:-}"; then
    echo "- FIREBASE_CLI_TOKEN: run 'firebase login:ci' locally and copy token"
  fi
  if is_placeholder "${EXISTING[FIREBASE_GROUPS]:-}"; then
    echo "- FIREBASE_GROUPS: Firebase App Distribution -> Testers & Groups -> group alias (comma-separated)"
  fi
  if is_placeholder "${EXISTING[FASTLANE_TEAM_ID]:-}"; then
    echo "- FASTLANE_TEAM_ID: Apple Developer account -> Membership -> Team ID"
  fi
  if is_placeholder "${EXISTING[FASTLANE_ITC_TEAM_ID]:-}"; then
    echo "- FASTLANE_ITC_TEAM_ID: App Store Connect -> Users and Access -> Team ID"
  fi
  if is_placeholder "${EXISTING[FASTLANE_BUNDLE_IDENTIFIER]:-}"; then
    echo "- FASTLANE_BUNDLE_IDENTIFIER: Xcode target Signing & Capabilities -> Bundle Identifier"
  fi
  if is_placeholder "${EXISTING[MATCH_GIT_URL]:-}"; then
    echo "- MATCH_GIT_URL: Git URL of your private certificates repo used by fastlane match"
  fi
  if is_placeholder "${EXISTING[MATCH_PASSWORD]:-}"; then
    echo "- MATCH_PASSWORD: create/set encryption password used with fastlane match"
  fi
  if is_placeholder "${EXISTING[MATCH_GIT_BASIC_AUTHORIZATION]:-}"; then
    echo "- MATCH_GIT_BASIC_AUTHORIZATION: base64 of 'username:token' for cert repo access"
  fi
  if is_placeholder "${EXISTING[GH_TOKEN]:-}"; then
    echo "- GH_TOKEN: GitHub personal token with repo + workflow scopes"
  fi
}

declare -A EXISTING
read_existing

PROJECT_FILE="$(find_project_file)"
if [[ -z "$PROJECT_FILE" ]]; then
  PROJECT_FILE="cicd.xcodeproj"
fi

SCHEME="$(infer_scheme "$PROJECT_FILE")"
if [[ -z "$SCHEME" ]]; then
  SCHEME="$(basename "$PROJECT_FILE" .xcodeproj)"
fi

BUNDLE_ID="$(infer_build_setting "$PROJECT_FILE" "$SCHEME" PRODUCT_BUNDLE_IDENTIFIER || true)"
TEAM_ID="$(infer_build_setting "$PROJECT_FILE" "$SCHEME" DEVELOPMENT_TEAM || true)"
FIREBASE_APP_ID="$(infer_firebase_app_id || true)"
MATCH_URL="$(infer_match_git_url || true)"

set_inferred "CICD_PROJECT_FILE" "$PROJECT_FILE"
set_inferred "CICD_DEFAULT_SCHEME" "$SCHEME"
set_inferred "CICD_DEFAULT_CONFIGURATION" "Debug"
set_inferred "CICD_TEST_DESTINATION" "platform=iOS Simulator,name=iPhone 15,OS=latest"

if [[ -n "$BUNDLE_ID" ]]; then
  set_inferred "FASTLANE_BUNDLE_IDENTIFIER" "$BUNDLE_ID"
fi
if [[ -n "$TEAM_ID" ]]; then
  set_inferred "FASTLANE_TEAM_ID" "$TEAM_ID"
fi
if [[ -n "$FIREBASE_APP_ID" ]]; then
  set_inferred "FIREBASE_APP_ID" "$FIREBASE_APP_ID"
fi
if [[ -n "$MATCH_URL" ]]; then
  set_inferred "MATCH_GIT_URL" "$MATCH_URL"
fi
set_inferred "FIREBASE_GROUPS" "testers"

write_env_file

echo "Generated/updated $ENV_FILE with inferred defaults and safe placeholders."
print_fetch_steps_for_missing
