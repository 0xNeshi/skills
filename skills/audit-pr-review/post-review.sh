#!/usr/bin/env bash
# Posts approved change requests as one review on a pull request.
#
# Usage: post-review.sh <payload.json>
# The payload format is described in SKILL.md. Set DRY_RUN=1 to print the
# request instead of posting it.
set -euo pipefail

REPO="OpenZeppelin/canton-contracts"

fail() { echo "error: $*" >&2; exit 1; }

payload="${1:-}"
[[ -f "$payload" ]] || fail "usage: post-review.sh <payload.json>"

pr=$(jq -er '.pr' "$payload") || fail "payload has no pr"
jq -er '.commit_id | select(test("^[0-9a-f]{40}$"))' "$payload" >/dev/null \
  || fail "payload needs the full 40-character commit_id"
event=$(jq -r '.event // "COMMENT"' "$payload")
[[ "$event" == "COMMENT" || "$event" == "REQUEST_CHANGES" ]] || fail "unknown event: $event"
[[ $(jq '(.comments // []) | length' "$payload") -gt 0 || -n $(jq -r '.body // ""' "$payload") ]] \
  || fail "payload has no comments and no body"
[[ "$event" != "REQUEST_CHANGES" || -n $(jq -r '.body // ""' "$payload") ]] \
  || fail "REQUEST_CHANGES needs a body"
jq -e '(.comments // []) | all(.path and (.line | type == "number") and .body)' "$payload" >/dev/null \
  || fail "every comment needs path, line and body"

# Reject AI attribution and machine artifacts: en and em dashes, invisible and
# non-breaking spaces, and attribution lines.
artifacts=$(jq -r '.body // "", (.comments // [])[].body' "$payload" | LC_ALL=en_US.UTF-8 grep -nP \
  '[\x{2013}\x{2014}\x{200B}-\x{200D}\x{2060}\x{FEFF}\x{00A0}]|(?i)generated (with|by)|co-authored-by|\bclaude\b|chatgpt|\bas an ai\b' || true)
[[ -z "$artifacts" ]] || fail "review text contains AI artifacts:
$artifacts"

request=$(jq --arg event "$event" '
  {commit_id, event: $event,
   comments: [(.comments // [])[] | {path, line, side: "RIGHT", body}
     + (if .start_line then {start_line, start_side: "RIGHT"} else {} end)]}
  + (if (.body // "") != "" then {body} else {} end)' "$payload")

if [[ -n "${DRY_RUN:-}" ]]; then
  echo "POST repos/$REPO/pulls/$pr/reviews"
  echo "$request"
  exit 0
fi

gh api --method POST "repos/$REPO/pulls/$pr/reviews" --input - --jq '.html_url' <<<"$request"
