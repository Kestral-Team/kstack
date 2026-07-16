---
name: acceptance-check
description: >-
  Validate the branch diff against the task's acceptance criteria before marking it done.
  Use when implementation looks complete, before a status update to done/awaiting_review, or when
  the user asks "did we cover everything?"
---

# Acceptance Check

Validate each acceptance criterion against the diff with evidence before updating task status.

## Workflow

1. Look up the task's description and acceptance criteria (see context.md for project-specific lookup method)
2. `git diff --stat $DIFF_BASE...HEAD` (diff base: `gt parent --no-interactive 2>/dev/null || echo "main"`)
3. Evaluate each criterion against the diff: **Yes / No / Partial**
4. All satisfied → set status based on PR state: `awaiting_review` if any linked PR is open/unmerged, `done` **only** if
   the PR is merged (or no PR exists and the user explicitly confirms completion)
5. Gaps → report what's missing; ask the user: address now, descope explicitly, or proceed anyway

## Evaluating Criteria

- Criteria live in the task description — checklists, "acceptance criteria" sections, or prose requirements. If the task
  has none, fall back to the linked plan's phase checklists; if neither exists, say so and skip the check rather than
  inventing criteria.
- Judge against the **diff**, not your memory of the session. Read the changed files where a criterion is ambiguous.
- A criterion is **Partial** when the happy path works but a stated edge case, surface, or user type is missing.

## Report Format

```markdown
**Acceptance Check — [task slug]**

| Criterion     | Status  | Evidence                          |
| ------------- | ------- | --------------------------------- |
| [criterion 1] | Yes     | [file/behavior that satisfies it] |
| [criterion 2] | Partial | [what's covered, what's missing]  |

**Verdict:** [criteria satisfied / N gaps to resolve] **Status action:** [awaiting_review — PR is open | done — PR is
merged | done — no PR, user confirmed]
```

Post the verdict as part of the closing progress comment — the audit trail should show the criteria were checked.
**Never set `done` when a linked PR is still open.** Use `awaiting_review` instead; `done` is only for merged PRs or
when no PR exists and the user explicitly confirms completion.

## Rules

- Run before `done`, and ideally before `awaiting_review` — cheaper to fix gaps before review than after
- Descoping is a valid outcome, but it must be explicit: update the task description and note it in the comment
- Never silently mark done with known gaps

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
