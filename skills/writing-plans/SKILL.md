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

**OPTIONAL SUB-SKILL:** Use summ:summ-todo to track plan writing progress

## Task Tracking
When tracking with SUMM-Todo:

```bash
# Get project name (default from git repo)
PLAN_FILE=$(basename "$PLAN_PATH" .md)
PROJECT=$(git remote get-url origin 2>/dev/null | sed -n 's#.*/\([^/]*\)\.git#1#p' || \
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
### Task N: [Component Name]
Description
Files
Tests
Verification
---
### Task 1: Setup & Context
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

## Remember
- Plan document lives in the repo, not in your head
- Plans are executed in isolated worktrees
- Each task is a single commit
- Verification commands should be exact and complete

- Use `summ:summ-todo` to track progress (optional)
