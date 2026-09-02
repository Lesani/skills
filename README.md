# Skills for Autonomous Engineering

> Fork of [`mattpocock/skills`](https://github.com/mattpocock/skills). Diverging — see [Divergences](#divergences-from-upstream) below. The upstream README is preserved [at the bottom](#upstream-readme).

Agent skills for autonomous end-to-end engineering — grill, plan, delegate, ship.

These skills are small, easy to adapt, and composable. They work with any model. Hack around with them. Make them your own.

## Quickstart (30-second setup)

### Claude Code plugin (recommended)

```bash
claude plugin marketplace add Lesani/skills
claude plugin install autonomous-engineering@lesani-skills
```

Pull updates later with `claude plugin marketplace update lesani-skills` and
`claude plugin update autonomous-engineering` (restart Claude Code to apply).
`claude plugin details autonomous-engineering` shows the skill inventory and its
projected token cost. The plugin ships `engineering`, `productivity` and `misc`
— `personal`, `in-progress` and `deprecated` stay out.

### Any other agent (skills.sh installer)

1. Run the skills.sh installer:

```bash
npx skills@latest add Lesani/skills
```

(Or `mattpocock/skills` for the upstream original.)

2. Pick the skills you want, and which coding agents you want to install them on. **Make sure you select `/setup-matt-pocock-skills`**.

3. Run `/setup-matt-pocock-skills` in your agent. It will:
   - Ask you which issue tracker you want to use (GitHub, Linear, or local files)
   - Ask you what labels you apply to ticks when you triage them (`/triage` uses labels)
   - Ask you where you want to save any docs we create

4. Bam - you're ready to go.

### Working on the skills themselves

`scripts/link-skills.sh` symlinks every skill (including `in-progress`) into
`~/.claude/skills/`, so a `git pull` here updates them in place and edits made
while using a skill land straight back in this working copy. Use this instead of
the plugin if you intend to send changes back.

## Divergences from upstream

This fork is tuned for **fully-AFK autonomous execution** end-to-end — the whole `grill-me` → `to-prd` → `to-issues` → `from-issues` pipeline aims to produce issues an agent can ship without further human input.

- **`to-issues`** — HITL is gated by a strict allow-list (physical hardware, external approval, decisions the PRD explicitly deferred). "Architectural decision" and "design review" are not HITL reasons. They are PRD bugs. AFK self-test required per slice. Triage labels named explicitly (`ready-for-agent` / `ready-for-human`).
- **`to-prd`** — adds a structured "Decisions Deferred" section that maps 1:1 to HITL slices downstream. Reminder to walk the future slice list before finalizing.
- **`grill-me`** — explicit goal framing ("lock every decision an autonomous implementer would otherwise ask"), end-of-grill sweep for unresolved decisions.
- **`improve-codebase-architecture`** — reworked into a read-plan-delegate workflow. The orchestrating session reads the codebase itself and writes committed rough plans (target interface, pseudocode, todos). Delegated opus/sonnet agents implement from those plans.
- **New skills** — notably `fable` (tiered delegation: the top model decides, opus plans, opus/sonnet implements), `merge-down`, `setup-foundry-claude`, and the `sync-skills` / `update-skills-repo` pair that keeps `~/.claude/skills/` and this repo in sync.
- **Scripts** — `scripts/ste-lint.sh`, a mechanical Simplified-Technical-English checker for any markdown prose artifact.

## Reference

### Engineering

Skills for daily code work.

- **[diagnose](./skills/engineering/diagnose/SKILL.md)** — Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test.
- **[grill-with-docs](./skills/engineering/grill-with-docs/SKILL.md)** — Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates `CONTEXT.md` and ADRs inline.
- **[triage](./skills/engineering/triage/SKILL.md)** — Triage issues through a state machine of triage roles.
- **[improve-codebase-architecture](./skills/engineering/improve-codebase-architecture/SKILL.md)** — Find deepening opportunities in a codebase, informed by the domain language in `CONTEXT.md` and the decisions in `docs/adr/`. Plans each rework as a committed rough plan, then delegates the implementation to agents.
- **[fable](./skills/engineering/fable/SKILL.md)** — Tiered delegation workflow that reserves the top model for decisions. The main session designs and records binding decisions, opus subagents do fine planning, opus/sonnet subagents implement.
- **[code-review](./skills/engineering/code-review/SKILL.md)** — Review the changes since a fixed point along two axes — repo standards and spec compliance — in parallel sub-agents.
- **[codebase-design](./skills/engineering/codebase-design/SKILL.md)** — Shared vocabulary for designing deep modules: interfaces, seams, adapters, leverage, locality.
- **[domain-modeling](./skills/engineering/domain-modeling/SKILL.md)** — Build and sharpen a project's domain model: terminology, ubiquitous language, architectural decisions.
- **[from-issues](./skills/engineering/from-issues/SKILL.md)** — Execute triaged issues end-to-end via subagents: implement, review twice, open a PR, report back to the issue.
- **[implement](./skills/engineering/implement/SKILL.md)** — Implement a piece of work based on a PRD or set of issues.
- **[merge-down](./skills/engineering/merge-down/SKILL.md)** — Merge feature branches and worktrees down into one integration branch, resolve the usual conflicts, then clean up.
- **[research](./skills/engineering/research/SKILL.md)** — Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo.
- **[setup-matt-pocock-skills](./skills/engineering/setup-matt-pocock-skills/SKILL.md)** — Scaffold the per-repo config (issue tracker, triage label vocabulary, domain doc layout) that the other engineering skills consume. Run once per repo.
- **[setup-foundry-claude](./skills/engineering/setup-foundry-claude/SKILL.md)** — PowerShell wrapper that runs Claude Code against Azure AI Foundry without leaking provider config into the rest of the shell session.
- **[tdd](./skills/engineering/tdd/SKILL.md)** — Test-driven development with a red-green-refactor loop. Builds features or fixes bugs one vertical slice at a time.
- **[to-issues](./skills/engineering/to-issues/SKILL.md)** — Break any plan, spec, or PRD into independently-grabbable GitHub issues using vertical slices.
- **[to-prd](./skills/engineering/to-prd/SKILL.md)** — Turn the current conversation context into a PRD and submit it as a GitHub issue.
- **[zoom-out](./skills/engineering/zoom-out/SKILL.md)** — Tell the agent to zoom out and give broader context or a higher-level perspective on an unfamiliar section of code.
- **[prototype](./skills/engineering/prototype/SKILL.md)** — Build a throwaway prototype to flush out a design — either a runnable terminal app for state/business-logic questions, or several radically different UI variations toggleable from one route.
- **[wizard](./skills/engineering/wizard/SKILL.md)** — Generate an interactive bash wizard that walks a human through steps only they can perform: credentials, CI secrets, third-party dashboards, one-off migrations.
- **[red-team](./skills/engineering/red-team/SKILL.md)** — Take apart any target — an app, a feature, a plan, a decision — with parallel adversarial agents, then kill the weak findings in a blue-team rebuttal pass. Only the survivors reach the user.

### Productivity

General workflow tools, not code-specific.

- **[caveman](./skills/productivity/caveman/SKILL.md)** — Ultra-compressed communication mode. Cuts token usage ~75% by dropping filler while keeping full technical accuracy.
- **[grill-me](./skills/productivity/grill-me/SKILL.md)** — Get relentlessly interviewed about a plan or design until every branch of the decision tree is resolved.
- **[ste](./skills/productivity/ste/SKILL.md)** — Rewrite prose (docs, READMEs, PR text, error messages — never code) into ASD-STE100 Simplified Technical English to remove AI slop.
- **[write-a-skill](./skills/productivity/write-a-skill/SKILL.md)** — Create new skills with proper structure, progressive disclosure, and bundled resources.

### Misc

Rarely used, kept around.

- **[git-guardrails-claude-code](./skills/misc/git-guardrails-claude-code/SKILL.md)** — Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, etc.) before they execute.
- **[migrate-to-shoehorn](./skills/misc/migrate-to-shoehorn/SKILL.md)** — Migrate test files from `as` type assertions to @total-typescript/shoehorn.
- **[scaffold-exercises](./skills/misc/scaffold-exercises/SKILL.md)** — Create exercise directory structures with sections, problems, solutions, and explainers.
- **[setup-pre-commit](./skills/misc/setup-pre-commit/SKILL.md)** — Set up Husky pre-commit hooks with lint-staged, Prettier, type checking, and tests.

