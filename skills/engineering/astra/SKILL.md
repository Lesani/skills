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

## Integration and verification — Astra

Re-read changed files, review critical paths, and verify the integrated result
with checks appropriate to the change. Follow the project's worktree, commit,
and deployment rules within the task's authorization. Report the outcome and
any remaining limitations.
