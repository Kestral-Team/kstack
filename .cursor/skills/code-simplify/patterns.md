# Simplification Patterns

## Required Fixes (Anti-Patterns)

- **Nested ternaries** → early returns or if/else
- **`as any` or `as unknown as`** → proper types or type guards
- **Raw `console.log/error` in production code** → use your project's logger

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
- **Excessive cognitive complexity (lint)** → extract branches, loops, or nested conditions into well-named helpers

## Clarity & Readability

- **Unclear variable names** → rename (booleans: `isX`, `hasX`, `canX`)
- **Magic numbers/strings** → extract to named constants
- **Multi-step expressions** → break into intermediate variables with clear names
- **Redundant code** → remove dead code, unused variables, unreachable branches
- **Over-abstraction** → inline if the abstraction adds no value

## Data Handling

- **Repeated array/object operations** → consolidate or extract helpers
- **Verbose null checks** → use optional chaining (`?.`) and nullish coalescing (`??`)

<!-- Add patterns specific to your project's frameworks and conventions here.
     For example:
     - Preferred logging patterns
     - Database query conventions (ORM-specific)
     - Component library usage patterns
     - Import alias preferences
-->
