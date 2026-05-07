---
name: merge-down
description: Merge multiple feature branches and worktrees down into a single integration branch, resolve the conflicts that always show up (sln files, formatting, modify/delete), then clean up merged worktrees, branches, and stashes. Use when the user says "merge everything down", "consolidate branches", "clean up worktrees", or wants to unify divergent topic branches into dev/main.
---

# Merge Down

A workflow for collapsing parallel topic branches and worktrees into one integration branch (`dev/development`, `develop`, `main` — whatever the user calls it), then sweeping up everything that's now redundant.

The skill is mostly **discipline**: inventory before you touch anything, decide with the user, then execute in a fixed order that prevents the predictable foot-guns (orphaned branches, lost stashes, force-pushes that nuke other people's work, modify/delete conflicts that silently delete real code).

## Phase 1 — Inventory (never skip)

Always start by reporting the full state. Never act on assumptions.

Collect, in parallel where possible:

- `git worktree list` — every checkout the user has open.
- `git branch -a` and the current branch.
- For each non-target branch: `git rev-list --left-right --count <target>...<branch>` to see commits on each side. Anything `0	N` means the branch has nothing new (already merged or stale). Anything `M	N` with N > 0 means there's real work to merge.
- `git status -s` inside **each** worktree (not just root). Dirty trees in side worktrees are easy to miss and they block merges.
- `git stash list`.
- `git fetch` first so local tracking refs are honest, then `git rev-list --left-right --count <target>...origin/<target>` to spot incoming commits you need to pull before merging anything.

Present this as a single table or short list. Do **not** start merging yet.

## Phase 2 — Decide with the user

Surface every non-trivial decision before doing it:

- Which branches actually merge in? (Skip ones the user marks as stale or experimental.)
- For each dirty working tree: commit, stash, or discard?
- For uncommitted changes that look like real WIP (not auto-generated, not whitespace), **show the diff** and ask. Don't auto-commit code on the user's behalf without surfacing it.
- For "merge everything" requests, confirm whether deleted paths on the target should be resurrected if source branches still touch them (see Phase 4).

Default to the cautious option when in doubt. Pause and ask. Cost of a confirmation < cost of a destructive surprise.

## Phase 3 — Pull the target first

If `<target>` is behind `origin/<target>`, pull/merge it before merging anything else in. This avoids creating merges on a stale base and avoids the "force-push to fix it" temptation later.

If working-tree changes block the pull, stash them with a labelled message (`pre-merge: <what>`) — you'll surface that stash again in Phase 6.

## Phase 4 — Resurrect deleted-but-modified paths

This is the conflict that trips everyone up: target deleted `MotionToolkit/`, source branches still actively modify files inside `MotionToolkit/`. A normal merge produces "modify/delete" conflicts only on the touched files, **silently leaving the rest deleted**.

If the user wants the deleted paths back (almost always, when those branches contained real work), do this **before** the merge:

```bash
# Pick the most up-to-date source branch (most commits ahead of target)
git checkout <most-up-to-date-source> -- <path1> <path2> ...
git commit -m "Resurrect <paths> from <branch>"
```

Now the merges of all source branches land cleanly on top of restored paths.

If the user wants the paths to stay deleted, instead resolve modify/delete conflicts during merge by `git rm`-ing the conflicting files and dropping those source commits — but warn that the source branches' work is being discarded.

## Phase 5 — Merge the source branches

Order: oldest base first when reasonable, but it rarely matters once Phase 4 is done.

For each source branch:

```bash
git merge <branch> --no-ff -m "Merge <branch> into <target>: <one-line summary of what it brings>"
```

### Predictable conflicts and how to resolve them

- **`*.sln` `GlobalSection(ProjectConfigurationPlatforms)`** — both sides added entries for different projects. Resolve by **union**: keep all entries from both sides, drop the conflict markers. Do not pick one side.
- **Indentation- or formatting-only conflicts** (e.g., 2-space vs 4-space JSON, trailing-newline differences) — keep the side that matches the rest of the file's existing convention. Don't introduce a third style.
- **Generated/lock files** (`package-lock.json`, `Cargo.lock`, etc.) — regenerate after merge instead of hand-resolving.
- **Real code conflicts** — pause, show the user the conflict hunks, ask. Don't guess intent.

Always commit the merge resolution as the merge commit (don't amend it into something else).

## Phase 6 — Pop the pre-merge stash

If you stashed in Phase 3, `git stash pop` now. Resolve conflicts using the same rules from Phase 5. After resolving, run `git stash drop` only if the stash has been fully applied — `git stash list` should show the entry gone.

If the stash content is already in the tree (post-merge it became redundant), drop it but say so explicitly in the report.

## Phase 7 — Verify

```bash
<build command>   # dotnet build, cargo build, npm run build, etc.
<test command>    # if fast
```

Build "errors" caused by **file locks** (running processes holding `.exe` / `.dll` files) are not merge problems — flag them but don't try to fix them by killing user processes. Ask the user to close the running app.

Real compile errors **are** merge problems. Investigate.

## Phase 8 — Push

```bash
git push origin <target>
```

Never `--force` without an explicit user OK and a clear reason. The merges in Phase 5 are new commits on top of `<target>` — a normal fast-forward push is enough.

## Phase 9 — Cleanup (only after the user confirms)

In this order:

1. **Local merged branches** — for each source branch:
   ```bash
   git branch -d <branch>     # safe delete; refuses if commits aren't on the target
   ```
   If git refuses with "not fully merged" but you've verified the content **is** on the target (the warning fires when the branch is ahead of its **remote tracking ref** even if merged into target), use `-D` after explicitly confirming.

2. **Remote merged branches**:
   ```bash
   git branch -r --merged origin/<target>      # confirm what's safe
   git push origin --delete <branch>
   ```
   Skip `origin/main` and other protected branches even if they show up as "merged".

3. **Worktrees**:
   ```bash
   git worktree remove <path>
   ```
   Only remove a worktree if its branch was merged. Worktrees on still-active branches stay.

4. **Prune** so other terminals catch up:
   ```bash
   git fetch --prune
   ```

5. **Stashes** — audit each remaining stash:
   - Show its base commit, age, and `git stash show --stat`.
   - For each file in the stash, check whether its content is already applied (`git diff --quiet stash@{N} -- <file>`).
   - If the stash is fully obsolete (e.g., reverts a fix that's now committed, or its content matches the working tree), drop it.
   - If it has real WIP code that's not in tree, **show the diff to the user and ask** — never autonomously discard live WIP.

## Hard rules

- **Inventory before action.** Phases 1 and 2 are mandatory.
- **No force-push without explicit OK.** And never to shared branches like `main` / `master`.
- **No `git reset --hard` to "fix" a merge gone wrong.** Use `git merge --abort` instead — it's reversible.
- **Show real WIP before discarding it.** Code stashes, uncommitted modifications to non-generated files, etc.
- **Don't kill user processes** to unstick a build. Report the lock and let the user decide.
- **Confirm scope.** "Merge everything down" sometimes means "into dev", sometimes "into main", sometimes "and clean up too". Ask.

## Reporting

End with a concise summary:

- Merges done (which branch → target, summary of what each brought).
- Conflicts resolved and how (especially union/format/resurrect choices — these are decisions the user should be able to audit).
- What got cleaned (branches deleted, worktrees removed, stashes dropped).
- What was **left in place** and why (so the user knows nothing was silently dropped).
- Anything still needing action (e.g., open build errors, processes that need closing).
