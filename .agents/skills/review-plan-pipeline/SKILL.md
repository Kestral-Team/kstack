---
name: review-plan-pipeline
description: >-
  Fixed four-step plan review pipeline: plan-review (requirements validation mode), plan-review
  (interactive mode), product-review, review summary to Kestral. Orchestrates the full review pass
  for an implementation plan. Only invoked by the kstack subagent.
disable-model-invocation: true
---

# Review Plan Pipeline

You are reviewing an existing implementation plan to production-ready quality. Execute four steps in strict sequence. Do
not implement code — only review, validate, and surface issues for the plan.

**Start by creating a todolist with one item per step below.** Each item's first sub-action is reading that step's
SKILL.md via the Read tool. Mark an item in_progress only after the Read tool call succeeds.

## Step 1: Validate requirements

Read `.agents/skills/plan-review/SKILL.md` in full. Use **Mode 2: Requirements Validation**. Treat the plan as
the requirements document. Extract atomic requirements, verify each against the codebase, and classify as implemented /
partial / missing / unclear / needs manual verification.

Present the validation report to the user. Flag any high-risk gaps.

## Step 2: Review the plan

Read `.agents/skills/plan-review/SKILL.md` — use **Mode 1: Interactive Plan Review** (which references
`review-process.md`). Perform an interactive, section-by-section review of the plan against the codebase. Surface issues
and pause for user input between sections.

## Step 3: Product review

Read `.agents/skills/product-review/SKILL.md` in full (including its `review-process.md` reference) and follow
its workflow. Review the plan for surface area completeness — ensure every place the feature appears in the product is
accounted for, multi-user collaboration scenarios are considered, and AI agent interaction points are covered.

## Step 4: Review summary to task tracker

If a task is linked to the plan (task ID in frontmatter, or lookup finds one), post a **Review Summary** (see context.md
for project-specific sync method). Scope: the plan file reviewed; findings: validation gaps + review issues; verdict:
ready to implement or needs revision. Skip only if no task is linked.

## Final Output

After all steps, present a final summary:

- Key requirements validation findings
- Review issues raised and resolutions
- Product completeness assessment
- Review summary posted (or skipped)
- Recommended next step (hand off to implementation)

## Rules

- Follow the project's coding rules in `.cursor/rules/` (read `engineering-principles.mdc` and `meta-workflow.mdc`).
- Use the AskQuestion tool to resolve ambiguity rather than guessing.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
