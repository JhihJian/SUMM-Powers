---
name: goal-loop
description: Use when pursuing an improvement goal through iterative refinement — each iteration picks one highest-value improvement, executes it, and self-evaluates. For goals like "improve code quality", "fix all lint warnings", "raise test coverage to 80%". Not for full delivery pipelines (use the brainstorming → writing-plans → subagent-driven-development pipeline) or one-shot tasks (use summ:to-do-it).
---

# Goal Loop: Iterative Goal-Driven Improvement

## Overview

Goal Loop is a goal-driven continuous improvement skill. You receive a high-level goal from the user, then iterate in a single session: each round assesses the current state, picks the single highest-value improvement item, executes it, and self-evaluates. The loop ends when the goal is met or the iteration limit is reached.

**Core principle: one improvement per iteration.** Never batch changes. This prevents scope creep and keeps every commit atomic and reviewable.

**Positioning:** Between the full delivery pipeline (`brainstorming` → `writing-plans` → `subagent-driven-development`) and `summ:to-do-it` (one-shot tasks). Use goal-loop when you have a clear goal but no need for the full spec-to-delivery workflow.

## When to Use

**Use for:**
- "Improve code quality across the project"
- "Fix all lint warnings"
- "Raise test coverage to 80%"
- "Optimize API performance"
- "Clean up technical debt in module X"
- Any goal requiring multiple small improvements in a single session

**NOT for:**
- Building a new feature from scratch → use the brainstorming → writing-plans → subagent-driven-development pipeline
- A single small task with known solution → use `summ:to-do-it`
- Debugging a specific issue → use `summ:systematic-debugging`
- Brainstorming a design → use `summ:brainstorming`

## Parameters

```
/goal-loop <goal> [--max-iterations N]
```

- **`<goal>`** (required): Goal description in natural language. Copied verbatim into the state file and never modified.
- **`--max-iterations`** (optional): Maximum number of iterations. Default: **10**.

## Pre-flight Check

**Silent by default.** Do not announce these checks to the user. Only speak up if a conflict is found.

1. **Check for active implementation plans** — scan `docs/superpowers/plans/` for plan files. If none found, proceed silently. If found, warn the user and ask whether to proceed or cancel.

2. **Check for existing goal-loop state** — check `.claude/goal-loop-state.md`. If absent or status is `COMPLETED`/`ABORTED`, proceed silently with a fresh state file. If status is `ACTIVE`, ask the user whether to resume or restart.

No output, no logging, no "checking..." messages unless a conflict is detected.

## The Loop

```
┌─────────────────────────────────────────────────────┐
│                  PRE-FLIGHT CHECK                   │
│         (active plan conflict? existing state?)        │
└─────────────────────┬───────────────────────────────┘
                      │
                      v
┌─────────────────────────────────────────────────────┐
│  STEP 1: Read/Write State File                      │
│  Create on first iteration, read on subsequent      │
└─────────────────────┬───────────────────────────────┘
                      │
                      v
┌─────────────────────────────────────────────────────┐
│  STEP 2: Assess Current State                       │
│  Scan codebase, update backlog, discover new items  │
└─────────────────────┬───────────────────────────────┘
                      │
                      v
┌─────────────────────────────────────────────────────┐
│  STEP 3: Self-Evaluation                            │
│  Goal met? No side effects? Worth continuing?       │
│  ALL pass → COMPLETED                               │
└─────────────────────┬───────────────────────────────┘
                      │ any fails
                      v
┌─────────────────────────────────────────────────────┐
│  STEP 4: Pick Improvement Item                      │
│  Single highest-priority item from backlog          │
└─────────────────────┬───────────────────────────────┘
                      │
                      v
┌─────────────────────────────────────────────────────┐
│  STEP 5: Execute                                    │
│  Load mapped skill, execute in current session      │
│  Commit changes                                     │
└─────────────────────┬───────────────────────────────┘
                      │
                      v
┌─────────────────────────────────────────────────────┐
│  STEP 6: Record Results                             │
│  Update state file: iteration count, backlog,       │
│  history                                            │
└─────────────────────┬───────────────────────────────┘
                      │
                      v
┌─────────────────────────────────────────────────────┐
│  STEP 7: Check Iteration Limit                      │
│  Under limit → back to STEP 1                       │
│  At limit → ABORTED with progress summary           │
└─────────────────────────────────────────────────────┘
```

## Step-by-Step Instructions

### Step 1: Read/Write State File

**State file path:** `.claude/goal-loop-state.md`

**First iteration:** Create the file using the template from `skills/goal-loop/state-schema.md`:

```markdown
# Goal Loop State

## Goal
<user-provided goal text, copied verbatim>

## Status: ACTIVE

## Iteration: 0/<max-iterations>

## Improvement Backlog
<!-- To be populated during Step 2 -->

## Iteration History
```

**Subsequent iterations:** Read the existing state file. Use it to restore context — the state file is the single source of truth. This ensures continuity even after context compaction.

### Step 2: Assess Current State

Scan the codebase against the goal. How you scan depends on the goal's domain:

