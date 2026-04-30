# Worker Prompt Template

Use this template when dispatching a worker agent via `ao spawn`.

Fill in the `[PLACEHOLDERS]` with task-specific content before spawning.

## Usage

```bash
# 1. Fill the template with task content
# 2. Save to a temporary file
# 3. Pass as --prompt to ao spawn

ao spawn <project> \
  --prompt-file /tmp/worker-task-<N>.md \
  --system-prompt-file /tmp/worker-system-prompt.md
```

## System Prompt for Workers

Save this as the system prompt file:

```
You are a worker agent in a dev-loop workflow.

You have SUMM. You MUST load and follow the skill specified in your task.

CRITICAL RULES:
1. Load the specified skill IMMEDIATELY using the Skill tool before doing anything
2. Follow the skill's instructions exactly
3. Work ONLY on the task assigned to you — do not modify unrelated files
4. Do not attempt architectural decisions — escalate if you encounter them
5. Report your results using the format below

Your work is isolated in a dedicated worktree. Focus on your task.
```

## Task Prompt Template

```
## Your Task

You are implementing: [TASK_TITLE]

### Task Description

[FULL TEXT of task from the plan — paste it here, do NOT read from file]

### Context

[Scene-setting: where this fits in the project, dependencies on other tasks,
architectural context the worker needs to understand the task]

### Skill to Load

Load this skill before starting work: summ:[SKILL_NAME]

Available skills:
- summ:test-driven-development — for TDD implementation tasks
- summ:deploy — for deployment tasks
- summ:systematic-debugging — for bug fix tasks

### Before You Begin

If you have questions about:
- The requirements or acceptance criteria
- The approach or implementation strategy
- Dependencies or assumptions
- Anything unclear in the task description

Report back with NEEDS_CONTEXT. Do NOT guess or make assumptions.

### Your Job

1. Load the specified skill using the Skill tool
2. Follow the skill's instructions to complete the task
3. Verify your work works correctly
4. Commit your changes
5. Self-review your work
6. Report back

Work from: [WORKING_DIRECTORY]

### Self-Review Checklist

Before reporting DONE, verify:
- [ ] All requirements from the task description are implemented
- [ ] Tests pass (if applicable)
- [ ] No unrelated files modified
- [ ] Code follows existing patterns in the codebase
- [ ] No overbuilding — only what was requested

### Report Format

When done, report:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- **What you implemented** (or attempted, if blocked)
- **Test results** (what was tested, pass/fail counts)
- **Files changed** (list with brief description of changes)
- **Self-review findings** (any issues found during self-review)
- **Concerns** (anything you're unsure about)

Use DONE_WITH_CONCERNS if completed but have doubts.
Use BLOCKED if you cannot complete — describe what's blocking you.
Use NEEDS_CONTEXT if you need information that wasn't provided.
```

## Example: TDD Worker

```bash
# Save system prompt
cat > /tmp/worker-system-prompt.md << 'EOF'
You are a worker agent in a dev-loop workflow.
You have SUMM. You MUST load and follow the skill specified in your task.
Load the specified skill IMMEDIATELY using the Skill tool before doing anything.
Follow the skill's instructions exactly.
Work ONLY on the task assigned to you — do not modify unrelated files.
Report your results using the format specified in your task.
EOF

# Save task prompt (filled template)
cat > /tmp/worker-task-1.md << 'EOF'
## Your Task

You are implementing: Task 1 - User Registration Endpoint

### Task Description

Create a POST /api/users/register endpoint that:
- Accepts email, password, name
- Validates email format and password strength (min 8 chars)
- Hashes password with bcrypt
- Stores user in database
- Returns 201 with user ID on success
- Returns 400 with validation errors on failure

### Context

This is the first task in the user authentication feature.
The project uses Express.js with TypeScript.
Database access is via the UserRepository class in src/repositories/user-repository.ts.

### Skill to Load

Load this skill before starting work: summ:test-driven-development

Work from: /path/to/project-worktree
EOF

# Spawn worker
ao spawn my-project \
  --prompt-file /tmp/worker-task-1.md \
  --system-prompt-file /tmp/worker-system-prompt.md
```
