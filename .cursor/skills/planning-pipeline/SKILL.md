---
name: planning-pipeline
description: >-
  Planning pipeline: write-plan, then hand off to review-plan-pipeline for the full review pass
  (plan-review, product-review). Spike mode skips the review pass and ends with decision capture.
  Only invoked by the kstack subagent.
disable-model-invocation: true
---

# Planning Pipeline

You are producing an implementation plan and reviewing it to production-ready quality. Do not implement code.

**Mode selection:** If the request is a timeboxed question to de-risk ("Spike X", "figure out whether Y works") rather
than a feature to scope, run in **spike mode**. Otherwise run in **full mode** (default).

**Start by creating a todolist** — full mode: Phase 1 (write plan), Phase 2 (review plan), Phase 3 (sync). Spike mode:
Phase 1 (write spike plan), Phase 2 (sync + handoff). Mark Phase 1 in_progress after reading the write-plan skill.

## Phase 1: Write the plan

Read `.cursor/skills/write-plan/SKILL.md` in full and follow its workflow, using the matching plan mode (full,
spike, or project). Author the plan under `docs/plans/`. Stay within the planning directory — do not implement anything.

Pause after the plan is written and present a summary to the user. Wait for approval before proceeding.

## Phase 2: Review pass (full mode only)

Read `.cursor/skills/review-plan-pipeline/SKILL.md` in full and follow its workflow.

**Spike mode skips this phase** — a timeboxed question doesn't need a product review pass.

## Phase 3: Task tracker sync

Sync the plan to the task tracker (see context.md for project-specific sync instructions):

- If the plan references an existing task, update its status and post a progress comment
- If no task exists yet, the write-plan skill already offers to create one — this phase is a catchall
- **Spike mode:** create a new task from the prototype context if none exists

Skip if no task is linked and the user doesn't specify one.

## Spike tail (spike mode only)

The pipeline ends after Phase 3 — the engineer runs the investigation. Tell the user the closing steps so they aren't
lost:

1. Investigate within the timebox (read code, check constraints — if it turns into real building, that's prototyping)
2. When concluded, invoke `.cursor/skills/decision-capture/SKILL.md` to record the outcome
3. On proceed, `.cursor/skills/handoff-to-implementation/SKILL.md` creates the follow-up task

## Final Output

After all phases, present a final summary:

- Plan location (file path)
- Key requirements validation findings (full mode)
- Review issues raised and resolutions (full mode)
- Product completeness assessment (full mode)
- Kestral task synced (or skipped)
- Recommended next step — full mode: hand off to kstack with an implement request; spike mode: the spike tail steps
  above (investigate → decision-capture → handoff)

## Rules

- Follow the project's coding rules in `.cursor/rules/` (read `engineering-principles.mdc` and `meta-workflow.mdc`).
- Use the AskQuestion tool to resolve ambiguity rather than guessing.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
