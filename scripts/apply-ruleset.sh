#!/usr/bin/env bash
#
# apply-ruleset.sh — Apply the org-standard branch ruleset to a repository.
#
# Usage:
#   ./scripts/apply-ruleset.sh <repo-name> [--dry-run]
#   ./scripts/apply-ruleset.sh --all [--dry-run]
#
# Examples:
#   ./scripts/apply-ruleset.sh RPGLootFeed        # Apply to one repo
#   ./scripts/apply-ruleset.sh --all              # Apply to all org repos
#   ./scripts/apply-ruleset.sh RPGLootFeed --dry-run  # Preview without applying
#
# Prerequisites:
#   - gh CLI authenticated with admin:org scope
#   - jq installed
#
# The canonical ruleset definition lives in rulesets/default.json.
# Edit that file to change the standard, then re-run this script.

set -euo pipefail

ORG="McTalian-WoW-Addons"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULESET_FILE="$SCRIPT_DIR/../rulesets/default.json"
RULESET_NAME="Default"
DRY_RUN=false

# --- Helpers ---

usage() {
  echo "Usage: $0 <repo-name> [--dry-run]"
  echo "       $0 --all [--dry-run]"
  echo ""
  echo "Apply the org-standard branch ruleset to one or all repos."
  echo ""
  echo "Options:"
  echo "  --all       Apply to all non-archived, non-fork repos in the org"
  echo "  --dry-run   Show what would happen without making changes"
  echo "  --help      Show this help message"
  exit 1
}

check_deps() {
  if ! command -v gh &>/dev/null; then
    echo "❌ gh CLI is required but not found. Install: https://cli.github.com"
    exit 1
  fi
  if ! command -v jq &>/dev/null; then
    echo "❌ jq is required but not found. Install: https://jqlang.github.io/jq/"
    exit 1
  fi
  if [[ ! -f "$RULESET_FILE" ]]; then
    echo "❌ Ruleset file not found: $RULESET_FILE"
    exit 1
  fi
}

# Find the existing "Default" ruleset ID for a repo, or return empty string
get_existing_ruleset_id() {
  local repo="$1"
  GH_PAGER=cat gh api "repos/$ORG/$repo/rulesets" 2>/dev/null \
    | jq -r ".[] | select(.name == \"$RULESET_NAME\") | .id" \
    || echo ""
}

apply_ruleset() {
  local repo="$1"
  local ruleset_id

  echo "📋 $ORG/$repo"

  ruleset_id=$(get_existing_ruleset_id "$repo")

  if [[ -n "$ruleset_id" ]]; then
    # Update existing ruleset
    if $DRY_RUN; then
      echo "   🔍 Would UPDATE existing ruleset (id: $ruleset_id)"
    else
      GH_PAGER=cat gh api -X PUT "repos/$ORG/$repo/rulesets/$ruleset_id" \
        --input "$RULESET_FILE" >/dev/null 2>&1
      echo "   ✅ Updated ruleset (id: $ruleset_id)"
    fi
  else
    # Create new ruleset
    if $DRY_RUN; then
      echo "   🔍 Would CREATE new ruleset"
    else
      local new_id
      new_id=$(GH_PAGER=cat gh api -X POST "repos/$ORG/$repo/rulesets" \
        --input "$RULESET_FILE" 2>&1 | jq -r '.id')
      echo "   ✅ Created ruleset (id: $new_id)"
    fi
  fi
}

get_all_repos() {
  GH_PAGER=cat gh api "orgs/$ORG/repos" \
    --paginate \
    -q '.[] | select(.archived == false and .fork == false) | .name' \
    2>/dev/null | sort
}

# --- Main ---

main() {
  local target=""
  local all=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)     all=true; shift ;;
      --dry-run) DRY_RUN=true; shift ;;
      --help|-h) usage ;;
      -*)        echo "Unknown option: $1"; usage ;;
      *)         target="$1"; shift ;;
    esac
  done

  if ! $all && [[ -z "$target" ]]; then
    usage
  fi

  check_deps

  echo ""
  echo "🔧 Org Ruleset: $RULESET_NAME"
  echo "   Source: $RULESET_FILE"
  if $DRY_RUN; then
    echo "   Mode: DRY RUN (no changes will be made)"
  fi
  echo ""

  if $all; then
    local repos
    repos=$(get_all_repos)
    if [[ -z "$repos" ]]; then
      echo "❌ No repos found in $ORG (or insufficient permissions)"
      exit 1
    fi
    local count
    count=$(echo "$repos" | wc -l | tr -d ' ')
    echo "Found $count repos in $ORG:"
    echo ""
    while IFS= read -r repo; do
      apply_ruleset "$repo"
    done <<< "$repos"
  else
    # Verify the repo exists
    if ! gh api "repos/$ORG/$target" >/dev/null 2>&1; then
      echo "❌ Repository $ORG/$target not found (or insufficient permissions)"
      exit 1
    fi
    apply_ruleset "$target"
  fi

  echo ""
  echo "Done! 🎉"
}

main "$@"
