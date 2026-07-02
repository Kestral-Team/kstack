---
name: kestral-sync
description: >-
  Sync session progress to your task tracker. Use after push, phase completion, PR creation, or
  review conclusion. Delegates to the task tracker's sync workflow for full instructions.
---

# Task Tracker Sync

Sync session progress to your project's task tracker. See context.md for the project-specific API and intents.

## When to sync

- After `git push`, `gt submit`, or `gh pr create`
- Phase or feature complete
- PR created or linked
- Review, bugfix, or prototype conclusion
- User asks to sync

Skip for: review-feedback fixes, CI fixes, dep bumps, lint fixes, no new progress since last comment.

## Auth failures

If any sync call returns an auth error (401, unauthorized), stop. Ask the user to re-authenticate. Do not retry until
they confirm.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
