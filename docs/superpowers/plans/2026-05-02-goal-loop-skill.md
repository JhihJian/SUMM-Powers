# Goal Loop Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summ:subagent-driven-development (recommended) or summ:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the goal-loop skill — a goal-driven iterative improvement skill that takes a high-level goal and loops through analyze→execute→evaluate cycles until self-assessment determines the goal is met.

**Architecture:** Single SKILL.md defines the iterative loop logic with state file persistence. A state-schema.md provides the template. A commands/goal-loop.md provides the slash command entry point. The skill is pure documentation (no scripts) — the agent reads SKILL.md and follows the process.

**Tech Stack:** Markdown skill definitions following SUMM-Powers conventions.

**Spec:** `docs/superpowers/specs/2026-05-02-goal-loop-design.md`

---

## File Structure

| File | Responsibility |
|------|---------------|
| `skills/goal-loop/state-schema.md` | State file template — defines the `.claude/goal-loop-state.md` format that the skill reads/writes each iteration |
| `skills/goal-loop/pressure-test-scenarios.md` | Test scenarios — edge cases that verify the skill handles all loop conditions correctly |
| `skills/goal-loop/SKILL.md` | Core skill definition — the iterative loop process, self-evaluation criteria, skill mapping, and behavior constraints |
| `commands/goal-loop.md` | Slash command — triggers the skill with goal parameter and optional `--max-iterations` |

---

## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Create state schema template | `skills/goal-loop/state-schema.md` | S | Pure template, no logic |
| 2 | Write pressure test scenarios | `skills/goal-loop/pressure-test-scenarios.md` | M | "TDD for skills" — write scenarios before SKILL.md |
| 3 | Create SKILL.md | `skills/goal-loop/SKILL.md` | L | Core skill definition, the main deliverable |
| 4 | Create slash command | `commands/goal-loop.md` | S | 3-line command wrapper |
| 5 | Validate and commit | all files | S | Verify skill loads, commit |

---

### Batch 1 (Tasks 1-2)

### Task 1: Create state schema template

**Files:**
- Create: `skills/goal-loop/state-schema.md`

- [ ] **Step 1: Create the state schema file**

Create `skills/goal-loop/state-schema.md` with the following content:

```markdown
# Goal Loop State File Schema

This file defines the format for `.claude/goal-loop-state.md`, which the goal-loop skill reads and writes each iteration.

## Template

```markdown
# Goal Loop State

## Goal
<user-provided goal text, copied verbatim from command>

## Status: ACTIVE
<!-- One of: ACTIVE | COMPLETED | ABORTED -->

## Iteration: 1/<max-iterations>
<!-- Increment the first number each iteration -->

## Improvement Backlog
<!-- Ordered by priority (highest first). Mark [x] when completed. -->
- [ ] <improvement item description>

## Iteration History
<!-- Add a new section after each iteration. -->
### Iteration N — <one-line summary>
- Action: <what was done>
- Skill used: summ:<skill-name>
- Result: <outcome summary>
- Files changed: <list of modified/created files>
```

## Field Rules

- **Goal**: Never modify after initialization. This is the anchor for self-evaluation.
- **Status**: Only transitions forward: ACTIVE → COMPLETED or ACTIVE → ABORTED. Never back to ACTIVE.
- **Iteration**: Format is `current/max`. Increment current by 1 after each iteration. Never modify max.
- **Improvement Backlog**: Re-prioritize each iteration. Add new items discovered during assessment. Remove items that became irrelevant. Mark `[x]` for completed items with `(iter N)` annotation.
- **Iteration History**: Append-only. Never edit past iterations.
```

- [ ] **Step 2: Verify the file exists**

Run: `cat skills/goal-loop/state-schema.md | head -5`
Expected: Shows the file header starting with "# Goal Loop State File Schema"

- [ ] **Step 3: Commit**

```bash
git add skills/goal-loop/state-schema.md
git commit -m "feat(goal-loop): add state file schema template"
```

---

### Task 2: Write pressure test scenarios

**Files:**
- Create: `skills/goal-loop/pressure-test-scenarios.md`

- [ ] **Step 1: Create the pressure test scenarios file**

Create `skills/goal-loop/pressure-test-scenarios.md` with the following content:

