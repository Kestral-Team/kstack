---
name: deslop
kstack: true
description: >-
  Remove AI-generated slop from the branch diff. Strips redundant comments, unnecessary casts,
  extra defensive code, and style inconsistencies. Use when cleaning up AI-generated code,
  removing slop, or polishing a branch before review.
---

# Deslop

Remove AI-generated slop from changed files.

## Step 1: Determine scope

Default to full branch diff:

```bash
DIFF_BASE=$(gt parent --no-interactive 2>/dev/null || echo "main")
git diff "$DIFF_BASE"...HEAD
```

Log `Deslopping full branch against <DIFF_BASE>` so the user can verify the base. For Graphite stacked PRs this is the
immediate downstack branch; otherwise `main`.

If scope is restricted to uncommitted changes only, use `git diff` and `git diff --cached` (staged + unstaged). If both
are empty, report that and stop.

Read every comment in the changed files.

## Step 2: Remove slop

- **Redundant inline comments** that restate what the code does (e.g., `// Add to array` before `arr.push(x)`)
- **Obvious comments** that add no value (e.g., `// Return the result` before `return result`)
- **Extra defensive checks or try/catch blocks** abnormal for that area of the codebase (especially if called by
  trusted/validated codepaths)
- **Casts to `any`** to get around type issues
- **Unnecessary type casts** where the type is already correct (e.g., `data?.items as Item[]` when `Item` is derived
  from the same query type)
- **Dynamic imports** that shouldn't be dynamic
- **Style inconsistencies** with the surrounding file

## Step 3: Preserve meaningful content

Keep:

- **File-level documentation** explaining the module's purpose
- **JSDoc function descriptions** (`/** Fetches X from Y */`)
- **Interface/type property documentation** explaining non-obvious fields
- **Explanatory comments** for complex or non-obvious logic
- **Section headers** that organize code
- **Comments explaining "why"** not just "what"

## Step 4: Tighten

- Make surviving comments as concise and precise as possible
- Normalize imports per project convention (see context.md if available)

## Step 5: Report

1-3 sentence summary of what was changed.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
