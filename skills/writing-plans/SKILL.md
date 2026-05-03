---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans
## Overview
Write comprehensive implementation plans assuming that engineer has zero context in our codebase and questionable taste. Document everything they need to know: which files to touch in each task, code, testing. docs that might need to check, how to test. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume you are a skilled developer, but know almost nothing about our toolset or problem domain. Assume that don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create an implementation plan"

**Context:** This should be run in a dedicated worktree (created by brainstorming skill)

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check
If the spec covers multiple independent subsystems, should have been broken into sub-project specs during brainstorming. If I wasn't, suggest breaking this into separate plans — 1 per subsystem. Each plan should produce working, testable software on its own.

## File Structure
Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility
- Files should be small enough to hold in context at once
- Files that change together should live together. Split by responsibility, not by technical layers.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - only if a file you're modifying has grown unwieldy, including a split in the plan, reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Batch Generation

Always use two-phase generation — even for small plans. This prevents quality degradation and generation interruptions on large plans, and has no downside on small ones.

### Phase 1: Task Index

After the plan header and file structure sections, generate a task index table before any detailed task content:

```markdown
## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Project setup | `package.json`, `tsconfig.json` | S | Init project structure |
| 2 | Data models | `src/models/*.ts` | L | 4 model files, core types |
| 3 | API routes | `src/routes/*.ts` | M | CRUD endpoints |
| ... | ... | ... | ... | ... |

Complexity: S = ~50 lines of task content, M = ~150 lines, L = ~300+ lines
Batch budget: each batch targets ≤ 3M equivalent (1L = 2M = 3S)
```

This forces upfront planning of all tasks before writing any detailed content, and provides complexity estimates that drive batch sizing.

### Phase 2: Batch Generation

Generate detailed task content in dynamically-sized batches based on the complexity budget:

**Batch budget rules:**
- Each batch targets ≤ 3M complexity equivalent
- Equivalence: 1L = 2M = 3S
- Examples: 3M, or 1L+1S, or 1L (alone), or 5S

**Generation flow:**
1. Write plan header (unchanged)
2. Write file structure section (unchanged)
3. Write task index table
4. For each batch:
   - Write `---` separator followed by `### Batch N (Tasks X-Y)` heading
   - Generate full detailed content for each task in the batch
   - Continue immediately to next batch (no user confirmation, no inter-batch review)
5. Run self-review once at the end across all batches
6. Save plan file

**OPTIONAL SUB-SKILL:** Use summ:summ-todo to track plan writing progress

## Task Tracking
When tracking with SUMM-Todo:

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step


## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summ:subagent-driven-development (recommended) or summ:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**


```bash
# Get project name (default from git repo)
PLAN_FILE=$(basename "$PLAN_PATH" .md)
PROJECT=$(git remote get-url origin 2>/dev/null | sed -n 's#.*/\([^/]*\)\.git#\1#p' || \
  basename "$(git rev-parse --show-toplevel 2>/dev/null)" || \
  echo "summ-plans")

# Ensure project exists
todo project show "$PROJECT" 2>/dev/null || todo project add "$PROJECT" -d "Project tasks"
# Create plan task before writing (with project prefix)
TASK_ID=$(todo add "$PROJECT: Write plan - <title>" --pri medium --tag plan)
# Start writing
todo start $TASK_ID
# Complete when plan is saved
todo done $TASK_ID -m "Plan saved to docs/plans/$PLAN_FILE.md"
```
**Keep it simple:** One SUMM-Todo task per plan Task. No dependencies, no parent/child relationships

## Bite-Sized Task Granularity
**Each step is 1 action (2-5 minutes):**
- "Write failing test" - step
- "Run it to make sure it fails" - step
- "Implement minimal code to make test pass" - step
- "Run tests and make sure they pass" - step
- "Commit" - step

## Plan Structure
```
markdown
# [Feature Name] Implementation Plan
Goal / Architecture / Tech Stack
---

## File Structure
(file list and responsibilities)

## Task Index
| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | ... | ... | M | ... |

---

### Batch 1 (Tasks 1-3)

### Task 1: [Component Name]
Description
Files
Tests
Verification

### Task 2: ...
...

---

### Batch 2 (Tasks 4-6)

### Task 4: ...
...
```
Use checkboxes to validate each task and track progress. Present task details after user approval.

## Anti-Pattern: Adding Validation Later
This is the validation at task-level, not during planning. Only at the end.

## Chunk Boundaries
Each chunk should be self-contained and easy to review (~10-50 lines):
- One major logical section (scope, architecture, files)
- One logical section (approach, task breakdown, verification)
- One technical section (commands, dependencies, env setup)

Avoid vague descriptions like "Add tests for X feature" — be specific about what you test

## Key Principles
- **Exact file paths always** - No "update the corresponding files"
- **Complete commands always** - No partial implementations
- **Exact verification commands** - No "run the tests" or "check it it works"
- **DRY** - Don't repeat code across files
- **YAGNI** - No speculative features
- **Generalization** - Solutions must be generic. Ask yourself: "If input changes, will this still work?"
- **Allow replanning** - When direction is wrong, pivot. Sunk cost is not a reason to continue
- **Lightweight first** - Prefer the simplest approach. Complexity must be justified by value
- **Context Isolation** - When dispatching subagents, provide only the context they need

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Plan document lives in the repo, not in your head
- Plans are executed in isolated worktrees
- Each task is a single commit
- Verification commands should be exact and complete
- Use `summ:summ-todo` to track progress (optional)
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Index consistency:** Does the task index match the actual tasks generated? Same count, same titles, same files. If tasks were added or removed during batch generation, update the index to match.

**3. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**4. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, automatically start execution:

**Announce:**

"Plan complete and saved to `docs/superpowers/plans/<filename>.md`.

Starting Subagent-Driven execution — N tasks, fresh subagent per task with two-stage review."

**Then immediately invoke:** summ:subagent-driven-development

**Fallback:** If subagents are not available on this platform, use summ:executing-plans instead and announce "Starting batch execution — N tasks, direct execution with checkpoints."

**Do not ask the user to choose.** Default to Subagent-Driven. The executing-plans skill is an internal fallback, not a user-facing option.
