---
name: sync-skills
description: Sync the local lesani/skills clone with what's installed under ~/.claude/skills, and surface any uncommitted edits in the repo for push. Bidirectional but with the repo as source of truth. Use when the user says "sync skills", "update skills", "pull skill changes", "I edited skills on the other machine", or invokes /sync-skills.
---

# Sync Skills

Keeps the cloned `skills` repo (default `~/source/repos/skills`) and the active install at `~/.claude/skills/` aligned. **The repo is the source of truth.** Anything in `~/.claude/skills/` that doesn't exist in the repo is treated as a candidate to *promote up* to the repo, not as something to keep.

This is intentionally thin — six steps, no plumbing. If something is unclear at any step, stop and ask the user.

## Step 1 — Locate the repo

Default to `~/source/repos/skills`. If absent, ask the user where it lives (or offer `gh repo clone lesani/skills ~/source/repos/skills`).

Confirm it's the right repo: `git -C <path> remote -v` should show `lesani/skills` (or the user's fork).

## Step 2 — Pull

```bash
git -C <repo> fetch
git -C <repo> status -sb       # are there uncommitted local edits?
git -C <repo> pull --ff-only
```

If `pull --ff-only` fails because the local branch is ahead or diverged, **don't auto-merge** — surface it. The user wants to know if their local repo has unpushed work.

## Step 3 — Mirror repo → ~/.claude/skills/

For each `<repo>/skills/<category>/<name>/` (skipping `deprecated/` and `in-progress/`), mirror its contents into `~/.claude/skills/<name>/`. The category folders flatten — Claude only looks at skill names.

For each skill, compare and report:

- **New** (in repo, not installed) → copy in.
- **Updated** (content differs, repo's mtime newer or content changes) → overwrite, report which files changed.
- **Removed in repo** (installed but not in repo, and the user doesn't recognize it) → ask before deleting; could be a hand-written local skill.
- **Identical** → skip silently.

Don't follow symlinks blindly; if a skill is already a symlink into the repo, leave it as-is and note it.

## Step 4 — Detect "promote up" candidates

Look for skills installed under `~/.claude/skills/<name>/` that have **no counterpart anywhere** in the repo (not `deprecated/`, not `in-progress/`, not any category). Two cases:

- **Hand-authored local skill** the user wants to keep private → leave alone, mention it.
- **A skill the user created on this machine and forgot to add to the repo** → offer to copy it into `<repo>/skills/<category>/<name>/`, with the user picking the category.

Always ask before copying anything *up* into the repo. Never assume.

## Step 5 — Surface uncommitted repo edits

If `git -C <repo> status` shows uncommitted changes (from a previous skill-writing session, or from a Step 4 promotion):

```bash
git -C <repo> status -s
git -C <repo> diff --stat
```

Show the user. Offer to commit + push:

```bash
git -C <repo> add <paths>
git -C <repo> commit -m "<short message — let the user supply it or suggest one>"
git -C <repo> push
```

Do **not** commit + push silently. The user controls the message.

## Step 6 — Final report

End with:

- **Pulled**: N commits since last sync (or "already up to date").
- **Installed/updated locally**: list of skill names changed in `~/.claude/skills/`.
- **Promoted up**: any skills copied from `~/.claude/skills/` into the repo (rare).
- **Pushed**: commits pushed, or "nothing to push".
- **Left alone**: anything you noticed but didn't touch (e.g., local-only skills, divergent branches), so the user can decide later.

## Hard rules

- Repo is source of truth for shared content. Local edits to `~/.claude/skills/` get **promoted up**, never just kept.
- Never `--force-push` or rebase the skills repo.
- Never auto-commit without showing the diff and getting a message from the user.
- Never delete a skill from `~/.claude/skills/` without asking (it might be hand-authored or installed from elsewhere).
- If the repo's current branch isn't `main` (or whatever the default is), stop and ask — you might be on a feature branch the user is mid-edit on.
