# Interactive section-by-section review of an implementation plan against the codebase

Detailed, interactive plan review. Walk through the plan section-by-section, validate against codebase, surface issues,
pause for user input between sections.

**The goal**: Make reviewing a complex implementation plan a delight, not a chore. The user gains confidence in the plan
while you shepherd them through — validating feasibility, catching gaps, and making what could be an overwhelming
document feel actionable and well-grounded. You drive; they cross-examine.

## Usage

- Review a specific plan file (provide the path, e.g. `docs/plans/myFeature.md`)
- Review the plan in the current file or most recent `docs/plans/` file (default)

---

## Setup

### Step 1: Determine Target and Pre-load

Locate and read the full plan document. Then **proactively explore the codebase** to validate the plan's assumptions:

```bash
# Read the plan file
cat $PLAN_PATH

# Read files the plan references
# Read files the plan proposes to modify
# Search for existing patterns the plan should follow
```

**Performance optimization**: Read the full plan AND all referenced/affected files upfront in parallel. This way, when
walking through sections later, everything is already in context — responses are instant, no re-reading between
sections.

### Step 2: Context

Proactively look for and read relevant context:

- Related existing implementations (similar features already built)
- Referenced files and directories
- Existing patterns in the codebase that the plan should follow
- Related documentation in `docs/`

Read silently for background — don't walk through context with the user or ask permission. Use it to validate claims
during review.

---

## Section Plan

**For large plans (>3 phases or significant scope)**: Group sections for review.

### Creating the Section Plan

Analyze the plan and group into coherent review sections based on:

- **Open Questions** - unresolved decisions that block implementation
- **Technical Approach** - core architecture and design decisions
- **Phase Breakdown** - each implementation phase
- **Integration Points** - how it connects to existing systems
- **Risk Areas** - parts that seem complex, underspecified, or risky

Present the plan:

```
## Plan: [title]

**Scope**: X phases, ~Y files affected

### Review Sections

| Section | Focus | Risk Level |
|---------|-------|------------|
| 1. Open Questions | Unresolved decisions, blocking items | High |
| 2. Technical Approach | Core architecture, patterns, tooling | Medium |
| 3. Phase 1: [name] | [scope] | [assessment] |
| 4. Phase 2: [name] | [scope] | [assessment] |
| 5. Integration & Dependencies | External systems, existing code | Medium |
| 6. Edge Cases & Error Handling | Failure modes, recovery | High |

**Review approach**: I'll review each section, present a findings report, then pause for discussion before moving to the next.

Ready to start with Section 1? (yes / reorder / adjust sections)
```

Wait for confirmation. User can request different groupings.

---

## Section-by-Section Review

For each section:

### 1. Section Overview

```
## Section N: [Section Name]

**Focus**: [what this section covers]

**Key Questions**: [what we're validating]
```

### 2. Walk Through Content

For each part of the section, validate against the codebase:

```
### [Topic]

**Plan States**:
- [claim or proposed change]

**Codebase Reality**:
- [what actually exists]
- [relevant patterns or constraints]

**Assessment**: ✅ Accurate / ⚠️ Needs adjustment / ❌ Incorrect
```

### 3. Section Findings Report

After reviewing the section, present a structured findings report:

```
### Section N Findings

| # | Severity | Issue | Location in Plan | Recommendation |
|---|----------|-------|------------------|----------------|
| 1 | Critical | Missing dependency on X | Phase 2, Step 3 | Add step to update X first |
| 2 | Medium | Underspecified error handling | Phase 1, Step 5 | Define retry strategy |
| 3 | Low | Could simplify using existing util | Phase 3 | Consider using `fooUtils.ts` |

**Questions for Discussion**:
1. [Question about unclear design decision]
2. [Question about scope or priority]

**Section Status**: [Summary assessment]

---

**Pause**: Let's discuss these findings before moving to Section N+1.
- Which items need revision?
- Any clarifications on the plan intent?
- Ready to continue? (revise now / discuss / next section)
```

**Always pause here.** User decides what to address before proceeding.

### 4. Revise (if requested)

If user requests revisions:

1. Propose specific plan text changes
2. Get confirmation
3. Apply changes
4. Ask: "Ready for Section N+1?"

---

## Small Plan Flow (Alternative)

**For small plans (<3 phases or straightforward changes)**: Use topic-by-topic review.

```
## Plan: [title]

**Scope**: [brief description]

| # | Topic | Focus |
|---|-------|-------|
| 1 | Problem Statement | Is it clear and accurate? |
| 2 | Proposed Solution | Is the approach sound? |
| 3 | Implementation Steps | Are they complete and ordered correctly? |
| 4 | Affected Files | Are all files identified? Any missing? |
| 5 | Edge Cases | Are failure modes handled? |

Ready for Topic 1? (yes / skip to [topic] / done)
```

---

## Plan-Specific Validation Checks

**Run these checks against every plan. Flag issues immediately.**

### Scope & Clarity

- ❌ **Vague requirements** — "handle errors appropriately" without specifics
- ❌ **Missing acceptance criteria** — how do we know when it's done?
- ❌ **Scope creep signals** — phrases like "and also" or "while we're at it"
- ❌ **Undefined terms** — jargon or concepts not explained
- ✅ **Clear task breakdown** — each step is actionable and specific

### Technical Accuracy

- ❌ **References to non-existent files** — verify all file paths exist
- ❌ **Incorrect existing patterns** — plan claims X works way Y, but it doesn't
- ❌ **Outdated assumptions** — references to deprecated or changed systems
- ❌ **Missing dependencies** — changes require other changes not mentioned
- ✅ **Aligned with codebase patterns** — follows existing conventions

### Completeness

- ❌ **Missing phases** — clear gaps in the implementation sequence
- ❌ **Orphaned changes** — edits that require corresponding updates elsewhere
- ❌ **No error handling** — happy path only, no failure modes
- ❌ **No testing strategy** — how will we verify this works?
- ❌ **Missing GraphQL dual-file updates** — server schema without client operations
- ❌ **No documentation plan** — changes that affect documented areas without noting which docs to update (use the
  [documentation-update skill](../documentation-update/SKILL.md) decision matrix to identify affected doc types)
- ✅ **End-to-end coverage** — from data model to UI (where applicable)

### Feasibility & Risk

- ❌ **Underestimated complexity** — "just update X" for complex changes
- ❌ **Hidden prerequisites** — requires groundwork not mentioned
- ❌ **Risky ordering** — dependencies not properly sequenced
- ❌ **No rollback consideration** — what if we need to revert?
- ✅ **Incremental milestones** — can test/verify at intermediate points

### Kestral-Specific Checks

- ❌ **Missing workspace isolation** — multi-tenant data access not considered
- ❌ **`user_id` in workspace-scoped table** — new tables should use `actor_id` (per-workspace identity), not `user_id`
  (cross-workspace auth). Only inherently cross-workspace tables (e.g., `actor` itself, `desktop_device`) should
  reference `user_id`
- ❌ **Missing migration** — data model changes without migration plan
- ❌ **In-memory state for distributed systems** — won't work with multiple Cloud Run instances
- ❌ **Missing codegen step** — GraphQL changes without `pnpm run generate`
- ❌ **Raw SQL outside queries files** — Kysely pattern not followed
- ✅ **Proper transaction handling** — multi-step DB changes use transactions

---

## Topic-by-Topic Review (for small plans or within sections)

For each topic:

### 1. Show the Content

Display the relevant plan excerpt:

```
### The Plan States (Lines N-M)

[show the relevant section]

**Claim**: [summarize what the plan asserts or proposes]
```

### 2. Validate Against Codebase

```
**Codebase Check**:

[Show relevant code that confirms or contradicts the plan]

**Assessment**:
- ✅ Accurate: [explanation]
- ⚠️ Partially correct: [what's right, what's wrong]
- ❌ Incorrect: [what the codebase actually shows]
```

### 3. Example Scenario (when helpful)

For complex logic, walk through a concrete case:

```
**Scenario**: User creates a task with @-mention

Plan says:
1. Create task
2. Parse mentions
3. Notify mentioned users

But existing pattern shows:
1. Parse mentions FIRST (validation)
2. Create task
3. Notify asynchronously via job queue

**Issue**: Plan has ordering backwards and misses async pattern
```

### 4. Topic Summary

```
### Summary for [Topic]

| Aspect | Assessment |
|--------|------------|
| Accuracy | ✅ / ⚠️ [concern] |
| Completeness | ✅ / ⚠️ [missing X] |
| Feasibility | ✅ / ⚠️ [risk] |
| Alignment | ✅ / ⚠️ [pattern mismatch] |

Ready for the next topic? (yes / questions? / done)
```

**Always pause here.** User can ask questions, go back, or continue.

---

## Critical Review Mindset

Don't just summarize — actively look for problems. After walking through each section, pause and ask yourself:

### Scope & Dependencies

- **Hidden dependencies**: What else needs to change that isn't mentioned?
- **Order matters**: Are phases sequenced correctly? Could earlier phases block later ones?
- **Integration points**: Where does this touch other systems? Are those interfaces correct?

### Feasibility & Complexity

- **Underestimated work**: Does "update X" actually require significant changes?
- **Missing groundwork**: Are there prerequisites that should be their own phases?
- **Testability**: Can each phase be verified independently?

### Edge Cases & Failure Modes

- **What if it fails?**: Is error handling specified? Recovery paths?
- **Partial completion**: If phase 3 of 5 fails, what state are we in?
- **Concurrency**: What if two users trigger this simultaneously?

### Missing Pieces

- **What's NOT in the plan**: Are there obvious steps that should be there?
- **Silent assumptions**: What does the plan assume without stating?
- **Migration/rollback**: How do we handle existing data? Can we revert?

### Design Questions

- **Is this the right approach?**: Even if detailed, is there a simpler design?
- **Over-engineering**: Is the plan more complex than necessary?
- **Under-engineering**: Is the plan too simple for the actual requirements?

### Codebase-Specific Concerns

- **Pattern alignment**: Does this follow existing conventions or introduce new ones?
- **Workspace isolation**: Multi-tenant considerations addressed?
- **Generated types**: GraphQL codegen workflow included?
- **Testing strategy**: How will this be tested?

**Surface issues as you go** — don't save them all for the end. When you spot something:

```
⚠️ **Potential gap**: [description]

**Why this matters**: [concrete impact if not addressed]

**Suggested addition**: [if you have one]
```

This transforms the review from "summarizing what the plan says" to "ensuring the plan will actually work."

---

## Interview Phase

After completing section reviews, conduct a targeted interview:

```
## Interview: Clarifying Questions

Based on my review, I have questions about intent, tradeoffs, and priorities.
For each question, I'll provide my recommended answer with reasoning.

---

**Question 1**: [Technical or design question]

**My Recommendation**: [Your suggested answer]
**Reasoning**: [Why this makes sense based on codebase patterns]

Your answer? (agree / disagree / discuss)
```

Continue with 3-7 focused questions covering:

- **Ambiguous design decisions** the plan doesn't address
- **Tradeoffs** between approaches mentioned or implied
- **Priorities** when scope might need trimming
- **Edge cases** not explicitly handled
- **Testing strategy** if not specified

**Keep questions non-obvious** — don't ask things clearly answered in the plan.

---

## Final Summary

After all sections and interview complete:

```
## Review Complete

### Section Summary

| Section | Status | Issues Found | Key Revisions |
|---------|--------|--------------|---------------|
| 1. Open Questions | ✅ Resolved | 2 (addressed) | Decided on X |
| 2. Technical Approach | ✅ Valid | 1 (minor) | Aligned with Y pattern |
| 3. Phase 1 | ⚠️ Needs work | 3 (1 critical) | Added error handling |
| ... | ... | ... | ... |

### Plan Quality Checklist

| Check | Status |
|-------|--------|
| Clear problem statement | ✅ / ❌ |
| Actionable steps | ✅ / ❌ |
| All affected files identified | ✅ / ❌ |
| Error handling specified | ✅ / ❌ |
| Testing strategy included | ✅ / ❌ |
| Follows codebase patterns | ✅ / ❌ |
| GraphQL dual-file considered | ✅ / ❌ / N/A |
| Resolver error handling follows global wrapper/config pattern (if plan touches resolvers) | ✅ / ❌ / N/A |
| Migration plan (if needed) | ✅ / ❌ / N/A |
| Multi-instance safe | ✅ / ❌ / N/A |
| Documentation updates identified | ✅ / ❌ / N/A |

**Overall Assessment**: [1-2 sentences]

### Recommended Next Steps

1. [First priority action]
2. [Second priority action]
3. Ready to implement: Yes / After revisions
```

---

## Guidelines

- **Validate, don't just summarize** — your job is to catch gaps, not narrate
- **Be critical but constructive** — identify problems AND suggest solutions
- **Check the codebase** — don't trust claims without verification
- **Pause after each section** — never proceed without user confirmation
- **Revise before continuing** — address issues before moving on
- **Use concrete examples** — show exactly where the plan is right/wrong
- **Think holistically** — how does this plan interact with the system?
- **Ask good questions** — surface implicit assumptions
- **Be direct** — if the plan is incomplete, say so clearly