```markdown
# Goal Loop Pressure Test Scenarios

These scenarios verify the goal-loop skill handles all loop conditions correctly. Each scenario describes a situation and the expected agent behavior.

## Scenario 1: Happy path — goal achieved in 3 iterations

**Situation:** User runs `/goal-loop "Fix all lint warnings in the project"` with `--max-iterations 10`. The project has lint warnings that can be fixed in 3 rounds.

**Expected behavior:**
1. Iteration 1: Agent discovers 23 warnings, creates backlog with 3 items (categorized), picks highest priority, fixes 12 warnings.
2. Iteration 2: Re-assesses, picks next item, fixes remaining 8 warnings.
3. Iteration 3: Re-assesses, picks last item, fixes last 3 warnings. Self-evaluation passes all 3 criteria. Status → COMPLETED. Outputs `<goal-loop-complete>` promise.

**Verify:** State file shows Status: COMPLETED, Iteration: 3/10, all backlog items checked, 3 iteration history entries.

## Scenario 2: Iteration limit reached

**Situation:** User runs `/goal-loop "Refactor the entire frontend architecture"` with `--max-iterations 5`. The goal is too large for 5 iterations.

**Expected behavior:**
1. Each iteration makes progress on one improvement item.
2. After iteration 5, self-evaluation determines goal is NOT met, but iteration count equals max.
3. Status → ABORTED (NOT COMPLETED).
4. Agent outputs current progress summary and remaining backlog items.
5. Agent does NOT discard or delete the state file — user can resume later.

**Verify:** State file shows Status: ABORTED, all 5 history entries present, backlog still has unchecked items.

## Scenario 3: Self-evaluation catches new problem introduced by improvement

**Situation:** During iteration 2, the agent refactors a module but accidentally breaks tests. Self-evaluation criterion 2 (no side effects) fails.

**Expected behavior:**
1. Agent detects the broken tests during self-evaluation.
2. Agent does NOT mark as COMPLETED.
3. Agent adds "Fix broken tests from refactor" to the backlog as high priority.
4. Next iteration picks this item and fixes it.
5. Only after fixing does self-evaluation pass all 3 criteria.

**Verify:** Backlog shows the fix item added mid-loop, iteration history documents the issue.

## Scenario 4: Backlog evolves — new items discovered

**Situation:** Goal is "Improve code quality". During iteration 1 (fixing lint), agent discovers the project has no test coverage.

**Expected behavior:**
1. Agent finishes iteration 1 (lint fixes) — one item per iteration.
2. During next assessment phase, agent adds "Add unit tests" to backlog.
3. Backlog is re-prioritized — agent may decide tests are higher priority than remaining lint issues.
4. Agent picks the highest priority item (which may be the newly discovered one).

**Verify:** Backlog grows over iterations, priority order changes between iterations.

## Scenario 5: Goal is already met at start

**Situation:** User runs `/goal-loop "Fix all lint warnings"` but the project has zero lint warnings.

**Expected behavior:**
1. Initial assessment finds no improvements needed.
2. Self-evaluation passes all 3 criteria immediately.
3. Status → COMPLETED with Iteration: 1/10.
4. Outputs `<goal-loop-complete>` with "Goal already met, no changes needed."

**Verify:** State file shows COMPLETED in iteration 1, empty backlog, single history entry noting no work needed.

## Scenario 6: Multiple goals in one statement

**Situation:** User runs `/goal-loop "Fix lint warnings and add tests and improve documentation"`. This is actually 3 goals in one.

**Expected behavior:**
1. Agent treats the full text as a single compound goal (no splitting).
2. Initial backlog includes items for all three areas.
3. Each iteration works on one item from any area.
4. Self-evaluation checks against the full compound goal.
5. Only completes when ALL aspects of the compound goal are addressed.

**Verify:** Backlog spans multiple areas, iteration history shows work across domains.

## Scenario 7: Skill correctly selects appropriate SUMM skill

**Situation:** During backlog prioritization, items include: "Refactor module X" (architecture), "Fix bug in Y" (debugging), "Add feature Z" (TDD).

**Expected behavior:**
1. "Refactor module X" → agent loads `summ:improve-architecture`
2. "Fix bug in Y" → agent loads `summ:systematic-debugging` then `summ:test-driven-development`
3. "Add feature Z" → agent loads `summ:test-driven-development`
4. Each iteration loads exactly one skill before executing.

**Verify:** Each iteration history entry records which skill was used.

## Scenario 8: State file persists across context compaction

**Situation:** Running a long goal-loop (8+ iterations). Context window gets compacted mid-session.

**Expected behavior:**
1. Agent reads state file at the start of each iteration to restore context.
2. After compaction, the next iteration reads the state file and continues correctly.
3. No iteration history is lost — it's in the state file, not just in conversation memory.
4. Backlog state is reconstructed from file, not from memory.

**Verify:** The loop continues correctly after compaction because all state is in the file.

## Scenario 9: User provides no --max-iterations

**Situation:** `/goal-loop "Clean up dead code"` with no iteration limit specified.

**Expected behavior:**
1. Default max-iterations = 10.
2. State file shows Iteration: N/10.
3. Behavior identical to explicitly specifying `--max-iterations 10`.

**Verify:** State file and behavior match the default.

## Scenario 10: Conflict with active dev-loop plan

**Situation:** `docs/superpowers/plans/` contains an active implementation plan from dev-loop. User then runs goal-loop.

**Expected behavior:**
1. Skill checks for active plans in `docs/superpowers/plans/`.
2. If found, warns user: "Active dev-loop plan detected. Consider completing it first to avoid conflicts."
3. Asks user whether to proceed anyway.
4. If user proceeds, continues normally.
5. If user declines, stops without creating state file.

**Verify:** Warning is issued before any state file creation or iteration begins.
```