### Other categories

- **[personal](./skills/personal/README.md)** — skills tied to one machine's setup, not promoted in the plugin.
- **[in-progress](./skills/in-progress/README.md)** — rough drafts, excluded from the plugin until they graduate.
- **[deprecated](./skills/deprecated/README.md)** — no longer used, kept for reference.

## Scripts

- **`scripts/ste-lint.sh`** — mechanical STE checks (contractions, semicolons, British spellings, banned words, passive markers, sentence length) for any markdown prose artifact. Run it on explicit files. Judgment stays with the reader.
- **`scripts/link-skills.sh`**, **`scripts/list-skills.sh`** — local setup helpers that symlink and list the installed skills.

---

## Upstream README

Upstream by Matt Pocock — his newsletter, where most of the original thinking lives, is here:

[Sign Up To Matt's Newsletter](https://www.aihero.dev/s/skills-newsletter)

<p>
  <a href="https://www.aihero.dev/s/skills-newsletter">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://res.cloudinary.com/total-typescript/image/upload/v1777382277/skills-repo-dark_2x.png">
      <source media="(prefers-color-scheme: light)" srcset="https://res.cloudinary.com/total-typescript/image/upload/v1777382277/skill-repo-light_2x.png">
      <img alt="Skills" src="https://res.cloudinary.com/total-typescript/image/upload/v1777382277/skill-repo-light_2x.png" width="369">
    </picture>
  </a>
</p>

### Why These Skills Exist

I built these skills as a way to fix common failure modes I see with Claude Code, Codex, and other coding agents.

#### #1: The Agent Didn't Do What I Want

> "No-one knows exactly what they want"
>
> David Thomas & Andrew Hunt, [The Pragmatic Programmer](https://www.amazon.co.uk/Pragmatic-Programmer-Anniversary-Journey-Mastery/dp/B0833F1T3V)

**The Problem**. The most common failure mode in software development is misalignment. You think the dev knows what you want. Then you see what they've built - and you realize it didn't understand you at all.

This is just the same in the AI age. There is a communication gap between you and the agent. The fix for this is a **grilling session** - getting the agent to ask you detailed questions about what you're building.

**The Fix** is to use:

- [`/grill-me`](./skills/productivity/grill-me/SKILL.md) - for non-code uses
- [`/grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md) - same as [`/grill-me`](./skills/productivity/grill-me/SKILL.md), but adds more goodies (see below)

These are my most popular skills. They help you align with the agent before you get started, and think deeply about the change you're making. Use them _every_ time you want to make a change.

#### #2: The Agent Is Way Too Verbose

> With a ubiquitous language, conversations among developers and expressions of the code are all derived from the same domain model.
>
> Eric Evans, [Domain-Driven-Design](https://www.amazon.co.uk/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215)

**The Problem**: At the start of a project, devs and the people they're building the software for (the domain experts) are usually speaking different languages.

I felt the same tension with my agents. Agents are usually dropped into a project and asked to figure out the jargon as they go. So they use 20 words where 1 will do.

**The Fix** for this is a shared language. It's a document that helps agents decode the jargon used in the project.

<details>
<summary>
Example
</summary>

Here's an example [`CONTEXT.md`](https://github.com/mattpocock/course-video-manager/blob/076a5a7a182db0fe1e62971dd7a68bcadf010f1c/CONTEXT.md), from my `course-video-manager` repo. Which one is easier to read?

- **BEFORE**: "There's a problem when a lesson inside a section of a course is made 'real' (i.e. given a spot in the file system)"
- **AFTER**: "There's a problem with the materialization cascade"

This concision pays off session after session.

</details>

This is built into [`/grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md). It's a grilling session, but that helps you build a shared language with the AI, and document hard-to-explain decisions in ADR's.

It's hard to explain how powerful this is. It might be the single coolest technique in this repo. Try it, and see.

> [!TIP]
> A shared language has many other benefits than reducing verbosity:
>
> - **Variables, functions and files are named consistently**, using the shared language
> - As a result, the **codebase is easier to navigate** for the agent
> - The agent also **spends fewer tokens on thinking**, because it has access to a more concise language

#### #3: The Code Doesn't Work

> "Always take small, deliberate steps. The rate of feedback is your speed limit. Never take on a task that’s too big."
>
> David Thomas & Andrew Hunt, [The Pragmatic Programmer](https://www.amazon.co.uk/Pragmatic-Programmer-Anniversary-Journey-Mastery/dp/B0833F1T3V)

**The Problem**: Let's say that you and the agent are aligned on what to build. What happens when the agent _still_ produces crap?

It's time to look at your feedback loops. Without feedback on how the code it produces actually runs, the agent will be flying blind.

**The Fix**: You need the usual tranche of feedback loops: static types, browser access, and automated tests.

For automated tests, a red-green-refactor loop is critical. This is where the agent writes a failing test first, then fixes the test. This helps give the agent a consistent level of feedback that results in far better code.

I've built a **[`/tdd`](./skills/engineering/tdd/SKILL.md) skill** you can slot into any project. It encourages red-green-refactor and gives the agent plenty of guidance on what makes good and bad tests.

For debugging, I've also built a **[`/diagnose`](./skills/engineering/diagnose/SKILL.md)** skill that wraps best debugging practices into a simple loop.

#### #4: We Built A Ball Of Mud

> "Invest in the design of the system _every day_."
>
> Kent Beck, [Extreme Programming Explained](https://www.amazon.co.uk/Extreme-Programming-Explained-Embrace-Change/dp/0321278658)

> "The best modules are deep. They allow a lot of functionality to be accessed through a simple interface."
>
> John Ousterhout, [A Philosophy Of Software Design](https://www.amazon.co.uk/Philosophy-Software-Design-2nd/dp/173210221X)

**The Problem**: Most apps built with agents are complex and hard to change. Because agents can radically speed up coding, they also accelerate software entropy. Codebases get more complex at an unprecedented rate.

**The Fix** for this is a radical new approach to AI-powered development: caring about the design of the code.

This is built in to every layer of these skills:

- [`/to-prd`](./skills/engineering/to-prd/SKILL.md) quizzes you about which modules you're touching before creating a PRD
- [`/zoom-out`](./skills/engineering/zoom-out/SKILL.md) tells the agent to explain code in the context of the whole system

And crucially, [`/improve-codebase-architecture`](./skills/engineering/improve-codebase-architecture/SKILL.md) helps you rescue a codebase that has become a ball of mud. I recommend running it on your codebase once every few days.

### Summary

Software engineering fundamentals matter more than ever. These skills are my best effort at condensing these fundamentals into repeatable practices, to help you ship the best apps of your career. Enjoy.
