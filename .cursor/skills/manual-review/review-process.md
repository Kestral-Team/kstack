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
- Related `docs/plans/` files
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

Read and apply all checks from `checks.md` (in `code-review/`) against every file in the diff. Flag
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

Run through all checks from `checks.md` (in `code-review/`) and report status for each applicable
check as: pass / fail [file:line] / N/A.

**Overall**: [1-2 sentences]

### Documentation Updates Needed

Use the documentation-update skill to identify affected doc types.

| Doc | What needs updating | Priority |
|-----|-------------------|----------|
| [doc path] | [description] | High / Low |


### Recommended Next Steps

1. Run `/deslop` to clean up AI-generated code artifacts
3. [Any other follow-up actions]
```

---

## Critical Review Mindset

Don't just explain — actively look for problems:

### State & Lifecycle

- **Cleanup symmetry**: If state is set, is it reset? Check cleanup paths, disconnect handlers, error recovery.
- **Lifecycle consistency**: Does state survive scenarios it shouldn't?
- **Guard completeness**: Missing "already active" checks, re-entrancy protection?
- **Multi-instance safety**: In-memory state used for cross-request coordination? Will it work across your cloud provider
  instances?

### Edge Cases & Races

- **Concurrent calls**: Called twice rapidly — orphaned promises, overwritten callbacks?
- **Ordering assumptions**: Code assumes events arrive in specific order?
- **Partial failures**: If step 3 of 5 fails, is state consistent?
- **Cleanup ownership**: Rollback uses authoritative write-path output, not stale pre-check state?

### Missing Pieces

- **What's NOT in the diff**: Needed updates elsewhere that aren't present?
- **Defensive gaps**: Missing timeouts, size limits, null checks?

### Codebase-Specific Concerns

- **Workspace isolation**: Could one workspace access another's data?
- **GraphQL generation**: Types changed but codegen not run?
- **Error handling**: Error handling follows project conventions?
- **N+1 queries**: Database calls inside a loop?

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
