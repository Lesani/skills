---
name: fable-hybrid
description: Fable with a second model family - the Claude main session designs, Claude subagents plan and implement, GPT Sol reviews every plan and every slice diff and writes the user-facing text. Use when the user invokes /fable-hybrid or asks for Claude implementation with Sol review.
---

# Fable-hybrid

Claude designs, plans and implements, as in `fable`. GPT Sol (`gpt-6.1-sol`,
or the latest Sol) does two things:

- **Review.** Sol reviews each fine plan before implementation and each
  slice diff before the next slice starts. A reviewer from another model
  family catches different mistakes.
- **Language.** Sol writes all user-facing text: UI strings in every
  locale, notices, release notes and website copy. Claude wires it in.

## Calling Sol

Use the `sol` wrapper (`~/.local/bin/sol`, source `vamoto-meta/unraid/sol`).
It runs pi once, without a session, and prints Sol's answer:

    sol -C <repo> -o <scratchpad>/sol-<topic>.md <brief.md>

- Read-only tools by default. Use `-w` only when Sol must write a file
  itself (rare; prefer taking its text from stdout).
- Run it from Bash with `run_in_background` for anything longer than a
  quick question. A review takes minutes, not seconds.
- The wrapper prints GPT usage before and after on stderr. Note it in your
  report when a run is expensive.
- Run one Sol call at a time. Two parallel pi runs hung once (no tool call
  in 30 min). Progress streams to `<out>.log`, one line per tool call; an
  empty log after a few minutes means a stuck run, not a slow one.
- Keep a brief focused: one area, "about 40 tool calls at most", a word
  limit on the report. A whole-plan review in one call timed out at 25 min;
  split by area, each finished in about 3 min.

Sol cannot ask you questions during a run. Write a complete brief:

1. **Goal**, in one sentence.
2. **Binding inputs**: the design and plan paths, marked BINDING.
3. **What to read**: the diff command (`git -C <repo> diff <base>...<branch>`)
   or the key files.
4. **What to check**: the acceptance criteria and the risks you care about.
5. **Output format**: findings ranked by severity, each with `file:line`, the
   concrete failure scenario, and a suggested fix. Say "no findings" if
   there are none. For copy: the strings as a table (key, en, de, ...).
6. **Limits**: do not edit files, do not run builds or long tests, do not
   redesign. Raise a contradiction with the design as a finding.

## Phase 1 — Design (you, the main session)

As in `fable`: read enough code to decide, resolve ambiguities with the
user, record decisions (CONTEXT.md, ADRs), write the rough design. Cut the
work into **feature slices**: 2–6 slices, each one testable by itself, with
disjoint file ownership. Commit the design before you spawn agents.

## Phase 2 — Fine planning (Claude Plan agents)

As in `fable`: one `opus` Plan agent per slice, with the binding design,
the key files, and this deliverable: ordered steps, file-by-file changes,
an exact test list, the device or simulator check, risks.

## Phase 3 — Plan review (you, then Sol)

1. Read the plan yourself and fix the obvious problems.
2. Send the plan and the design to Sol for review. Ask specifically for
   wrong assumptions about the code, missing cases, steps that contradict
   the design, and tests that would not catch the failure they target.
3. Triage every Sol finding. Accept it, or reject it with a one-line reason.
   Record accepted fixes as `BINDING AMENDMENT` notes in the plan file.
   Sol's review is evidence, not authority: you decide. A disagreement that
   is really a product question goes to the user.

## Phase 4 — Build and test each slice (Claude implementers)

As in `fable`, with an explicit model per agent (`opus` for engine,
concurrency and cross-cutting work; `sonnet` for well-specified UI and
mechanical work). The implementer writes the code and its tests, runs the
focused tests for what it touched, runs the simulator check when the slice
changes UI or device behaviour, and reports the commands with their output.
A report without test output is not finished.

For a slice with user-facing text, get the text from Sol **before** the
implementer starts: describe the screen, the situation, the tone and any
length limit, and ask for every locale. Put Sol's table in the plan file.

## Phase 5 — Review the slice (you, then Sol), immediately

When a slice reports, before the next one starts:

1. Rerun its focused tests yourself. Read the diff on the critical paths.
2. Send the whole slice diff to Sol for review (one reviewer, the whole
   diff, never numbered part files).
3. Triage the findings as in Phase 3. Send the same implementer back with
   the accepted findings, while its context is warm. Retest.

## Phase 6 — Integrate and verify (you)

Run the full suite and the integrated device or simulator checks on the
merged result. This confirms that the slices work together. It should find
little, because each slice was tested and reviewed. Merge and push per the
project's workflow. Ask the user to test.

## Rules of thumb

- Sol reviews; it does not implement. Do not hand it a slice to build.
- One Sol call per plan, per slice diff, per copy batch. No review loops on
  unchanged code: after fixes, re-review only when the fix was substantial.
- If a Sol run fails (timeout, exit code, empty output), rerun it once with
  the same brief. If it fails again, report it and continue with your own
  review. Do not silently skip the review.
- Cost order: your tokens > opus > Sol review > sonnet.
