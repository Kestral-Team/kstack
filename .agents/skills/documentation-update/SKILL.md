---
name: documentation-update
kstack: true
description: >-
  Update project docs to match code changes. Use when adding docs, checking what a change requires,
  or syncing docs/skills/commands with code.
---

# Documentation Update

Read the project's master doc index first; update it when adding/removing doc files. See context.md for project-specific
doc locations, naming conventions, and the full documentation types table.

## Documentation Types (Generic)

| # | Type               | Update when                                   |
| - | ------------------ | --------------------------------------------- |
| 1 | Long-form docs     | New features, architecture, processes         |
| 2 | README indexes     | Adding/removing doc files                     |
| 3 | Diagrams           | Adding/removing services, changing data flows |
| 4 | AI coding rules    | New coding patterns, framework usage changes  |
| 5 | AI agent skills    | Skill workflow changes, new tools/patterns    |
| 6 | Agent config       | Adding/removing rules, skills, commands       |
| 7 | Agent instructions | Modifying agent behavior, adding tools        |
| 8 | Inline JSDoc       | When signature alone doesn't convey intent    |

---

## Writing Style

1. **Link, never duplicate.** Relative markdown links. End docs with See Also + Code Pointers table.
2. **Skeleton:** Title → Overview (2-4 sentences) → Body (by concept) → Decision tables → Code Pointers →
   Troubleshooting → See Also.
3. **Tables** for structured data. ASCII art for simple state machines, mermaid for complex flows. Blockquote callouts
   for warnings.
4. **Concise.** Current state only. One doc covers one topic end-to-end (server + client + schema together).

---

## Decision Matrix: What to Update

| Change type               | Required docs                          | Recommended docs                             |
| ------------------------- | -------------------------------------- | -------------------------------------------- |
| **Infrastructure**        | Infrastructure docs + diagrams         | Master index, architecture summary           |
| **New feature**           | Feature/app docs                       | Master index, relevant folder README         |
| **Agent changes**         | Agent instruction files                | Agent docs, architecture diagrams            |
| **Schema changes**        | N/A (codegen handles types)            | App docs if user-facing                      |
| **Database migration**    | N/A unless architecturally significant | Dev process docs for new patterns            |
| **New integration**       | Integration docs                       | Master index, integration list               |
| **Testing patterns**      | N/A                                    | Testing docs if establishing new conventions |
| **Dev workflow changes**  | Dev process docs                       | Commands/architecture summary                |
| **New coding convention** | Rule file                              | Rules index                                  |
| **New AI skill/command**  | Skill/command file                     | Agent config index                           |

See context.md for project-specific paths for each category.

---

## Session-Driven Skill & Command Refinement

After completing work, reflect on whether skills or commands should be updated. Distinct from
[rule-evolution](../rule-evolution/SKILL.md) (coding conventions) — this covers agent workflow artifacts.

| Signal                                                      | Action                                        |
| ----------------------------------------------------------- | --------------------------------------------- |
| Skill workflow was wrong, confusing, or missed an edge case | Update the skill's `SKILL.md`                 |
| Command/skill produced errors or required workarounds       | Update `.agents/skills/<name>/SKILL.md`       |
| Had to deviate from a skill's instructions                  | Update the skill to match the correct path    |
| Skill was hard to discover                                  | Improve the `description` frontmatter         |
| Skill/command missing for a workflow you did manually       | Suggest creating one (user approval required) |

Propose changes before writing — one suggestion per artifact. Prefer editing over creating. Update `AGENTS.md` if
descriptions change.

---

## Workflow

1. **Identify affected doc types** — use the decision matrix.
2. **Create or update** — `camelCase.md` in the correct `docs/` subdirectory. Edit `.d2` source (never `.svg`).
3. **Update indexes** — `docs/README.md` (always), folder README, `AGENTS.md` (rules/skills/commands), `CLAUDE.md` (only
   if architecture/commands changed).
4. **Reflect on skills & commands** — review the session for friction signals (see table above). Propose updates. Skip
   if straightforward.
5. **Commit docs with code.**

---

## Quality Checklist

- [ ] Relative cross-doc links; no broken links
- [ ] Consistent file naming; master index updated if files added/removed
- [ ] Follows skeleton per §Writing Style
- [ ] Concise; one doc per topic end-to-end

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
