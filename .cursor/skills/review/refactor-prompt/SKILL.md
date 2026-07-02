---
name: refactor-prompt
description: >-
  Compress agent instruction/prompt files for minimal token cost while preserving behavioral coverage.
  Also detects evalmaxxing — prompt changes overfitted to eval fixtures or to one specific reported bug
  rather than genuine behavior improvements. Use when the user asks to refactor, compress, shorten, or
  optimize agent prompts, check for evalmaxxing, or review a branch that modifies prompts, eval fixtures,
  or both.
---

# Refactor Prompt

Two modes for agent prompt quality:

1. **Compress** (default) — reduce token cost while preserving behavioral coverage
2. **Detect evalmaxxing** — find prompt changes tailored to pass eval fixtures or patch one specific bug rather than
   improving real behavior

---

## Mode 1: Compress

Refactor agent prompt/instruction files. Every line in these files is paid for on every production call. The goal is to
preserve behavioral coverage while cutting token cost.

### Scope

Default: the file(s) the user specifies (via @-mention or description).

If no file is specified, find changed prompt surfaces on this branch:

```bash
DIFF_BASE=$(gt parent --no-interactive 2>/dev/null || echo "main")
git --no-pager diff "$DIFF_BASE"...HEAD --name-only \
  | rg '(Instruction|Prompt|instruction|prompt).*\.(md|ts)$'
```

Narrow the file pattern per project convention (see context.md for project-specific paths).

Read each file in full before making changes.

### Compression Rules

Apply these in order of impact:

1. **One rule = one sentence.** A behavioral rule should be one declarative sentence stating what the agent must do,
   plus optionally one sentence stating the failure to avoid. If a rule takes more than ~5 lines, it is bloated.

2. **Kill worked examples unless structural.** WRONG/CORRECT pairs, multi-row tables, and numbered scenario walkthroughs
   are justified only when the rule is about a precise output shape (JSON format, anchor syntax) that cannot be conveyed
   in prose, covers a real edge case, or replaces many lines of rules. Even then, keep one minimal example.

3. **Collapse duplicate rules.** If two sections say the same thing at different granularities, keep the more concise
   one and delete the other. Cross-reference with `per §N` instead of restating.

4. **Preserve useful structure.** Keep boundaries that separate goals, constraints, context, examples, output formats,
   and stop rules; compress within those sections before merging them.

5. **Strip narrative framing.** Remove paragraphs that explain when the rule applies, what the user might say, what the
   agent might be tempted to do, and why the wrong thing is wrong. The agent needs the rule, not the backstory.

6. **Prefer positive, specific rules.** Replace long negative lists with the desired behavior; reserve `always`,
   `never`, `must`, and `only` for safety, tool-use, output-format, or production invariants.

7. **Remove score-chasing meta-reminders.** Lines like "Re-read the instruction before finishing", "Self-check before
   any X", "make sure to", and "always remember to" are failure post-mortems (fixture or bug report) pasted into
   prompts; preserve imperative wording when it carries a real production invariant.

8. **Merge sub-sections that cover one anti-pattern.** A new `###` section for a single behavioral rule is almost always
   bloat. Fold it into the relevant existing section as a bullet or sentence.

9. **Prefer terse enumerations.** Instead of a paragraph per checklist item, use a compact numbered list where each item
   is one line.

### What to Preserve

- Rules that describe general principles applying across many user interactions
- Structural output format specifications (JSON shape, entity-embed syntax)
- Tool-routing tables and classification logic
- Section boundaries that keep instructions, context, examples, output format, and stop rules unambiguous
- Cross-references to other sections (`per §N`)
- Any rule the agent demonstrably needs to avoid a real production failure (not just an eval fixture)

### Process

1. Read the target file(s) in full.
2. Identify each rule/section that violates the compression rules above.
3. Propose the full set of compressions as a summary before making changes.
4. Apply changes one section at a time, preserving surrounding context.
5. Check that no success criteria, tool-routing rules, output formats, or stop conditions were removed or buried.
6. When relevant evals exist, run or recommend the focused evals that cover the changed behavior.
7. Count lines before and after; report the delta.

Do not change rules that are already concise. Do not add new rules or behaviors.

---

## Mode 2: Detect Evalmaxxing

Analyze the current branch for evalmaxxing — prompt/instruction changes overfitted to a single observed failure rather
than genuinely improving agent behavior. The failure source can be an eval fixture or a specific reported bug: both
produce the same anti-pattern of hyperfixated rules that don't generalize.

### Scope

- Analyze the full branch diff (default)
- Analyze only uncommitted changes (when user specifies)

```bash
DIFF_BASE=$(gt parent --no-interactive 2>/dev/null || echo "main")
git --no-pager diff "$DIFF_BASE"...HEAD
```

### Step 1: Categorize changed files

Partition the diff into three buckets:

**Prompt changes** — files containing agent instructions or system prompts (instruction markdown, agent config files,
tool descriptions). See context.md for project-specific file patterns.

**Eval changes** — files related to the eval framework (test fixtures, scoring logic, eval configs). See context.md for
project-specific file patterns.

**Scorer prompt changes** — within changed scorer files, look for evaluator prompt or rubric text.

If there are **no prompt changes** and **no scorer prompt changes**, report that and stop.

Read the full content of every changed prompt file, eval fixture, and scorer file. Also pull:

- Lines added per prompt file: `git --no-pager diff "$DIFF_BASE"...HEAD --stat -- <prompt-files>`
- Recent prompt history: `git --no-pager log --oneline -- <prompt-file> | head -10`

### Step 2: Apply Analysis Tests

Read [analysis-criteria.md](analysis-criteria.md) for the full red-flag lists, then apply each test to every prompt
change and scorer prompt change:

- **Specificity** — does the prompt mirror exact phrasing/entities/scenarios from eval fixtures or a specific bug
  report?
- **Generality** — does the change state a general principle, fix a real gap, or simplify? A rule that only restates one
  failure's reproduction steps is bug hyperfixation, not a fix. If none apply, suspicious.
- **Proportionality** — many fixture changes + prompt tweaks to pass them = evalmaxxing. Prompt changes without evals =
  untested (flag separately).
- **Eval fixture quality** — trivial fixtures, narrow mocks, instructional fixture content, semantic IDs, exact-casing
  queries, missing confounders/negative cases, scorer brittleness.
- **Scorer specificity** — fixture-shaped rubrics, example leakage, single-scenario anchoring, scorer rewrites that hide
  evalmaxxing.
- **Prompt bloat** — apply the Compression Rules from Mode 1 to the diff; prompt bloat is a form of evalmaxxing even
  when example data doesn't literally mirror a fixture.

### Step 3: Report

```markdown
### Summary

[One paragraph: overall assessment and severity]

### Prompt Changes Analyzed

For each changed prompt/scorer file:

- **File**: path
- **What changed**: brief description
- **Type**: `production prompt` | `scorer prompt`
- **Verdict**: `clean` | `suspicious` | `evalmaxxing`
- **Evidence**: specific lines and correlated fixtures (if suspicious/evalmaxxing)

### Eval Quality

[Quality concerns with fixtures or scorers if they were also changed]

### Recommendations

[Concrete suggestions — rewrite as general principle, broaden fixtures, add confounders, compress, etc.]
```

Keep the report concise. Only flag real issues.

---

## Project Context

Read [`context.md`](./context.md) and apply it as additional project-specific constraints layered on top of this
workflow. If it does not exist, skip this section.
