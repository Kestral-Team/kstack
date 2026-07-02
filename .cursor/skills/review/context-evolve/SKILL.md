---
name: context-evolve
description: >-
  Capture new project-specific learnings into context files. Runs during reviews or after debugging
  to evolve the project's skill knowledge base. Use when the thread reveals patterns, anti-patterns,
  conventions, or codebase gotchas that should be remembered.
---

# Context Evolve

Scan the current thread for new learnings and propose additions to the appropriate `context.*` files.

## Trigger Points

- End of `code-review` (after findings are written)
- End of `manual-review` (after discussion concludes)
- Explicitly invoked: "update context", "remember this pattern", "add this to our checks"
- Optionally after `fix-issues` or `debugging` when a new codebase pattern is discovered

## Workflow

### 1. Scan the thread for learnings

Look for:

- Patterns discovered ("we always need X when doing Y")
- Anti-patterns hit ("never do X because it causes Y")
- Conventions clarified ("our approach to X is always Y")
- Tooling quirks ("this command requires flag Z in our setup")
- Codebase-specific gotchas ("table X uses actor_id not user_id")
- Review findings that represent reusable knowledge (not one-off bugs)

**Skip if nothing new was learned** — this is a no-op when the thread was routine.

### 2. Classify each learning

Determine the target context file:

| Learning type             | Target                                                                  |
| ------------------------- | ----------------------------------------------------------------------- |
| Security or quality check | `../code-review/context.checks.md`                                      |
| Review ordering or focus  | `../code-review/context.md` or `../manual-review/context.md`            |
| Implementation convention | Relevant skill under `../../implementation/*/context.md`                |
| Testing pattern           | `../../implementation/testing-patterns/context.md`                      |
| Debugging pattern         | `../../retroactive/debugging/context.md`                                |
| Build/deploy convention   | Relevant pipeline under `../../pipelines/*/context.md`                  |
| General project knowledge | Closest matching skill's `context.md` (use `../../<category>/<skill>/`) |

If no existing context file is appropriate, propose creating a new one in the most relevant skill directory.

### 3. Dedup

Read the target context file. Check if the learning is already captured — same concept, even if worded differently.

- **Already present:** Skip silently.
- **Partially present:** Propose extending the existing section rather than adding a duplicate.
- **Not present:** Proceed to step 4.

### 4. Propose additions

Present to the user:

```markdown
**Context Evolution — [N] new learning(s)**

| # | Learning              | Target file | Action                            |
| - | --------------------- | ----------- | --------------------------------- |
| 1 | [concise description] | `[path]`    | Add new section / Extend existing |

### Proposed addition to `[target file]`:

[exact markdown that would be appended]
```

**Wait for user approval** before writing. The user may adjust wording, redirect to a different file, or reject.

### 5. Update

Append approved content to the target context file(s). Follow the existing file's structure and tone.

- Add under an existing section heading if one fits
- Create a new `##` section if the learning is a new category
- Keep entries concise — 1-3 sentences per learning, with code examples where helpful

## Relationship to rule-evolution

| What was learned                                          | Goes to                                          |
| --------------------------------------------------------- | ------------------------------------------------ |
| Universal constraint that should always apply (hard rule) | `rule-evolution` → `.cursor/rules/*.mdc`         |
| Skill-scoped project pattern (soft knowledge)             | `context-evolve` → `context.md` / `context.*.md` |

Both can fire from the same review — use judgment on which is appropriate. Hard constraints that should break
lint/review go to rules. Soft patterns that inform skill behavior go to context files.

## Rules

- Never write to context files without user approval
- Prefer extending existing sections over creating new ones
- Keep additions concise and actionable
- A "no new learnings" result is the most common outcome — do not force findings

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
