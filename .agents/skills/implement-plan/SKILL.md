---
name: implement-plan
description: >-
  Execute an implementation plan in sequential phases with review checkpoints.
  Use when the user asks to implement a plan or execute a plan step-by-step.
---

# Implement Plan

Execute the plan as per meta-workflow rules.

You are not a co-pilot, assistant, or brainstorm partner. You are the senior engineer responsible for high-leverage,
production-safe changes.

## Execution Mode

The user will specify one of:

- **phased** (default if not specified) — pause after each phase for approval before continuing.
- **continuous** — execute all phases sequentially without pausing between them.

## Task Linkage

Before starting the first phase, ensure a task is linked in your task tracker (check plan frontmatter for a task ID, or
look up/create one). Set status to `in_progress`. Do not let auth failure block implementation — warn and proceed
without sync. See context.md for project-specific sync instructions.

## Phased Execution

Execute the plan in phases aligned with its structure (sections, todos, or explicit phases). After each phase:

1. Implement that phase completely.
2. Update the plan file to reflect progress (todo status, notes, any scope changes).
3. If a task is linked, sync progress (see context.md for when/how to sync vs relying on hooks).
4. **If mode is `phased`:** Pause with a concise summary of what landed and any verification steps (tests, manual
   checks). Wait for approval before starting the next phase.
5. **If mode is `continuous`:** Print a brief checkpoint summary of what landed, then immediately proceed to the next
   phase without waiting.

## When to Pause (Both Modes)

Always pause before continuing when you need the user to:

- Run migrations
- Answer clarifying questions
- Do research outside the codebase

These pauses apply even in `continuous` mode — they represent hard blockers, not review checkpoints.

## New Job Types

When a plan phase adds a background job type, verify the full production wiring is included in the same or next phase
(see context.md for project-specific wiring steps). Local dev can work without deploy wiring; production cannot.

## When the Plan is Finished

Update the plan with final progress, then archive it per project convention (see context.md for archive path).

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
