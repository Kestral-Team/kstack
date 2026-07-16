# Shared Review Checks

Canonical check definitions used by review types. Apply every check to the diff — only report findings that are
relevant. Don't force every check into every file.

---

## Security

Apply these when the diff touches resolvers, REST/webhook endpoints, redirects, file handling, server-side fetches of
user-influenced URLs, or anything rendered from user/integration-derived content. Severity is almost always blocker.

### Authorization & IDOR

- ❌ Query missing tenant scoping (e.g., missing workspace/org filter) with IDs derived from authenticated context
- ❌ Resolver trusting a client-supplied tenant ID or role instead of server-side context
- ❌ Child resource fetched/mutated by ID without verifying the parent chain
- ❌ Mutation spreading an entire input object into an update (mass assignment) — whitelist updatable fields explicitly
- ❌ Entity IDs used as capability tokens without cryptographic randomness
- ✅ Permission checks for role-gated actions using the project's permission system

### SSRF (User-Influenced URLs)

Webhook callback URLs, integration endpoints, URL fetch/preview features.

- ❌ Server-side fetch to a user-provided URL without scheme allowlist (http/https only) and blocking of private/
  internal targets (localhost, RFC1918, `169.254.169.254`, cloud metadata endpoints)
- ❌ Following redirects without re-validating each hop
- ✅ Domain allowlist for integrations; request timeouts and response size limits

### Open Redirect

OAuth callbacks and login/post-auth redirect params.

