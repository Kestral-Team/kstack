---
name: handoff-to-implementation
description: >-
  Create a follow-up implementation task with decision context pre-filled after a spike or prototype
  concludes with "proceed". Use when a validated approach needs to become trackable implementation
  work without the engineer re-explaining the context from scratch.
---

# Handoff to Implementation

Create a follow-up implementation task with decision context pre-filled so the implementer can start without re-reading
the spike history.

## Preconditions

- A decision exists — captured via [decision-capture](../decision-capture/SKILL.md) or stated directly by the user
- The decision is **proceed** (don't create implementation tasks for pivot/kill outcomes)

## Workflow

### 1. Assemble the handoff context

Pull from the concluded spike/prototype:

- The original question and the decision made
- Rationale and accepted trade-offs
- Evidence links (mockup, POC branch, benchmarks)
- Anything explicitly descoped or deferred during the decision

### 2. Create the implementation task

Create a task in the project's task tracker (see context.md for project-specific sync instructions):

- **Find the project**: same project as the spike/prototype task if one exists; otherwise search projects and ask the
  user if ambiguous
- Fill the description template from the handoff context assembled in step 1 (title framing, source linking, chain
  references)

### 3. Link the chain

Reference the originating task in the new description and post a "Follow-up implementation: [task link]" comment on it.
If the prototype code is being kept, note the branch name in the new task.

### 4. Confirm

Present the created task as a markdown link. Offer next steps:

- Pick it up now → [task-pickup](../task-pickup/SKILL.md)
- Needs a full plan first → planning pipeline with the decision as input

## Rules

- One implementation task per decision — split into subtasks only if the scope clearly demands it
- The description must stand alone: an implementer should not need to read the whole spike history
- Never mark the new task in_progress — it's a handoff, not a claim

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
