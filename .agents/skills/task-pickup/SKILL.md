---
name: task-pickup
kstack: true
description: >-
  Claim a task from your task tracker and start working on it. Use when the user says "I'm working
  on [task]", picks up a task from the board, or wants to start an existing task — handles lookup,
  conflict check, claim, status, branch naming, and context pull in one flow.
---

# Task Pickup

Turn "I'm working on [task]" into a claimed task with the right status and a correctly named branch — no manual tracker
fiddling.

## Workflow

### 1. Resolve the task

Look up the task in your task tracker (see context.md for project-specific lookup method):

1. Task Lookup — resolve from URL, slug, or search query
2. Conflict Check — stop and warn if someone else is actively on it or it's already done

### 2. Derive and confirm the branch name

Derive the branch name from the task identifier + title (lowercase, hyphenated, drop filler words).

**Ask the user before any git or branch registration** — present the suggested name, let them adjust.

### 3. Claim the task and create the branch

1. **Claim:** Set assignee, status to in-progress, and register the branch on the task (see context.md for API)
2. **Create the git branch** — detect if Graphite is in use:
   - Run `gt log short` silently — if it lists branches, use `gt create <branch-name>`
   - Otherwise `git checkout -b <branch-name>`

### 4. Pull working context

Surface what the implementer needs before writing code:

- Task description + acceptance criteria
- Linked plan if one references this task
- Open PRs or comments on the task that constrain the work

If the task originated from a plan, suggest the implementation pipeline; otherwise implement directly.

### 5. PR body context (when the PR is created later)

Seed the PR body from the task:

```markdown
## Why

[task description summary — the user-facing problem]

[task link]

## What

[changes summary — filled at PR time]
```

## Confirmation

End with: "Claimed [task-slug](task url), set to In Progress, on branch `slug-short-title`." Plus any conflict or
context warnings surfaced along the way.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
