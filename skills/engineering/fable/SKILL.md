---
name: fable
description: Tiered delegation workflow that reserves the top model for decisions - the main session designs and records binding decisions, opus subagents do fine planning, opus/sonnet subagents implement. Use when implementing a non-trivial feature or change, or when the user invokes /fable or asks to "plan with opus and implement with opus/sonnet".
---

# Fable: design → fine-plan → implement

The orchestrator makes and records decisions.
Delegate everything downstream: opus plans, opus/sonnet implements.
The orchestrator reviews and verifies.

## Phase 1 — Design (you, the main session — do NOT delegate this)

- Read enough real code to *decide*, not to implement: data model, the
  architecture seam the feature lands on, wire protocol, UX shape.
- Resolve ambiguities: ask the user if they are available. Otherwise adopt
  your recommendation and record it as a decision.
- Record decisions where they persist: CONTEXT.md glossary terms for new
  domain language. Write an ADR when a decision is hard to reverse,
  surprising, and a real trade-off.
- Write a rough-design doc to the scratchpad. Cover, per feature: user
  model / storage & model changes / architecture / wire protocol & UI /
  (testing approach, if applicable) / implementation order / shared agent constraints.
- Commit the design docs before you spawn any agents.

## Phase 2 — Fine planning (opus Plan agents)

- Spawn one Plan agent per independent workstream. Launch them in parallel.
- Each prompt MUST contain: a pointer to the rough design marked BINDING
  (plan, do not redesign), an explicit key-file list, a per-area summary of
  what to plan, the deliverable format, and the environment constraints.
- Demand this deliverable format:
  - ordered steps grouped by area
  - file-by-file changes, with binding code snippets only for the tricky parts
  - an exact test list with names
  - risks and edge cases
  - backend/frontend ownership split into disjoint file sets
- Warn planners about known failure modes: variable shadowing in snippets,
  lock/concurrency discipline, prose that contradicts its own snippet.
- Save each returned plan verbatim to scratchpad `plan-<feature>.md`.

## Phase 3 — Plan review (you)

- Read each plan critically before anyone implements: mentally execute the
  snippets, cross-check against the rough design and against sibling plans.
- Record fixes as `BINDING AMENDMENT` notes appended to the plan file.
  Implementers follow the plan file, not the conversation history.

## Phase 4 — Implementation (opus or sonnet, by complexity)

- Triage per workstream. Always set the model explicitly:
  - concurrency, engine, architectural, or cross-cutting work → `opus`
  - well-specified UI, mechanical edits, tests from an exact list → `sonnet`
  - trivial one-liners → `haiku`
- Run agents in parallel only with DISJOINT file ownership (e.g. backend
  vs. frontend trees), stated in each prompt.
- Subagents inherit no CLAUDE.md: every prompt restates the environment
  rules (relative paths, no `cd` prefix, ASCII-only output, exact venv test
  command, branch rules, files they must not touch).
- One feature branch per feature. State in the prompt whether agents commit
  their own scope or leave the commits to you — one convention per feature.

## Phase 5 — Verify and deliver (you)

- Run the FULL test suite yourself. Never trust an agent's green claim.
- Personally diff-review the critical paths (engine, concurrency, protocol).
- Merge and push per the project's git workflow.
- Ask the user to test. Defer CHANGELOG/records until they confirm.

## Rules of thumb

- If you write implementation code in Phase 1, stop — decide, record, delegate.
- If an agent is idle without a report, send one nudge ("send your report").
- Before you edit a file an agent touched, read it again.
- Cost order: your tokens > opus > sonnet — push work down, decisions up.
