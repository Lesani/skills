# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec-compliance reviewer subagent for an issue-tracker-resident task.

**Purpose:** Verify the implementer built what the issue requested — every acceptance criterion, nothing extra.

Adapted from `superpowers:subagent-driven-development/spec-reviewer-prompt.md`.

```
Agent tool (general-purpose):
  description: "Review spec compliance for issue #N"
  prompt: |
    You are reviewing whether an implementation matches the issue's specification.

    ## What was requested

    Issue #N: [issue title]

    ### Issue body (verbatim)

    [PASTE the full issue body here]

    ### Acceptance criteria

    - [ ] Criterion 1
    - [ ] Criterion 2
    - [ ] Criterion 3
    ...

    These checkboxes ARE the contract. Each must be demonstrably satisfied.

    ## What the implementer claims they built

    [PASTE the implementer's full report here, including their acceptance-criteria-coverage map]

    ## Branch and commits

    - Branch: feat/issue-<N>-<slug>
    - Base SHA: [commit before this issue's work]
    - Head SHA: [latest commit on the branch]
    - Working directory: [absolute path]

    ## CRITICAL: Do not trust the report

    The implementer's report may be incomplete, inaccurate, or optimistic. You MUST verify
    everything independently by reading the code on the branch.

    **Do NOT:**
    - Take their word for what they implemented.
    - Trust their claims about completeness.
    - Accept their interpretation of acceptance criteria.

    **DO:**
    - Read the actual code on the branch (diff against base SHA).
    - Compare actual implementation to each acceptance criterion line by line.
    - Check for missing pieces they claimed to implement.
    - Look for extra features they didn't mention.
    - Run the tests yourself if possible; verify they actually exercise behavior.

    ## Your job

    Read the implementation code and verify:

    **Acceptance criteria coverage:**
    - For each `- [ ]` in the issue, find the code/test that satisfies it. Cite file:line.
    - If a criterion is not demonstrably met, mark it as missing.
    - Do not accept "the report says it's done" without finding it in the code.

    **Missing requirements:**
    - Did they implement everything that was requested?
    - Are there acceptance criteria they skipped or partially handled?
    - Did they claim something works but didn't actually wire it up?

    **Extra / unneeded work:**
    - Did they build things outside the issue's scope?
    - Did they over-engineer or add nice-to-haves not in the criteria?
    - Did they add flags, options, or future-proofing not requested?

    **Misunderstandings:**
    - Did they interpret a criterion differently than intended? Flag the divergence.
    - Did they solve the wrong problem? Did they implement the right behavior the wrong way?

    **Tests:**
    - Do tests actually exercise the behavior described in the criteria?
    - Are they mocking the thing they're supposed to verify?

    Verify by reading code, not by trusting the report.

    ## Report

    Return one of:

    - **✅ Spec compliant** — every acceptance criterion satisfied, nothing extra. Cite the
      file:line for each criterion's evidence.

    - **❌ Issues found** — list specifically:
      - Missing: which criteria are not met, and what's needed.
      - Extra: which features were added beyond scope, and where.
      - Misinterpreted: which criteria were handled the wrong way, with the divergence explained.
      - Each item with file:line references where applicable.

    The implementer (same subagent) will fix issues, then you'll review again. Don't accept
    "close enough" — partial fixes get re-reviewed.
```
