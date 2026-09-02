# Engineering

Skills for daily code work.

- **[diagnose](./diagnose/SKILL.md)** — Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test.
- **[grill-with-docs](./grill-with-docs/SKILL.md)** — Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates `CONTEXT.md` and ADRs inline.
- **[triage](./triage/SKILL.md)** — Triage issues through a state machine of triage roles.
- **[improve-codebase-architecture](./improve-codebase-architecture/SKILL.md)** — Find deepening opportunities in a codebase, informed by the domain language in `CONTEXT.md` and the decisions in `docs/adr/`. Plans each rework as a committed rough plan, then delegates the implementation to agents.
- **[fable](./fable/SKILL.md)** — Tiered delegation workflow that reserves the top model for decisions. The main session designs and records binding decisions, opus subagents do fine planning, opus/sonnet subagents implement.
- **[code-review](./code-review/SKILL.md)** — Review the changes since a fixed point along two axes — repo standards and spec compliance — in parallel sub-agents.
- **[red-team](./red-team/SKILL.md)** — Take apart any target — an app, a feature, a plan, a decision — with parallel adversarial agents, then kill the weak findings in a blue-team rebuttal pass. Only the survivors reach the user.
- **[codebase-design](./codebase-design/SKILL.md)** — Shared vocabulary for designing deep modules: interfaces, seams, adapters, leverage, locality.
- **[domain-modeling](./domain-modeling/SKILL.md)** — Build and sharpen a project's domain model: terminology, ubiquitous language, architectural decisions.
- **[from-issues](./from-issues/SKILL.md)** — Execute triaged issues end-to-end via subagents: implement, review twice, open a PR, report back to the issue.
- **[implement](./implement/SKILL.md)** — Implement a piece of work based on a PRD or set of issues.
- **[merge-down](./merge-down/SKILL.md)** — Merge feature branches and worktrees down into one integration branch, resolve the usual conflicts, then clean up.
- **[research](./research/SKILL.md)** — Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo.
- **[setup-matt-pocock-skills](./setup-matt-pocock-skills/SKILL.md)** — Scaffold the per-repo config (issue tracker, triage label vocabulary, domain doc layout) that the other engineering skills consume.
- **[setup-foundry-claude](./setup-foundry-claude/SKILL.md)** — PowerShell wrapper running Claude Code against Azure AI Foundry: scopes provider env vars to a single run instead of the whole shell, pins the model aliases to current models, and adds a ccstatusline badge when an override endpoint is active.
- **[tdd](./tdd/SKILL.md)** — Test-driven development with a red-green-refactor loop. Builds features or fixes bugs one vertical slice at a time.
- **[to-issues](./to-issues/SKILL.md)** — Break any plan, spec, or PRD into independently-grabbable GitHub issues using vertical slices.
- **[to-prd](./to-prd/SKILL.md)** — Turn the current conversation context into a PRD and submit it as a GitHub issue.
- **[zoom-out](./zoom-out/SKILL.md)** — Tell the agent to zoom out and give broader context or a higher-level perspective on an unfamiliar section of code.
- **[prototype](./prototype/SKILL.md)** — Build a throwaway prototype to flush out a design — either a runnable terminal app for state/business-logic questions, or several radically different UI variations toggleable from one route.
- **[wizard](./wizard/SKILL.md)** — Generate an interactive bash wizard that walks a human through steps only they can perform: credentials, CI secrets, third-party dashboards, one-off migrations.
