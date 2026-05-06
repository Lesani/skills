# Issue Tracker Adapters

Per-tracker commands for the operations `from-issues` performs. The skill adapts its calls to whichever tracker the repo uses.

## Operations the skill needs

For any tracker, the skill must be able to:

1. **List open issues** with labels and basic metadata.
2. **Get a single issue's body and comments** by number.
3. **List labels** on a single issue.
4. **Post a comment** on an issue.
5. **Open a PR / merge request** referencing an issue.
6. **Push a branch** to the remote.

The skill never closes or modifies the parent issue.

## Gitea (via `tools/gitea-issue.js`, the starshipviewer convention)

The repo ships `tools/gitea-issue.js` — a CLI wrapper around the Gitea REST API that reads `GITEA_API_TOKEN` and `GITEA_REPO` from `.env.local`. Use it for issue operations:

```bash
# List open issues with labels
node tools/gitea-issue.js list

# Get a single issue's full body
node tools/gitea-issue.js get <number>

# Post a comment on an issue
node tools/gitea-issue.js comment <number> --body "..."

# Close an issue (skill should NOT use this on parent issues; only after PR merge if appropriate)
node tools/gitea-issue.js close <number>
```

For PR creation against Gitea, `tools/gitea-issue.js` does not currently expose a PR command. The skill should:

1. Push the branch with `git push -u origin feat/issue-<N>-<slug>`.
2. Either:
   - Use the Gitea REST API directly via curl/Node (POST `/api/v1/repos/<owner>/<repo>/pulls`), or
   - Post a comment on the issue with the branch name and ask the user to open the PR through Gitea's web UI.

For v1 of this skill, prefer the comment-and-prompt approach unless `tools/gitea-issue.js` is later extended with `pr create`.

**HITL detection:** check for a label named `hitl` on the issue. The skill's labels query parses the `(label1, label2)` suffix from `gitea-issue.js list` output, or fetches labels per-issue via the API for accuracy.

**Triage gate label:** check for `needs-triage` (or whatever the project uses). Issues with this label are skipped.

## GitHub (via `gh` CLI)

```bash
# List open issues with labels (JSON for parsing)
gh issue list --state open --json number,title,labels,body

# Get a single issue
gh issue view <number> --json number,title,labels,body,comments

# Post a comment
gh issue comment <number> --body "..."

# Open a PR
gh pr create --title "..." --body "Closes #<N>" --head feat/issue-<N>-<slug>

# Push branch
git push -u origin feat/issue-<N>-<slug>
```

## GitLab (via `glab` CLI)

```bash
glab issue list --state opened
glab issue view <iid>
glab issue note <iid> --message "..."
glab mr create --title "..." --description "Closes #<iid>"
git push -u origin feat/issue-<iid>-<slug>
```

## Local-markdown (e.g. `.scratch/issues/`)

For repos using the local-markdown convention (one `.md` file per issue under a directory like `.scratch/issues/`):

- "List" = `ls .scratch/issues/*.md`
- "Get" = read the file
- "Comment" = append a `## Comment YYYY-MM-DD HH:MM` section to the file
- "PR" = produce a branch + push + write a note in the issue file with the branch name; the user reviews locally
- "Labels" = front-matter `labels:` field (YAML)

The skill should detect the convention by checking for `.scratch/issues/` and follow the front-matter format the existing files use.

## Per-repo configuration

If `AGENTS.md`, `CLAUDE.md`, or `docs/agents/issue-tracker.md` describes a non-default workflow (e.g. a custom CLI, a self-hosted GitLab on a non-standard port, a script wrapper), use that instead. The skill should read those files first before falling back to the heuristics above.

If no configuration is found and the heuristics don't match anything, ask the user — don't guess.
