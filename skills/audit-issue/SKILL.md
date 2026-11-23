---
name: audit-issue
description: Draft and create a GitHub issue in OpenZeppelin/canton-contracts for an OpenZeppelin audit finding, with type, labels, milestone, priority, effort and blocking relationships. Use when given an audits.openzeppelin.com finding URL to turn into an issue.
argument-hint: <finding URL>
---

Write a GitHub issue in markdown for this audit finding: $ARGUMENTS

Split the title from the description, so I can copy each separately.

Follow the format of https://github.com/OpenZeppelin/canton-contracts/issues/87. For every code change, add a Tests list under Changes: the new behavior and each case it must refuse.

Run `git fetch origin main` and take the commit SHA from `git rev-parse origin/main`. Read the code at that commit, not at the branch that is checked out, and link files through `https://github.com/OpenZeppelin/canton-contracts/tree/<sha>`.

Keep it short: state what must hold after the fix and why, and leave the mechanism to the implementer. If the fix only works with one mechanism, name it and check it against the list below.

## Checking the facts and the fix

The auditor reviews each issue as a fix plan. Check the draft the same way before showing it.

Facts:
- Confirm every statement about behavior in the code, not from the finding. Before writing "only X" or "no Y", list every choice that reaches the same state.
- Read the open pull requests (`gh pr list --repo OpenZeppelin/canton-contracts`). Where one fixes another finding and changes code this issue relies on, describe the code as it will be once it merges.

Scope:
- Map each recommendation in the finding to a change. If the issue leaves one out or departs from it, give the reason in the platform response.
- Apply the change everywhere the pattern lives, such as both transfers and allocations, and both the library templates and the custom example. A reason for leaving one out must hold for the approach this issue takes, not only for today's code.

What must hold after the fix. State each as a requirement in the issue:
- Caller inputs: when the fix reads a contract id, context entry or record from a choice argument, state whose authority it must carry, so that a look-alike created by another party, or by the admin alone, is refused.
- Bounds: every time or amount bound that holds today still holds under hostile inputs, such as a backdated `requestedAt` or repeated settlements.
- Overlapping roles: the fix works when one party holds two roles, such as the admin as an allocation's only executor.
- Other paths: no public function, fallback or workaround that the issue proposes or leaves exported skips the checks the main path makes, such as the actor, deadline, expiry and pinning checks.

What the documentation must say:
- Workarounds: the authority or visibility each one grants beyond its purpose.
- Canton mechanisms: the limit of each one the docs rely on, such as the command deduplication period, and what to do past it.
- Consumer replacements: when consumers write their own template or choice in place of a library one, the checks it must keep and any choice it must add.

Then check who would witness the new actions, custom templates that reuse the code, registry policy the fix bypasses, and docs consumers rely on. Turn each complication or implication into a bullet under a Notes section. A Note that names a bypass or a gap becomes a change, unless the Note says why the gap stays open.

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

## Review

Before showing the draft, start a fresh agent. Give it the finding URL, the draft, the commit SHA and the list from "Checking the facts and the fix", and none of your reasoning. Ask it to check each statement in the draft against the code, check the draft against the list, and report what an auditor would flag. Fix what holds up.

## Creating the issue

Show me the draft: title, description, type, labels, milestone, priority, effort and relationships. Wait for my approval.

Then copy `${CLAUDE_SKILL_DIR}/create-issue.sh` to the scratchpad directory, edit the "Issue" section of the copy with the approved values, run the copy with `bash`, and report the issue URL. Leave the template unchanged.

## Responding on the audit platform

After the issue exists, file the client response on the finding with the OpenZeppelin Platform MCP tool `audit_issue_submit_response`:
- `org_slug` and `issue_slug` come from the finding URL `https://audits.openzeppelin.com/<org_slug>/<audit slug>/issue/<issue_slug>`;
- `proposedResolution`: `acknowledged_will_resolve`;
- `message`: the new issue's URL in angle brackets, for example `<https://github.com/OpenZeppelin/canton-contracts/issues/101>`. When the issue departs from the finding's recommendation or leaves part of it out, put one or two sentences before the URL that say what the issue does instead and why.

The message must agree with the issue: a count, name or scope it states is the issue's. When an existing issue is changed to cover this finding, the message says which of its changes addresses this finding. Then check the response on each finding that issue already covered, and include a resubmission in the draft for each one that no longer matches.

Submitting overwrites any existing response. Check the finding with `audit_issue_get` first; if `hasClientResponse` is true, include the existing response in the draft so I can see what would be replaced.

Show me the draft response: the finding identifier, `proposedResolution` and `message`. Wait for my approval, then submit it. Report the response's `url` as a markdown link with the finding identifier as the text.
