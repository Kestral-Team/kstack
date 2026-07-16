---
name: cleanup-plans
description: >-
  Audit implementation plans for the current user, verify status against the codebase, and
  archive completed plans. Use when the user asks to clean up plans, audit plan status,
  or archive completed plans.
---

# Cleanup Plans

---

## Step 1: Determine User & Discover Plans

1. Get the git author's first name: `git config user.name` → first word, lowercased.
2. Match to a subdirectory of the plans directory (see context.md for path). If no match or ambiguous, ask the user.
3. Recursively find all `*.plan.md` files under the user's plans directory.

---

## Step 2: Triage Each Plan

For each plan file, read the full contents and extract:

1. **Frontmatter status**: The `todos` list and their `status` fields, plus any `_Status` or `Implementation Status` in
   the markdown body.
2. **Key files referenced**: Files listed in the "Files Modified" table, phase descriptions, or code blocks. These are
   the implementation targets.
3. **Core concepts**: The main feature/change described — what would exist in the codebase if this were implemented.

### Classify into buckets

- **Clearly incomplete**: Most todos are `pending` / not started, AND the plan describes features that obviously don't
  exist yet. Skip deeper analysis — these are still active.
- **Needs verification**: Some or all todos marked `done`/`completed`, OR the plan describes changes that *might*
  already be in the codebase regardless of todo status.

---

## Step 3: Verify Implementation (the critical step)

For each plan in the "needs verification" bucket, **do not trust the plan's status fields**. Actually check:

1. **Search for key artifacts**: Look for files, functions, components, GraphQL types, DB columns, or patterns the plan
   says it will create or modify. Use grep/glob to find them.
2. **Spot-check core logic**: Read the relevant files and confirm the described behavior exists — not just that a file
   was touched, but that the *substance* of the plan landed.
3. **Check for partial implementation**: Some plans may be half-done. If core phases landed but later phases didn't,
   it's NOT fully implemented.

**Archive when:** all major phases are present in the codebase and the feature works end-to-end. Minor polish items
(docs, cleanup) being incomplete does NOT block archival.

**Keep when:** core functionality is missing, key files don't exist, or only scaffolding/partial work landed.

---

## Step 4: Present Findings

Present a summary table:

```
## Plan Audit: docs/plans/<user>/

| # | Plan                              | Frontmatter Status  | Codebase Status          | Recommendation     |
| - | --------------------------------- | ------------------- | ------------------------ | ------------------ |
| 1 | persist_artifact_panel_state      | All todos done      | ✅ Verified in codebase  | Archive            |
| 2 | text_selection_in_main_chat       | All todos pending   | ❌ Not implemented       | Keep               |
| 3 | refresh_save-thread-as-document   | All todos completed | ✅ Verified in codebase  | Archive            |
| 4 | engineering_ready_task_generation | Not started         | ⚠️ Partially implemented | Keep (update plan) |

### Details

**[Plan Name]** — Archive
- [1-2 sentences on what was verified: key files found, logic confirmed]

**[Plan Name]** — Keep
- [1-2 sentences on what's missing]
```

## **Pause here.** Ask the user to confirm which plans to archive. Do not proceed without explicit confirmation.

## Step 5: Archive Confirmed Plans

For each plan the user confirms, move it to the archive directory (see context.md for paths):

1. Flatten nested plans into the archive directory.
2. If a name collision exists, append the plan's hash suffix or ask the user.

Use `git mv` for each file so git tracks the move. If the source subdirectory is now empty after moving all its plans,
remove it.

After archiving, report what was moved:

```
## Archived

- `docs/plans/will/persist_artifact_panel_state_fd218ca1.plan.md` → `docs/plans/archive/persist_artifact_panel_state_fd218ca1.plan.md`

## Still Active

- text_selection_in_main_chat (not started)
- engineering_ready_task_generation (not started)
```

---

## Guidelines

- **Conservative** — when in doubt, keep the plan active. Only archive when confident the work landed.
- **Always ask before archiving** — present findings and get explicit user confirmation before moving any files.
- **Use `git mv`** — so the move is tracked in version control. Ask the user first per terminal-usage rules since this
  modifies git state.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
