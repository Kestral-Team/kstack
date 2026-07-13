---
name: implementation-pipeline
description: >-
  Implementation pipeline with optional pickup and ship phases around the core build: task-pickup →
  implement-plan → review-pipeline polish pass → acceptance-check + merge readiness. Only invoked by
  the kstack subagent.
disable-model-invocation: true
---

# Implementation Pipeline

You are picking up, implementing, and delivering a task to production quality. The core is Build (always runs); Pickup
and Ship are optional entry/exit phases.

**Phase selection:**

- **Pickup** — run when the user is starting from a task reference and has no branch yet. Skip if a branch already
  exists or the invoking agent already resolved/claimed the task.
- **Build** — always runs.
- **Ship** — run when the user wants the work taken to merge-ready ("get this shipped"). Skip if they're handing off to
  a reviewer after the polish pass.

**Start by creating a todolist with the selected phases.** Mark the first in_progress after reading its skill.

## Phase 0: Pickup (optional)

Read `.cursor/skills/task-pickup/SKILL.md` in full and follow its workflow: task lookup, conflict check,
derive and confirm branch name, `claim_task_and_branch`, then create the git branch (ask before git state changes).

## Phase 1: Implement the plan

**Preamble — Conflict Check:** Skip if Pickup ran or the invoking agent already performed a conflict check and passed a
resolved task ID. Otherwise, check for conflicts via the task tracker (see context.md for project-specific conflict
check API). If another member is actively working on the same task, pause and inform the user before proceeding.

Read `.cursor/skills/implement-plan/SKILL.md` in full and follow its workflow. Execute the plan in phases
aligned with its structure. After each phase, update the plan file and pause for user approval (unless the user
specifies continuous mode).

**After each phase (phased mode only):** Check if the plan has a `### Phase N Manual Tests` section for the
just-completed phase. If it does, offer to run E2E tests via `.cursor/skills/run-e2e-plan/SKILL.md`
before proceeding to the next phase. If the section doesn't exist, skip without prompting. In **continuous mode**, skip
test execution entirely — tests run during Ship or on-demand via `/run-e2e`.

When all implementation phases are complete, proceed to Phase 2.

## Phase 2: Polish pass

Read `.cursor/skills/review-pipeline/SKILL.md` in full and follow its workflow.

## Phase 3: Ship (optional)

1. **Automated manual tests:** If the plan already has `### Phase N Manual Tests` sections, read
   `.cursor/skills/run-e2e-plan/SKILL.md` and run them. If the plan has no structured test sections, read
   `.cursor/skills/manual-test-plan/SKILL.md` to generate a test plan from the diff first, then run it
   via `run-e2e-plan`. Present results with screenshots and pause for user verification.
2. Read `.cursor/skills/babysit-pr/SKILL.md` — resolve comments, fix CI, resolve conflicts until
   merge-ready.
3. Read `.cursor/skills/acceptance-check/SKILL.md` — validate the diff against the task's acceptance
   criteria. Surface gaps; never silently mark done.
4. Set status based on PR merge state: `awaiting_review` while PR is open/unmerged; `done` **only** when PR is merged
   (or no PR exists and the user explicitly confirms completion). **Never set `done` on an unmerged PR** — passing
   acceptance criteria does not mean the task is done.

## Final Output

After the selected phases, present a final summary:

- What was implemented (phases completed)
- Code review findings and how they were resolved
- Simplifications and deslop changes made
- Documentation updated
- Acceptance check verdict (if Ship ran)
- Any remaining risks or follow-ups

## Rules

- Follow the project's coding rules in `.cursor/rules/` (read `engineering-principles.mdc` and `meta-workflow.mdc`).
- Run lint and typecheck after making changes (see context.md for exact commands).
- Use the AskQuestion tool to resolve ambiguity rather than guessing.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
