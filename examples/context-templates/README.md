# Context Templates

kstack skills are generic workflows. **`context.md`** files layer project-specific constraints on top without forking
skills.

Each skill directory ships with an empty `context.md` stub. Copy patterns from these templates into the matching skill
folder under `.agents/skills/`.

## Priority order

1. `implement-plan/context.md` — task linkage, archive path, job wiring
2. `code-review/context.md` + `context.checks.md` — review ordering and extra checks
3. `write-plan/context.md` — plan directory and task integration
4. `kestral-sync/context.md` — Kestral MCP sync workflow (if using Kestral)

## Files

| Template                    | Copy to                                          |
| --------------------------- | ------------------------------------------------ |
| `implement-plan-context.md` | `.agents/skills/implement-plan/`                 |
| `code-review-context.md`    | `.agents/skills/code-review/context.md`          |
| `code-review-checks.md`     | `.agents/skills/code-review/context.checks.md`   |
| `write-plan-context.md`     | `.agents/skills/write-plan/context.md`           |
| `deslop-context.md`         | `.agents/skills/deslop/context.md`               |

Run `./scripts/init-context.sh` to recreate empty stubs without overwriting filled files.
