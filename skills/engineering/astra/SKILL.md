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
stop an agent. Cancel the hourly wake when no agents remain running.

If a run fails, preserve its partial evidence, diagnose the failure, and recover
proactively through the same governed delegation protocol. Resume only a
resumable child; otherwise label a fresh same-role recovery. Do not silently
substitute models or execution modes. Do not stop at reporting a recoverable
failure while the authorized task remains unfinished; ask only when recovery
requires a genuine owner decision or new authorization.

## Integration and verification — Astra

Re-read changed files, review critical paths, and verify the integrated result
with checks appropriate to the change. Follow the project's worktree, commit,
and deployment rules within the task's authorization. Report the outcome and
any remaining limitations.
