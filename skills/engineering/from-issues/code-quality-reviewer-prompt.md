# Code Quality Reviewer Prompt Template

Use this template when dispatching a code-quality reviewer subagent for an issue-tracker-resident task.

**Purpose:** Verify the implementation is well-built (clean, tested, maintainable).

**Only dispatch after spec compliance review passes (✅).** Wrong order = wasted cycles.

Adapted from `superpowers:subagent-driven-development/code-quality-reviewer-prompt.md` and `superpowers:requesting-code-review`.

```
Agent tool (general-purpose):
  description: "Review code quality for issue #N"
  prompt: |
    You are reviewing the code quality of work landed for issue #N: [issue title].

    Spec compliance has already been verified separately. Your job is the quality of the
    code itself, independent of "did they build the right thing."

    ## Issue context

    Issue #N body summary (one paragraph): [paste the "What to build" section, plus any
    "Code organization" notes from the parent PRD that apply]

    ## Branch and commits

    - Branch: feat/<feature-slug> (shared feature branch)
    - Base SHA: [commit before this slice's work]
    - Head SHA: [latest commit on the branch from this slice's implementer]
    - Working directory: [absolute path — same worktree the implementer used; do NOT spin up your own]

    Diff to review:
        git diff <base-sha>..<head-sha>

    ## Review areas

    Apply the standard code-review template (`superpowers:requesting-code-review/code-reviewer.md`
    if available) plus the following emphases for issue-driven work:

    **Module decomposition:**
    - Does each new or modified file have one clear responsibility with a well-defined interface?
    - Are units decomposed so they can be understood and tested independently?
    - Did the implementation follow the file structure implied by the parent PRD's
      "Implementation Decisions" / module list?

    **File size and shape:**
    - Did this implementation create new files that are already large?
    - Did it significantly grow existing files? (Don't flag pre-existing file sizes — focus
      on what THIS change contributed.)
    - Are there opportunities to extract a deeper module that was missed?

    **Naming:**
    - Do names describe what things do, not how they work?
    - Are there leaking implementation details in public names?

    **Tests:**
    - Are tests targeting external behavior, not implementation internals?
    - Are mocks used only at genuine system boundaries?
    - Are the deep modules called out in the parent PRD's "Testing Decisions" actually tested?

    **Idiom and patterns:**
    - Does the new code follow established patterns in the surrounding codebase?
    - Did the change introduce a new pattern that conflicts with existing ones?

    **Error handling:**
    - Errors raised at meaningful boundaries, not swallowed?
    - No try/except that hides bugs?

    **Performance and resource use:**
    - Anything obviously O(N²) where O(N) was straightforward?
    - Resource leaks (event listeners, intervals, file handles)?

    **Security and safety:**
    - Standard checks (injection, XSS, path traversal, unsafe HTML where relevant).

    ## Report format

    Return:

    - **Strengths:** what was done well. Be specific.
    - **Issues:** grouped by severity:
      - **Critical:** must fix before merge. Bugs, regressions, security issues.
      - **Important:** should fix before merge. Quality issues that will rot if shipped.
      - **Minor:** nice to fix. Style, micro-optimizations, naming nits.
    - **Assessment:** ✅ Approved / ❌ Changes required.

    Cite file:line for every issue. The implementer (same subagent) fixes Critical and
    Important issues, then you review again. Don't accept "close enough" on Critical or
    Important — partial fixes get re-reviewed. Minor issues can be deferred at the user's
    discretion.
```
