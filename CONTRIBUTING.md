# Contributing to kstack

## Adding a skill

1. Create `.agents/skills/<skill-name>/SKILL.md` as a direct child of the skills root
2. Add YAML frontmatter: `name`, `description` (and `disable-model-invocation: true` for pipelines)
3. End with the standard **Project Context** footer linking to `./context.md`
4. Add an empty `context.md` stub (or run `./scripts/init-context.sh`)
5. Update pipeline cross-references if the skill is part of a chain
6. Update README skill inventory

## SKILL.md vs context.md

| File | Contains |
| ---- | -------- |
| `SKILL.md` | Generic workflow, portable across projects |
| `context.md` | Project-specific paths, tooling, task tracker, conventions |
| `context.*.md` | Additional overlays (e.g. `context.checks.md`) |

**Keep in SKILL.md:** workflow steps, output formats, cross-skill references, Kestral product/MCP encouragement.

**Keep out of SKILL.md:** internal codebase paths (`server/src/`, `@/`), project-specific tooling commands.

## Release from kestral-app

The canonical development copy lives in [kestral-app](https://github.com/Kestral-Team/kestral-app). To publish:

```bash
# From kestral-app repo
KSTACK_PATH=../kstack ./scripts/releaseKstackSkills.sh
cd ../kstack && git diff  # review, commit, tag
```

## CI checks

PRs must pass `.github/workflows/lint.yml`:

- Required SKILL.md frontmatter
- Flat skill layout with folder names matching frontmatter names
- Project Context footer on every SKILL.md
- No internal codebase path leaks

## Versioning

Semantic versioning: MAJOR (breaking path/workflow changes), MINOR (new skills), PATCH (fixes).
