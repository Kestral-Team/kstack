---
name: manual-test-plan
description: >-
  Generate a focused manual test plan from the current branch diff. Use when the user asks for a test
  plan, QA checklist, or manual testing steps for their changes. Includes API/integration host testing
  when the diff touches relevant endpoints.
---

# Manual Test Plan

Generate a focused manual test plan from the branch diff vs main.

## Process

1. Determine the diff base:

```bash
DIFF_BASE=$(gt parent --no-interactive 2>/dev/null || echo "main")
git --no-pager diff "$DIFF_BASE"...HEAD
```

2. Review the diff and create a focused manual test plan using the structured format below.

3. **If the diff touches API/integration endpoints** (see context.md for detection rules), add a dedicated integration
   test section. Tailor tests to the changed operations or routing logic.

## Output Format (UI / in-app flows)

Use the heading-based format so the `run-e2e-plan` skill can parse and automate these tests via Playwright:

```markdown
#### Test 1: [Short test name]

- **Steps**: [Semicolon-separated user actions, e.g. Navigate to /settings; Click "Save"]
- **Expected**: [What should be true after steps]
- **Screenshot**: `[filename-stem]`
```

Group tests by changed area. For each area, cover:

1. **Happy path** — core functionality works as intended
2. **Edge cases** — boundary conditions, empty states, error handling (1-2 quick checks)
3. **No regressions** — nearby features, styling, and existing behavior remain intact

## Automation

These test plans can be executed automatically via the `run-e2e-plan` skill, which generates Playwright scripts from the
structured format, runs them headless with screenshots, and reports pass/fail results. Tests with the `Screenshot` field
produce visual evidence in `e2e/results/`.

**Integration/API host tests are not Playwright-automatable** — they require manual testing in the relevant client
environment. See context.md for project-specific integration testing details (detection rules, setup, output format).

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
