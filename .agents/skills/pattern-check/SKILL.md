---
name: pattern-check
kstack: true
description: >-
  Search existing tasks and incidents for similar bugs or review misses, and link related issues.
  Use after creating a retroactive bugfix task, when a review finds a familiar-looking issue, or
  when the user asks "have we seen this before?"
---

# Pattern Check

Search task history for the same class of issue, link related tasks, and recommend rule-evolution when a pattern is
confirmed.

## When to Run

- After creating a retroactive bugfix task
- When a review or incident finding feels familiar
- During a retrospective: "is this a one-off or a cluster?"
- The user asks "have we seen this before?"

## Workflow

### 1. Frame the issue class

Describe the issue as a **class**, in user-facing and system terms — not the specific instance:

- Subsystem ("daily brief generation", "task sync")
- Failure mode ("stale data after edit", "missing workspace scoping", "timeout under load")
- Symptom ("users saw someone else's data", "job silently failed")

### 2. Search task history

Search your task tracker for prior instances (see context.md for project-specific search methods):

- Use semantic/concept search with the issue class framing
- Use keyword search with subsystem terms
- Check both open and done tasks; prior *fixed* instances are exactly the signal

### 3. Classify the result

| Matches found | Verdict           | Action                                                              |
| ------------- | ----------------- | ------------------------------------------------------------------- |
| 0             | One-off           | Note "no prior pattern" on the task; done                           |
| 1-2           | Possible cluster  | Link the related tasks; flag for attention                          |
| 3+            | Confirmed pattern | Link tasks + recommend [rule-evolution](../rule-evolution/SKILL.md) |

### 4. Link and report

- Cross-reference: post a comment on the current task listing related tasks (markdown links), and optionally on the most
  relevant prior task pointing forward
- Report to the user:

```markdown
**Pattern Check — [issue class]**

[N related tasks found]

| Task               | Status | What it was      |
| ------------------ | ------ | ---------------- |
| [KES-12](task url) | Done   | [1-line summary] |

**Verdict:** [one-off / possible cluster / confirmed pattern — recommend rule-evolution]
```

## Rules

- Search before declaring "no pattern" — absence of links must mean absence of matches, not absence of looking
- Don't spam links: only cross-reference tasks that share the failure class, not the same subsystem generally
- A confirmed pattern (3+) should always end with a rule-evolution recommendation

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
