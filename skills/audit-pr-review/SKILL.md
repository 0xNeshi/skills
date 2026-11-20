---
name: audit-pr-review
description: Review an OpenZeppelin/canton-contracts pull request that fixes an OpenZeppelin audit finding, using its linked issues, the findings on audits.openzeppelin.com and every other audit issue, plus a canton-basic-review pass and a documentation review. Drafts change requests with file and line, and posts the approved ones to the PR. Use when given a PR number or URL to review against its audit finding.
argument-hint: <PR number or URL>
---

Review this pull request against the audit finding it fixes: $ARGUMENTS

Repository: `OpenZeppelin/canton-contracts`. Do not modify the working tree, check out branches or commit.

## 1. Gather context

1. **PR.** `gh pr view <n> --repo OpenZeppelin/canton-contracts --json number,title,body,url,baseRefName,headRefName,headRefOid,closingIssuesReferences,files`. Get the diff with `gh pr diff <n>`. The diff is against the PR's base branch: when the PR is stacked on another PR, code the base PR introduces is out of scope. Read changed files at the head commit without checking out: `git fetch origin pull/<n>/head`, then `git show <headRefOid>:<path>`. Read existing review comments (`gh api repos/OpenZeppelin/canton-contracts/pulls/<n>/comments` and `gh pr view <n> --json reviews`) so you do not repeat a point already raised.
2. **Linked issues.** `closingIssuesReferences` plus every `#<n>` in the PR body that is an issue, not a PR. Read each with `gh issue view <n> --json number,title,body,labels,state`. These define the scope of the review.
3. **Findings.** Each linked issue body links its finding as `https://audits.openzeppelin.com/<org_slug>/<audit_slug>/issue/<issue_slug>`. Read each with the OpenZeppelin Platform MCP tool `audit_issue_get` (`response_format: full`) for the description, recommendation, comments and client response.
4. **Every other audit issue.** `gh issue list --repo OpenZeppelin/canton-contracts --label audit --state all --limit 200 --json number,title,body,state`, and the audit's finding list with `audit_get` (`response_format: full`). Read the full body of an issue or finding only when a problem you found may belong to it.

## 2. Review

Run three reviews. Start the basic review and the documentation review as two `general-purpose` subagents in one message, then do the scope review yourself while they run.

Give each subagent the PR number and URL, `headRefOid`, the base branch, the changed files, the linked issue bodies, and the findings' descriptions and recommendations. Tell it to:
- read code with `gh pr diff <n>` and `git show <headRefOid>:<path>`, and never check out, edit or write in the repository; any report file goes in the scratchpad directory;
- not ask questions, and answer any question its skill asks from the context given;
- return each finding as `path:line` (new-file line at `headRefOid`), the problem, the concrete failure or cost to the reader, and the proposed change.

### Scope review

Check that the PR:
- resolves the finding as the issue describes it: each bullet under the issue's Changes and Notes, and the finding's recommendation where the issue does not narrow it;
- introduces no correctness, authorization or privacy defect in the code it changes;
- tests the fixed behavior, including the failure the finding describes;
- updates the documentation the issue names and any `README.md` that describes the changed behavior;
- follows `AGENTS.md` for the packages it touches.

### Basic review (subagent)

Invoke the `canton-basic-review` skill in standalone mode on the Daml files the PR changes and the code they call. Infer invariants from the findings and the code. Skip the stage-start drift check, Artifact Drift, Capture Gate and Stage Handoff, and do not write `post-core/basic-review.md`. Return the findings by severity.

### Documentation review (subagent)

Review the documentation and comments the PR adds or changes: Markdown files, `--` comments in `.daml` files, and comments in scripts and configuration. Review the added and changed lines and the paragraph each sits in.

Flag each added or changed sentence that is verbose or redundant:
- it repeats what the code, an identifier's name or a signature already says;
- it repeats a rule already stated in the same file, in another file the PR changes, or in a document it links to; keep one explanation and refer to it from elsewhere;
- it restates standard Daml or Canton semantics or repository release policy;
- outside `CHANGELOG.md`, it narrates the fix or the review: "now", "previously", "no longer", finding IDs such as `L-05`, issue or PR numbers;
- it keeps its meaning with fewer words or without the sentence;
- a doc comment covers more than its own symbol: it describes what callers do with the result, or carries a rule for a party other than the caller, such as the admin's automation. Move that rule to where `AGENTS.md` places operational assumptions;
- a trust boundary, security limitation or operational assumption is stated twice, in a doc comment and a `README.md`. Keep one copy, where `AGENTS.md` places it;
- it lists test names, outside a test comment that names the test covering the other half of a behavior;
- it uses shorthand the reader has to decode ("skips the funding"), or packs more than one condition into a sentence;
- a comment opens against the convention: a verb sentence for a function or choice that acts, "Implementation for `Allocation.allocation_cancelImpl`." for an interface method implementation, a noun phrase for a type, field, predicate, view, constant or module. Vendored text keeps its upstream wording;
- it says code calls, matches or reproduces third-party code without a permalink to the exact lines at a pinned commit.

