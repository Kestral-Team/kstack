---
name: write-plan
description: >-
  Author structured implementation plan documents. Use when the user asks to write a plan, create an
  implementation plan, design a feature spec, or says /plan.
---

# Implementation Planning

Write an implementation plan document (see context.md for project-specific output path).

## Plan Modes

Pick the mode from the request framing. Default is **full mode**.

| Mode               | Trigger                                                               | Output shape                                                          |
| ------------------ | --------------------------------------------------------------------- | --------------------------------------------------------------------- |
| **Full** (default) | "Write a plan for X" — scoped feature work                            | Full structure below: phases, risks, success metrics                  |
| **Spike**          | "Spike X to de-risk Y" — a question to answer, not a feature to build | Question framing, timebox, success criteria. NO implementation phases |
| **Project**        | Work too big for one task — multi-week, multiple workstreams          | Full structure + workstream breakdown, ownership, milestones          |

### Spike mode

The plan is a framed question, not a build plan:

- **Question:** the specific uncertainty to resolve ("Will SSE handle our reconnect requirements?")
- **Timebox:** how long before committing to a direction regardless of certainty
- **Success criteria:** what evidence would justify proceed / pivot / kill
- **Approach sketch:** 2-3 bullets on how to investigate — not phases, not checklists

Spike plans skip the review pass (`review-plan-pipeline`) — a timeboxed question doesn't need product review. When the
spike concludes, [decision-capture](../../prototyping/decision-capture/SKILL.md) records the outcome. If the
investigation requires *building* something substantial, that's prototyping — keep the plan minimal and let the engineer
iterate.

### Project mode

Adds to the full structure:

- **Workstreams:** parallel tracks of work, each with its own phases and a named owner (or "unassigned")
- **Milestones:** cross-workstream checkpoints with target outcomes
- **Task mapping:** Kestral task creation produces a project + phase tasks + subtasks (via
  `sync_session_workflow({ intent: "create" })` — **From Plan**) rather than flat phase tasks

## Plan Directory Selection

Place plans in the project's designated plans directory (see context.md for paths and naming conventions).

## Plan Structure

- Describe the work to be done and why it matters.
- Spell out which files/directories change and how.
- Break delivery into sequential phases (`Phase N – Title`) each with a checklist covering tasks, file scopes, testing
  expectations, and tooling gates.
- For phases with **user-facing changes**, include a `### Phase N Manual Tests` subsection using the heading-based
  format below. Pure backend/infrastructure/migration phases can skip this.
- Surface dependencies, migrations, feature flags, and required pauses (e.g., `run your codegen step`).
- Define success metrics and post-change validation steps.

### Manual test format

Each phase with UI or user-facing changes should include a structured manual test section that the `run-e2e-plan` skill
can parse and automate via Playwright:

```markdown
### Phase 1 Manual Tests

#### Test 1: Login and see dashboard

- **Steps**: Navigate to `/`
- **Expected**: Sidebar visible with project list
- **Screenshot**: `home-dashboard`

#### Test 2: Create a new task

- **Steps**: Click "New task" button; Type title "Test task"; Press Enter
- **Expected**: Task appears in list with title "Test task"
- **Screenshot**: `task-creation`
```

Fields: **Steps** (semicolon-separated user actions), **Expected** (what should be true — used for assertions and
screenshot evaluation), **Screenshot** (filename stem saved to `e2e/results/`). Existing plans with ad hoc test sections
remain valid.

Sections: metadata slab (status, owner, dates), executive summary, open questions, goals/non-goals, architecture/flow,
phases with checklists, dependencies/risks, validation metrics, rollout checklist. Keep prose factual — no fluff.

### Background job types

If the plan introduces new background job types, include a dedicated phase for production wiring (see context.md for
project-specific job wiring steps).

Name the plan file in `snake_case` as `plan_name.plan.md`.

## Research

Use available tools and MCPs for research (documentation, database schema, online search if gaps remain). Use the
AskQuestion tool liberally to resolve ambiguity before planning.

**CRITICAL**: Stay within the planning directory. Do **not** implement the plan or modify other files.

## Task Tracker Integration

If the user referenced a task (URL, slug, or pasted details), look it up for context. Store the task ID in plan
frontmatter so sync works automatically. After the plan is written, offer to create tracking tasks (see context.md for
project-specific sync instructions).

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
