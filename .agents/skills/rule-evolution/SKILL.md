---
name: rule-evolution
description: >-
  Turn a review finding or incident into a durable prevention: a new or updated .cursor/rules/*.mdc
  rule, skill check, or checklist item. Use after a review surfaces "we should always check X", after
  a production incident reveals a preventable class of bug, or when the same miss keeps recurring.
---

# Rule Evolution

Turn a finding into codified prevention (rule, skill check, or checklist item) and record a retrospective comment on the
originating task.

## When to Run

- A review surfaces a generalizable miss ("we should always null-check X", "every resolver needs Y")
- A production incident's root cause was preventable by a static check or convention
- [pattern-check](../pattern-check/SKILL.md) reports 3+ occurrences of the same issue class
- The user asks "should we add a rule for this?"

## Workflow

### 1. Generalize the finding

Before writing anything, answer:

- What is the **class** of bug, not the instance? ("missing workspace_id filter", not "tasksQueries.ts line 42")
- Would a rule have caught it at authoring time, or is it only detectable at review/runtime?
- How often could this realistically recur? One-off oddities don't deserve rules — rules have a context cost on every
  session that loads them.

If it's not generalizable or too rare, stop — say so rather than adding noise.

### 2. Pick the prevention mechanism

| Mechanism                                         | When                                                                                           |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Existing rule update (`.cursor/rules/*.mdc`)      | The class fits an existing rule's scope — extend it                                            |
| New rule (`.cursor/rules/*.mdc`)                  | Recurring class, applies to a file glob or always; no existing home                            |
| Skill check (e.g. `review/code-review/checks.md`) | Detectable in review but not expressible as an authoring rule                                  |
| Lint rule / CI check                              | Mechanically detectable — prefer this over prose when feasible (suggest, don't implement here) |
| Checklist item in an existing skill               | Process gap rather than code gap                                                               |

Prefer **editing an existing rule or check** over creating a new file — rule sprawl dilutes attention.

### 3. Draft the change

- Follow the conventions in the create-rule skill if making a new `.mdc` (frontmatter: `description`, `globs`,
  `alwaysApply`)
- State the rule as a positive instruction with a short rationale and a good/bad example where it earns its tokens
- Keep it minimal — one class of bug per rule addition

Present the draft to the user before writing the file. Rules affect every future session; they get human sign-off.

### 4. Record the retrospective

Post a retrospective to the originating task (review task, incident task, or bugfix task) via your task tracker (see
context.md for project-specific sync instructions).

## Rules

- Never add a rule without user approval — context cost is real and permanent
- One finding class per invocation; batch-proposing rules dilutes scrutiny
- If the prevention is better as a lint/CI check, say so and stop at the recommendation

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
