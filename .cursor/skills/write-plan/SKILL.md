---
name: write-plan
description: >-
  Author structured implementation plan documents. Use when the user asks to write a plan, create
  an implementation plan, design a feature spec, or says /plan.
---

# Implementation Planning

Write an implementation plan document under your project's plans directory (e.g., `docs/plans/`).

## Plan Structure

Mirror this structure in the plan: metadata slab (status, owner, created, last updated, implementation status),
executive summary, open questions, goals/non-goals, architecture/flow, numbered phases with adjacent checklists,
dependencies/risks, validation metrics, and rollout checklist. Keep the prose factual and directive — no fluff sections.

- Describe the work to be done and why it matters.
- Spell out which files/directories change and how.
- Break delivery into sequential phases (`Phase N – Title`) each with a checklist covering tasks, file scopes, testing
  expectations, and tooling gates.
- Surface dependencies, migrations, feature flags, and required pauses (e.g., codegen steps).
- Define success metrics and post-change validation steps.

## Disambiguation

Make liberal use of the AskQuestion tool to resolve ambiguity and confirm assumptions before planning.

**CRITICAL**: Stay within the planning directory. Do **not** implement the plan or modify other files.
