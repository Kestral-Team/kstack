---
name: babysit-pr
description: >-
  Get a PR to merge-ready state by triaging comments, resolving conflicts, and fixing CI.
  Includes Graphite detection, migration conflict handling, and conflict resolution. Use when
  the user asks to babysit a PR, get a PR merge-ready, or fix CI on a PR.
---

# Babysit PR

Triage comments, resolve conflicts, fix CI, and keep the branch up to date — loop until the PR is green and mergeable.

## Environment detection

Detect whether the user uses **Graphite** or **plain git** by running `which gt`.

- **Graphite found:** use `gt sync`, `gt restack`, `gt s -u` (or `gt s -u --force` after restack)
- **Graphite not found:** use `git fetch origin main`, `git merge origin/main` (or `git rebase origin/main`), `git push`

## Workflow

### 1. Gather PR state

Run **in parallel**:

```bash
gh pr view <number> --json title,mergeable,mergeStateStatus,statusCheckRollup,reviewDecision,comments,reviews
gh pr checks <number>
```

Fetch **unresolved review threads** (inline comments) via GraphQL — filter to `isResolved: false` so you don't re-read
closed threads:

```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            path
            line
            comments(first: 20) {
              nodes {
                id
                databaseId
                body
                author { login }
                createdAt
              }
            }
          }
        }
      }
    }
  }' -f owner='{owner}' -f repo='{repo}' -F number=<number>
```

Read only each thread's comment bodies and the minimum location context needed to act — do not dump the full JSON into
your reasoning.

### 2. Sync with main

Keep the branch current with the base branch before addressing anything else.

- **Graphite:** `gt sync` → `gt restack` (resolve conflicts) → `gt s -u --force`
- **Git:** `git fetch origin main && git merge origin/main` → resolve conflicts → `git push`

If there are **migration conflicts** (see context.md for migration path), see "Migration conflicts" below — do NOT
auto-resolve these.

### 3. Triage comments

Review every **unresolved** thread (automated reviewers, human reviewers). Treat each comment as a reported issue and
follow the full **[fix-issues skill](../fix-issues/SKILL.md)** workflow — validate, classify, fix
confirmed issues only. See context.md for known reviewer bots to expect.

After validating each thread, **close the loop on GitHub** — do not leave addressed or dismissed threads open:

| Outcome                 | Action                                                                                                                            |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **Valid — fixed**       | Push the fix, then reply briefly if it helps the reviewer (commit SHA or one-line summary), then **resolve the thread**           |
| **Invalid — not a bug** | **Reply** explaining why (already correct, out of scope, misunderstanding, stale after rebase, etc.), then **resolve the thread** |
| **Uncertain**           | **Reply** asking for clarification or a concrete repro; **leave the thread open**                                                 |

#### Reply to a thread

Use the first comment's `databaseId` from the thread as the reply anchor:

```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments/{comment_database_id}/replies \
  -f body='Fixed in abc1234 — added workspace_id filter to the query.'
```

Keep replies concise and specific. For invalid findings, cite the evidence (file/line, test, or behavior) — don't just
say "won't fix."

#### Resolve a thread

Use the thread's GraphQL `id` (not the comment database ID):

```bash
gh api graphql -f query='
  mutation($threadId: ID!) {
    resolveReviewThread(input: { threadId: $threadId }) {
      thread { isResolved }
    }
  }' -f threadId='{thread_id}'
```

Resolve **every thread you triaged** in this pass — both fixed and invalid. Only leave threads open when you genuinely
need reviewer input.

Process threads one at a time: validate → fix or reply → resolve (if applicable) → next thread.

### 4. Fix CI failures

If CI is red:

1. Read the failure logs: `gh run view <run_id> --log-failed`
2. Apply the smallest fix that addresses the root cause
3. Commit, push, and re-check CI
4. Repeat until green

### 5. Push and verify

After all fixes:

1. Push using the detected tool (Graphite `gt s -u` or `git push`)
2. Wait for CI to run: poll `gh pr checks <number>` until all checks complete
3. If new failures appear, go back to step 4

### 6. Report

Summarize:

- What was fixed and why
- What was dismissed as invalid (with the rationale you posted on each thread)
- Which threads were resolved vs left open pending clarification
- What was intentionally left alone
- Current CI / mergeable status

---

## Migration conflicts

When rebasing or merging with main produces conflicts in migration files:

**STOP. Do not resolve migration conflicts automatically.**

Notify the user that migration sequence numbers collide with main. Ask them to:

1. Roll back locally applied migrations (if any) before renumbering
2. Confirm they're ready to proceed

**Only after the user confirms**, run the project's migration renumber command (see context.md for exact commands).
Stage and commit the renames, then continue the workflow.

---

## Conflict resolution guidelines

- **Code conflicts:** resolve when intent is clearly the same on both sides (e.g., both sides added an import, both
  sides edited adjacent lines with compatible changes). When in doubt, ask.
- **Generated files** (type codegen output, lockfiles): accept main's version, then regenerate.
- **Documentation / markdown:** prefer main's version for sections that were updated independently; merge content
  additions from both sides.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
