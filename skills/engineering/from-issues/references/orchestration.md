# Orchestration Reference

Detailed flow for `from-issues`: DAG sequencing, parallelism, HITL workflow, failure recovery. The main `SKILL.md` covers the high-level steps; this file fills in the corner cases.

## DAG sequencing

Issues form a directed acyclic graph via the `## Blocked by` section in their body. The skill builds the DAG once at the start of a run, then re-evaluates after each issue completes.

### Parsing blockers

The "Blocked by" section is plain text. Recognized forms:

- `#13`
- `#13, #17, #19`
- A bullet list of `- #N` lines
- "None - can start immediately" → no blockers

The skill extracts integer issue numbers from this section (regex on `#(\d+)`). Unparseable text → treat as a blocker that's never satisfied (i.e., halt and ask the user) rather than silently ignoring it.

### Ready set computation

An issue is ready iff:

1. State is open.
2. No `needs-triage` label (or the project's equivalent).
3. Every `Blocked by` issue is in the closed state.

Re-compute the ready set:
- At skill startup.
- After every issue completes (a freshly-merged PR may close issues that unblock others).
- Never within the per-issue execution loop — that loop targets one issue and runs to completion or escalation.

### Tie-breaking

When multiple issues are ready, pick:

1. The one with the **most downstream issues blocked on it** (unblocks the most work). Compute by walking the inverse-blocker graph.
2. Tie-break by smallest issue number (oldest, deterministic).

This rule turns the DAG into a natural critical-path ordering without needing manual priority labels.

## Wave model and parallelism

The skill executes as a sequence of **waves**. Each wave is a set of issues that can run concurrently. Most waves are size 1 (sequential, no worktrees). With `--parallel K`, the skill picks up to K independent issues per wave.

### Independence heuristic

Two issues are "safe to run in parallel" if their changesets are unlikely to overlap. Heuristics, in order of confidence:

1. **Explicit module separation**: parent PRD lists modules; each issue's "What to build" names a distinct one.
2. **Acceptance-criteria text**: criteria mention disjoint file/area keywords (e.g. "screenshot" vs "camera-modes" vs "scene-tree").
3. **No shared blockers in their dependency tree**: weaker signal, useful as a tiebreaker.

When in doubt, run fewer in parallel. A merge conflict from over-eager parallelism wastes more time than the parallelism saved.

### Wave mechanics

Setup (parallel waves only):

1. From the feature branch tip, create K-1 throwaway worktrees at `../<repo>-wave-<N>-<slug>/`, each on the feature branch (same branch in all worktrees — the feature branch already isolates the wave from `main`). The main worktree handles the K-th issue.
2. Use `superpowers:using-git-worktrees` conventions if available.

Dispatch:

3. Dispatch all K implementers in **a single message with K Agent tool calls** (per `superpowers:dispatching-parallel-agents`). Each subagent's prompt includes the absolute path of its assigned worktree.
4. Sequential waves (K=1) skip steps 1–3 and run the implementer directly in the main worktree.

Per-slice review (still in the implementer's worktree):

5. Spec reviewer → fixes → quality reviewer → fixes. All in the same worktree where the implementer wrote, including for parallel waves. Reviewers do **not** get their own worktrees.

Wave merge-back (controller's job, in the main worktree):

6. For each non-main worktree: fast-forward / clean-merge its commits onto the feature branch in the main worktree. Use `git merge --ff-only <worktree-branch-tip>` where possible.
7. **On real conflict**: stop and resolve. Small conflicts: controller resolves directly. Large or scope-unclear conflicts: dispatch a merge subagent with the conflicting hunks and the relevant slice context.
8. Remove throwaway worktrees with `git worktree remove` once their commits are on the feature branch. Don't accumulate them.

Integration check:

9. Run a focused test pass on the feature branch tip — at minimum the test files touched by the wave. Per-slice reviews already vetted each slice in isolation; this catches cross-slice regressions only.

Subsequent waves branch from the new feature-branch tip, so they always see the accumulated work.

### Forbidden parallelism / worktree footguns

- **Never** dispatch two implementer subagents into the same worktree at the same time. They'll race on the same files.
- **Never** run an implementer in parallel with its own spec or quality reviewer.
- **Never** parallelize across the same file area unless ADRs / plan guidance say it's safe.
- **Never** spin up a worktree for a sequential implementer or for a reviewer. Worktrees are only for concurrent writers in a parallel wave.
- **Never** pass `isolation: "worktree"` to the Agent tool as a default. It's appropriate only for the K concurrent implementers in a parallel wave, and only if you've manually pre-created and pre-branched the worktree (or are using the Agent tool's isolation parameter as the worktree creation mechanism — pick one approach per wave, not both).
- **Never** end a wave without merging the worktrees back. The feature branch tip is the source of truth; throwaway worktrees should not outlive the wave that created them.

## HITL workflow

HITL-flagged issues need human design checkpoint before the implementer runs. Detection:

- Label `hitl` on the issue (preferred — explicit and visible).
- Or: a marker line in the issue body like `**Type: HITL**` (legacy, for issues created before the label convention).

### Halt and brief

When the skill picks an HITL issue:

1. **Stop dispatch.** Do not run the implementer.
2. Print a brief to the user:
   - Issue number and title.
   - One-paragraph "What to build" summary.
   - The full acceptance criteria.
   - Any open questions the skill identified (ambiguous criteria, conflicting blockers, unstated assumptions).
3. Ask: "Approve dispatch as-is, refine the spec first, or skip?"
4. Resume only on explicit approval.

### `--include-hitl` mode

If the user passed `--include-hitl`, do not halt. Print the brief inline (so the user has visibility) and proceed to dispatch. This is the right mode for an experienced user who wants a long autonomous run with all HITL slices already pre-reviewed.

## Failure recovery

### Implementer status handling

| Status | Action |
|---|---|
| `DONE` | Proceed to spec review. |
| `DONE_WITH_CONCERNS` | Read concerns. If correctness or scope, address before review (re-dispatch with guidance). If observation only ("file is getting big"), note and proceed to review. |
| `NEEDS_CONTEXT` | Provide the missing context as additional prompt material; re-dispatch the same implementer. |
| `BLOCKED` | Diagnose the blocker. Options: provide more context and re-dispatch; re-dispatch with a more capable model; break the issue down further (post a comment on the issue suggesting a split); escalate to the user. |

Never re-dispatch the same implementer with the same model and same context — something must change between attempts.

### Reviewer-found issues

Both spec and quality reviewers can return ❌. The same implementer subagent fixes the issues, then the reviewer reviews again. Loop until clean.

If the loop exceeds a reasonable budget (say 3 rounds on the same review stage), stop and surface to the user — there's likely a deeper misalignment.

### Tracker errors

If the issue tracker call fails (network, auth, malformed response):

- Retry once.
- If still failing, halt and surface the error. Don't continue blindly — a missed comment or PR link breaks the audit trail.

### Worktree errors

If worktree creation fails (existing worktree at the same path, dirty state, conflicting branch):

- Don't force or clean. Surface the conflict and ask the user. Worktree state often represents in-progress work.

### Wave merge-back errors

If the wave merge-back hits a real conflict:

- Stop the run before dispatching the next wave.
- Small / mechanical conflicts: controller resolves in the main worktree, commits, then continues.
- Large / scope-unclear conflicts: dispatch a merge subagent with the conflicting hunks, both slices' acceptance criteria, and the file's surrounding context. Wait for it to finish before continuing.
- If the subagent can't resolve cleanly, surface to the user — don't force-merge or drop a slice.

## What the skill never does

- **Never close or modify the parent PRD issue.** Only the slice issues, and only via PR-merge auto-close where the tracker supports it.
- **Never edit acceptance criteria.** If criteria are wrong or ambiguous, post a comment on the issue and ask the user to amend.
- **Never silently swallow review failures.** Every review round is logged and posted as a comment when the issue is wrapped up.
- **Never bypass the triage gate.** `needs-triage` issues are skipped, full stop.
- **Never push to main/master directly.** Always via a feature branch and a PR.
- **Never force-merge.** A PR with failing reviews waits for the user.

## Skill state across runs

The skill is stateless between invocations — it re-reads the issue tracker each run. This means:

- If a previous run partially completed work on an issue (branch exists, PR not yet open), the skill detects the existing branch and asks the user how to proceed (continue, abandon, or take over).
- If a previous run posted comments and opened a PR but the PR isn't merged, the skill leaves it alone — the user owns the merge decision.
- The skill doesn't maintain its own database of in-flight work. The git branches and the issue tracker are the source of truth.
