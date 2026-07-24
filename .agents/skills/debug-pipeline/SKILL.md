---
name: debug-pipeline
kstack: true
description: >-
  Debug pipeline: investigate (prod or local) → fix-issues → scoped polish (deslop + code-simplify)
  → pattern-check → kestral-sync retroactive capture. Only invoked by the kstack subagent.
disable-model-invocation: true
---

# Debug Pipeline

You are investigating a reported problem, fixing the root cause, and capturing the outcome. Execute five steps in
sequence. Keep fixes minimal and targeted — this is not a feature build or a full review pass.

**Mode selection:** Pick the investigation mode before starting:

- **prod** — the issue is in production: user reports, error alerts, Cloud Run/Sentry signals, "users are seeing X".
- **local** — the issue is local: dev errors, test failures, build breaks, "I'm hitting Y locally".
- **Auto-detect** — mentions of "production", "users", "Cloud Run", "Sentry", or deployed behavior → prod. Otherwise
  default to local. Ask via AskQuestion if genuinely ambiguous.

**Start by creating a todolist with one item per step below.** Each item's first sub-action is reading that step's
SKILL.md via the Read tool. Mark an item in_progress only after the Read tool call succeeds.

## Step 1: Investigate

**prod mode** — work from deployed evidence, not assumptions:

1. Gather the symptom, error message, affected users or endpoints, and time window. Check recent deploys.
2. Identify whether the failure is in the service or a background job.
3. Pull logs for that window, starting narrow (±2 min) and widening as needed.
4. Correlate against recent code changes (`git log`) and deployment history.

**local mode** — reproduce before theorizing: trigger the error, read the failing code path, and form a hypothesis. If
the project keeps a catalog of known bug classes, check it for a match first.

See context.md for the project's log/error-tracking tooling and any debugging catalog.

End this step with a **root cause hypothesis backed by evidence** (logs, stack traces, failing queries, code paths).
Present it to the user before fixing — if the evidence is inconclusive, say so and keep digging rather than guessing.

## Step 2: Fix

Read `.agents/skills/fix-issues/SKILL.md` in full and follow its workflow. Treat the confirmed root cause as the issue
list. Apply the smallest safe fix, run lint/typecheck on touched files.

## Step 3: Scoped polish

Run a lightweight polish pass **scoped to the files touched by the fix only** — not the full branch diff:

1. Read `.agents/skills/deslop/SKILL.md` — strip slop from the fix.
2. Read `.agents/skills/code-simplify/SKILL.md` — simplify the fix if warranted.

Do not run the full review-pipeline; debug fixes should stay small and targeted.

## Step 4: Pattern check

Read `.agents/skills/pattern-check/SKILL.md` in full and follow its workflow. Search task history for prior occurrences
of this issue class. If 3+ matches are found, recommend `.agents/skills/rule-evolution/SKILL.md` to the user.

Skip this step if the task tracker is unavailable (auth check fails) — note the skip in the final summary.

## Step 5: Task tracker sync

Post a structured bugfix record to the task tracker (see context.md for project-specific sync method):

1. If no active tracking task matches this bug, create a new bugfix task
2. If an active tracking task already exists, post a bugfix comment (root cause, fix, evidence links)
3. Link the branch/PR to the tracking task
4. Set status: `awaiting_review` while PR is open; `done` only on merge

Skip only if the task tracker is unavailable and the user doesn't specify a task.

## Final Output

After all steps, present a final summary:

- Root cause and the evidence that confirmed it
- Fix applied (files touched, what changed)
- Pattern check verdict (one-off / cluster / confirmed pattern — and whether rule-evolution was recommended)
- Kestral task created/updated (or skipped)
- Any remaining risks or follow-ups (rollback considerations, monitoring to watch)

## Rules

- Follow the project's coding rules in `.cursor/rules/` (read `engineering-principles.mdc` and `meta-workflow.mdc`).
- Never apply a fix before presenting the root cause hypothesis with evidence.
- Run lint and typecheck after making changes (see context.md for exact commands).
- Use the AskQuestion tool to resolve ambiguity rather than guessing.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
