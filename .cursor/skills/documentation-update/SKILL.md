---
name: documentation-update
description: >-
  Update project documentation when code changes land. Knows documentation types, where each lives,
  naming conventions, and which indexes to keep in sync. Use when updating documentation, adding new
  docs, checking what docs a change requires, or when the user asks to document a feature or update READMEs.
---

# Documentation Update

Update or create documentation to match code changes. This skill maps documentation types in the repo, when each
applies, and how to keep indexes in sync.

---

## Documentation Types

<!-- Customize this table for your project's doc structure -->

| # | Type | Location | Update when |
| - | ---- | -------- | ----------- |
| 1 | Long-form docs | `docs/` subdirectories | New features, architecture, processes |
| 2 | README indexes | Each major directory | Adding/removing doc files |
| 3 | Architecture diagrams | `docs/` (`.d2`, mermaid, etc.) | Adding/removing services, changing data flows |
| 4 | AI coding rules | `.cursor/rules/` | New coding patterns, framework usage changes |
| 5 | AI agent skills | `.cursor/skills/<name>/SKILL.md` | Skill workflow changes, new tools/patterns |
| 6 | Agent config | `AGENTS.md`, `CLAUDE.md` | Adding/removing rules, skills, commands |
| 7 | Inline JSDoc | Source files | When signature alone doesn't convey intent |

---

## Writing Style Rules

1. **Link aggressively, never duplicate.** When a concept is documented elsewhere, link to it.
2. **End docs with "See Also" or "References".** Cross-link related docs and source files.
3. **Include a "Code Pointers" table** at the end of feature docs mapping areas to file paths.
4. **Follow this skeleton:** Title → Overview → Body sections → Decision tables → Code Pointers → See Also.
5. **Use tables for structured data** (enums, states, columns, config, decision matrices).
6. **Be concise.** Current state only (not history). Minimal code examples.

---

## Decision Matrix: What to Update

<!-- Customize these rows for your project -->

| Change type | Required docs | Recommended docs |
| ----------- | ------------- | ---------------- |
| **Infrastructure** (deploy, cloud) | `docs/infrastructure/` + diagrams | Main README index |
| **New feature** | `docs/app/` or `docs/features/` | README index |
| **API / schema changes** | N/A (codegen handles types) | Feature docs if user-facing |
| **Database migration** | N/A unless architecturally significant | Dev process docs for new patterns |
| **New integration** | `docs/integrations/<name>.md` | README index, config docs |
| **Dev workflow changes** | `docs/development_process/` | `CLAUDE.md` commands section |
| **New coding convention** | `.cursor/rules/*.mdc` | `AGENTS.md` rules index |
| **New AI skill** | `.cursor/skills/<name>/SKILL.md` | `AGENTS.md` skills section |

---

## Workflow

1. **Identify affected doc types** — use the decision matrix. Most changes affect 1-2 types.
2. **Create or update the doc** — follow your project's naming convention.
3. **Update indexes** — main README, folder READMEs, `AGENTS.md` as applicable.
4. **Commit docs with code** — documentation is part of the deliverable.

---

## Quality Checklist

- [ ] No content duplicated from another doc — linked instead
- [ ] Cross-doc links use relative paths
- [ ] "See Also" or "References" section at the end
- [ ] Follows skeleton: Title → Overview → Body → Code Pointers → See Also
- [ ] Tables used for structured data
- [ ] Content is concise — current state, not history
- [ ] README index updated if files were added/removed
- [ ] No broken internal links
