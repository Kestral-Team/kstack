# Analysis Criteria

Full red-flag lists for the Step 2 analysis tests in [SKILL.md](SKILL.md).

## Specificity test

Does the prompt change introduce language that mirrors the **exact phrasing, entities, or scenarios** found in eval
fixtures or in a specific bug report? Red flags:

- **Fixture-echo**: The prompt now mentions specific entity names, tool names, parameter patterns, or decision sequences
  that appear verbatim in new or modified fixtures
- **Bug-echo**: The prompt adds a rule whose wording tracks one reported failure — the exact user phrasing, entity type,
  or tool sequence from the repro — instead of the underlying principle that would also catch neighboring cases
- **Narrow branching**: The prompt adds a conditional behavior ("when the user asks about X, always do Y") that maps 1:1
  to a fixture scenario or a single bug report rather than describing a general principle
- **Keyword stuffing**: The prompt repeats specific phrases that a scorer is likely pattern-matching on
- **Score-chasing qualifiers**: Adding hedging language ("make sure to", "always remember to", "it is critical that")
  around behaviors that only matter for eval scoring, not real users

## Generality test

A good prompt change should satisfy at least one of:

- **Describes a general principle** that applies across many user interactions, not just one eval scenario or one
  reported bug
- **Fixes a class of failures** rather than one reproduction case — ask "what is the smallest general rule that would
  have prevented this bug?" and check the change states that rule, not the repro steps
- **Simplifies or clarifies** existing instructions without adding new conditional paths
- **Removes or consolidates** redundant instructions

## Proportionality test

Compare the ratio of prompt changes to eval changes:

- If the branch adds/modifies many eval fixtures but only tweaks prompts to pass those specific fixtures, that's
  evalmaxxing
- If the branch changes prompts and adds evals that *test the general behavior the prompt enables*, that's healthy
- If the branch changes prompts without any eval changes, flag it as untested — it can still be bug hyperfixation per
  the specificity and generality tests

## Eval fixture quality

Also check whether the eval fixtures themselves are overfitted:

- **Trivially passable**: Fixtures that test obvious behavior any reasonable prompt would handle
- **Unrealistically narrow**: Fixtures with mock data so tailored that only one specific prompt phrasing would pass
- **Instructional fixture content**: Source document/body content includes meta notes, reminders, comments, headings, or
  placeholder text that cue the behavior being evaluated instead of representing plausible user data. That should be
  replaced with unrelated realistic content.
- **Missing negative cases**: Only happy-path fixtures without adversarial or ambiguous inputs
- **Scorer brittleness**: Scorers that check for exact string matches or rigid output structure rather than semantic
  correctness
- **Semantic IDs**: Mock entity IDs that contain descriptive or domain-relevant content instead of opaque identifiers.
  IDs like `wc-folder-q4-status` or `wc-status-updates-folder` leak semantic hints the agent can exploit to pick the
  "right" entity without truly understanding the query. All mock IDs should be opaque (e.g. `wc-1`, `folder-2`,
  `task-101`, `proj-001`, `doc-3`). This applies to every `id`, `parentId`, `projectId`, `assigneeId`, `createdById`,
  `workContextId`, or similar identifier field in `mockTools` data. The only exception is IDs that are self-referencing
  constants unrelated to the fixture scenario (e.g. `current-user-id`, `test-workspace`).
- **Exact-casing queries**: The user's input query uses the exact same casing as mock entity titles/names. In real
  usage, users frequently type in lowercase or inconsistent casing (e.g. "product specs" when the entity is named
  "Product Specs"). Fixture queries should use different capitalization than mock entities to test that the agent and
  tool chain handle fuzzy matching rather than relying on exact string equality.
- **Missing confounders**: Lookup tool mock responses return only the target entity with no distractors. In a real
  workspace, queries return multiple results — some relevant, some not. Mock tool responses should include at least one
  confounding entity (similar name, same type, or overlapping domain) so the eval tests the agent's ability to
  disambiguate and select the correct entity from a realistic result set.

## Scorer specificity test

Also check whether changed scorers are overfitted to a particular fixture rather than the general behavior:

- **Fixture-shaped rubric**: The scorer prompt names the exact concepts, entities, or sequence from one fixture instead
  of describing the capability in domain-agnostic terms
- **Example leakage**: "For example" guidance in the scorer effectively reproduces the target fixture's expected answer
- **Single-scenario anchoring**: The scorer assumes one workflow, one tool path, or one domain even though the eval type
  should support multiple scenarios
- **Hidden evalmaxxing**: No production prompt changed, but the scorer was rewritten so the fixture now grades highly
  for the existing behavior

## Prompt scope and bloat test

Eval work tends to grow prompts: the easiest way to pass a fixture is to spell out the exact behavior in worked examples
and reminders. That is evalmaxxing even when the example data does not literally mirror a fixture.

Apply the Mode 1 Compression Rules from [SKILL.md](SKILL.md) to every new rule/section in the diff. Compress toward:

```
**<Behavior name>:** <one declarative sentence stating what the agent must do>.
<optional: one sentence stating the failure mode to avoid, no backstory>.
<optional: one minimal JSON or markdown example, only if the shape cannot be conveyed in prose>.
```

Red flags beyond the compression rules:

- **Fixture-shaped example data.** Worked examples whose row shape, column count, section headings, or instruction
  phrasing mirror a specific fixture's shape (even with renamed entities). Double-suspicious: bloats the prompt AND
  nudges toward fixture passage.
- **Post-mortem clarifications.** Parenthetical sub-rules that read as failure post-mortems — from a fixture or a bug
  report — pasted into the prompt (e.g., "X is for Y, not for Z"). Strip down to the actual rule.

How to measure:

- Run `git --no-pager diff "$DIFF_BASE"...HEAD --stat -- <prompt-files>` and note lines added per prompt file.
- Walk each new rule/section in the diff and count its line cost. If a single rule costs more than ~10–15 lines, ask:
  "Could this be one sentence? Is the worked example load-bearing?"
- Read the latest 1–2 commits on each touched prompt file (`git --no-pager log --oneline -- <file> | head -10`, then
  `git --no-pager show <commit> -- <file>`). If a recent commit compressed earlier prose into terse rules, apply that
  terseness as the bar for the rest of the diff.
- Surviving prior cleanup passes does not certify a section as well-sized; the cleanup may simply not have reached it
  yet.
