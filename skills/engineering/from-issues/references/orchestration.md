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

## Parallelism

Default is serial (one issue at a time). With `--parallel K`, the skill picks up to K independent issues per dispatch wave.

### Independence heuristic

Two issues are "safe to run in parallel" if their changesets are unlikely to overlap. Heuristics, in order of confidence:

1. **Explicit module separation**: if the parent PRD's "Implementation Decisions" lists modules and each issue's "What to build" names a distinct one, parallel is safe.
2. **Acceptance-criteria text**: if the criteria mention disjoint file/area keywords (e.g. "screenshot" vs "camera-modes" vs "scene-tree"), parallel is plausible.
3. **No shared blockers in their dependency tree**: weaker signal but useful as a tiebreaker.

When in doubt, run fewer in parallel. A merge conflict from over-eager parallelism wastes more time than the parallelism saved.

### Parallel mechanics

For each parallel issue:

1. Create a worktree at `../<repo-name>-issue-<N>/` (use `superpowers:using-git-worktrees` conventions if available).
2. Check out a fresh branch `feat/issue-<N>-<slug>` in that worktree.
3. Dispatch the implementer subagent **in that worktree's directory**. The subagent's prompt includes the absolute path so it works in the right tree.
4. Run the spec/quality review loop in that same worktree.
5. Push and PR-prep from that worktree.
6. After the PR is open (or branch is pushed and the comment is posted), the worktree can be left in place — clean up after the user merges, or keep for follow-up fixes.

The skill controller should dispatch all K parallel implementers in **a single message with K Agent tool calls** (not sequentially), per `superpowers:dispatching-parallel-agents`.

### Forbidden parallelism

- **Never** dispatch two implementer subagents into the same worktree at the same time. They'll race on the same files.
- **Never** run an implementer in parallel with its own spec or quality reviewer.
- **Never** parallelize across the same file area unless explicit ADRs / plan guidance say it's safe.

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