- ❌ Redirecting to a raw user-supplied URL
- ✅ Relative paths only (single leading `/`, reject `//`, `\`, and `javascript:`/`data:` schemes) or an allowlisted
  host set

### XSS Sinks

React escapes JSX interpolation by default — the risk is the escape hatches.

- ❌ `dangerouslySetInnerHTML` with user/integration-derived content not sanitized through DOMPurify
- ❌ Markdown/HTML rendering configured to allow raw HTML; user-uploaded SVGs served inline from the app origin
- ❌ User input flowing into `href`/`src` without scheme validation (`javascript:` URLs)

### File Uploads

- ❌ Type validation by extension or client `Content-Type` alone — validate magic bytes against an allowlist
- ❌ User-controlled filenames in storage paths (traversal/injection) — use generated IDs, discard original names
- ❌ Uploads served from the app origin without `Content-Disposition: attachment` and `X-Content-Type-Options: nosniff`
- ❌ No server-side size limit

### Secrets & Client Exposure

- ❌ Secret in a client-exposed env var, client bundle, or a GraphQL field reachable by the client
- ❌ Internal error details, stack traces, or raw SQL errors returned to the client
- ✅ Third-party calls requiring secrets happen server-side only

**Ask**: "If an attacker enumerates valid IDs and controls every string input, does each new code path still deny
access, refuse internal fetches, and render content inert?"

---

## Ownership-Safe Cleanup (TOCTOU Guard)

When code performs rollback/cleanup (delete row, remove blob, unsync index) after a later failure, verify cleanup
ownership is decided from authoritative write-path results, not a pre-read.

- ❌ Flags derived from a pre-check query, then used after other writes
- ❌ "check if exists" → create-or-reuse helper → cleanup that trusts the original check
- ❌ Cleanup deleting by ID without proving this request created that resource
- ❌ Rollback code that can affect reused/shared records under concurrency
- ✅ Cleanup gating uses an authoritative ownership signal returned by the same create-or-reuse function
- ✅ Tests cover the concurrency scenario where another request can create/reuse the same resource

**Ask**: "If another request creates/reuses the same record between the pre-check and write, could this cleanup delete
someone else's data?"

---

## Transaction Scope (No External I/O)

Database transactions hold a connection for their entire duration. External I/O inside a transaction pins the connection
and risks pool exhaustion under degradation.

- ❌ HTTP/API calls, file storage I/O, or message queue publishes inside a transaction
- ❌ Functions accepting a transaction client that internally perform network I/O
- ❌ Transaction wrapping a function that uses the default connection internally (not the transaction client)
- ✅ Two-phase prepare/execute: I/O before transaction, short transaction for DB writes only
- ✅ Pre-generated IDs when external I/O needs the ID before the transaction

**Ask**: "If this external call takes 5 seconds, does the DB connection stay pinned the whole time?" If yes, it must be
hoisted out.

---

## Connection Pinning (Session Locks & Raw Connections)

Raw connection checkouts (`connection().execute()`) pin a pool slot for the callback's entire lifetime. Combined with
session-scoped advisory locks, the connection stays pinned until the lock is released — often across external I/O.

- ❌ Raw connection checkout with external I/O inside the callback
- ❌ Session-scoped advisory locks held across async work with network I/O
- ✅ Transaction-scoped advisory locks that auto-release on commit/rollback
- ✅ Distributed locks (Redis) for coordination that spans external I/O
- ✅ Raw connection checkout only for short, DB-only operations

**Ask**: "Does this code hold a raw DB connection or session lock while awaiting external I/O?"

---

## Transaction Connection Leaks (Hidden Default Executor)

Query functions that default their executor to the main DB instance silently acquire a **separate** connection when
called inside a transaction. Under concurrent mutations, each transaction holds its own connection *plus* one per leaked
call, quickly exhausting the pool.

- ❌ Query function called inside a transaction without passing the transaction client
- ❌ Query helper with a defaulting executor parameter, called from a transaction block without forwarding it
- ✅ Every query function inside a transaction receives the transaction client explicitly

**Ask**: "Does every query function called inside this transaction receive the transaction client? If any default to the
main instance, that's a leaked connection."

---

## Concurrent Queries on Shared Transaction Client

Most database drivers do not support concurrent queries on a single client. `Promise.all` over async operations that
share one transaction client risks serialization errors or silent data corruption.

- ❌ `Promise.all(items.map(async (item) => { ... trx ... }))` with shared transaction client
- ✅ Sequential `for...of` loop when all operations share one transaction client
- ✅ `Promise.all` only when each callback uses its own connection or separate transaction

**Ask**: "Are multiple concurrent async operations sharing a single transaction client? If so, they must be serialized."

---

## Transaction Scope Too Wide

- ❌ Transaction wrapping a function that internally uses the default connection — the transaction slot sits idle while
  separate pool connections are acquired
- ✅ Only wrap operations that actually use the transaction client

---

## Query Fan-Out & Pool Amplification

A single request can exhaust the connection pool by fanning out into many concurrent queries that each check out their
own connection. Under concurrent user load, per-request fan-out multiplies into pool saturation.

- ❌ `Promise.all(ids.map((id) => queryFn(id)))` where `ids` is unbounded or data-driven
- ❌ The same expensive traversal computed independently by multiple functions within a single request
- ❌ Field resolvers that re-run expensive parent-level queries instead of receiving pre-computed results
- ✅ Batch N per-ID queries into a single `WHERE id IN (...)` query
- ✅ Compute expensive traversals once and thread results to downstream consumers
- ✅ `Promise.all` fan-out bounded by a known small constant, not by data size

**Ask**: "How many pool connections does a single request to this endpoint check out? Multiply by realistic concurrent
users — does it stay well under the pool max?"

---

## Query-Level Filtering vs In-Memory Filtering

Push filtering, scoping, and membership checks into SQL whenever the database can do it.

- ❌ Fetch a broad row set and filter in application code
- ❌ Use a capped/sampled query result for a different purpose than it was fetched for
- ✅ Express predicates in the query so the DB returns only what you need
- ✅ Early-return before querying when inputs make the result empty

---

## DRY (Don't Repeat Yourself)

Look for duplicated logic that reveals a missing abstraction.

- ❌ Identical or near-identical logic blocks copied across files or functions
- ❌ Magic values repeated without a shared constant or generated enum
- ❌ Type definitions written by hand that duplicate generated schema types
- ❌ Similar patterns differing only by entity name — likely a missing utility
- ✅ Shared utilities extracted for logic used in more than one place
- ✅ Constants centralized; generated types used instead of hand-written duplicates

**Ask**: "If this logic changes, how many places need updating? More than one is a smell."

---

## Optimistic Responses (Client Mutations)

When a PR adds or modifies a mutation call that updates a single field on an existing entity, check whether an
optimistic response is provided so the UI updates instantly.

- ❌ Single-field mutation without optimistic response — user sees a loading delay
- ❌ Optimistic response includes related entities with placeholder data — corrupts normalized cache
- ❌ Optimistic response missing `__typename` or `id`
- ❌ Manual cache rollback in `catch` blocks — the framework handles rollback automatically
- ✅ Optimistic response with `__typename`, `id`, and only the changed field(s)

**Skip for**: bulk operations, create/delete mutations, external system syncs, debounced text inputs.

---

## Multi-Instance Compatibility

When the server runs multiple instances, in-memory state breaks when requests/callbacks hit different instances.

- ❌ `new Map()` / `new Set()` at module scope for request/session state
- ❌ `AbortController` stored in memory for later retrieval by different requests
- ❌ State tokens, dedupe caches, or rate limiters without distributed storage backing
- ❌ OAuth flows, webhook callbacks, or async operations assuming same-instance routing
- ✅ Caches with TTL that gracefully handle misses
- ✅ Read-only config or performance optimizations with fallbacks

**Ask**: "If request A creates state on instance 1 and request B hits instance 2, does this code still work?"

---

## Migration Deploy Safety

Destructive schema changes (column drops, renames, type changes) must not ship in the same deploy as the code that stops
reading the column. The migration runs against the live DB while the old code revision still serves traffic — any query
referencing the dropped column returns 500s for every user until the new revision is fully active.

- ❌ Migration drops/renames a column AND the same PR removes code references to it — single deploy will break
- ❌ `DROP TABLE` in a migration when any query function still references the table
- ❌ `ALTER COLUMN TYPE` to an incompatible type in the same deploy that changes the query
- ✅ **Phase 1 deploy**: code stops selecting/writing the column (column still exists, harmlessly ignored)
- ✅ **Phase 2 deploy**: migration drops the column (no code references it)
- ✅ Adding columns with defaults is safe in a single deploy (old code ignores new columns)

**Ask**: "If the migration runs but the old code keeps serving for 30 minutes, does every query still work?"

---

## Docker Base Image Stability

Production Docker images must use **pinned** base image tags to prevent silent runtime breakage from upstream patch
releases.

- ❌ Floating tags (`node:24`, `python:3.12`) — resolve to different patch versions on each build
- ❌ Transitive dependencies bundling deprecated HTTP clients fragile on modern runtimes
- ✅ Pinned to a specific patch version (e.g., `node:24.16.0`)
- ✅ Comment near the pin explaining why

**Ask**: "If the base image tag resolves to a new patch tomorrow, will every transitive dependency still work?"

---

## Configuration & Infrastructure Impact Analysis

When a PR modifies configuration or infrastructure files, the blast radius extends far beyond the diff.

**For every config change, answer**:

1. What behavior does this setting control?
2. What currently depends on the old behavior?
3. For each dependent, does the new value break it?
4. Is the change consistent across environments (local, CI, Docker, production)?
5. Is the change consistent across workspace packages?

- ❌ Restrictive change without auditing existing dependents
- ❌ Config change without evidence of a dependency audit
- ✅ Restrictive changes enumerate every affected package/build step and confirm each still works

---

## React Hook Hygiene (`useRef` / `useEffect` Necessity)

Every `useRef` and `useEffect` should justify its existence.

### `useRef` — Is it actually needed?

- ❌ `useRef` for state that could be a function parameter
- ❌ `useRef` for a derived value that could be `useMemo`
- ❌ `useRef` holding state that should trigger re-renders (should be `useState`)
- ✅ `useRef` for DOM element references
- ✅ `useRef` for mutable values read across renders that must NOT trigger re-renders
- ✅ `useRef` for timer/animation-frame IDs needing cleanup

### `useEffect` — Is it actually needed?

- ❌ `useEffect` that derives state from props/state (should be computed during render)
- ❌ `useEffect` that responds to a user event (should be in the event handler)
- ❌ `useEffect` with cleanup that doesn't match setup
- ✅ `useEffect` that synchronizes with an external system (DOM, network, subscriptions)
- ✅ `useEffect` with proper cleanup that mirrors setup

---

## Multi-Tab Session Compatibility

Users commonly keep multiple tabs open. Client-side code that coordinates dedup, fires side effects, or manages polling
must handle this correctly.

### Storage semantics

- ❌ `sessionStorage` used to coordinate across tabs — it's per-tab
- ✅ `localStorage` for cross-tab dedup timestamps and cooldown gates

### Background tab efficiency

- ❌ `setInterval` firing unconditionally in background tabs
- ✅ Interval callbacks gated on `document.visibilityState === 'visible'`

### Duplicate side effects

- ❌ Mutations fired on timer/focus without checking whether another tab already handled the work
- ✅ Cross-tab dedup via `localStorage` timestamp + cooldown window

---

## Test Coverage & Quality

Don't just check whether tests exist — verify they actually prove the code works.

- New logic should have tests; bug fixes should have regression tests
- ❌ Assertions only check `toBeDefined()` without verifying actual behavior
- ❌ Mock return values identical to expected assertions (proves nothing)
- ❌ Single happy-path test for logic with multiple branches
- ✅ Assertions verify outcomes (return values, side effects, state changes)
- ✅ Edge cases, error handling, and boundary conditions are covered

---

## Prompt–Eval Co-evolution (Evalmaxxing Risk)

When the diff touches **both** agent prompts **and** eval fixtures/scorers, check for overfitting.

- ❌ Prompt wording that mirrors exact phrasing from new/modified fixtures
- ❌ New conditional instructions mapping 1:1 to a single fixture
- ✅ Prompt changes describe general principles applicable across many interactions
- ✅ Eval fixtures test general behavior, not the other way around

**Ask**: "Would this prompt change improve behavior for a real user who never sends a message like the eval fixture?"

---

## Project-Specific Checks

If `context.checks.md` exists in this folder, read and apply those checks in addition to the universal checks above.