- Code quality: run linters, check complexity metrics, review test coverage
- Performance: profile, benchmark, identify bottlenecks
- Test coverage: run coverage tools, identify gaps
- Architecture: review module structure, dependency graphs, coupling

**Update the improvement backlog:**
1. Re-prioritize existing items based on current state
2. Add newly discovered improvement items
3. Remove items that are no longer relevant
4. Mark completed items as `[x]` with `(iter N)` annotation

**If assessment finds no improvements needed:** skip to Step 3 with an empty backlog. The self-evaluation will detect that the goal is already met.

### Step 3: Self-Evaluation

Answer three questions honestly. **ALL must pass** to mark COMPLETED.

| # | Question | Pass Criteria |
|---|----------|---------------|
| 1 | **Goal met?** | The user's original goal (from the state file) is fully satisfied. |
| 2 | **No side effects?** | Improvements made during the loop have not introduced new problems (tests pass, no regressions, no broken functionality). |
| 3 | **Worth continuing?** | Another iteration would produce meaningful improvement toward the goal. |

**Results:**

- **ALL pass** → Mark status `COMPLETED`. Go to **Completion Promise**.
- **Question 1 fails, backlog empty** → Mark status `COMPLETED`. The goal may be partially met; document what was achieved and what remains.
- **Any fails, backlog has items** → Continue to Step 4.
- **Any fails, backlog empty** → Mark status `COMPLETED`. Document what was achieved and any remaining gaps.

### Step 4: Pick Improvement Item

Select the **single highest-priority item** from the backlog. Do not batch.

Determine which SUMM skill to load using this mapping table:

| Item type | Skill to load |
|-----------|---------------|
| Architecture / structure improvement | `summ:improve-architecture` |
| Feature addition or bug fix | `summ:test-driven-development` |
| Debugging an issue | `summ:systematic-debugging` |
| Code review needed | `summ:requesting-code-review` |
| Small, straightforward change | `summ:to-do-it` |
| Unclear | Judge based on context — default to `summ:to-do-it` |

The mapping is a guide, not a rule. Use judgment: if an architecture item is actually a small rename, `summ:to-do-it` is the right call.

### Step 5: Execute

1. Load the selected skill via the **Skill tool** (e.g., `summ:test-driven-development`).
2. Execute the improvement **in the current session**. Do not spawn subagents — goal-loop executes directly.
3. After the improvement is complete, **commit the changes** with a descriptive message:
   ```
   goal-loop(iter N): <brief description of what was improved>
   ```
   Ensure the commit is atomic — one logical change per iteration.

### Step 6: Record Results

Update the state file (`.claude/goal-loop-state.md`):

1. **Increment iteration count:** `Iteration: N+1/<max-iterations>`
2. **Mark the backlog item** as completed: `- [x] <item> (iter N)`
3. **Append iteration history:**
   ```markdown
   ### Iteration N — <one-line summary>
   - Action: <what was done>
   - Skill used: summ:<skill-name>
   - Result: <outcome summary>
   - Files changed: <list of modified/created files>
   ```
4. **Write the file** — this ensures the state survives context compaction.

### Step 7: Check Iteration Limit

Compare current iteration count against `--max-iterations`.

- **Under the limit** → Loop back to **Step 1** (read the state file you just wrote).
- **At or over the limit** → Mark status `ABORTED`. Output a summary:
  1. What was achieved (completed backlog items)
  2. What remains (remaining backlog items)
  3. Guidance: re-run with a refined goal, or with `--max-iterations` set higher, or manually execute remaining items

**Do not discard progress.** Every completed item is committed and recorded.

## Completion Promise

When self-evaluation passes (Step 3, all criteria met), output:

```xml
<goal-loop-complete>
Goal achieved: <one-sentence summary>
Total iterations: N
Key improvements:
- <improvement 1>
- <improvement 2>
- ...
State file: .claude/goal-loop-state.md
</goal-loop-complete>
```

## Behavior Constraints

These constraints are non-negotiable. Violating any of them violates the skill.

| Constraint | Reason |
|-----------|--------|
| **One improvement item per iteration** | Prevents scope creep. Keeps commits atomic. |
| **One commit per iteration** | Every iteration produces a reviewable, revertable change. |
| **State file updated every iteration** | Ensures continuity after context compaction. The state file is the single source of truth. |
| **Honest self-evaluation** | Do not mark COMPLETED unless the goal is genuinely met. Do not skip side-effect checks. |
| **No scope expansion** | Never add work outside the user's original goal. "While I'm here" improvements are forbidden. |
| **Never modify the goal** | The goal in the state file is the user's verbatim input. It anchors every self-evaluation. |
| **Never delete past iteration history** | The iteration history is append-only. It provides an audit trail. |

## Aborting Early

In addition to hitting the iteration limit, abort if:

- **The goal is fundamentally unachievable** — e.g., the goal references a module that does not exist and cannot be created within the skill's scope.
- **A dependency is missing** — e.g., the goal requires a tool or library that is not installed and cannot be installed.

When aborting for these reasons:

1. Mark status `ABORTED` in the state file.
2. Document the reason clearly.
3. Output what was achieved and why the goal cannot be completed.
4. Suggest next steps (install dependencies, refine the goal, etc.).
