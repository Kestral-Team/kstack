# Code Review — Project Context

## Review Ordering

When reviewing a PR, prioritize in this order:

1. GraphQL schemas — the API contract
2. Database queries — data access patterns
3. Server resolvers — core backend logic
4. Client GraphQL operations — how the frontend consumes the API
5. React/UI components — presentation layer

## Plan Context

Check related plan files if referenced in the PR description. Extract `kestralTaskId` from frontmatter for sync.

## Lint and Typecheck

Run your project's lint and typecheck commands after substantive fixes.