- [ ] **Step 2: Verify the file exists**

Run: `cat skills/goal-loop/pressure-test-scenarios.md | head -5`
Expected: Shows the file header starting with "# Goal Loop Pressure Test Scenarios"

- [ ] **Step 3: Commit**

```bash
git add skills/goal-loop/pressure-test-scenarios.md
git commit -m "test(goal-loop): add pressure test scenarios"
```

---

### Batch 2 (Task 3)

### Task 3: Create SKILL.md

**Files:**
- Create: `skills/goal-loop/SKILL.md`

This is the core deliverable. The SKILL.md must cover:
1. YAML frontmatter (name, description)
2. Overview and when to use / not use
3. Trigger and parameters
4. The iterative loop process (7 steps per iteration)
5. Self-evaluation criteria (3 questions)
6. Skill mapping table
7. Completion promise format
8. Behavior constraints
9. Conflict detection with dev-loop

- [ ] **Step 1: Create SKILL.md**

Create `skills/goal-loop/SKILL.md` with the following content:

```markdown
---
name: goal-loop
description: Use when given a high-level improvement goal (e.g. "optimize code quality", "improve UI", "increase test coverage") — iterates analyze→execute→evaluate cycles until self-assessment confirms the goal is met or iteration limit is reached
---

# goal-loop: Goal-Driven Iterative Improvement

Given a high-level goal, iterate through assessment→execution→evaluation cycles until the goal is met. Each iteration picks one improvement item, executes it, and evaluates overall progress.

**Input:** A goal statement in natural language. No design spec required.

**Core principle:** One improvement per iteration. Assess globally, act locally, evaluate honestly.

## When to Use

**Use for:**
- Code quality improvements ("reduce tech debt in the auth module")
- Project-wide optimizations ("improve test coverage", "clean up dead code")
- Incremental enhancements ("improve UI responsiveness", "add error handling")
- Any goal that benefits from iterative improvement with self-assessment

**NOT for:**
- Building new features from scratch → use `summ:dev-loop`
- One-off small tasks → use `summ:to-do-it`
- Debugging a specific issue → use `summ:systematic-debugging`
- Design exploration → use `summ:brainstorming`

## Parameters

- **goal** (required): The improvement goal, in natural language
- **--max-iterations** (optional, default: 10): Maximum number of iterations

## Pre-flight Check

Before starting the loop:

1. Check for active dev-loop plans in `docs/superpowers/plans/`. If found, warn: "Active dev-loop plan detected at `<path>`. Running goal-loop concurrently may cause conflicts. Proceed?"
2. If user declines, stop. If user confirms or no plans found, continue.
3. Check for existing state file at `.claude/goal-loop-state.md`. If found with Status: ACTIVE, ask: "Existing goal-loop state found (iteration `<N>/<max>`). Resume or start fresh?"
4. Initialize or resume based on user response.

## The Loop

```
INITIALIZE
  ↓