For each, give the replacement text or "delete". A replacement keeps the text the same length or shorter unless it adds a missing fact. Give the net line change of each replacement.

### Triage

Merge the three sets of findings and drop duplicates. For every problem, decide where it belongs:
- **Change request:** the linked issues own it, or the PR introduces it.
- **Covered elsewhere:** another audit issue owns it, whether open or closed. Do not draft a change request; note it with the issue number.
- **Drop:** neither applies. Do not report it.

Verify each change request against the code at the head commit before drafting it. Drop any you cannot tie to a concrete line and either a concrete failure or, for documentation, the exact text to cut or replace.

## 3. Draft

Show me, in this order:

1. One line: the PR, the linked issues and their findings, as markdown links.
2. Change requests, numbered `CR-1`, `CR-2`, ... most severe first. For each:

   ````markdown
   ### CR-1: <short title>
   [<path>:<line>](<path>#L<line>) or [<path>:<start>-<end>](<path>#L<start>-L<end>) - in diff | outside diff

   <comment text exactly as it will be posted>
   ````

   Write the location as a markdown link to the local file, so I can click it to open the code: the link target is the path relative to the repository root, then `#L<line>` or `#L<start>-L<end>`. Do not wrap the link in backticks. These local links appear only in the draft. Posted comments are pinned to the remote file and line through the payload in step 4.

   The comment text states the problem, then the change. Add a short code example only when the change is not obvious from the text: a few lines in a fenced block with a language tag (`daml`, `sh`, `markdown`). When the change replaces whole lines in the diff, such as shorter documentation text, use a GitHub suggestion block (```` ```suggestion ````) holding the replacement lines instead.

   Place each comment on the line where the change goes, using new-file line numbers at `headRefOid`. Prefer a line inside a diff hunk, added or context, on the right side; a multi-line range must stay in one hunk. When the change belongs outside the diff, such as a missing doc update in an unchanged file, mark it "outside diff".
3. Covered elsewhere: one line each, `#<issue> (<finding id>): <problem> at [<path>:<line>](<path>#L<line>)`, with the same local link. Omit the section when empty.

If there are no change requests, say so in one line and stop.

## Writing

Comments must read as if a person wrote them:
- No AI attribution or artifacts: no "Generated with", `Co-Authored-By`, mention of an AI, or emoji. Use a hyphen ("-"), never an en or em dash. No non-breaking, zero-width or other invisible characters.
- State the problem in two or three plain sentences, then give the change. A reader new to the code understands each sentence on first read. Give one reason, not every reason.
- When a change request goes against what a linked issue asks for, say so in its body.
- One idea per sentence, active voice, plain words. Name the exact file, choice, function or field.
- Describe an action by what its caller writes and what it does to the contract: the field, choice or operation ("naming the holding in the `inputHoldingCids` of a new transfer or allocation, which consumes it through `fundHolding`"), not the internal step it reaches ("passing the holding to a factory as an input, which runs `fundHolding`").
- A suggestion block is the final file text. After adding or moving a sentence in it, reread the whole block and replace every "there", "it", "this" or "one" that now follows a different noun with the name it stands for.
- Do not join two sentences with a colon or semicolon. Write two sentences.
- No praise, no restating the finding, no summary, no hedging the facts don't need. Delete any sentence that loses nothing when removed.
- Format code identifiers, files and paths with backticks.

Before showing the draft, reread it against these rules and fix what fails. Count the lines each suggestion removes and adds, and rewrite any suggestion that grows the text without adding a fact. The script rejects text that still contains dashes, invisible characters or attribution lines.

## 4. Post

Wait for my approval. I approve all change requests, specific ones by number, or edited versions. Post only what I approve, with my edits.

Write a payload to the scratchpad directory:

```json
{
  "pr": 132,
  "commit_id": "<headRefOid the draft was made against>",
  "event": "COMMENT",
  "body": "",
  "comments": [
    { "path": "packages/token/token-cip112-utils/daml/OpenZeppelin/Token/Cip112/Utils/Holding.daml", "line": 42, "body": "..." },
    { "path": "...", "start_line": 10, "line": 14, "body": "..." }
  ]
}
```

- `comments` holds the approved "in diff" change requests.
- `body` holds the approved "outside diff" change requests, each as a `[<path>:<line>](https://github.com/OpenZeppelin/canton-contracts/blob/<commit_id>/<path>#L<line>)` link followed by its comment text, separated by blank lines. Leave it empty when there are none.
- `event` is `COMMENT` unless I ask to request changes, then `REQUEST_CHANGES`, which needs a non-empty `body`.

Run `bash ${CLAUDE_SKILL_DIR}/post-review.sh <payload>`. It posts everything as one review, so a rejected line posts nothing. If GitHub rejects a line, move that comment to `body` as an outside-diff comment and run it again. Report the review URL.
