---
name: run-e2e-plan
description: >-
  Run E2E tests from a plan file using Playwright. Generates test scripts from structured
  test sections, executes them headless with screenshots, and reports results. Use when the user asks
  to run E2E tests, verify a phase, automate QA checks, or says /run-e2e.
---

# Run E2E Plan

Execute manual test plans automatically via Playwright. Generates test scripts from structured plan sections, runs them
headless with screenshots, and reports pass/fail results with visual evidence.

## Prerequisites

- Playwright installed (`@playwright/test` in devDependencies + browser binaries)
- Dev servers running
- E2E environment configured (see context.md for project-specific env setup)

## Workflow

### Step 0: Health Check

Before anything else, resolve the server URL and verify dev servers are running. Read `playwright.config.ts` to
understand the port resolution chain, then health-check both servers:

```bash
# Resolve server URL the same way playwright.config.ts does
SERVER_URL=$(grep -m1 'VITE_SERVER_URL=' client/.env 2>/dev/null | cut -d= -f2 | tr -d '"'"'" || echo "http://localhost:$(grep -m1 'PORT=' server/.env 2>/dev/null | cut -d= -f2 | tr -d '"'"'" || echo 3000)")
echo "Server URL: $SERVER_URL"

curl -sf http://localhost:5173 > /dev/null 2>&1 && echo "Client OK" || echo "Client DOWN"
curl -sf "$SERVER_URL/health" > /dev/null 2>&1 && echo "Server OK" || echo "Server DOWN"
```

If either fails, **stop immediately** and tell the user:

> Dev servers not running. Start them with `pnpm run dev` in `client/` and `server/`.

Do not proceed with test generation.

### Step 1: Parse

Read the plan file and extract manual test sections.

**Structured format** (preferred): Look for `### Phase N Manual Tests` headings containing `#### Test N:` blocks with
`Steps`, `Expected`, and `Screenshot` fields.

**Ad hoc format** (fallback): If the plan uses inline checklists (`- [ ] Manual test: ...`), numbered paths, or test
matrices, interpret them best-effort — extract test names, steps, and expected outcomes from the prose.

If a specific phase is requested, extract only that phase's tests. Otherwise extract all phases.

### Step 2: Clean

Delete any existing files in `e2e/tests/generated/` to prevent stale test accumulation:

```bash
rm -f e2e/tests/generated/*.spec.ts
```

### Step 3: Generate

Write a Playwright test file to `e2e/tests/generated/{planName}-phase{N}.spec.ts`.

**Selector strategy** (follow this priority order):

1. `page.getByRole()` — accessible name, most resilient to markup changes
2. `page.getByText()` — good for visible labels
3. `page.locator('[data-testid="..."]')` — explicit test hooks
4. Avoid CSS class selectors or XPath — fragile

**Template:**

```typescript
import { test, expect } from '@playwright/test';

test.describe('Phase 1 Manual Tests', () => {
  test('Login and see dashboard', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('navigation')).toBeVisible();
    await page.screenshot({ path: 'e2e/results/home-dashboard.png', fullPage: true });
  });
});
```

Auth is handled automatically — the `chromium` project in `playwright.config.ts` sets `storageState` and depends on the
`auth-setup` project. Generated tests inherit this and do not need `test.use({ storageState })`.

Each test should:

- Translate natural-language steps into Playwright actions
- Take a screenshot after completing the steps (named per the `Screenshot` field)
- Add soft assertions for expected outcomes where possible

### Step 4: Run

Execute the generated tests:

```bash
pnpm run e2e:test:file e2e/tests/generated/{file}
```

Auth setup runs automatically via Playwright's project dependency system.

### Step 5: Retry on Failure

If a test fails:

1. Read the Playwright error output
2. Fix the generated test script (selector issues, timing, missing waits)
3. Re-run **once**

If it fails again, report the failure with the error message and any captured screenshot.

### Step 6: Report

Read each screenshot from `e2e/results/` using the Read tool (supports images) and evaluate against the "Expected" text
from the test plan.

**Evaluation criteria:**

- **Pass**: Expected elements are clearly visible, UI appears functional, no error messages or broken layout
- **Fail**: Blank page, error messages, missing expected elements, broken layout, loading spinners that never resolve

Present a structured summary:

```
## Test Results

| Test | Status | Screenshot | Notes |
|------|--------|------------|-------|
| Login and see dashboard | Pass | ![](e2e/results/home-dashboard.png) | Sidebar visible |
| Create a new task | Fail | ![](e2e/results/task-creation.png) | Button not found |
```

Embed screenshots inline so the user can visually verify.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
