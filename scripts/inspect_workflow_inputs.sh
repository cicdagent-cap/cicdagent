#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_URL="${1:-}"
REF_NAME="${2:-}"

if [ -z "$WORKFLOW_URL" ] || [ -z "$REF_NAME" ]; then
  echo "Usage: $0 <workflow-url> <branch>"
  exit 1
fi

if ! command -v gh >/dev/null; then
  echo "Install GitHub CLI: https://cli.github.com/"
  exit 1
fi

GH_HOST=""
REPO=""
FILE=""

if [[ "$WORKFLOW_URL" =~ ^https?://([^/]+)/([^/]+/[^/]+)/actions/workflows/([^/?#]+) ]]; then
  GH_HOST="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
  FILE="${BASH_REMATCH[3]}"
else
  echo "Invalid workflow URL"
  exit 1
fi

if ! gh auth status --hostname "$GH_HOST" >/dev/null 2>&1; then
  echo "Run: gh auth login --hostname $GH_HOST"
  exit 1
fi

echo "🔍 Inspecting inputs..."
echo

gh api \
  --hostname "$GH_HOST" \
  -H "Accept: application/vnd.github.raw" \
  "/repos/$REPO/contents/.github/workflows/$FILE?ref=$REF_NAME" |
ruby -ryaml -e '
data = YAML.safe_load(STDIN.read, aliases: true) || {}
triggers = data["on"] || data[true] || {}
dispatch = triggers["workflow_dispatch"] || {}
inputs = dispatch["inputs"] || {}

if inputs.empty?
  puts "No inputs found"
  exit 0
end

puts "Detected inputs:\n"

inputs.each do |name, cfg|
  cfg ||= {}
  puts "- #{name}"
  puts "  type: #{cfg["type"]}" if cfg["type"]
  puts "  required: #{cfg["required"] || false}"
  puts "  default: #{cfg["default"]}" if cfg.key?("default")

  if cfg["options"]
    puts "  options:"
    cfg["options"].each { |o| puts "   - #{o}" }
  end
  puts
end
'