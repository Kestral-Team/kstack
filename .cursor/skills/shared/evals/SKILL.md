---
name: evals
description: >-
  Agent eval development patterns including model config sharing, eval file structure,
  and running evals. Use when writing or modifying agent evals, creating eval fixtures
  or scorers, or configuring eval model settings.
---

# Agent Eval Development

## Model Configuration: Share, Don't Duplicate

Eval agents **must** use the same model configuration as their production counterpart. Never duplicate model arrays or
`defaultOptions` between agent and eval files — drift invalidates eval results.

### Pattern: Import from the production agent

```typescript
export const sortProjectModelConfig = {
  model: [
    { model: google('gemini-3-flash-preview'), maxRetries: 2 },
    { model: openai('gpt-5.4-mini'), maxRetries: 2 },
  ],
  defaultOptions: { providerOptions: { /* ... */ } },
};

import { sortProjectModelConfig } from 'your-project/mastra/agents/generateTasks/sortProjectAgent';
return new Agent({ id: 'sortProjectAgent-eval', model: sortProjectModelConfig.model, defaultOptions: sortProjectModelConfig.defaultOptions, instructions, tools });
```

### Variants

- **Eval needs different `defaultOptions`**: import model array only, build options locally.
- **Circular deps**: extract model config into standalone file (e.g. `workflowRouterModelConfig.ts`).
- **`modelTier: fast` fixtures**: fast-tier uses `gpt-5.4-mini` defined in eval config, not production agent.

### Model-specific tool call behavior

Gemini Flash emits 40-50+ parallel calls to the same tool in a single step, bypassing per-step loop guards. Prefer
OpenAI models for tool-calling agents. Pass `{ maxExecutions: N }` to cap mock tool responses.

### Naming conventions

| Export shape                | Naming pattern              | Example                        |
| --------------------------- | --------------------------- | ------------------------------ |
| `{ model, defaultOptions }` | `<agentName>ModelConfig`    | `citationTaggingModelConfig`   |
| Model array only            | `<agentName>ModelArray`     | `generalAgentModelArray`       |
| Standalone file             | `<agentName>ModelConfig.ts` | `workflowRouterModelConfig.ts` |

## Instruction Files: Same Path as Production

Use `readAgentInstructionFile()` from `your-project/utils/fileUtils` with the **identical path string** in both production agent
and eval. Paths resolve relative to `src/` (dev) or `dist/` (bundle) via `process.cwd()`.

```typescript
const instructions = readAgentInstructionFile('mastra/agents/documents/documentEditorAgentInstruction.md');
```

YAML fixtures use `path.join(__dirname, 'fixtures')` — different resolution strategy.

| Asset             | Helper                                          | Path style                  |
| ----------------- | ----------------------------------------------- | --------------------------- |
| Instruction `.md` | `readAgentInstructionFile('mastra/agents/...')` | Project-root relative       |
| Fixture YAML      | `path.join(__dirname, 'fixtures')`              | Relative to eval `index.ts` |

Never use `__dirname` for instructions (breaks in production bundle) or inline instruction strings (drift).

### Related docs

- [`docs/agents/agent_context_passing.md`](../../../../docs/agents/agent_context_passing.md)

## Mock Tool Data Must Match the Full Output Schema

`createEvalMockTool` validates fixture `mockTools` data against the tool's Zod `outputSchema` at agent construction
time. Missing fields (even `.nullable()`) cause instant failure (0ms, 0% score).

**Fix options:**

1. Add the missing field to the YAML (e.g. `sourceCreatedAt: null`).
2. Patch in the `agentFactory` to inject defaults before creating the mock tool.

### `mustIncludeParams` must use the tool's actual parameter name

Match the tool's `inputSchema` field names, not the eval's input field name. E.g. `taskQuery` accepts `query`, not
`request`.

## Pattern Mocks: Input-Conditional Responses

If a tool mock has both `patterns` (array) and `default` keys, the framework uses `createEvalPatternMockTool`.

### YAML syntax

```yaml
mockTools:
  documentLookup:
    patterns:
      - when:
          query: { isNotNull: true }
        response:
          success: true
          mode: "discover"
          documents: [{ id: "wc-001", title: "Sprint Notes" }]
          # ... all outputSchema fields
        label: "discover"
      # additional patterns for other modes...
    default:
      success: true
      mode: "discover"
      documents: []
      workContext: null
      totalCount: 0
      message: "No results"
      # ... all outputSchema fields
```

### Condition operators

| Operator           | Matches when                       |
| ------------------ | ---------------------------------- |
| `isNotNull: true`  | Field present and not null         |
| `isNull: true`     | Field null, undefined, or absent   |
| `contains: "str"`  | Substring match (case-insensitive) |
| `equals: value`    | Exact equality                     |
| `matches: "regex"` | Regex test on string field         |

Multiple keys in `when` are AND-ed. `responsePatcher` from `agentFactory` auto-applies to pattern responses.

### One-shot patterns (`once: true`)

`once: true` makes a pattern fire only on its first match; subsequent matches fall through to `default`. Prevents
looping on rephrased queries.

### When to use

- **Static**: Tools called once or same response always correct.
- **Pattern (no `once`)**: Multi-modal tools with distinct input shapes.
- **Pattern with `once: true`**: Single-mode query tools where the agent might rephrase.

## Loop Guard and Finalization

The eval runner aborts when the agent calls the same tool with identical arguments 3+ times. Scoring proceeds with
whatever output exists.

**Finalization pass:** When an agent with `structuredOutput` exhausts `maxSteps` or is aborted, the runner makes one
additional `agent.generate()` call (`maxSteps: 1`) to synthesize findings into scorable output.

**`maxSteps` priority:** `fixture.metadata.maxSteps` > `config.maxSteps` > default (10). Only increase beyond 10 for
fixtures requiring many distinct tool calls. Keep `maxSteps` at 10 by default — the loop guard catches infinite loops.

## Eval File Structure

```
evals/<evalName>/
├── index.ts        # Agent factory, config export, scorer re-exports
├── types.ts        # Input/output types (optional)
├── scorers/        # Scoring functions
└── fixtures/       # YAML test fixtures organized by category
```

### Active eval suites

See context.md for the project-specific list of eval suites and agents.

## Running Evals

See context.md for the exact run commands for your project.

### Interpreting results

- **Pass:** All scorers above `passingThreshold` (default 0.7).
- **0ms / 0% / no scorer output:** Mock data schema validation failed — check `outputSchema` vs YAML.
- **"duplicate tool call detected":** Agent looped 3+ times. Needs pattern mocks or prompt refinement.
- **`Raw Agent Output: ""`:** `maxSteps` exhausted and finalization failed.
- **Low `tool-strategy`:** LLM judge found suboptimal tool selection.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