┌─────────────────────────────┐
│  1. Read/write state file   │
│  2. Assess current state    │◄──────────┐
│  3. Self-evaluation         │           │
│     └─ PASS → COMPLETE      │           │
│     └─ FAIL → continue      │           │
│  4. Pick top backlog item   │           │
│  5. Execute (one item)      │           │
│  6. Record results          │           │
│  7. Check iteration limit   │           │
│     └─ OK → loop back ─────┘           │
│     └─ MAX → ABORT                       │
└─────────────────────────────┘
```

### Step 1: Read/Write State File

**First iteration:** Create `.claude/goal-loop-state.md` using the schema from `skills/goal-loop/state-schema.md`. Set Goal to the user's input, Status to ACTIVE, Iteration to 1/<max>.

**Subsequent iterations:** Read the state file. Extract: goal, current iteration, backlog, history. This restores context even after conversation compaction.

### Step 2: Assess Current State

Analyze the codebase against the goal:

1. **Scan relevant areas** — based on the goal, determine which parts of the codebase to examine. For "improve quality", look at code structure, lint output, test coverage. For "improve UI", look at components, styles, UX patterns.
2. **Evaluate progress** — compare current state against the goal. What's improved? What's still lacking?
3. **Update backlog** — re-prioritize existing items based on new information. Add newly discovered improvement opportunities. Remove items that are no longer relevant.
4. **Be specific** — each backlog item should be actionable: "Refactor the UserAuth class to extract validation logic" not "Improve auth".

### Step 3: Self-Evaluation

Answer these three questions honestly:

1. **Goal met?** — Is the user's original goal fully satisfied? Not "progress made", but "goal achieved".
2. **No side effects?** — Did improvements introduce new problems? Check: tests still pass, no regressions, no new lint errors, no broken functionality.
3. **Worth continuing?** — Would another iteration produce meaningful improvement, or are we at diminishing returns?

**All three pass → COMPLETED.** Write completion promise, update state, stop.
**Any fails → continue to Step 4.** The failing criterion informs what goes into the backlog next.

### Step 4: Pick Improvement Item

From the prioritized backlog, select the **single highest-priority item**.

Determine which SUMM skill to load:

| Item type | Skill to load |
|-----------|--------------|
| Architecture/structure improvement | `summ:improve-architecture` |
| Feature addition or bug fix | `summ:test-driven-development` |
| Debugging an issue | `summ:systematic-debugging` |
| Code review needed | `summ:requesting-code-review` |
| Small, straightforward change | `summ:to-do-it` |
| Unclear | Judge based on context — default to `summ:to-do-it` |

This table is guidance, not law. Use judgment.

### Step 5: Execute

1. Load the selected skill via the Skill tool.
2. Execute the improvement in the current session — no worker dispatch.
3. Follow the loaded skill's process exactly.
4. Commit the changes when done. One commit per iteration.

### Step 6: Record Results

Update `.claude/goal-loop-state.md`:

1. Increment iteration counter.
2. Mark the completed backlog item as `[x]` with `(iter N)`.
3. Append to iteration history: action taken, skill used, result, files changed.
4. If new issues were discovered during execution, add them to the backlog.

### Step 7: Check Iteration Limit

- **iteration < max** → return to Step 2.
- **iteration = max** → set Status to ABORTED. Output:
  - Current progress summary (what was accomplished)
  - Remaining backlog items (what's left)
  - Suggestion for resuming or adjusting the goal

## Completion Promise

When self-evaluation passes, output:

```
<goal-loop-complete>
Goal achieved: <one-sentence summary>
Total iterations: N
Key improvements:
- <improvement 1>
- <improvement 2>
- ...
Files changed: <count> files across <areas>
</goal-loop-complete>
```

## Behavior Constraints

- **One item per iteration** — never batch multiple improvements in one round.
- **One commit per iteration** — atomic changes, easy to roll back.
- **State file every iteration** — ensures recoverability after context compaction.
- **Don't discard on abort** — ABORTED state preserves all progress. User can resume.
- **Self-evaluation is honest** — "progress made" ≠ "goal met". Be rigorous.
- **No scope expansion** — if the goal is "fix lint", don't start refactoring architecture. Stick to what was asked.

## Aborting Early

If at any point the agent determines the goal is fundamentally unachievable (e.g., it requires capabilities outside the current environment, or the goal is too vague to evaluate), set Status to ABORTED and explain why. Suggest what the user could do: refine the goal, break it into smaller pieces, or use a different skill.
```

