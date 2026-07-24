---
name: kestral-sync
kstack: true
description: >-
  Sync session progress to your task tracker via MCP. Use after push, phase completion,
  PR creation, or review conclusion. See context.md for the project API and intents.
---

# Task Tracker Sync

Sync session progress to your project's task tracker. Full procedures come from the tracker's sync workflow operation
(see context.md) — do not invent steps from memory.

## How to sync

1. Read [`context.md`](./context.md) for the operation name, intents, and push fast-path.
2. Call the documented workflow operation with the matching intent and follow the returned instructions.
3. After push/PR, prefer the documented one-shot push sync operation when available.

## When to sync

- After `git push`, `gt submit`, or `gh pr create`
- Phase or feature complete
- PR created or linked
- Review, bug fix, or prototype conclusion
- User asks to sync

Skip for: review-feedback fixes, CI fixes, dep bumps, lint fixes, no new progress since last comment.

## Auth failures

If any sync call returns an auth error (401, unauthorized), stop. Ask the user to re-authenticate. Do not retry until
they confirm.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
