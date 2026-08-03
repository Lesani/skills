---
name: sync-skills
description: Sync the local lesani/skills clone with what's installed under ~/.claude/skills, and surface any uncommitted edits in the repo for push. Bidirectional but with the repo as source of truth. Use when the user says "sync skills", "update skills", "pull skill changes", "I edited skills on the other machine", or invokes /sync-skills.
---

# Sync Skills

Keeps the cloned `skills` repo (default `~/.claude/skills-repos/lesani-skills`) and the active install at `~/.claude/skills/` aligned. **The repo is the source of truth.** Anything in `~/.claude/skills/` that doesn't exist in the repo is treated as a candidate to *promote up* to the repo, not as something to keep.

This is intentionally thin — six steps, no plumbing. If something is unclear at any step, stop and ask the user.

## Step 1 — Locate the repo

Default to `~/.claude/skills-repos/lesani-skills`. If absent, check `~/.claude/skills-repos/` for a differently-named clone, then ask the user where it lives (or offer `gh repo clone Lesani/skills ~/.claude/skills-repos/lesani-skills`).

Confirm it's the right repo: `git -C <path> remote -v` should show `Lesani/skills` (or the user's fork).

The clone is typically **shallow** (`.git/shallow` present, only a commit or two of history). That's fine for syncing, but don't expect `git log` to explain where a file originally came from.

## Step 2 — Pull

```bash
git -C <repo> fetch
git -C <repo> status -sb       # are there uncommitted local edits?
git -C <repo> pull --ff-only
```

If `pull --ff-only` fails because the local branch is ahead or diverged, **don't auto-merge** — surface it. The user wants to know if their local repo has unpushed work.

## Step 3 — Link repo → ~/.claude/skills/

The install is **symlink-based, not copy-based**. The repo ships its own linker; run it:

```bash
bash <repo>/scripts/link-skills.sh
```

It creates one symlink per skill in `~/.claude/skills/<name>/` pointing at `<repo>/skills/<category>/<name>/`. The category folders flatten — Claude only looks at skill names. It includes `in-progress/` and skips only `deprecated/`. It is idempotent (`ln -sfn`), so re-running it is a safe no-op that also repairs drift.

Because every skill is a symlink, **Step 2's pull already updated their contents**. There is no per-file copy, compare, or "Updated vs Identical" bookkeeping to do. The only thing this step changes is the *set* of links:

- **New** (in repo, not yet linked) → the script creates the link.
- **Removed in repo** → leaves a dangling symlink. Find them with
  `for l in ~/.claude/skills/*; do [ -e "$l" ] || echo "DANGLING: $l"; done`
  and ask before removing.

Report which skills were newly linked, and note that the rest were already current.

## Step 4 — Detect "promote up" candidates

Since every synced skill is a symlink, a **real directory** in `~/.claude/skills/` is by definition local-only:

```bash
find ~/.claude/skills -maxdepth 1 -mindepth 1 -type d
```

Anything it lists has no counterpart in the repo (checked across every category, including `deprecated/` and `in-progress/`). Two cases:

- **Hand-authored local skill** the user wants to keep private → leave alone, mention it.
- **A skill the user created on this machine and forgot to add to the repo** → offer to move it into `<repo>/skills/<category>/<name>/`, with the user picking the category, then re-run `link-skills.sh` to replace the real directory with a symlink.

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
- **Newly linked**: skill names that gained a symlink in `~/.claude/skills/` (everything else updated in place via the pull).
- **Promoted up**: any skills copied from `~/.claude/skills/` into the repo (rare).
- **Pushed**: commits pushed, or "nothing to push".
- **Left alone**: anything you noticed but didn't touch (e.g., local-only skills, divergent branches), so the user can decide later.

## Hard rules

- Repo is source of truth for shared content. Local edits to `~/.claude/skills/` get **promoted up**, never just kept.
- Never `--force-push` or rebase the skills repo.
- Never auto-commit without showing the diff and getting a message from the user.
- Never delete a skill from `~/.claude/skills/` without asking (it might be hand-authored or installed from elsewhere).
- Never edit a file under `~/.claude/skills/<name>/` — it's a symlink, so you'd be editing the repo working copy without noticing. Edit `<repo>/skills/<category>/<name>/` directly and let Step 5 surface the diff.
- If the repo's current branch isn't `main` (or whatever the default is), stop and ask — you might be on a feature branch the user is mid-edit on.
