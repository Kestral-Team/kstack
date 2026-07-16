---
name: write-migration
description: >-
  Scaffold and implement database migrations using team conventions. Use when the user asks to write
  a migration, create a migration, or change the database schema.
---

# Write Migration

Follow these steps to scaffold and implement a migration correctly.

## 1. Generate the Migration File

Run the project's migration scaffold command (see context.md for the exact command and output location).

## 2. Implement the Migration

Open the new migration file and implement:

- Write idempotent `up` and `down` steps
- Use `{ ifNotExists: true }` / `{ ifExists: true }`
- Wrap conditional DDL in `DO $$ ... END $$`
- Do not use broad exception handlers (no `WHEN others`)
- Avoid redundant/speculative indexes (UNIQUE/PK already create indexes)
- See context.md for project-specific conventions (identity columns, naming, etc.)

## 3. Test Locally (dev)

Run the migration up, down, and up again to verify idempotency (see context.md for exact commands).

- After a successful dev `up`, the schema dump is refreshed automatically.
- Never edit a previously released migration; create a new one to fix issues.

## 4. Check for Destructive Change Safety

If the migration drops, renames, or changes the type of a column/table, it **must not ship in the same deploy** as the
code that stops reading it. The migration runs against the live DB while the old code revision still serves traffic.

- **Additive changes** (new columns, new tables): safe in one deploy.
- **Destructive changes** (drop column, rename, type change): require two-phase deploy.
  - Phase 1: deploy code that stops selecting/writing the column.
  - Phase 2: deploy migration that drops the column (after Phase 1 is live).

If the current work includes both a destructive migration and code changes removing references, split into two PRs or
flag to the user that the migration must deploy separately.

## 5. Update Downstream Artifacts if Schema Changes

- Query functions that reference changed tables
- GraphQL schema & operations (then run codegen)
- Affected TypeScript types/usages

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
