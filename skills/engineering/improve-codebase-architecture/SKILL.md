---
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase, informed by the domain language in CONTEXT.md and the decisions in docs/adr/. Use when the user wants to improve architecture, find refactoring opportunities, consolidate tightly-coupled modules, make a codebase more testable and AI-navigable, or plan and execute a large architectural rework.
---

# Improve Codebase Architecture

Surface architectural friction, decide the **deepening opportunities**, and delegate the implementation. A deepening opportunity is a refactor that turns a shallow module into a deep one. The goal is testability and AI-navigability, at reworks too large for one session to implement alone.

**Division of labor:** you are the orchestrating session and the most expensive model. Spend your tokens on reading and decisions. Delegated agents spend the implementation tokens. You never write implementation code — not in the plan, not in the repo.

## Glossary

Use these terms exactly in every suggestion. Consistent language is the point. Do not drift into "component," "service," "API," or "boundary." Full definitions are in [LANGUAGE.md](LANGUAGE.md).

- **Module** — anything with an interface and an implementation (function, class, package, slice).
- **Interface** — everything a caller must know to use the module: types, invariants, error modes, ordering, config. Not just the type signature.
- **Implementation** — the code inside.
- **Depth** — leverage at the interface: a lot of behavior behind a small interface. **Deep** = high leverage. **Shallow** = interface nearly as complex as the implementation.
- **Seam** — where an interface lives: a place where you can alter behavior without editing in place. (Use this, not "boundary.")
- **Adapter** — a concrete thing that satisfies an interface at a seam.
- **Leverage** — what callers get from depth.
- **Locality** — what maintainers get from depth: change, bugs, and knowledge concentrated in one place.

Key principles (see [LANGUAGE.md](LANGUAGE.md) for the full list):

- **Deletion test**: imagine that you delete the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.**
- **One adapter = hypothetical seam. Two adapters = real seam.**

The project's domain model _informs_ this skill. The domain language gives names to good seams. ADRs record decisions that the skill must not re-litigate.

## Process

### 1. Explore (you — do NOT delegate this)

First read the project's domain glossary and the ADRs for the area you touch.

Then walk the codebase yourself with Read/Grep/Glob. Do not send Explore subagents and work from their summaries. You form the architectural judgment while you read the code firsthand. Explore organically and note where you experience friction:

- Where does one concept force you to bounce between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where did someone extract pure functions only for testability, while the real bugs hide in the call sites (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to any module you suspect is shallow: does deletion concentrate the complexity, or only move it? A "yes, concentrates" is the signal you want.

### 2. Present candidates

Present a numbered list of deepening opportunities. For each candidate:

- **Files** — which files/modules are involved
- **Problem** — why the current architecture causes friction
- **Solution** — plain English description of what would change
- **Benefits** — explained in terms of locality and leverage, and also in how tests would improve
- **Tag** — **clear-cut** (the deepened shape is obvious once named) or **contentious** (an open design question remains: where the seam goes, what survives at the interface, which callers absorb what)

**Use CONTEXT.md vocabulary for the domain, and [LANGUAGE.md](LANGUAGE.md) vocabulary for the architecture.** If `CONTEXT.md` defines "Order," say "the Order intake module" — not "the FooBarHandler," and not "the Order service."

**ADR conflicts**: if a candidate contradicts an existing ADR, surface it only when the friction is strong enough to reopen the ADR. Mark it clearly (e.g. _"contradicts ADR-0007 — but worth reopening because…"_). Do not list every theoretical refactor an ADR forbids.

Do NOT propose interfaces yet. Ask the user: "Which of these would you like to explore?"

### 3. Grill the contentious ones

Candidates tagged **contentious** get a grilling conversation before you write any plan. Approved **clear-cut** candidates go directly to Phase 4. If the user is unavailable and a contentious question blocks a plan, adopt your own recommendation. Record it as a decision in the plan's Goal section. Do not silently downgrade the candidate to clear-cut.

In the grilling conversation, walk the design tree with the user: constraints, dependencies, the shape of the deepened module, what sits behind the seam, which tests survive. Apply the side effects inline as decisions crystallize:

- If you name a deepened module after a concept that is not in `CONTEXT.md`, add the term to `CONTEXT.md` — the same discipline as `/grill-with-docs` (see [CONTEXT-FORMAT.md](../grill-with-docs/CONTEXT-FORMAT.md)). Create the file lazily if it does not exist.
- If the conversation sharpens a fuzzy term, update `CONTEXT.md` immediately.
- If the user rejects the candidate with a load-bearing reason, offer an ADR: _"Want me to record this as an ADR so future architecture reviews do not re-suggest it?"_ Offer this only when a future explorer needs the reason. Skip ephemeral or self-evident reasons. See [ADR-FORMAT.md](../grill-with-docs/ADR-FORMAT.md).
- To explore alternative interfaces for the deepened module, see [INTERFACE-DESIGN.md](INTERFACE-DESIGN.md).

### 4. Rough plan (you — the last thing you write)

For each approved candidate, write `docs/rework/<slug>.md`. The doc has exactly five sections:

1. **Goal** — one paragraph: which modules deepen into what, in CONTEXT.md + LANGUAGE.md vocabulary, plus any decisions adopted on the user's behalf.
2. **Target interface** — the deepened module's interface as a real code block: signatures, types, error modes, invariants. This is a decision, so it is the one section that contains real code.
3. **Sketch** — pseudocode for the tricky parts only (concurrency, ordering, error handling, migration of state). Plain prose for everything else.
4. **Todos** — ordered checklist of mechanical steps with file paths: create X, move Y into it, delete Z, update the callers found at A/B/C, write tests T1/T2 against the new interface.
5. **Constraints** — behavior that must not change, tests that must stay green, wire/storage formats that are frozen, and the environment rules the implementer needs.

Commit the plan docs before you spawn any agent. Implementers follow the plan file, not the conversation history, and the file must survive this session.

### 5. Delegate implementation

Spawn one implementation agent per plan. Run agents in parallel only with disjoint file ownership, stated in each prompt. Delegate every approved candidate — also the small ones. A small candidate means a short plan and a single agent, not a reason to implement it inline.

Each prompt contains: the path to the committed plan marked **BINDING** (implement, do not redesign), the key-file list, the restated constraints section, and the full environment rules. Subagents inherit no CLAUDE.md, so restate the path conventions, the test command, the ASCII-output rules, and whether the agent commits its own scope.

Model: `opus` by default — it does the fine-grained planning inside its own context, then writes the code. Use `sonnet` when the todo list is purely mechanical. Always set the model explicitly.

### 6. Verify and deliver (you)

- Run the full test suite yourself. Never trust an agent's green claim.
- Diff-review the seams that were the point of the rework — the new interfaces and their call sites.
- Before you edit a file an agent touched, read it again.
- Merge per the project's git workflow. Ask the user to test before you update the CHANGELOG or other records.

## Red flags — stop and delegate

| Thought | Reality |
|---|---|
| "Too small to delegate — coordination overhead" | The plan doc IS the coordination. A small candidate = a short plan + a single agent. Your context is the scarce resource, not the agent's time. |
| "Nothing to parallelize here" | Delegation is not for parallelism. It keeps implementation tokens out of the orchestrator's context. |
| "The user is in a hurry — just do it" | Delegation is the fast path: agents implement while you plan the next candidate. |
| "The skill stops at design" | It does not. Phases 4–6 are the execution path. |
| You write compilable code in the Sketch, or you edit a source file yourself | That is Phase 5's job. Express it as a Todo instead. |
