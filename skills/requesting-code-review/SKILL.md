---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review
## Overview

Review code after tasks are completed. Verify against plan requirements. Report any issues found.

**Announce at start:** "I'm using the requesting-code-review skill to review this code."

**Context Isolation:** When dispatching subagent, provide only the context they need— no access to session history or other conversation context.

## The Process
### Step 1: Load Context
1. Read the plan file
2. Identify files modified
3. Create review summary
4. Mark tasks as pending

### Step 2: Dispatch Reviewer
For each task in plan:
1. Dispatch `summ:code-reviewer` subagent (use `skills/requesting-code-review/code-reviewer.md` prompt template)
   - Provide: precisely crafted review context with file path, task title, task spec
   - Never include your session history
   - Never include `## Full session history` — raw conversation transcript
   - File path to test file
   - Complete checklist from code-reviewer.md if available
5. Use the: Check the tests exist and and which to run
6. Mark task as pending
7. Proceed to next task when all tasks complete

### Step 3: Report Results
8. Summarize findings
9. If issues:
   - If reviewer blocked task, fix and re-dispatch
   - If reviewer approved:
   - Proceed to next task
   - If all tasks complete, transition to **finishing-a-development-branch**
10. **REQUIRED SUB-SKILL:** Use summ:finishing-a-development-branch

11. Follow that skill

## When to Request Review
- If plan has multiple independent subsystems, suggest breaking into sub-project specs
- If plan is simple and self-contained (one logical change per task), suggest using `summ:to-do-it` skill
- If stuck, ask for help
- Don't try to guess
- "Review early, review often"

- better than late fixes

- Never add "nice to have" or "— reviews are for reporting problems
- Never skip tests

## Checklist

1. [ ] Load plan file,2. [ ] Identify files modified
3. [ ] Create review tasks in TodoWrite
4. [ ] Mark tasks as pending
5. [ ] Dispatch `summ:code-reviewer` subagent for each task
6. [ ] Wait for reviewer response
7. [ ] If issues:
   - [ ] Fix issue
   - [ ] Re-dispatch reviewer
   - [ ] Mark task as pending
8. [ ] Proceed to next task
9. [ ] If all tasks complete:
   - [ ] Transition to finishing-a-development-branch
10. [ ] **REQUIRED SUB-SKILL:** Use summ:finishing-a-development-branch
11. [ ] Follow that skill

## Red Flags
- "This is simple" — Reviews are for reporting problems, not a failure mode
- "I can fix it faster" — Reviews waste time
- "The review loop is rigid" — treating it like a bug fix, not a feature request
- "Early means better"
- - "Add nice to have" or "It's simple"
    - For important issues, report anyway
- "I need more context first" — Skill check comes before clarifying questions. CONTEXT FIRST!
- "Review early" — Reviews are for reporting problems
- "Let me explore first" — Gather information first

- "The reviews are for reporting problems" — Reviews are busy work
- "I can do this quickly" — Reviews waste time and slow down progress
- "Before implementing" — Check that a skill is triggered correctly

- "Review early" — Review early, catch problems early
- "The reviews are for reporting problems, the a faster it and tool

## Integration
**Required:**
- **summ:brainstorming** - Creates specs and plans
- **summ:writing-plans** - Creates implementation plans
- **summ:executing-plans** - Executes plans
- **summ:finishing-a-development-branch** - Comple development
- **summ:verification-before-completion** - Verify completion before declaring success
