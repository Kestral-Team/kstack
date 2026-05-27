# Shared Review Checks

Canonical check definitions used by review skills. Apply every check to the diff — only report findings that are
relevant. Don't force every check into every file.

<!-- Add your project-specific checks below. These examples show the format. -->

---

## Example: Type Safety

- ❌ `as any` or `as unknown as` casts that bypass the type system
- ❌ Nested ternaries in JSX (hard to read, easy to misparse)
- ✅ Proper type guards or generic constraints

**Ask**: "Is this cast hiding a real type mismatch, or is the type system just lacking context?"

---

## Example: Transaction Scope (No External I/O)

Database transactions hold a connection for their entire duration. External I/O inside a transaction pins the
connection and risks pool exhaustion under load.

- ❌ HTTP calls, file I/O, or third-party API calls inside a database transaction
- ✅ Two-phase prepare/execute: I/O before transaction, short transaction for DB writes only

**Ask**: "If this external call takes 5 seconds, does the DB connection stay pinned the whole time?"

---

## Example: DRY (Don't Repeat Yourself)

- ❌ Identical logic blocks copied across files or functions
- ❌ Magic values repeated without a shared constant
- ✅ Shared utilities extracted for logic used in more than one place

**Ask**: "If this logic changes, how many places need updating? More than one is a smell."

---

## Example: Test Quality

- ❌ Assertions only check `toBeDefined()` without verifying actual values
- ❌ Mock return values identical to expected assertions (round-tripping mocks)
- ✅ Assertions verify the outcome of the feature (return values, side effects, state changes)

---

<!-- Add checks specific to your project's architecture and common failure modes here.
     Good candidates:
     - Multi-tenancy / workspace isolation rules
     - Background job wiring requirements
     - Caching and cache invalidation patterns
     - Error handling conventions
     - Configuration and infrastructure change review
-->
