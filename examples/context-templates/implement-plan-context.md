# Implement Plan — Project Context

## Kestral Task Linkage

Before starting, check plan frontmatter for `kestralTaskId`. If absent, call
`execute_operation("sync_session_workflow", { intent: "pickup" })` on the `user-kestral` MCP and follow the **Task
Lookup** and **Conflict Check** instructions. If no match, call with `{ intent: "create" }` and create from the plan.

## Progress Sync

After each phase, if a Kestral task is linked and you did NOT just push (the post-push hook handles sync after push),
call `execute_operation("sync_session_workflow", { intent: "update" })` and follow the **Progress Comment**
instructions. If you pushed during the phase, the hook already triggered sync — skip the explicit call.

## Job Wiring

If the plan adds background jobs, verify your project's job registry, queue routing, and deploy config are updated in
the same PR or a follow-up phase.

## Archive Path

Move completed plans to your archive directory (e.g. `docs/plans/archive/`). Use `git mv` to preserve history.
