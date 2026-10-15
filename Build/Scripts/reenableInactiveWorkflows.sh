#!/usr/bin/env bash
#
# GitHub disables a scheduled workflow after 60 days without repository
# activity. It does so silently: the runs simply stop and no failed run shows
# up anywhere. This script finds workflows in that state across the
# organisation and switches them back on.
#
# Only the state "disabled_inactivity" is touched. A workflow that somebody
# turned off on purpose has the state "disabled_manually" and is left alone.
#
# Usage:
#   reenableInactiveWorkflows.sh [--dry-run] [--org <name>] [--report <file>]
#
# Requires the gh CLI, authenticated with a token that may read and write
# Actions in the organisation's repositories.

set -euo pipefail

ORG="TYPO3-Documentation"
DRY_RUN=0
REPORT=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --org) ORG="$2"; shift 2 ;;
        --report) REPORT="$2"; shift 2 ;;
        -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

findings=""
failures=0

for repo in $(gh repo list "$ORG" --limit 200 --no-archived --json name --jq '.[].name'); do
    # Repositories with Actions switched off answer 404 here; skip them.
    workflows=$(gh api "repos/$ORG/$repo/actions/workflows" \
        --jq '.workflows[] | select(.state == "disabled_inactivity") | "\(.id)\t\(.path)"' \
        2>/dev/null) || continue
    [ -z "$workflows" ] && continue

    while IFS=$'\t' read -r id path; do
        [ -z "$id" ] && continue
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "would re-enable: $repo $path"
            findings="${findings}* \`$repo\` — \`$path\` (not re-enabled, dry run)"$'\n'
        elif gh api -X PUT "repos/$ORG/$repo/actions/workflows/$id/enable" --silent 2>/dev/null; then
            echo "re-enabled: $repo $path"
            findings="${findings}* \`$repo\` — \`$path\`"$'\n'
        else
            echo "FAILED to re-enable: $repo $path" >&2
            findings="${findings}* \`$repo\` — \`$path\` (could not be re-enabled, check the token)"$'\n'
            failures=1
        fi
    done <<< "$workflows"
done

if [ -z "$findings" ]; then
    echo "No workflow was disabled by inactivity."
fi

if [ -n "$REPORT" ]; then
    {
        echo "# Workflows disabled by inactivity"
        echo
        echo "Written by \`Build/Scripts/reenableInactiveWorkflows.sh\`."
        echo
        echo "The timestamp below is updated on every run even when nothing was"
        echo "found, and the run commits this file. That commit is the point:"
        echo "it counts as repository activity and so keeps the scheduled"
        echo "workflows of this repository from being disabled in turn. Please"
        echo "do not remove it as noise."
        echo
        echo "Last checked: $(date -u '+%Y-%m-%d %H:%M UTC')"
        echo
        if [ -z "$findings" ]; then
            echo "Nothing was disabled by inactivity at the last check."
        else
            echo "Re-enabled at the last check:"
            echo
            printf '%s' "$findings"
        fi
    } > "$REPORT"
    echo "report written to $REPORT"
fi

exit $failures
