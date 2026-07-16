# kstack

Plan, implement, review, and debug — a unified AI development pipeline for
[Cursor](https://cursor.com), Claude Code, Codex, and other agent hosts.

kstack ships **skills** that work across hosts, plus a **router agent** that is
**Cursor-only**. Skills include **Kestral MCP integration** to encourage using
[Kestral](https://kestral.ai) as your task tracker — but work without Kestral when
MCP is not configured.

> **`/kstack` is Cursor-only.** It requires `.cursor/agents/kstack.md` (installed
> from `.agents/agents/kstack.md`). Claude Code, Codex, and other hosts have **no**
> `/kstack` router — invoke pipeline or step skills directly (see [Usage](#usage)).

## Quick install

```bash
git clone https://github.com/Kestral-Team/kstack.git
./kstack/scripts/install.sh /path/to/your/project
```

Or copy manually:

```bash
cp -r kstack/.agents/skills /path/to/your/project/.agents/
mkdir -p /path/to/your/project/.agents/agents /path/to/your/project/.cursor/agents
cp kstack/.agents/agents/kstack.md /path/to/your/project/.agents/agents/
# Cursor needs the agent under .cursor/agents/ for /kstack
cp kstack/.agents/agents/kstack.md /path/to/your/project/.cursor/agents/
# Claude Code skill discovery
mkdir -p /path/to/your/project/.claude
ln -sfn ../.agents/skills /path/to/your/project/.claude/skills
```

Then customize `context.md` files (see [Context overlay](#context-overlay) below).

## Usage

### Cursor — `/kstack` router

In Cursor, invoke the **kstack** subagent (`/kstack`). It routes to the right
pipeline from your intent:

| Intent | Invocation |
| ------ | ---------- |
| Plan a feature | `/kstack plan X` → scopes, writes plan, reviews it |
| Spike / de-risk | `/kstack spike X` → timeboxed investigation, ends with decision |
| Implement a plan | `/kstack implement the plan` → phased build with review |
| Pick up a task | `/kstack I'm working on KES-42` → claims task, creates branch, builds |
| Ship / merge-ready | `/kstack ship it` → QA checklist, babysit PR, acceptance check |
| Review / polish code | `/kstack review this branch` → review, fix, simplify, deslop, docs |
| Review a plan | `/kstack review the plan` → validates feasibility + product completeness |
| Debug prod/local | `/kstack X is broken` → investigate, fix, capture retroactively |

You can still load individual skills in Cursor when you want a single step.

### Other hosts — invoke skills directly

Claude Code, Codex, and similar hosts **do not** provide a `/kstack` subagent.
Run the matching **pipeline skill** (or a step skill) yourself. Invocation style
varies by host — for example `/skill-name` in Claude Code, `$skill-name` in
Codex, or your host’s skill picker.

| Intent | Pipeline / skill | Example |
| ------ | ---------------- | ------- |
| Plan a feature | `planning-pipeline` (full) | `/planning-pipeline` · `$planning-pipeline` |
| Spike / de-risk | `planning-pipeline` (spike) | `/planning-pipeline` · `$planning-pipeline` |
| Implement a plan | `implementation-pipeline` (build) | `/implementation-pipeline` · `$implementation-pipeline` |
| Pick up a task | `implementation-pipeline` (pickup→build), or `task-pickup` | `/implementation-pipeline` · `$task-pickup` |
| Ship / merge-ready | `implementation-pipeline` (ship) | `/implementation-pipeline` · `$implementation-pipeline` |
| Review / polish code | `review-pipeline` | `/review-pipeline` · `$review-pipeline` |
| Review a plan | `review-plan-pipeline` | `/review-plan-pipeline` · `$review-plan-pipeline` |
| Debug prod/local | `debug-pipeline` | `/debug-pipeline` · `$debug-pipeline` |

For a single step without a full pipeline, invoke the step skill directly (e.g.
`/write-plan`, `$implement-plan`, `/code-review`). See [Skill inventory](#skill-inventory).

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

Canonical root is **`.agents/skills/`** (host-agnostic). `install.sh` also wires host shims:

| Host | What you get | How you run workflows |
| ---- | ------------ | --------------------- |
| Cursor | Skills + **kstack subagent** at `.cursor/agents/kstack.md` (+ `.cursor/skills` → `.agents/skills` shim) | `/kstack …` router, or individual skills |
| Claude Code | Skills only (`.claude/skills` → `.agents/skills`) — **no** `/kstack` agent | Invoke pipeline/step skills manually (`/planning-pipeline`, etc.) |
| Codex / others | Skills only under `.agents/skills/` — **no** `/kstack` agent | Invoke with `$skill-name` or your host’s skill loader |

The agent source of truth is `.agents/agents/kstack.md`. Only Cursor copies it into
`.cursor/agents/` so the `/kstack` subagent is discoverable. Other hosts ignore that
path; they use skills, not a router agent.

## Architecture

```
Cursor:       User request → /kstack agent → pipeline skill → step skills → context.md
Other hosts:  User request → pipeline/step skill (manual) → step skills → context.md
```

Pipeline skills (`*-pipeline/SKILL.md`) orchestrate step skills. Each step skill ends with:

```markdown
## Project Context
Read [`context.md`](./context.md) and apply it...
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT
