---
name: plan-review
description: >-
  Interactive plan review and requirements validation against the codebase. Use when the user asks
  for a plan review, wants to validate an implementation plan, or provides a requirements doc, spec,
  PRD, acceptance criteria, or gap analysis to verify against the codebase.
---

# Plan Review

Two modes, same goal: verify that a plan or spec is grounded in codebase reality.

When the plan touches auth/permissions, redirects, file uploads, server-side fetches of user-provided URLs, or rendering
of user/integration-derived content, apply the Security section of
[code-review/checks.md](../../review/code-review/checks.md) to the proposed design.

## Mode 1: Interactive Plan Review

Interactive, section-by-section review of an implementation plan. Validate against the codebase, surface issues, and
pause for user input between sections.

Read [review-process.md](review-process.md) for the full review workflow including setup, validation approach,
section-by-section format, and final summary template.

## Mode 2: Requirements Validation

Turn a requirements document into a concrete verification pass against the actual product. Use when the user provides a
requirements doc, spec, PRD, acceptance criteria, or gap analysis.

Do not trust checklists, plan statuses, or requirement wording at face value. Verify the codebase first, then use
runtime validation only where static evidence is not enough.

### Step 1: Intake the Document

1. Read the full requirements doc.
2. Extract **atomic requirements**:
   - Split combined bullets into separate checks when they describe distinct behaviors.
   - Preserve the author's wording where possible.
   - Note ambiguous language and assumptions.
3. If scope is unclear, ask before validating:
   - target environment or branch
   - feature flag / tenant / seed-data assumptions
   - whether browser verification is expected now or only if needed

### Step 2: Build the Verification Checklist

For each requirement, create one checklist item with: requirement text, expected surface area (`client` / `server` /
`db` / `jobs` / `docs` / `runtime`), and verification method (`codebase`, `runtime`, or both).

Prefer many small checklist items over a few broad ones.

### Step 3: Verify in the Codebase First

For each checklist item:

1. Search for likely entry points:
   - routes, GraphQL operations, components, hooks, jobs, feature flags, schema changes, copy strings, tests
2. Read the relevant files and confirm the **substance** of the requirement — not just that a file, symbol, or test
   mentions it.
3. Capture concrete evidence:
   - file paths
   - key symbols
   - short explanation of why the code does or does not satisfy the requirement

If the requirement spans multiple layers, verify each required layer.

### Step 4: Classify Conservatively

Use exactly one status per requirement:

- `implemented`: The requirement is satisfied end-to-end based on strong evidence.
- `partial`: Some meaningful implementation exists, but scope, edge cases, or a required layer is missing.
- `missing`: No meaningful implementation was found.
- `unclear`: Evidence conflicts, or the requirement is too ambiguous to score confidently.
- `needs manual verification`: The code strongly suggests support, but runtime behavior still needs to be confirmed.

Rules:

- Prefer `partial` over `implemented` when an important detail is missing.
- Prefer `needs manual verification` over `implemented` when the requirement is primarily visual, interaction-based,
  auth-dependent, or environment-dependent.
- Prefer `unclear` over guessing.

### Step 5: Use Browser Verification Only When Needed

Open a browser session only when:

- code inspection cannot prove the behavior
- the requirement is inherently runtime or visual
- the user explicitly wants manual verification

When using the browser: verify only unresolved items, follow the smallest realistic user flow, record observations. Stop
and report if blocked by login, permissions, missing data, feature flags, or required manual setup. If several attempts
fail without new evidence, report the blocker and most likely next step.

### Step 6: Produce the Report

```markdown
# Requirements Validation

## Checklist

- [implemented] Requirement text
  - Evidence: `path/to/file` - short reason this satisfies the requirement
  - Notes: optional caveat

- [partial] Requirement text
  - Evidence: `path/to/file` - what exists today
  - Gap: what is still missing

- [missing] Requirement text
  - Evidence: No relevant implementation found in the inspected areas

- [needs manual verification] Requirement text
  - Code evidence: `path/to/file` - why runtime behavior seems likely
  - Runtime check needed: exact behavior still to confirm

## Open Questions

- Assumption or ambiguity that affects confidence

## Highest-Risk Gaps

- Short bullet list of the most important missing or partial requirements
```

### Evidence Standards

- Do not mark a requirement `implemented` based only on naming matches, comments, or TODOs.
- Tests are supporting evidence, not primary proof of production behavior.
- Documentation is supporting evidence, not proof.
- If the requirement claims an end-to-end workflow, verify the full path, not one layer in isolation.
- If the doc includes stretch goals or future work, separate them from committed requirements before scoring.

### Generalization Rules

- Treat any format (markdown, docs, issues, pasted bullets) as input — adapt checklist granularity but keep output
  requirement-by-requirement.
- If the doc mixes requirements with design ideas, validate only normative requirements unless the user asks for broader
  product feedback.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
