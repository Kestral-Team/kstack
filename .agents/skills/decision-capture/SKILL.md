---
name: decision-capture
description: >-
  Capture the decision when a spike, prototype, or investigation concludes. Use when a prototype or
  spike wraps up, the user makes a go/no-go call after de-risking, or an investigation answers its
  question — prompts "what did you decide?" and writes the decision + rationale to the task tracker.
---

# Decision Capture

Record the outcome as a durable artifact — decision, rationale, and evidence links.

## When to Run

- A prototype concludes — regardless of outcome (proceed, pivot, or kill)
- A planning spike answers (or fails to answer) its question
- The user makes a direction call after any de-risking work
- An investigation ends with "we're not doing this" — capturing the *no* prevents relitigating later

## Workflow

### 1. Gather evidence context

Collect what exists before asking the user anything:

- Current branch and diff stats (`git branch --show-current`, `git diff --stat`)
- Artifacts produced: mockup files (`scratchpad/mockups/*.mock.html`), POC branches, benchmark results
- The original question — from the spike plan's frontmatter, the linked Kestral task, or session context

### 2. Prompt for the decision

Ask the user (use the AskQuestion tool where options are discrete):

1. **Decision** — proceed / pivot / kill
2. **Rationale** — why this direction, what trade-offs were accepted (1-2 sentences)
3. **Code disposition** — keep the prototype code (promote the branch) or discard it
4. **Evidence** — confirm which artifacts support the decision (pre-fill from step 1)

Don't interrogate — pre-fill everything inferable from context and ask only what's missing.

### 3. Write the decision to your task tracker

Record the decision on the linked task (see context.md for project-specific sync instructions):

- If a task exists for the spike/prototype → post a **Decision Comment** and update status (`done` for proceed/kill with
  no follow-up; keep open if work continues on the same task)
- If no task exists → create one from the prototype context, then post the Decision Comment
- Link artifacts: mockup file path, POC branch name, benchmark numbers

### 4. Route the outcome

- **Proceed, large scope** → offer the planning pipeline (full plan informed by the validated approach)
- **Proceed, small scope** → offer [handoff-to-implementation](../handoff-to-implementation/SKILL.md)
- **Proceed, code kept** → suggest promoting the prototype branch into the implementation pipeline
- **Pivot** → offer to re-frame the question and start another round
- **Kill** → close the task with the rationale documented; no further action

## Rules

- Always capture, even for "kill" decisions — the absence of a path taken is valuable context
- Plain language: outcomes and trade-offs, not implementation details
- One Decision Comment per conclusion — don't duplicate if the decision was already posted (dedup check)

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
