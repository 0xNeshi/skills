# 0xNeshi skills

A Claude Code plugin marketplace with skills for OpenZeppelin `canton-contracts` audit work. The marketplace `0xneshi-skills` holds one plugin, `0xneshi`, which loads every skill under `skills/`.

## Skills

| Skill | Purpose |
| --- | --- |
| [`audit-issue`](skills/audit-issue/) | Drafts a GitHub issue in `OpenZeppelin/canton-contracts` for an audit finding, creates it with type, labels, milestone, priority, effort and relationships, and files the client response on the audit platform. |
| [`audit-rebase`](skills/audit-rebase/) | Prepares the rebase of an audit-fix pull request onto `main`: finds the commits only the PR introduces, gives the reviewer the rebase command, resolves each conflict so it satisfies the audit finding behind every side, and checks the PR against findings fixed on `main` since it branched. It never commits or pushes. |

## Requirements

- Claude Code running in a clone of `OpenZeppelin/canton-contracts`. The skills read the codebase.
- DPM, for the build and checks `audit-rebase` runs.
- `gh`, logged in with write access to `OpenZeppelin/canton-contracts`.
- `jq`, and GNU `grep` with the `en_US.UTF-8` locale. The bundled scripts use `grep -P`, which macOS `grep` lacks.
- The OpenZeppelin Platform MCP connector, for `audit_get`, `audit_issue_get` and `audit_issue_submit_response`.

## Install

```sh
claude plugin marketplace add 0xNeshi/skills
claude plugin install 0xneshi@0xneshi-skills
```

Inside a session, run the same commands as `/plugin marketplace add 0xNeshi/skills` and `/plugin install 0xneshi@0xneshi-skills`, then `/reload-plugins`.

`install` uses user scope by default, which loads the skills in every project. Pass `--scope project` to record the plugin in the project's `.claude/settings.json`, or `--scope local` to record it in `.claude/settings.local.json`.

If a project already has copies of these skills in `.claude/skills/`, delete them so each skill loads once.

## Integrate into a project

To offer the plugin to everyone who works in a repository, add this to its `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "0xneshi-skills": {
      "source": { "source": "github", "repo": "0xNeshi/skills" }
    }
  },
  "enabledPlugins": {
    "0xneshi@0xneshi-skills": true
  }
}
```

When a teammate trusts the repository folder, Claude Code prompts them to add the marketplace and install the plugin.

## Use

Claude picks a skill when a request matches its description. To invoke one directly:

```text
/0xneshi:audit-issue https://audits.openzeppelin.com/<org>/<audit>/issue/<issue>
/0xneshi:audit-rebase 154
```

## Update

```sh
claude plugin marketplace update 0xneshi-skills
claude plugin update 0xneshi@0xneshi-skills
```

The plugin sets no `version`, so every commit on the default branch is a new version.

## Add a skill

Create `skills/<name>/SKILL.md`. Refer to files bundled with the skill as `${CLAUDE_SKILL_DIR}/<file>`; Claude Code replaces the variable with the skill's installed directory.

Load the plugin from a checkout without installing it, and validate the manifests:

```sh
claude --plugin-dir .
claude plugin validate .
```
