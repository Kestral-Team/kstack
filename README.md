# kstack

Plan, Implement, Review — a unified AI development pipeline for [Cursor](https://cursor.com).

kstack gives your Cursor agent structured workflows for planning features, implementing plans, and reviewing code to production quality. It ships as a set of Cursor skills and a router agent that delegates to the right pipeline based on your intent.

## Installation

Copy the `.cursor/` directory into your project root:

```bash
cp -r .cursor/ /path/to/your/project/.cursor/
```

Or clone this repo as a sibling and symlink:

```bash
git clone https://github.com/Kestral-Team/kstack.git ../kstack
ln -s ../kstack/.cursor/agents/kstack.md .cursor/agents/kstack.md
ln -s ../kstack/.cursor/skills/* .cursor/skills/
```

## Usage

Invoke the kstack subagent in Cursor, or use individual skills directly.

### Pipelines

kstack routes your request to one of three pipelines:

| Intent | Pipeline | What it does |
| ------ | -------- | ------------ |
| "Plan a feature" | **Planning** | write-plan → validate → review → product review |
| "Implement the plan" | **Implementation** | implement-plan → full review pipeline |
| "Review this PR" | **Review** | code-review → fix-issues → simplify → deslop → docs |

### Individual Skills

Each skill can be used standalone:

| Skill | Description |
| ----- | ----------- |
| `code-review` | One-pass AI code review (tech-lead style) |
| `manual-review` | Interactive section-by-section PR walkthrough |
| `code-simplify` | Refactor for readability while preserving behavior |
| `deslop` | Strip AI-generated slop (redundant comments, unnecessary casts) |
| `fix-issues` | Validate and fix reported issues with minimal changes |
| `implement-plan` | Execute plans in sequential phases with review checkpoints |
| `write-plan` | Author structured implementation plan documents |
| `manual-test-plan` | Generate focused manual test plans from branch diffs |
| `documentation-update` | Update docs to match code changes |

## Customization

Four files are designed to be customized for your project:

| File | Purpose |
| ---- | ------- |
| `code-review/checks.md` | Project-specific architectural and runtime review checks |
| `code-simplify/patterns.md` | Simplification patterns for your frameworks and conventions |
| `documentation-update/SKILL.md` | Your doc types, locations, naming conventions, and update workflow |
| `write-plan/SKILL.md` | Your plan directory structure, tooling gates, and plan template |

These ship with generic examples and `<!-- Add your project-specific ... -->` markers. Fill them in to teach the agent your project's conventions.

## Architecture

```
User request
    │
    ▼
┌─────────┐
│ kstack  │  (router — .cursor/agents/kstack.md)
│  agent  │
└────┬────┘
     │ routes to one of:
     ├──────────────────────────────────────────┐
     │                                          │
     ▼                                          ▼
┌──────────────┐  ┌────────────────────┐  ┌──────────────┐
│   Planning   │  │  Implementation    │  │    Review     │
│   Pipeline   │  │    Pipeline        │  │   Pipeline    │
├──────────────┤  ├────────────────────┤  ├──────────────┤
│ 1. write-plan│  │ 1. implement-plan  │  │ 1. code-review│
│ 2. validate  │  │ 2. review pipeline │  │ 2. fix-issues │
│ 3. review    │  │    (steps 1-5)     │  │ 3. simplify   │
│ 4. product   │  │                    │  │ 4. deslop     │
│    review    │  │                    │  │ 5. docs update│
└──────────────┘  └────────────────────┘  └──────────────┘
```

## Requirements

- [Cursor](https://cursor.com) IDE with agent mode enabled
- A project with version control (git)

## License

MIT
