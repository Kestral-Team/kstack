# Code Review — Additional Checks

Project-specific checks layered on top of `checks.md`.

## Workspace / Tenant Isolation

- ❌ Queries missing tenant scoping (e.g. missing workspace/org filter)
- ❌ Resolver trusting client-supplied tenant ID instead of server-side context

## Import Conventions

Document your project's import alias and component wrapper conventions here.

## Transaction Patterns

- ❌ Network/LLM/external I/O inside long DB transactions unless intentional
