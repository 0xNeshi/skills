#!/usr/bin/env bash
# Creates a GitHub issue with its type, labels, milestone, Priority and Effort
# issue fields, and blocking and relates-to relationships.
#
# This file is a template. Copy it, edit the "Issue" section of the copy, and
# run the copy with bash.
# Every name is resolved to an ID before the issue is created, so a wrong type,
# field value or milestone fails without leaving a half-configured issue.
set -euo pipefail

REPO="OpenZeppelin/canton-contracts"
OWNER="${REPO%%/*}"

# ---- Issue ------------------------------------------------------------------
TITLE='TODO'

BODY=$(cat <<'MD'
TODO
MD
)

TYPE="Task"        # Bug | Feature | Task
LABELS=("audit" "severity: low" "component: token-cip112")
MILESTONE="M1"
PRIORITY="Medium"  # Urgent | High | Medium | Low
EFFORT="Low"       # High | Medium | Low
BLOCKED_BY=()      # issue numbers whose fix must land before this one
BLOCKS=()          # issue numbers that must wait for this one
RELATES_TO=()      # issue numbers tightly coupled with this one
# -----------------------------------------------------------------------------

fail() { echo "error: $*" >&2; exit 1; }

[[ "$TITLE" != "TODO" && "$BODY" != "TODO" ]] || fail "edit TITLE and BODY first"

# Reject AI attribution and machine artifacts: en and em dashes, invisible and
# non-breaking spaces, and attribution lines.
artifacts=$(printf '%s\n%s\n' "$TITLE" "$BODY" | LC_ALL=en_US.UTF-8 grep -nP \
  '[\x{2013}\x{2014}\x{200B}-\x{200D}\x{2060}\x{FEFF}\x{00A0}]|(?i)generated (with|by)|co-authored-by|\bclaude\b|chatgpt|\bas an ai\b' || true)
[[ -z "$artifacts" ]] || fail "title or body contains AI artifacts:
$artifacts"

# Resolve every ID up front.
type_id=$(gh api graphql -f o="$OWNER" \
  -f query='query($o: String!) { organization(login: $o) { issueTypes(first: 50) { nodes { id name } } } }' \
  --jq ".data.organization.issueTypes.nodes[] | select(.name == \"$TYPE\") | .id")
[[ -n "$type_id" ]] || fail "unknown issue type: $TYPE"

fields_json=$(gh api graphql -f o="$OWNER" \
  -f query='query($o: String!) { organization(login: $o) { issueFields(first: 50) { nodes { ... on IssueFieldSingleSelect { id name options { id name } } } } } }')

field_id() { jq -r --arg f "$1" '.data.organization.issueFields.nodes[] | select(.name == $f) | .id' <<<"$fields_json"; }
option_id() { jq -r --arg f "$1" --arg o "$2" '.data.organization.issueFields.nodes[] | select(.name == $f) | .options[] | select(.name == $o) | .id' <<<"$fields_json"; }

priority_field=$(field_id "Priority");     priority_option=$(option_id "Priority" "$PRIORITY")
effort_field=$(field_id "Effort");         effort_option=$(option_id "Effort" "$EFFORT")
[[ -n "$priority_field" && -n "$priority_option" ]] || fail "unknown Priority: $PRIORITY"
[[ -n "$effort_field" && -n "$effort_option" ]] || fail "unknown Effort: $EFFORT"

gh api "repos/$REPO/milestones?state=all" --jq ".[] | select(.title == \"$MILESTONE\") | .number" | grep -q . \
  || fail "unknown milestone: $MILESTONE"

existing_labels=$(gh label list --repo "$REPO" --limit 500 --json name --jq '.[].name')
for label in "${LABELS[@]}"; do
  grep -qxF "$label" <<<"$existing_labels" || fail "unknown label: $label"
done

node_id() { gh issue view "$1" --repo "$REPO" --json id --jq .id; }

declare -A related_ids
for number in "${BLOCKED_BY[@]}" "${BLOCKS[@]}" "${RELATES_TO[@]}"; do
  related_ids[$number]=$(node_id "$number") || fail "unknown issue: #$number"
done

# Create the issue.
label_args=()
for label in "${LABELS[@]}"; do label_args+=(--label "$label"); done

url=$(gh issue create --repo "$REPO" --title "$TITLE" --body "$BODY" \
  --milestone "$MILESTONE" "${label_args[@]}")
number="${url##*/}"
issue_id=$(node_id "$number")
echo "created #$number: $url"

gh api graphql -f i="$issue_id" -f t="$type_id" \
  -f query='mutation($i: ID!, $t: ID!) { updateIssueIssueType(input: {issueId: $i, issueTypeId: $t}) { issue { number } } }' >/dev/null
echo "type: $TYPE"

gh api graphql -f i="$issue_id" \
  -f pf="$priority_field" -f po="$priority_option" -f ef="$effort_field" -f eo="$effort_option" \
  -f query='mutation($i: ID!, $pf: ID!, $po: ID!, $ef: ID!, $eo: ID!) {
    setIssueFieldValue(input: {issueId: $i, issueFields: [
      {fieldId: $pf, singleSelectOptionId: $po},
      {fieldId: $ef, singleSelectOptionId: $eo}
    ]}) { clientMutationId } }' >/dev/null
echo "priority: $PRIORITY, effort: $EFFORT"

add_blocked_by() {
  gh api graphql -f i="$1" -f b="$2" \
    -f query='mutation($i: ID!, $b: ID!) { addBlockedBy(input: {issueId: $i, blockingIssueId: $b}) { clientMutationId } }' >/dev/null
}

for blocker in "${BLOCKED_BY[@]}"; do
  add_blocked_by "$issue_id" "${related_ids[$blocker]}"
  echo "blocked by #$blocker"
done

for blocked in "${BLOCKS[@]}"; do
  add_blocked_by "${related_ids[$blocked]}" "$issue_id"
  echo "blocks #$blocked"
done

for related in "${RELATES_TO[@]}"; do
  gh api graphql -f i="$issue_id" -f r="${related_ids[$related]}" \
    -f query='mutation($i: ID!, $r: ID!) { addRelatesTo(input: {issueId: $i, relatedIssueId: $r}) { clientMutationId } }' >/dev/null
  echo "relates to #$related"
done
