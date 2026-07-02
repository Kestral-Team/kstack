# Interactive Section-by-Section PR Review

Walk through PR changes section-by-section in clear, junior-friendly language, surface issues, and pause for user input
between sections. Assume the reader is a junior engineer: define jargon, connect implementation to product behavior. You
drive; they cross-examine.

## Usage

- Review a specific PR number
- Review PR for the current branch
- Review worktree changes (e.g., `../rc_feature-x`)

---

## Setup

### Step 1: Determine Target and Pre-load

```bash
gh pr view $PR_NUMBER --json headRefName,baseRefName,author,title
gh pr diff $PR_NUMBER  # full diff, not just --stat
```

Read the full diff and all changed files upfront in parallel for instant responses during the walkthrough.

### Step 2: Context

Silently read for background (don't walk through docs with the user):

- PR description for linked docs
- Related `docs/plans/` files — extract any `kestralTaskId` from frontmatter or `todos[]` entries for later sync
- Related design docs if the PR title suggests one exists

---

## Section Plan

Group files into logical sections based on feature, layer, or concern boundaries. For small PRs (<5 files), each file
can be its own section.

**File ordering within sections:** GraphQL schemas -> DB queries -> server resolvers -> client operations -> React
components -> tests -> docs/configs.

Present the plan:

```
## PR: [title]

**Scope**: X files, +Y/-Z lines

| Section | Files | Focus |
|---------|-------|-------|
| 1. Workflow Router | workflowRouter.ts, workflowRouting.ts | Core routing logic |
| 2. GraphQL Schema | agenticCommand.graphql, knowledge.graphql | New types and operations |
| 3. Client Integration | KnowledgeSearch.tsx, ChatTemplateManager.tsx | UI handling |

**Review approach**: I'll review each section, present findings, then pause for discussion.

Ready to start with Section 1? (yes / reorder / adjust sections)
```

Wait for confirmation.

---

## Per-Section Review

For each section (or file in small PRs):

### 1. Overview

State which files are in this section and what it accomplishes (1-2 sentences).

### 2. Walk Through Changes

For each file, explain key changes and notable design decisions. For non-obvious logic, walk through a concrete scenario
showing before/after behavior.

### 3. Findings Report

```
| # | Severity | Issue | Location | Recommendation |
|---|----------|-------|----------|----------------|
| 1 | Critical | [description] | file.ts:L45 | [fix suggestion] |
| 2 | Medium | [description] | file.ts:L78 | [fix suggestion] |

**Questions for Discussion**:
1. [design decision question]

**Pause**: Which issues should we fix now? Ready to continue?
```

**Always pause here.** User decides before proceeding.

### 4. Fix Issues (if requested)

Apply fixes, run typecheck/lint, summarize, then ask: "Ready for next section?"

---

## Codebase-Specific Checks

Read and apply all checks from [../code-review/checks.md](../code-review/checks.md) against every file in the diff. Flag
violations immediately as you encounter them.

---

## Final Summary

After all sections are reviewed:

```
## Review Complete

### Section Summary

| Section | Key Changes | Issues Found | Status |
|---------|-------------|--------------|--------|
| 1. Workflow Router | New LLM-based routing | 1 critical (fixed) | done |
| 2. GraphQL Schema | New types | None | done |

### Codebase Checklist

Run through all checks from [../code-review/checks.md](../code-review/checks.md) and report status for each applicable
check as: pass / fail [file:line] / N/A.

**Overall**: [1-2 sentences]

### Documentation Updates Needed

Use the documentation-update skill decision matrix to identify affected doc types.

| Doc | What needs updating | Priority |
|-----|-------------------|----------|
| [doc path] | [description] | High / Low |

Include `docs/costs.md` when the PR changes models or cost-relevant LLM usage.
Include `docs/development_process/featureFlags.md` when feature flags are added/removed/changed.

### Recommended Next Steps

1. Read and follow the [deslop skill](../deslop/SKILL.md) to clean up AI-generated code artifacts
2. Run refactor-prompt skill (Mode 2: Detect Evalmaxxing) if PR touches agent instructions alongside eval fixtures
3. [Any other follow-up actions]
```

---

## Kestral Sync

After presenting the Final Summary, optionally sync review findings to the linked Kestral task.

### Step 1: Task lookup

Call `execute_operation("sync_session_workflow", { intent: "update" })` and follow the returned **Task Lookup**
instructions. Lookup order is defined there:

- User-provided task URL/slug in conversation
- Plan frontmatter `kestralTaskId` (from docs read during Setup Step 2)
- `execute_operation("deep_research", { query })` framed as user-facing problem + branch name
- Session-held task ID from earlier in the thread

### Step 2: No task found

If task lookup returns nothing, call `execute_operation("sync_session_workflow", { intent: "create" })` and offer task
creation using the **From Current Work** instructions. If the user declines, skip sync and end the review.

### Step 3: Draft PR offer

Check for an open PR on the current branch
(`gh pr list --head $(git branch --show-current) --json number,title,url,isDraft --limit 1`).

If **no PR exists**, ask:

> Create a draft PR for this branch and link it to [task link]? (yes / skip)

- **yes** — follow **Draft PR Creation** from the `sync_session_workflow` update instructions; PR body should reflect
  the review summary and recommended next steps
- **skip** — continue without creating a PR

If a PR **already exists** (including when manual-review was invoked with a PR number), skip this offer. If the PR is
not yet linked to the task, link it after the user confirms the review comment in step 5.

### Step 4: Present review comment

Synthesize a draft **Review Summary** (format from the `sync_session_workflow` update instructions) from the Final
Summary — section table, overall verdict, recommended next steps. Ask:

> Post this review summary to [task link]? (yes / edit / skip)

- **edit** — user revises wording, then re-ask
- **skip** — end without MCP write (PR link from step 3 still stands if created)

### Step 5: Post

On **yes**:

- Call `execute_operation("add_task_comment", { taskId, content })` with the **Review Summary** format
- If a PR exists (pre-existing or just created) and is not yet linked, call
  `execute_operation("link_pr_to_task", { taskId, prUrl })` (once per session)
- Do **not** change task status — review completion is not a status transition; status updates remain governed by
  `sync_session_workflow` **Status Update** rules

### Step 6: Confirm

Tell the user what was synced (task URL, PR URL if applicable, what was posted).

---

## Critical Review Mindset

Don't just explain — actively look for problems:

### State & Lifecycle

- **Cleanup symmetry**: If state is set, is it reset? Check cleanup paths, disconnect handlers, error recovery.
- **Lifecycle consistency**: Does state survive scenarios it shouldn't?
- **Guard completeness**: Missing "already active" checks, re-entrancy protection?
- **Multi-instance safety**: In-memory state used for cross-request coordination? Will it work across Cloud Run
  instances?

### Edge Cases & Races

- **Concurrent calls**: Called twice rapidly — orphaned promises, overwritten callbacks?
- **Ordering assumptions**: Code assumes events arrive in specific order?
- **Partial failures**: If step 3 of 5 fails, is state consistent?
- **Cleanup ownership**: Rollback uses authoritative write-path output, not stale pre-check state?
- **Multi-tab sessions**: Users keep 5+ tabs open for hours. Client-side timers, dedup keys, and side effects must
  handle N parallel instances. `sessionStorage` is per-tab — it cannot coordinate across tabs. Does this code fire
  duplicate mutations when multiple tabs cross a time/slot boundary?

### Missing Pieces

- **What's NOT in the diff**: Needed updates elsewhere that aren't present?
- **Defensive gaps**: Missing timeouts, size limits, null checks?

### Codebase-Specific Concerns

See `context.md` for project-specific review concerns (tenant isolation, code generation, error handling conventions).

### Design Questions

- **Is this the right approach?** Even if correctly implemented, is there a simpler design?
- **Hidden assumptions**: What does this code assume about its environment?

**Surface issues as you go** — when you spot something:

```
**Potential issue**: [description]
**Scenario**: [concrete example of how it fails]
**Suggested fix**: [if you have one]
```

---

## Guidelines

- Assume a junior audience — explain clearly, define jargon
- Explain the "why", not just the "what"
- Use concrete examples for non-obvious logic
- Be critical, not just descriptive — find problems, not just narrate
- Think holistically — ripple effects across the system
- Pause after each section — never proceed without confirmation
- Fix before continuing — address agreed issues before next section
- Flag anti-patterns immediately
- Capture Design Anti-Patterns — if the user expresses frustration with AI-generated design, record it in the project's
  design documentation (see context.md for specific locations)
