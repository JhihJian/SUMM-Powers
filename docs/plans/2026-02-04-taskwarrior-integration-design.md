# TaskWarrior Integration Design

## Goal

Add TaskWarrior task tracking capability to writing-plans and executing-plans skills, enabling external task management for development workflows.

## Background

TaskWarrior is a command-line task management system. By integrating it with SUMM's planning and execution skills, users can:

- Track plan writing progress in TaskWarrior
- Track execution of individual plan tasks in TaskWarrior
- Use TaskWarrior's reporting and filtering capabilities
- Maintain a unified task view across multiple projects

## Architecture

### New Skill: taskwarrior

Create a standalone `skills/taskwarrior/SKILL.md` that:

1. **Can be called independently** - Users can invoke it directly for task operations
2. **Can be used as a sub-skill** - Other skills integrate via REQUIRED SUB-SKILL mechanism
3. **Provides core operations** - Add, start, complete tasks with proper tags

### Integration Points

**writing-plans skill:**
- Creates a plan task when starting to write a plan
- Marks task as started when writing begins
- Marks task as completed when plan is saved

**executing-plans skill:**
- Creates a task for each Task in the plan
- Marks each task as started/completed during execution

## Task Design

### Tags

- `+plan` - For plan writing tasks
- `+execute` - For execution tasks
- `+plan:<filename>` - Plan file identifier (e.g., `+plan:2026-02-04-feature`)

### Project

- Use git project name from `git remote get-url origin`
- Fallback to git directory basename
- Final fallback: `summ-plans`

### Task Examples

Plan writing task:
```
description: "Write plan: Add user authentication"
project: "my-project"
tags: +plan +plan:2026-02-04-add-user-auth
status: pending -> in-progress -> completed
```

Execution task:
```
description: "Task 1: Create user model"
project: "my-project"
tags: +execute +plan:2026-02-04-add-user-auth
status: pending -> in-progress -> completed
```

## Implementation Steps

1. Create `skills/taskwarrior/SKILL.md` using summ:writing-skills
2. Modify `skills/writing-plans/SKILL.md` to integrate taskwarrior
3. Modify `skills/executing-plans/SKILL.md` to integrate taskwarrior
4. Test skill creation with subagents per summ:writing-skills TDD process

## Files

- Create: `skills/taskwarrior/SKILL.md`
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `skills/executing-plans/SKILL.md`

## Notes

- TaskWarrior command failures are not handled (assume TaskWarrior is available)
- Task description generation is left to Claude Code CLI (not over-specified)
- skill follows DRY principle - TaskWarrior knowledge centralized in taskwarrior skill
