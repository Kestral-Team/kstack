---
name: code-review
description: >-
  One-pass AI code review of a PR or branch diff (tech-lead style). Use when the user asks for a
  code review, PR review, AI review, or wants code quality, architecture, bugs, and patterns reviewed.
---

# Code Review

Read [review-process.md](review-process.md) for the full review workflow including context gathering, section planning,
scrutiny criteria, and output format.

Read [checks.md](checks.md) for codebase-specific architectural and runtime checks to apply during review.

## Shared Principles

- **Assume bugs exist** — your job is to find them, not describe the code
- **Be specific and actionable** — name the failure scenario, cite the line
- **Distinguish severity** — blockers vs. nitpicks matter; when in doubt, escalate
- **Challenge complexity** — demand justification for every non-trivial decision
- **Think holistically** — consider ripple effects across the system

