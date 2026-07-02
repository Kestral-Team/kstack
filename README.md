# kstack

Plan, implement, review, and debug — a unified AI development pipeline for
[Cursor](https://cursor.com), Claude Code, and other agent hosts.

kstack ships structured skills and a router agent (`kstack`) that delegates to the right pipeline based on your intent.
Skills include **Kestral MCP integration** to encourage using [Kestral](https://kestral.ai) as your task tracker — but
work without Kestral when MCP is not configured.

## Quick install

```bash
git clone https://github.com/Kestral-Team/kstack.git
./kstack/scripts/install.sh /path/to/your/project
```

Or copy manually:

```bash
cp -r kstack/.cursor/ /path/to/your/project/.cursor/
```

Then customize `context.md` files (see [Context overlay](#context-overlay) below).

## Usage

Invoke the **kstack** subagent, or load individual skills directly.

| Intent | Pipeline |
| ------ | -------- |
| Plan a feature | `planning-pipeline` |
| Spike / de-risk | `planning-pipeline` (spike mode) |
| Implement a plan | `implementation-pipeline` |
| Pick up a task | `implementation-pipeline` (pickup) |
| Ship / merge-ready | `implementation-pipeline` (ship) |
| Review / polish code | `review-pipeline` |
| Review a plan | `review-plan-pipeline` |
| Debug prod/local | `debug-pipeline` |

## Skill inventory

### Planning

| Skill | Description |
| ----- | ----------- |
| `write-plan` | Author structured implementation plans |
| `plan-review` | Interactive plan validation |

### Implementation

| Skill | Description |
| ----- | ----------- |
| `implement-plan` | Phased plan execution with checkpoints |
| `task-pickup` | Claim task and create branch |
| `acceptance-check` | Validate diff against acceptance criteria |
| `babysit-pr` | Triage comments, fix CI, resolve conflicts |
| `manual-test-plan` | Generate QA checklist from diff |
| `run-e2e-plan` | Run Playwright tests from plan sections |
| `testing-patterns` | Vitest mocking reference |
| `graphql-patterns` | Resolver, error, cache patterns |
| `write-migration` | Database migration scaffold |

### Review

| Skill | Description |
| ----- | ----------- |
| `code-review` | One-pass tech-lead review |
| `manual-review` | Interactive section-by-section review |
| `product-review` | Product completeness review |
| `code-simplify` | Readability simplification |
| `deslop` | Strip AI-generated slop |
| `refactor-prompt` | Compress agent prompts |
| `rule-evolution` | Turn findings into rules |
| `context-evolve` | Grow project context files |

### Retroactive

| Skill | Description |
| ----- | ----------- |
| `fix-issues` | Triage and fix reported issues |
| `debugging` | Common bug patterns |
| `debug-prod` | GCP/Sentry production debugging |
| `pattern-check` | Cross-reference past incidents |

### Prototyping

| Skill | Description |
| ----- | ----------- |
| `single-page-mockup` | Shareable HTML mockups |
| `decision-capture` | Record spike decisions |
| `handoff-to-implementation` | Create follow-up tasks |

### Shared

| Skill | Description |
| ----- | ----------- |
| `documentation-update` | Sync docs with code |
| `cleanup-plans` | Archive completed plans |
| `evals` | Agent eval patterns |
| `kestral-sync` | Kestral MCP task sync |

## Context overlay

Every skill ships with an empty `context.md` stub:

```markdown
# Project Context

<!-- Add project-specific constraints for this skill. -->
```

Skills load generic workflow from `SKILL.md`, then read `context.md` for your project:

- Plan directory paths
- Lint/typecheck commands
- Task tracker integration (Kestral MCP)
- Codebase-specific review checks (`context.checks.md` for code-review)

**Starter templates:** `examples/context-templates/`

```bash
./scripts/init-context.sh   # recreate empty stubs (skips filled files)
```

## Per-host setup

| Host | Install path |
| ---- | ------------ |
| Cursor | `.cursor/skills/` + `.cursor/agents/kstack.md` |
| Claude Code | Symlink `.claude/skills/` → `.cursor/skills/` (optional) |
| Codex / Copilot | Copy skills to your host's skills directory |

## Architecture

```
User request → kstack agent → pipeline skill → step skills → context.md overlay
```

Pipelines (`pipelines/*-pipeline/SKILL.md`) orchestrate step skills. Each step skill ends with:

```markdown
## Project Context
Read [`context.md`](./context.md) and apply it...
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT
