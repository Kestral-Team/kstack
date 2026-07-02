---
name: debugging
description: >-
  Common bugs and debugging strategies. Use when debugging errors, investigating
  GraphQL/database/TypeScript issues, diagnosing connection pool exhaustion, resolving ESM
  circular dependency TDZ errors, or when the user asks to debug a local issue.
---

# Debugging Guide

Common bugs and debugging strategies. See context.md for the project-specific bug catalog with known error messages,
codebase-specific chains, and exact fix commands.

## Common Bug Classes

### GraphQL: null/undefined query or non-nullable field violations

**Cause:** Resolver references a query function that doesn't exist, or returns `null` for a non-nullable schema field.

**Fix:** Trace the resolver from the error's operation name, verify the query/field exists, and fix the mismatch. Run
codegen after schema changes.

### Database: column/relation not found, parameter mismatches

**Cause:** Query references a column, table, or parameter count that doesn't match the current schema.

**Fix:** Verify against actual schema (via MCP tools or migration files), then correct the query.

### Connection pool exhaustion

**Cause:** Too many concurrent operations each holding a DB connection. Common triggers: parallel mutations without
concurrency control, transaction functions using the default connection instead of the transaction client, or network
I/O inside transactions pinning connections.

**Diagnosis:** Look for timeout errors and slow query logs. Trace the mutation's resolver for transaction blocks and
check if every query function receives the transaction client.

**Fix patterns:** Throttle client-side parallel mutations, pass the transaction client to every query function inside
transactions, move external I/O outside transactions.

### ESM: "Cannot access 'X' before initialization" (Circular Dependency TDZ)

**Cause:** ESM circular imports where a transitive chain loops back to a module still evaluating. Module-scope access
throws a TDZ error; function-body access is safe (all modules resolved by call time).

**Fix:** Move the reference from module scope to a function body. The static `import` stays at the top — only the
*usage* moves. Use lazy getter functions instead of module-scope constant assignments.

---

## After Resolving an Issue

Ask the user: "Add this pattern to the debugging skill?" If yes, append an entry to context.md following the Cause / Fix
/ Prevention format above.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
