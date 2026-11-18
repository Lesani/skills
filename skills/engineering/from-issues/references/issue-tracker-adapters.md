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
