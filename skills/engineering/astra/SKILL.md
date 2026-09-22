---
name: astra
description: Coordinate complex work with Astra designing, Sol planning, and Terra implementing.
---

# Astra

## Rough planning — Astra

Inspect the relevant code and project instructions. Decide the architecture,
interfaces, scope, and acceptance criteria. Record the binding design and split
the work into independently owned areas.

## Fine planning — Sol

Split multi-topic work before the first delegation. Give each Sol agent one
cohesive topic or subsystem, not the entire sprint or backlog. For example,
planner controls, navigation guidance, and content/localization get separate
planning tasks. Each brief includes only its issue subset, relevant entry
points, shared contracts, ownership boundaries, and expected plan artifact.
Astra owns cross-topic synthesis; do not make every planner rediscover the
whole repository. Sequence dependent topics and assign shared files explicitly.

Delegate to `gpt-5.6-sol` using `collaboration.spawn_agent` with an explicit
`model` and `fork_turns: "none"`; full-history forks cannot override the model.

Provide the task, workspace, relevant instructions, binding design, key files,
and ownership boundaries. Request an ordered, file-specific plan with concrete
checks, dependencies, and risks. Sol plans without implementation edits and
raises contradictions rather than silently changing the design.

## Plan review — Astra

Review Sol's plan against the design and related workstreams. Record corrections
as binding amendments. Give Terra the complete reviewed plan and amendments,
inline or in a saved document. For a planning-only request, finish here.

## Execution ownership and acceptance — Astra

A planning-only request still stops after plan review. Once execution is approved,
Astra owns the whole approved task through acceptance, not merely agent dispatch.
Create the project's durable acceptance matrix before implementation: every
approved issue and observable criterion, required platform/surface checks,
source-review gate, evidence reference, candidate identity, owner and next action.
Keep approved scope separate from reported results so omitted work cannot vanish.
Use the project's sprint contract/validator when available. Do not invent a
second competing ledger. Native checks cannot be replaced by source tests.

States are `pending`, `running`, `pass`, `fail`, `blocked`, and `not_applicable` with an
explicit rationale. Partial evidence is not a whole-criterion pass. Historical
build evidence needs a recorded applicability assessment against the current
candidate; changed behavior requires fresh validation. Scope exceptions and
rollovers require the owner's recorded decision, not an agent's convenience.

After EVERY child result, reconcile the assigned criteria and then the whole
matrix. Record omissions, failures, evidence and next actions before dispatching
repairs/retests. A successful run receipt proves neither criterion acceptance
nor sprint completion. An empty fleet triggers this reconciliation, not stopping.
If authorized work remains, continue it. If all remaining paths genuinely need
new authority or external input, report BLOCKED with the exact decision/input
needed; keep the task open. Honor an explicit owner pause immediately.

For each blocker record cause, attempts, authorized alternatives and responsible
owner/next action. Reconsider parent-imposed temporary restrictions before calling
something blocked. Routine authorized setup, test data, supported tooling and
map downloads are engineering work, not renewed permission requests. Never
relax a real safety, publication or authorization boundary to make tests pass.

If workers repeatedly omit requirements or exhaust context/budget, diagnose the
constraint, split bounded deliverables and use a fresh same-role recovery where
appropriate. Preserve all missing criteria. Do not endlessly resume the same
oversized context or weaken acceptance to obtain a successful receipt. A scoped
child contract must match its actual deliverable; the whole-task gate stays with
the parent. Review evidence rather than just success labels.

Every milestone update starts with task/sprint INCOMPLETE, BLOCKED or COMPLETE,
verified issues X/Y (when applicable), outstanding criteria and next action.
Completion requires accepted required criteria and final integrated checks.
Owner-approved scope reductions must be reported separately: closing an adjusted
round does not mean all originally selected work passed. Publication/deployment
approval remains separate from implementation and test completion.

## Implementation — Terra

Delegate to `gpt-5.6-terra` with an explicit `model` and `fork_turns: "none"`.
Provide the reviewed plan, workspace, project instructions, file ownership,
and required checks. Terra implements, verifies, and reports changes, results,
and deviations. Design or ownership changes return to Astra for a decision.

Run independent workstreams in parallel only with disjoint ownership and useful
concurrent work for Astra. Sequence dependencies. Sol and Terra do not spawn
further agents. Report unavailable models instead of silently substituting them.

## Supervision and recovery — Astra

Do not impose agent or workflow completion deadlines: valid work can take
hours. Use deadline-free background orchestration and verify harness defaults
do not introduce an implicit deadline. This does not remove safety deadlines
for individual shell commands or tools.

While agents run, schedule an hourly wake for the parent to check progress,
errors, pending questions, and genuinely stuck work. Keep native completion
notifications for immediate follow-up. Elapsed time alone is not a reason to
stop an agent. When no agents remain, reconcile the acceptance matrix first.
Cancel/pause the hourly wake only after recording completion, an explicit owner
pause, or a genuine externally blocked handoff. If authorized work remains,
start the next bounded action; do not treat timer cleanup as task completion.

If a run fails, preserve its partial evidence, diagnose the failure, and recover
proactively through the same governed delegation protocol. Resume only a
resumable child; otherwise label a fresh same-role recovery. Do not silently
substitute models or execution modes. Do not stop at reporting a recoverable
failure while the authorized task remains unfinished; ask only when recovery
requires a genuine owner decision or new authorization.

## Integration and verification — Astra

Re-read changed files, review critical paths, and verify the integrated result
with checks appropriate to the change. Follow the project's worktree, commit,
and deployment rules within the task's authorization. Reconcile every required
criterion, run the project's fail-closed completion validator where available,
and verify issue/board/handoff updates before declaring completion. Never
silently roll unverified work out of scope. Report the outcome and any remaining
limitations against the original approved scope, not only the last agent's task.
