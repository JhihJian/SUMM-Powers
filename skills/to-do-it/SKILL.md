---
name: to-do-it
description: Use when executing small, logically straightforward tasks that don't require design docs or detailed plans. Quick analyze-confirm-execute cycle for simple fixes, small features, or setup tasks.
---

# Quick Todo Execution

## Overview

Execute small, clear tasks: analyze → confirm → execute → verify. Skip brainstorming and planning docs.

**Core principle:** Fast execution for straightforward tasks without overhead.

**IRON LAW: NO EXECUTION WITHOUT SUMM-TODO TASK FIRST.**

Violating the letter = violating the spirit. SUMM-Todo is mandatory, period.

## When to Use

**Use for:**
- Simple fixes (typos, renames, small logic changes)
- Small features (loading states, simple validation)
- Setup tasks (install dependencies, configure tools)
- Clear bug fixes (known issue, known solution)

**NOT for:**
- Features requiring architecture decisions
- Multi-system changes affecting many files
- Unclear approaches - use summ:brainstorming instead

## The Process

### 1. Analyze
Read relevant files, ask questions until clear, assess complexity (simple/medium/complex).

**Don't assume. Don't hide confusion. Surface tradeoffs.**
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

**Design principles（设计阶段遵守）：**
- Generalization — 方案必须通用，禁止硬编码
- Allow replanning — 发现方向错误时推翻重新规划
- Simplicity First — 最少代码解决问题，不写投机性功能。200 行能变 50 行就重写

### 2. Confirm
Present plan to user with **verifiable goals**:
```
I understand you want to: [summary]
Plan:
1. [Step] → verify: [check]
2. [Step] → verify: [check]
Complexity: simple/medium/complex
```

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

- **Simple/medium:** "Does this look right?"
- **Complex:** "This is complex. Proceed directly or use /summ:writing-plans?"

**On confirmation - MANDATORY ORDER:**
1. **Get project name** - `PROJECT=$(git remote get-url origin 2>/dev/null | sed -n 's#.*/\([^/]*\)\.git#\1#p' || basename "$(git rev-parse --show-toplevel 2>/dev/null)" || echo "summ-plans")`
2. **Ensure project exists** - `todo project show "$PROJECT" 2>/dev/null || todo project add "$PROJECT" -d "Project tasks"`
3. **Create SUMM-Todo task** - `todo add "$PROJECT: Task title" --pri <high|medium|low> --tag todo`. Save task ID.
4. **Start the task** - `todo start <id>` or `todo next --tag todo`
5. **Create TodoWrite** - Track execution steps

**NO EXCEPTIONS:** Not for "simple tasks", "quick fixes", "TodoWrite is enough", or "I'll add later". SUMM-Todo FIRST.

### 3. Execute
For each todo: mark in_progress → execute → mark completed

**Surgical Changes — Touch only what you must:**
- Don't "improve" adjacent code, comments, or formatting
- Don't refactor things that aren't broken
- Match existing style, even if you'd do it differently
- Remove imports/variables/functions that YOUR changes made unused
- Don't remove pre-existing dead code unless asked
- Every changed line should trace directly to the user's request

### 4. Verify and Complete
1. Verify (tests/build/lint for code, installation for setup, config applied)
2. **Mark SUMM-Todo done** - `todo done <id> -m "Result of task"` (BLOCKING: cannot clear TodoWrite until done)
3. Summarize changes
4. Clear TodoWrite

## Red Flags - You're Rationalizing

**STOP if thinking:**
- "Too simple for SUMM-Todo"
- "TodoWrite is sufficient"
- "I'll add it later"
- "Just this once"
- "Forgot task ID, skip marking done"

**All mean: You're violating the skill. Use SUMM-Todo.**

## When to Upgrade

Stop and suggest summ:writing-plans when:
- Multiple system interactions
- Scope creep (user keeps adding requirements)
- Unexpected architectural issues
- Can't understand after reasonable questioning

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Creating design docs/plan files | Don't. This skill skips docs intentionally |
| Over-analyzing | Read what's needed, confirm, execute |
| Skipping verification | Always verify before completing |
| **Starting before SUMM-Todo** | **STOP. Create SUMM-Todo task first.** |
| **"TodoWrite is enough"** | **Both required. TodoWrite = session, SUMM-Todo = global.** |
| **Not marking SUMM-Todo done** | **Search for task if forgot ID. Never skip.** |
| **Forgetting project prefix** | **Always use "ProjectName: task title" format.** |

## Key Principles

- **用中文与用户沟通** - 理解和确认都用中文进行
- **Generalization** - 方案必须通用，禁止硬编码
- **Allow replanning** - 发现方向错误时推翻重新规划
- **Simplicity First** - 最少代码解决问题，不写投机性功能。200 行能变 50 行就重写
- **Surgical Changes** - 只改必须改的，每行改动都能追溯到用户需求

## Integration

**Required:** `summ:summ-todo` - Global task tracking (CRITICAL: always use)

**Optional:** `summ:systematic-debugging`, `summ:verification-before-completion`

**Not compatible:** `summ:writing-plans`, `summ:brainstorming` (this replaces them for small tasks)
