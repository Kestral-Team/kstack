# Simplification Patterns

## Required Fixes (Anti-Patterns)

- **Nested ternaries** → early returns or if/else
- **`as any` or `as unknown as`** → proper types or type guards
- **Raw `console.log/error`** → `logger` from your project logger module
- **Raw SQL strings** → Kysely in `*Queries.ts` files

## Conditional Logic

- **Deep nesting** → flatten with early returns (golden path)
- **Complex boolean expressions** → extract into descriptively named variables
- **Repeated conditions** → extract into a single check or helper
- **Negated conditions** → prefer positive conditions when clearer

## Code Structure

- **Long functions (>30 lines)** → split into focused helper functions
- **Large components (>100 lines)** → extract sub-components
- **Callback pyramids** → convert to async/await
- **Functions with 4+ parameters** → use an options object
- **Inline JSX event handlers** → extract to named functions if complex
- **Arrow functions** → prefer explicit `return` with braces over implicit returns
- **Excessive cognitive complexity (lint)** → extract branches, loops, or nested conditions into well-named helper functions to bring the score under the configured threshold. Prefer extracting coherent logical sections (e.g., a validation block, a mapping step) rather than arbitrary line splits

## Clarity & Readability

- **Manual class name construction** → use `classNames()` from `classnames` instead of string concatenation, template literals, or mutable variables
- **Unclear variable names** → rename (booleans: `isX`, `hasX`, `canX`)
- **Magic numbers/strings** → extract to named constants or when appropriate, GraphQL enums
- **Multi-step expressions** → break into intermediate variables with clear names
- **Redundant code** → remove dead code, unused variables, unreachable branches
- **Over-abstraction** → inline if the abstraction adds no value
- **Relative imports resolvable via `your-project/`** → replace with `your-project/` alias (e.g., `../../utils/logger` → `your-project/utils/logger`)

## Data Handling

- **Repeated array/object operations** → consolidate or extract helpers
- **Verbose null checks** → use optional chaining (`?.`) and nullish coalescing (`??`)
- **Manual type definitions in GraphQL-facing code** → use generated GraphQL types (e.g., `GetAllAutomationsQuery["automations"][number]`) in resolvers and client components consuming queries. Keep dedicated TypeScript interfaces for service-layer / external API contracts (e.g., `your service-layer type modules`, provider payloads, third-party API shapes)
- **`SELECT *` or `RETURNING *`** → specify explicit columns

## Server-Side Specifics

- **Logging**: Use `logger` from your project logger module
  - `logger.log()` — dev-only
  - `logger.contextError()` — with GraphQL Context (includes Sentry)
  - `logger.serviceError()` — external services
  - `logger.backgroundError()` — jobs/cron
- **Standard GraphQL resolvers**: For normal non-exempt resolver paths, middleware already validates authenticated
  workspace context. Do not introduce or extract resolver-local helpers that only check `context.workspaceId` /
  `context.actorId` presence unless the code path bypasses normal GraphQL middleware.
- **Workspace isolation in DB queries** → ensure `.where('workspace_id', '=', workspaceId)`