- [ ] **Step 2: Verify the file structure**

Run: `head -5 skills/goal-loop/SKILL.md`
Expected: Shows YAML frontmatter starting with `---`

- [ ] **Step 3: Validate against pressure test scenarios**

Read `skills/goal-loop/pressure-test-scenarios.md` and mentally walk through each scenario against the SKILL.md to verify the skill handles all cases.

Checklist:
- [ ] Scenario 1 (happy path): Steps 2-3-5-6-7 support 3-iteration completion with promise
- [ ] Scenario 2 (limit reached): Step 7 handles ABORTED correctly
- [ ] Scenario 3 (side effects): Step 3 criterion 2 catches regressions
- [ ] Scenario 4 (evolving backlog): Step 2 re-prioritizes and adds items
- [ ] Scenario 5 (already met): Steps 2-3 pass immediately
- [ ] Scenario 6 (compound goal): Step 2 assesses against full goal text
- [ ] Scenario 7 (skill selection): Step 4 maps to correct skills
- [ ] Scenario 8 (context compaction): Step 1 reads state file each iteration
- [ ] Scenario 9 (no max-iterations): Parameters section specifies default 10
- [ ] Scenario 10 (dev-loop conflict): Pre-flight check handles this

- [ ] **Step 4: Commit**

```bash
git add skills/goal-loop/SKILL.md
git commit -m "feat(goal-loop): add core skill definition"
```

---

### Batch 3 (Tasks 4-5)

### Task 4: Create slash command

**Files:**
- Create: `commands/goal-loop.md`

- [ ] **Step 1: Create the command file**

Create `commands/goal-loop.md` with the following content:

```markdown
---
description: "Use the summ:goal-loop skill for goal-driven iterative improvement — provide a goal and it loops through analyze→execute→evaluate cycles until the goal is met"
---

Invoke the summ:goal-loop skill and follow it exactly as presented to you

ARGUMENTS: The improvement goal in natural language (required), optionally followed by --max-iterations N (default: 10)
```

- [ ] **Step 2: Verify the file**

Run: `cat commands/goal-loop.md`
Expected: Shows YAML frontmatter with description, then skill invocation instruction.

- [ ] **Step 3: Commit**

```bash
git add commands/goal-loop.md
git commit -m "feat(goal-loop): add slash command entry point"
```

---

### Task 5: Validate and final commit

**Files:**
- All goal-loop files

- [ ] **Step 1: Verify complete file structure**

Run: `find skills/goal-loop/ -type f && echo "---" && ls commands/goal-loop.md`
Expected:
```
skills/goal-loop/SKILL.md
skills/goal-loop/state-schema.md
skills/goal-loop/pressure-test-scenarios.md
---
commands/goal-loop.md
```

- [ ] **Step 2: Verify skill loads correctly**

Run: `head -3 skills/goal-loop/SKILL.md`
Expected: Valid YAML frontmatter with `name: goal-loop` and `description` field.

- [ ] **Step 3: Verify state file path is gitignored**

Run: `grep -c '\.claude/' .gitignore`
Expected: 1 or more (`.claude/` is already gitignored, so `.claude/goal-loop-state.md` is covered)

- [ ] **Step 4: Verify command references correct skill name**

Run: `grep 'summ:goal-loop' commands/goal-loop.md`
Expected: Line containing "Invoke the summ:goal-loop skill"

- [ ] **Step 5: Final verification commit (if any uncommitted changes remain)**

```bash
git status
# If clean, no commit needed. If not, commit remaining changes.
```
