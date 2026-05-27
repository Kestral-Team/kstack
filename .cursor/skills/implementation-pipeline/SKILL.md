---
name: implementation-pipeline
description: >-
  Fixed two-phase implementation pipeline: implement-plan, then hand off to review-pipeline for the
  full polish pass (code-review, fix-issues, code-simplify, deslop, documentation-update).
disable-model-invocation: true
---

# Implementation Pipeline

You are implementing a plan and polishing the result to production quality. Execute two phases in sequence.

**Start by creating a todolist with two items: Phase 1 (implement) and Phase 2 (polish).** Mark Phase 1 in_progress
after reading the implement-plan skill.

## Phase 1: Implement the plan

Read `.cursor/skills/implement-plan/SKILL.md` in full and follow its workflow. Execute the plan in phases aligned with
its structure. After each phase, update the plan file and pause for user approval (unless the user specifies continuous
mode).

When all implementation phases are complete, proceed to Phase 2.

## Phase 2: Polish pass

Read `.cursor/skills/review-pipeline/SKILL.md` in full and follow its workflow.

## Final Output

After both phases, present a final summary:

- What was implemented (phases completed)
- Code review findings and how they were resolved
- Simplifications and deslop changes made
- Documentation updated
- Any remaining risks or follow-ups

## Rules

- Follow your project's coding rules.
- Run your project's linter and type checker from the appropriate directory after making changes.
- Use the AskQuestion tool to resolve ambiguity rather than guessing.
