---
name: update-skills-repo
description: Sync edited skills from ~/.claude/skills/ to the Lesani/skills GitHub repo clone and push to main. Use when local skill edits should be published upstream.
---

Sync edited skills from `~/.claude/skills/` to the local clone of `Lesani/skills` and push to `main`.

Repo clone expected at `~/source/repos/skills/`. Layout: `skills/{category}/{name}/SKILL.md` where category ∈ `engineering | productivity | personal | misc | in-progress | deprecated`.

## Process

1. Verify the repo clone exists. Abort with a clear message if not.

2. Verify the repo is on `main` and clean. Run `git pull` first; abort on conflict.

3. For each `~/.claude/skills/{name}/SKILL.md`, locate the matching repo path by name. If multiple match, abort and surface. If no match, ask the user which category folder.

4. Show a diff summary: skill name, category, +/- line counts. Wait for user confirmation before any writes.

5. On confirmation: copy → stage → commit → push to `main`. Commit message brief, describes the change, no prose.

Skills present in the repo but missing locally: report, do not delete.
