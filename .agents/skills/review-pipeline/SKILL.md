---
name: review-pipeline
kstack: true
description: >-
  Fixed seven-step review pipeline: code-review, fix-issues, code-simplify, deslop, context-evolve,
  documentation-update, task-sync. Orchestrates the full polish pass for a branch. Only invoked by
  the kstack subagent.
disable-model-invocation: true
---

# Review Pipeline

You are reviewing and polishing branch changes to production quality. Execute seven steps in strict sequence on the
current branch diff (or scope the user specifies). Do not implement new features or execute an implementation plan —
only review, fix, simplify, deslop, evolve context, and update docs for existing changes.

**Start by creating a todolist with one item per step below.** Each item's first sub-action is reading that step's
SKILL.md via the Read tool. Mark an item in_progress only after the Read tool call succeeds.

## Step 1: Code review

Read `.agents/skills/code-review/SKILL.md` in full (including its `review-process.md` and `checks.md` references) and
follow its workflow. Perform a one-pass AI code review of the branch diff against the diff base. Produce a complete,
actionable review organized by logical sections.

## Step 2: Fix issues

Read `.agents/skills/fix-issues/SKILL.md` in full and follow its workflow. Take the issues from the code review in Step
1 as input. For each issue: validate whether it is real, identify the smallest safe fix, and apply changes sequentially.
Run lint/typecheck on touched files.

## Step 3: Code simplify

Read `.agents/skills/code-simplify/SKILL.md` in full (including its `patterns.md` reference) and follow its workflow.
Review every changed file in the branch diff. Check lint complexity, identify simplification opportunities, and refactor
for maximum readability while preserving functionality.

## Step 4: Deslop

Read `.agents/skills/deslop/SKILL.md` in full and follow its workflow. Strip AI-generated slop from the branch diff:
redundant comments, unnecessary casts, extra defensive code, style inconsistencies. Preserve meaningful documentation
and explanatory comments.

## Step 5: Context evolve

Read `.agents/skills/context-evolve/SKILL.md` in full and follow its workflow. Scan the thread for new learnings from
the review (patterns discovered, anti-patterns hit, conventions clarified). Propose additions to the relevant
`context.*` files. This step is a no-op if nothing new was learned — do not force findings.

## Step 6: Documentation update

Read `.agents/skills/documentation-update/SKILL.md` in full and follow its workflow. Identify which documentation types
are affected by the code changes (use the decision matrix in the skill). Create or update docs, sync indexes, and
include documentation changes in the deliverable.

## Step 7: Task tracker sync

Post a **Review Summary** to the task tracker (see context.md for project-specific sync method). Post even when the
review found nothing. Branch/PR linking and status updates may be handled by hooks — focus this step on the Review
Summary content only.

## Final Output

After all seven steps, present a final summary:

- Code review findings and how they were resolved
- Simplifications and deslop changes made
- Context learnings captured (or "no new learnings")
- Documentation updated
- Any remaining risks or follow-ups

## Rules

- Follow the project's coding rules in `.cursor/rules/` (read `engineering-principles.mdc` and `meta-workflow.mdc`).
- Run lint and typecheck after making changes (see context.md for exact commands).
- Use the AskQuestion tool to resolve ambiguity rather than guessing.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
