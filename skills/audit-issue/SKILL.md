---
name: audit-issue
description: Draft and create a GitHub issue in OpenZeppelin/canton-contracts for an OpenZeppelin audit finding, with type, labels, milestone, priority, effort and blocking relationships. Use when given an audits.openzeppelin.com finding URL to turn into an issue.
argument-hint: <finding URL>
---

Write a GitHub issue in markdown for this audit finding: $ARGUMENTS

Split the title from the description, so I can copy each separately.

Follow the format of https://github.com/OpenZeppelin/canton-contracts/issues/87

Link files through https://github.com/OpenZeppelin/canton-contracts/tree/1899f7a4326c9e1b6b76cb434e490e2e82331d9c

First check what the recommended fix involves in this codebase: who would witness the new actions, custom templates that reuse the code, registry policy it bypasses, and docs consumers rely on. Turn each complication or implication into a bullet under a Notes section.

Keep it short: say what needs to be done and why, not how to implement it.

## Writing

The issue and the platform response must read as if a person wrote them:
- No AI attribution or artifacts: no "Generated with", `Co-Authored-By`, mention of an AI, or emoji. Use a hyphen ("-"), never an en or em dash. No non-breaking, zero-width or other invisible characters.
- Start with the problem. One idea per sentence, active voice, plain words ("use", not "leverage"). Name the exact file, choice, function or field instead of "various" or "some".
- No filler: no restating the finding title, no summary at the end, no hedging the facts don't need. Delete any sentence that loses nothing when removed.
- Use lists only for parallel items; keep connected reasoning as prose.
- Format code identifiers, files and paths with backticks.

Before showing a draft, reread it against these rules and fix what fails. The script rejects a title or body that still contains dashes, invisible characters or attribution lines.

## Issue fields

- Type: Bug for a defect in current behavior, Feature for new capability, Task when no production package code changes.
- Labels: always `audit`, `severity: <severity>` from the finding ID prefix (C critical, H high, M medium, L low, N note), and `component: <component>` for each affected component. Add:
  - `breaking: source` when consumers must update code: a public signature or relied-on behavior changes, shippable as an upgrade;
  - `breaking: new package` when the fix cannot ship as a smart contract upgrade, such as a removed choice or choice-argument field;
  - `documentation` when no production package code changes;
  - `examples` when the only code change is under `examples/`;
  - `privacy` when the fix changes which parties see a contract, choice or transaction.
- Milestone: M1.
- Priority: High when the finding can strand funds, breaks typical use, or other fixes build on it; Medium for security caveats that must be documented and for narrower defects; Low for additive changes or findings only an admin misconfiguration triggers; Urgent only when a released deployment is exposed.
- Effort: Low for docs or one small code change; Medium for a change across several workflow paths or templates with tests; High for a change that reshapes a public API or replaces tests across several test packages.

## Relationships

Read the existing issues in https://github.com/OpenZeppelin/canton-contracts/issues, especially the audit ones ("[M1: Audit ..."). Record a relationship only when an issue:
- blocks this one: its fix must land first, or this fix is wrong without it;
- is blocked by this one: its fix must wait for this one, or this fix makes it unnecessary or wrong;
- is tightly coupled with this one: both change the same law, signature or choice, so they must be designed together.

When this issue is blocked by another issue, write it for a developer who starts after the blocking fix has landed. Describe the code as it will be then: name the functions, choices, fields and docs the blocking issue introduces or changes, and leave out work the blocking issue already does. Do not explain the code as it is today where the blocking fix replaces it.

Put blocking relationships in `BLOCKED_BY` and `BLOCKS`, and tightly coupled issues in `RELATES_TO`; the script adds them as GitHub relationships. Do not mention related issues in the description. Outside the issue content, list each relationship with a one-line reason. If no issue qualifies, omit the relationships.

## Creating the issue

Show me the draft: title, description, type, labels, milestone, priority, effort and relationships. Wait for my approval.

Then copy `${CLAUDE_SKILL_DIR}/create-issue.sh` to the scratchpad directory, edit the "Issue" section of the copy with the approved values, run the copy with `bash`, and report the issue URL. Leave the template unchanged.

## Responding on the audit platform

After the issue exists, file the client response on the finding with the OpenZeppelin Platform MCP tool `audit_issue_submit_response`:
- `org_slug` and `issue_slug` come from the finding URL `https://audits.openzeppelin.com/<org_slug>/<audit slug>/issue/<issue_slug>`;
- `proposedResolution`: `acknowledged_will_resolve`;
- `message`: the new issue's URL in angle brackets, for example `<https://github.com/OpenZeppelin/canton-contracts/issues/101>`.

Submitting overwrites any existing response. Check the finding with `audit_issue_get` first; if `hasClientResponse` is true, include the existing response in the draft so I can see what would be replaced.

Show me the draft response: the finding identifier, `proposedResolution` and `message`. Wait for my approval, then submit it. Report the response's `url` as a markdown link with the finding identifier as the text.
