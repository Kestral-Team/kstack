# Context Templates

kstack skills are generic workflows. **`context.md`** files layer project-specific constraints on top without forking
skills.

Each skill directory ships with an empty `context.md` stub. Copy patterns from these templates into the matching skill
folder under `.cursor/skills/`.

## Priority order

1. `implementation/implement-plan/context.md` — task linkage, archive path, job wiring
2. `review/code-review/context.md` + `context.checks.md` — review ordering and extra checks
3. `planning/write-plan/context.md` — plan directory and task integration
4. `shared/kestral-sync/context.md` — Kestral MCP sync workflow (if using Kestral)

## Files

| Template                     | Copy to                                              |
| ---------------------------- | ---------------------------------------------------- |
| `implement-plan-context.md`  | `.cursor/skills/implementation/implement-plan/`      |
| `code-review-context.md`     | `.cursor/skills/review/code-review/context.md`       |
| `code-review-checks.md`      | `.cursor/skills/review/code-review/context.checks.md` |
| `write-plan-context.md`      | `.cursor/skills/planning/write-plan/context.md`      |
| `deslop-context.md`          | `.cursor/skills/review/deslop/context.md`            |

Run `./scripts/init-context.sh` to recreate empty stubs without overwriting filled files.
