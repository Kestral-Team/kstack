---
name: planning-pipeline
description: >-
  Fixed four-step planning pipeline: write-plan, requirements-validation, plan-review, product-review.
  Orchestrates the full planning pass for a feature.
disable-model-invocation: true
---

# Planning Pipeline

You are producing an implementation plan. Execute four steps in strict sequence. After each skill completes, move to the
next — do not skip steps. Do not implement code.

**Start by creating a todolist with one item per step below.** Each item's first sub-action is reading that step's
SKILL.md via the Read tool. Mark an item in_progress only after the Read tool call succeeds.

## Step 1: Write the plan

Read `.cursor/skills/write-plan/SKILL.md` in full and follow its workflow. Author a structured implementation plan under
`docs/plans/`. Stay within the planning directory — do not implement anything.

Pause after the plan is written and present a summary to the user. Wait for approval before proceeding.

## Step 2: Validate requirements

Read `.cursor/skills/requirements-validation/SKILL.md` in full and follow its workflow. Treat the plan you just wrote as
the requirements document. Extract atomic requirements, verify each against the codebase, and classify as implemented /
partial / missing / unclear / needs manual verification.

Present the validation report to the user. Flag any high-risk gaps.

## Step 3: Review the plan

Read `.cursor/skills/plan-review/SKILL.md` in full (including its `review-process.md` reference) and follow its workflow.
Perform an interactive, section-by-section review of the plan against the codebase. Surface issues and pause for user
input between sections.

## Step 4: Product review

Read `.cursor/skills/product-review/SKILL.md` in full (including its `review-process.md` reference) and follow its
workflow. Review the plan for surface area completeness — ensure every place the feature appears in the product is
accounted for, multi-user collaboration scenarios are considered, and AI agent interaction points are covered.

## Final Output

After all four steps, present a final summary:

- Plan location (file path)
- Key requirements validation findings
- Review issues raised and resolutions
- Product completeness assessment
- Recommended next step (hand off to kstack with an implement request)

## Rules

- Follow your project's coding rules.
- Use the AskQuestion tool to resolve ambiguity rather than guessing.
