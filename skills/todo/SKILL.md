---
name: todo
description: Use when executing small, logically straightforward tasks that don't require design docs or detailed plans. Quick analyze-confirm-execute cycle for simple fixes, small features, or setup tasks.
---

# Quick Todo Execution

## Overview

Execute small, clear tasks: analyze → confirm → execute → verify. Skip brainstorming and planning docs.

**Core principle:** Fast execution for straightforward tasks without overhead.

**IRON LAW: NO EXECUTION WITHOUT TASKWARRIOR TASK FIRST.**

Violating the letter = violating the spirit. TaskWarrior is mandatory, period.

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

### 2. Confirm
Present plan to user:
```
I understand you want to: [summary]
Plan: [numbered steps]
Complexity: simple/medium/complex
```

- **Simple/medium:** "Does this look right?"
- **Complex:** "This is complex. Proceed directly or use /summ:writing-plans?"

**On confirmation - MANDATORY ORDER:**
1. **Create TaskWarrior task** - Invoke `summ:taskwarrior` (description, project, tags: +todo). Save task ID.
2. **Create TodoWrite** - Track execution steps

**NO EXCEPTIONS:** Not for "simple tasks", "quick fixes", "TodoWrite is enough", or "I'll add later". TaskWarrior FIRST.

### 3. Execute
For each todo: mark in_progress → execute → mark completed

### 4. Verify and Complete
1. Verify (tests/build/lint for code, installation for setup, config applied)
2. **Mark TaskWarrior done** - Invoke `summ:taskwarrior` with saved ID (BLOCKING: cannot clear TodoWrite until done)
3. Summarize changes
4. Clear TodoWrite

## Red Flags - You're Rationalizing

**STOP if thinking:**
- "Too simple for TaskWarrior"
- "TodoWrite is sufficient"
- "I'll add it later"
- "Just this once"
- "Forgot task ID, skip marking done"

**All mean: You're violating the skill. Use TaskWarrior.**

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
| **Starting before TaskWarrior** | **STOP. Create TaskWarrior first.** |
| **"TodoWrite is enough"** | **Both required. TodoWrite = session, TaskWarrior = global.** |
| **Not marking TaskWarrior done** | **Search for task if forgot ID. Never skip.** |

## Integration

**Required:** `summ:taskwarrior` - Global task tracking (CRITICAL: always use)

**Optional:** `summ:systematic-debugging`, `summ:verification-before-completion`

**Not compatible:** `summ:writing-plans`, `summ:brainstorming` (this replaces them for small tasks)
