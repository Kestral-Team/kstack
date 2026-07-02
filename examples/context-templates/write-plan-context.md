# Write Plan — Project Context

## Plan Directory

Plans live under your project's plans directory (e.g. `docs/plans/<user>/`). If ambiguous, ask the user.

## Kestral Task Integration

If the user referenced a Kestral task (URL, slug, or pasted details), call `entity_lookup` via the `user-kestral` MCP
for context. Store the task's ID as `kestralTaskId` in plan frontmatter.

After the plan is written, offer to create tracking tasks — call
`execute_operation("sync_session_workflow", { intent: "create" })` and follow the **From Plan** instructions.

## Project Mode Task Mapping

In project mode, task creation produces a project + phase tasks + subtasks (via
`sync_session_workflow({ intent: "create" })` — **From Plan**) rather than flat phase tasks.

## Background Job Wiring

If the plan introduces a new background job type, include a dedicated phase for production wiring (handler registry,
queue mapping, deploy config).
