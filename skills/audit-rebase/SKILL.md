---
name: audit-rebase
description: Rebase an audit-fix pull request in OpenZeppelin/canton-contracts onto main. Finds the commits only the PR introduces, rebases them, resolves each conflict so the result satisfies the audit finding behind every side of it, and checks the PR's own text against findings fixed on main since it branched. Use when an audit PR is behind main, conflicts with it, or was stacked on PRs that have since been squash-merged.
argument-hint: <PR number or URL>
---

Rebase this pull request onto `origin/main`: $ARGUMENTS

Work in a clone of `OpenZeppelin/canton-contracts`. Stop if the working tree has uncommitted changes. Run `git fetch origin`, and check out the PR's head branch if it is not checked out.

## 1. Find the PR's own commits

Audit PRs are often stacked on other audit PRs. Those merge into main by squash, so their commits stay on the PR branch under SHAs that main does not have, and `git rebase origin/main` would replay them.

1. List the PR's commits with `gh pr view <n> --json commits,headRefName,baseRefName`, and the graph with `git log --oneline --graph origin/<head> -<k>`.
2. For each commit that belongs to another branch (its subject names another finding, or a merge commit brings it in), find that branch's PR with `gh pr list --state all --head <branch> --json number,state,mergeCommit`. Note the squash commit it became on main.
3. The cutoff is the newest commit on the PR branch whose tree equals a commit on main. Confirm it with an empty `git diff --stat <cutoff> <squash commit>`. The PR's own commits are those after the cutoff.
4. If no tree matches, the other PR changed after the branch merged it, or never merged. Compare with `git range-diff` and tell me which commits differ instead of choosing a cutoff.

Show me the PR's own commits, each foreign commit with the PR and squash commit it went in as, and the command:

```sh
git rebase --onto origin/main <cutoff> <head branch>
```

Wait for my approval, then run it.

## 2. Trace each conflict to its findings

For every conflicted file, and for every hunk in it:

- **PR side**: the PR's own commit that made the change, and the issue it closes (`gh pr view <n> --json closingIssuesReferences`).
- **Main side**: the main commit that wrote the conflicting text. Search between the cutoff and `origin/main` with `git log --oneline <cutoff>..origin/main -S'<distinctive phrase>' -- <file>`, once for each sentence or line main added. One hunk can come from several commits. Take the PR number from the squash subject `(#<n>)` and the issue it closes.
- **Findings**: each issue body starts with `Addresses [<ID>](<finding URL>)`. Read the whole issue: the changes it asks for, and its Notes. When the issue does not settle a question, read the finding with the OpenZeppelin Platform MCP tool `audit_issue_get`.

Run `git checkout --conflict=zdiff3 <file>` to see the base next to both sides. Read the diff of each side against the base, not only the two results.

## 3. Resolve

- Keep both sides' changes. Where one side rewrote a passage and the other made a small edit to it, start from the rewrite and reapply the small edit.
- Keep a sentence next to the text it refers to ("that holding", "these inputs").
- Check every statement in the result against the code on `origin/main`, not against the code the PR was written for. A claim that held at the cutoff can fail after a main commit added a choice, a parameter or a path.
- For each finding behind the hunk, confirm the result still says or does everything the issue asks for in that place, and that nothing in it contradicts another finding's change.
- In code conflicts, apply the same checks to behavior, and keep the tests both sides added.

Stage each resolved file. Do not run `git rebase --continue`.

## 4. Check what merged without a conflict

A clean merge can still leave the PR wrong. For each main commit between the cutoff and `origin/main` that touches a file the PR's commits touch, or a choice, function or field they describe, read its finding issue. Then reread the PR's changes against it:

- A statement written as the only way to do something, when a main commit added another way.
- A premise in the PR's issue, often in its Notes ("today", "takes a self-transfer"), that a later fix changed.
- A reference to a function, field or signature that a main commit renamed or reshaped.
- A doc that a main finding requires to list every path, now missing the PR's path, or the reverse.

Fix each mismatch in the working tree and stage it. Give each fix a wording that satisfies both findings.

## 5. Validate

Check that no conflict markers remain (`grep -rnE '^(<<<<<<<|=======|>>>>>>>)'`). Run `dpm build --all` and `scripts/check.sh`. A Shake `BadDependency "BuildMulti"` error that names no file is a stale build cache; rerun once before treating it as a failure. When code changed, run `dpm damlc lint` and the `dpm test` commands from `AGENTS.md` for each affected package.

## 6. Report

For each conflict, report:

- the file and the symbol or section;
- each side: the finding ID, issue and PR, and what the finding asked for in that place;
- how you resolved it and why;
- whether the result satisfies every finding involved, with the code fact that shows it.

Then list each mismatch from step 4: file and line, the two findings, and the old and new wording. List the lines of the PR description and the commit messages that no longer match the rebased change, with the replacement text.

Wait for my approval before `git rebase --continue`, `git push --force-with-lease`, or `gh pr edit`.

## Writing

Doc text and PR text you write must read as if a person wrote them:

- No AI attribution or artifacts: no "Generated with", `Co-Authored-By`, mention of an AI, or emoji. Use a hyphen ("-"), never an en or em dash.
- Match the wording, tense and line width of the surrounding text. Doc comments cover only their own symbol, and rules for other actors go in the `README.md`.
- One idea per sentence, active voice, plain words. Name the exact file, choice, function or field.
