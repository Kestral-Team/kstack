---
name: manual-test-plan
description: >-
  Generate a focused manual test plan from the current branch diff. Use when the user asks for a test
  plan, QA checklist, or manual testing steps for their changes.
---

# Manual Test Plan

Generate a focused manual test plan from the branch diff vs main.

## Process

1. Determine the diff base:

```bash
DIFF_BASE=$(gt parent --no-interactive 2>/dev/null || echo "main")
git --no-pager diff "$DIFF_BASE"...HEAD
```

2. Review the diff and create a focused manual test plan.

## Output Format

For each changed area, provide:

1. **What to test** — specific user action or flow
2. **Expected result** — what should happen
3. **Edge cases** — 1-2 quick checks if relevant

## Focus Areas

1. **Happy path** — core functionality works as intended
2. **Edge cases** — boundary conditions, empty states, error handling
3. **No regressions** — nearby features, styling, and existing behavior remain intact
