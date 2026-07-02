---
name: single-page-mockup
description: >-
  Create a single self-contained HTML file that mocks a feature using inline React and CSS.
  Use when the user asks to prototype a UI flow, build a mockup, create a shareable demo,
  or iterate on a feature's look and feel before implementation.
disable-model-invocation: true
---

# Single-Page Mockup

Build a **single `.html` file** that mocks a feature flow with inline React, CSS, and fixture data. The file is
shareable (email, Slack, repo link) and opens in any browser with no build step.

## When to use

- Stakeholders want to see a flow before eng builds it
- Iterating on layout, copy, states, or interaction patterns
- Validating a multi-step UX (e.g. upload → processing → triage)

## Output

One file in a scratch/mockups directory (see context.md for project-specific output path). Mockups are ephemeral and
should not be committed.

## Step 1: Understand the feature

Before writing anything, read the relevant production components to extract:

1. **User flow** — the sequence of states/screens (e.g. empty → ready → running → results)
2. **Data shape** — the GraphQL types or component props that drive the UI
3. **Copy** — exact button labels, helper text, empty states, error messages
4. **Layout** — master-detail, card grid, wizard, sidebar, etc.
5. **Interaction patterns** — keyboard shortcuts, selection model, approve/reject/edit

If a plan or requirements doc exists, use it as the source of truth for scope.

## Step 2: Write the HTML file

Use this skeleton:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>[Feature] — Mock</title>
  <style>
    /* :root tokens, layout, component styles — all inline */
  </style>
</head>
<body>
  <div id="root"></div>
  <script src="https://unpkg.com/react@18/umd/react.production.min.js" crossorigin></script>
  <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js" crossorigin></script>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  <script type="text/babel" data-presets="react">
    // All React code here: fixtures, helpers, components, mount
    ReactDOM.createRoot(document.getElementById('root')).render(<App />);
  </script>
</body>
</html>
```

### CSS rules

- Extract design tokens from the project's design system (see context.md for token source locations).
- Port class names from production styles so the mock visually matches the real app.
- Include relevant keyframe animations (`spin`, `pulse`, `glow`).
- System font stack, `max-width: 1200px` centered, subtle gray page background.
- Light mode only. No external component library or icon library imports.

### React rules

- All code in one `<script type="text/babel">` block.
- Destructure hooks at the top: `const { useState, useCallback, useMemo, useEffect, useRef } = React;`
- Inline SVG icon components instead of Lucide (keep them small, stroke-based, 24x24 viewBox).
- Fixture data as top-level `const` arrays/objects matching the production GraphQL shape.
- Local `useState` for all interactions — no GraphQL, no fetch, no auth.
- Use `setTimeout` to simulate async operations (analysis, saves).
- Actions that would trigger backend work (apply, sync) use `window.alert()` or a small toast.

### Page chrome

Every mockup includes:

1. **Page header** — `<h1>` with feature name + "Playground", subtitle "Mock flow for product review."
2. **Network banner** — note that React/Babel load from CDN and internet is needed on first open.
3. **Tab bar or segmented control** — if the feature has multiple views/phases.

## Step 3: Build realistic fixtures

- Use plausible names, dates, content — not "Lorem ipsum" or "Test item 1".
- Include enough items (6-10 for lists, 2-3 for tabs) with mixed statuses so all visual variants are visible.
- Mirror the production GraphQL type fields so mock props match real components.

## Step 4: Implement interactions

Priority order:

1. **Navigation** — tabs, back/forward, selection
2. **Primary actions** — the main CTA the user evaluates (approve, submit, learn)
3. **State transitions** — loading → complete, empty → populated
4. **Keyboard shortcuts** — if the production feature has them, include them
5. **Secondary actions** — edit, reject, restore, remove
6. **Feedback** — toasts, inline status badges, count updates

Stub anything that would require a backend with `window.alert('Would [action]')` or an inline toast.

## Step 5: Verify

- Open the file directly in a browser (`open scratchpad/mockups/<name>.mock.html` or double-click).
- Walk through the full flow end to end.
- Check all states: empty, loading, populated, all-reviewed.
- Verify keyboard shortcuts work.
- Confirm no console errors.

## Constraints

- **One file only.** No separate JS, CSS, or JSON files.
- **No production imports.** Do not import from production codepaths, GraphQL clients, etc.
- **No changes to production code.** The mockup is standalone.
- **CDN-dependent.** Recipients need internet on first open. Document this in the banner.
- **Disposable.** The mockup will drift from production. It is a sketch, not a source of truth.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
