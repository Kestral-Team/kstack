---
name: review-pipeline
description: >-
  Fixed five-step review pipeline: code-review, fix-issues, code-simplify, deslop, documentation-update.
  Orchestrates the full polish pass for a branch.
disable-model-invocation: true
---

# Review Pipeline

You are reviewing and polishing branch changes to production quality. Execute five steps in strict sequence on the
current branch diff (or scope the user specifies). Do not implement new features or execute an implementation plan —
only review, fix, simplify, deslop, and update docs for existing changes.

**Start by creating a todolist with one item per step below.** Each item's first sub-action is reading that step's
SKILL.md via the Read tool. Mark an item in_progress only after the Read tool call succeeds.

## Step 1: Code review

Read `.cursor/skills/code-review/SKILL.md` in full (including its `review-process.md` and `checks.md` references) and
follow its workflow. Perform a one-pass AI code review of the branch diff against the diff base. Produce a complete,
actionable review organized by logical sections.

## Step 2: Fix issues

Read `.cursor/skills/fix-issues/SKILL.md` in full and follow its workflow. Take the issues from the code review in
Step 1 as input. For each issue: validate whether it is real, identify the smallest safe fix, and apply changes
sequentially. Run lint/typecheck on touched files.

## Step 3: Code simplify

Read `.cursor/skills/code-simplify/SKILL.md` in full (including its `patterns.md` reference) and follow its workflow.
Review every changed file in the branch diff. Check lint complexity, identify simplification opportunities, and refactor
for maximum readability while preserving functionality.

## Step 4: Deslop

Read `.cursor/skills/deslop/SKILL.md` in full and follow its workflow. Strip AI-generated slop from the branch diff:
redundant comments, unnecessary casts, extra defensive code, style inconsistencies. Preserve meaningful documentation
and explanatory comments.

## Step 5: Documentation update

Read `.cursor/skills/documentation-update/SKILL.md` in full and follow its workflow. Identify which documentation types
are affected by the code changes (use the decision matrix in the skill). Create or update docs, sync indexes
(`docs/README.md`, `AGENTS.md`, `CLAUDE.md` as needed), and include documentation changes in the deliverable.

## Final Output

After all five steps, present a final summary:

- Code review findings and how they were resolved
- Simplifications and deslop changes made
- Documentation updated
- Any remaining risks or follow-ups

## Rules

- Follow your project's coding rules.
- Run your project's linter and type checker from the appropriate directory after making changes.
- Use the AskQuestion tool to resolve ambiguity rather than guessing.
