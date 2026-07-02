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

## 4. Update Downstream Artifacts if Schema Changes

- Query functions that reference changed tables
- GraphQL schema & operations (then run codegen)
- Affected TypeScript types/usages

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
