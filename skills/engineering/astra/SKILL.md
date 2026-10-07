---
name: astra
description: Coordinate complex work with Astra designing and reviewing, and Sol agents planning and implementing whole feature slices that are tested as they are built.
---

# Astra

Astra (the parent) designs, decides, reviews and integrates. Sol agents plan
and implement. Work moves in **feature slices**, and each slice is built and
tested before the next one starts. Testing is how problems are found, so it
runs from the first slice. It is not a gate saved for the end.

## Models

Before the first dispatch, check the live model registry once. Select the
latest available Sol for planners, implementers and reviewers, unless the
project or owner names another model. Set `model` explicitly on every spawn,
and keep the selection fixed for the run. If a model is unavailable, report
it. Do not substitute another.

Spawn with the harness's own delegation tool: Codex
`collaboration.spawn_agent` (explicit `model`, `fork_turns: "none"`), or the
pi `subagent` tool (explicit `model`, fresh context). Children do not spawn
further agents.

## 1. Design — Astra

Read the relevant code and project instructions. Decide architecture,
interfaces, scope and acceptance criteria, and record the binding design.
Then cut the work into **feature slices**. A slice is one user-visible
behaviour or one cohesive subsystem change, end to end: code, its tests,
and its on-device or simulator check. Prefer 2–6 substantial slices. A slice
should take one agent hours, not minutes. Do not cut a feature into
file-sized or step-sized leases. Each slice must be testable by itself.

Give slices disjoint file ownership. Sequence the dependent ones. Shared
files are assigned to one slice by name.

## 2. Plan — Sol (optional per slice)

For a slice whose approach is not obvious, a Sol planner writes an ordered,
file-specific plan: changes, the **exact tests to add or run**, the device
or simulator check, and risks. The planner makes no edits, and it raises
contradictions with the design instead of changing the design. Astra reviews
the plan and records corrections as amendments. When the design already
answers how, skip this step: the implementer plans its own slice.

## 3. Build and test the slice — Sol implementer

One Sol implementer owns one slice and makes it work. It does not only write
the code. Its brief has the design, the reviewed plan, the file ownership
and the tests. The implementer:

1. Writes the code and the slice's tests together.
2. Runs the focused tests for what it touched (the project's test runner,
   only the affected files) and fixes the failures it finds.
3. Runs the slice's native or simulator check when the project requires one,
   or when the slice changes UI or device behaviour. Debug builds on
   simulators are always allowed for this. Restrictions on "final
   candidate only" apply to releases and owner test devices, not to
   simulators.
4. Reports the changed files, the commands it ran with pass/fail output, the
   evidence paths and any deviation from the plan.

A report with no test output is not finished. Send the agent back for it.

## 4. Review the slice — Astra, immediately

When a slice reports, review it before you dispatch the next one:

- Read the diff. Rerun the focused tests yourself. Do not trust a green claim.
- Check the slice against its acceptance criteria. If the project has a
  sprint contract, update that slice's cells now, once per slice. Do not
  update them after every message.
- On a failure, send the same implementer (or a fresh Sol with the failure
  output) back to fix it, then retest. Fix while the context is warm. Do not
  queue the failure for the end.

Run independent slices in parallel only when their file ownership is
disjoint. Otherwise run them in sequence.

## 5. Integrate and verify — Astra

After the last slice, run the integrated checks on the merged result: the
full suite (if the project requires one), and the integrated candidate's
device or simulator checks. This pass confirms the slices still work
together. It should find little, because each slice was already tested. A
failure here becomes a fix slice, not a new round of planning.

Report against the original approved scope: what passed, with evidence; what
is still open, and why; and any owner-approved reductions. Publication and
deployment approvals stay separate from implementation and test completion.

## Supervision

Rely on completion notifications. While agents run, keep at most one
fallback wake (hourly). Delete it as soon as no agents run, or when the owner
says stop. Never re-create a wake the owner stopped. Elapsed time alone is
not a reason to kill an agent. Do not set completion deadlines on agents;
safety timeouts on single commands still apply.

If an agent fails or runs out of context, keep its partial diff and output.
Diagnose the cause. Then continue with a fresh Sol on what remains of the
**same slice**, with the failure in the brief. Do not split the slice into
smaller and smaller pieces. Ask the owner only for a genuine decision or new
authority.

## Anti-patterns

- Implement everything, test at the end. Each slice is tested when it is built.
- Micro-leases: many tiny tasks with a bookkeeping step between each one.
- Chunked reviews: splitting a diff into numbered part files for review. Give
  one reviewer the whole slice diff instead.
- Ledgers that grow faster than the code. The acceptance contract records
  results. It is not the work.
- Treating a self-created process artifact (a chunk file, a lease, a receipt)
  as scope that must be closed.
