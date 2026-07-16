---
name: fix-issues
description: >-
  Validate reported issues against the codebase and fix confirmed ones with minimal, safe changes.
  Use when the user provides a list of issues, bugs, or review findings to triage and fix.
---

# Fix Issues

Discuss each issue, validate whether it is real, then fix all real issues with minimal changes.

## Workflow

1. Restate each reported issue and mark one of:
   - **Confirmed** (real bug/risk)
   - **Not reproducible** (explain why)
   - **Needs clarification** (missing facts)
2. For confirmed issues, identify the smallest safe fix and apply changes sequentially.
3. After each fix, re-evaluate whether later planned fixes still make sense.
4. Run lint/typecheck on touched files.
5. Summarize:
   - what was fixed
   - what was rejected (and why)
   - remaining risks or follow-ups

## Required Validation Checks

- **Transaction scope**: no network/LLM/GCS I/O inside long DB transactions unless intentional and justified.
- **Rollback ownership (TOCTOU guard)**: destructive cleanup must use authoritative write-path ownership signals (for
  example `wasCreated`), never stale pre-check state.
- **Atomicity**: related writes that must commit together share the same transaction client.
- **Error masking**: cleanup failures should be logged and should not hide the original business failure.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
