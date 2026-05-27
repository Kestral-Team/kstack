---
name: code-simplify
description: >-
  Simplify changed code in a PR or branch for readability while preserving behavior. Use when
  the user asks to simplify code, reduce complexity, clean up a PR, or improve readability of
  recent changes.
---

# Code Simplify

Review code changes and refactor for maximum simplicity and readability while preserving functionality.

## Usage

- Simplify code in a specific PR (provide PR number)
- Simplify code in current branch vs parent branch (default)

---

## Step 1: Gather Context

Determine the diff base branch, then gather the diff:

```bash
DIFF_BASE=$(gt parent --no-interactive 2>/dev/null || echo "main")
git --no-pager diff "$DIFF_BASE"...HEAD
```

Read all changed files in full to understand the complete context.

Before introducing a new helper, abstraction, parser, formatter, or utility:

1. Search the surrounding package for existing helpers with the same responsibility or naming family.
2. Search shared utility directories (`utils`, `services`, `db/queries`, component/common folders as applicable).
3. Prefer reusing or lightly extending an existing helper when it clearly fits the behavior.
4. Keep a new local helper only when no existing helper matches, or when reuse would force an awkward abstraction.

---

## Step 2: Check Lint Complexity

Run your project's linter and collect any `noExcessiveCognitiveComplexity` warnings in changed files. Each function that exceeds the max allowed complexity becomes a **mandatory** refactor target in Step 3 — extract coherent logical sections into well-named helpers until the score drops below the threshold.

---

## Step 3: Identify Simplification Opportunities

Review every changed file. Go beyond fixing anti-patterns — actively simplify. Include any lint complexity violations from Step 2 as additional targets.

### Hard Constraints

- **Avoid introducing `any` types** — even if it would reduce duplication or improve readability. Prefer duplicated code over compromising type safety.
- **No slop comments** — do NOT add comments that restate what the code does (e.g., `// Add to array`, `// Return the result`). Comments explaining "why" are fine.
- **No unnecessary defensive code** — don't add try/catch blocks or null checks that are abnormal for that area of the codebase

For the full catalog of simplification patterns, see [patterns.md](patterns.md).

---

## Step 4: Make Changes

Refactor the code directly. For each file:

1. Apply all simplifications that improve readability
2. Preserve identical functionality — no behavior changes
3. Bias toward clarity over cleverness

---

## Step 5: Report

Summarize in 2-4 sentences:

- Which files were simplified
- What patterns were addressed
- Any files skipped and why
