---
name: dev-loop
description: Use when automating a full development lifecycle from requirement to delivery — orchestrates planning, TDD implementation, code review, deployment, E2E verification, and value proof in a closed loop with automatic recovery on failure
---

# dev-loop: Development Delivery Closed-Loop

Automate the full lifecycle of a development requirement: planning, TDD implementation, code review, deployment, E2E verification, and value proof — with loop-back on failure and escalation when stuck.

**Core principle:** A master agent orchestrates worker agents through a fixed pipeline. Master agent never writes code. It coordinates, reviews, and judges. Workers execute using SUMM skills.

**Why a loop:** Failures are normal in development. Rather than stopping on failure, this workflow diagnoses the failure type, returns to the appropriate phase, and retries. Human is involved only at escalation or post-hoc review.

## When to Use

```dot
digraph when_to_use {
    "Have a development requirement?" [shape=diamond];
    "Need full lifecycle (plan → deploy → verify)?" [shape=diamond];
    "Can break into independent tasks?" [shape=diamond];
    "dev-loop" [shape=box style=filled fillcolor=lightgreen];
    "subagent-driven-development" [shape=box];
    "to-do-it" [shape=box];
    "brainstorm first" [shape=box];

    "Have a development requirement?" -> "Need full lifecycle (plan → deploy → verify)?" [label="yes"];
    "Have a development requirement?" -> "brainstorm first" [label="no - unclear"];
    "Need full lifecycle (plan → deploy → verify)?" -> "Can break into independent tasks?" [label="yes"];
    "Need full lifecycle (plan → deploy → verify)?" -> "subagent-driven-development" [label="no - just implement"];
    "Can break into independent tasks?" -> "dev-loop" [label="yes"];
    "Can break into independent tasks?" -> "to-do-it" [label="no - single task"];
}
```

**Use dev-loop when:**
- You have a clear development requirement (issue, user request, or spec)
- The requirement needs implementation + deployment + verification
- The work can be decomposed into tasks

**Don't use dev-loop when:**
- Quick fix or single change → use `summ:to-do-it`
- Only need implementation (no deploy/verify) → use `summ:subagent-driven-development`
- Requirement is unclear → use `summ:brainstorming` first

## Workflow State Machine

### Phases and Sub-states

```
Phase              Sub-state                  Actor
──────────────────────────────────────────────────────────────
PLANNING           BRAINSTORMING              Master Agent
                   PLAN_WRITING               Master Agent

BUILDING           TDD_IMPLEMENTING           Worker × N (Master dispatches)
                   CODE_REVIEWING             Master Agent

DELIVERING         DEPLOYING                  Worker (Master dispatches)
                   E2E_VERIFYING              Worker (Master dispatches)

VALIDATING         VALUE_PROVING              Master Agent
                   COMPLETING                 Master Agent
```

### Transition Rules

```
PLANNING.BRAINSTORMING
  → PLANNING.PLAN_WRITING     [brainstorming produces design]

PLANNING.PLAN_WRITING
  → BUILDING.TDD_IMPLEMENTING [plan with tasks produced]

BUILDING.TDD_IMPLEMENTING
  → BUILDING.CODE_REVIEWING   [all workers report DONE]
  → ESCALATED                 [worker BLOCKED, unresolvable]

BUILDING.CODE_REVIEWING
  → DELIVERING.DEPLOYING      [all PRs approved]
  → BUILDING.TDD_IMPLEMENTING [review issues → workers fix]

DELIVERING.DEPLOYING
  → DELIVERING.E2E_VERIFYING  [deploy successful, env ready]
  → BUILDING.TDD_IMPLEMENTING [deploy failed → code/config fix]

DELIVERING.E2E_VERIFYING
  → VALIDATING.VALUE_PROVING  [all E2E tests pass]
  → BUILDING.TDD_IMPLEMENTING [tests fail → bug fix]

VALIDATING.VALUE_PROVING
  → VALIDATING.COMPLETING     [requirement satisfied]
  → PLANNING.BRAINSTORMING    [requirement misunderstood]
  → BUILDING.TDD_IMPLEMENTING [partial implementation]

VALIDATING.COMPLETING
  → DONE                      [evidence archived, human notified]
```

### Loop-back Decision Table

| Failure source | Return to | Reason |
|----------------|-----------|--------|
| Code review issues | BUILDING.TDD | Code quality problems |
| Deploy failure | BUILDING.TDD | Code or config issue |
| E2E test failure | BUILDING.TDD | Bugs found |
| Value proof: wrong understanding | PLANNING | Requirement gap |
| Value proof: incomplete work | BUILDING.TDD | Missing features |
| Loop count ≥ 3 | ESCALATED | Force human intervention |

**Every loop-back increments loopCount.** When loopCount reaches maxLoops (default: 3), transition to ESCALATED regardless of failure type.

## Skills Used at Each Phase

| Phase | Skill | Who |
|-------|-------|-----|
| PLANNING.BRAINSTORMING | `summ:brainstorming` | Master |
| PLANNING.PLAN_WRITING | `summ:writing-plans` | Master |
| BUILDING.TDD_IMPLEMENTING | `summ:test-driven-development` | Worker |
| BUILDING.CODE_REVIEWING | `summ:requesting-code-review` | Master |
| DELIVERING.DEPLOYING | `summ:deploy` | Worker |
| DELIVERING.E2E_VERIFYING | Playwright / API tests | Worker |
| VALIDATING.VALUE_PROVING | Built into this skill | Master |

## Worker Dispatch

### How to Spawn a Worker

Use Agent-Orchestrator CLI to create isolated worker sessions:

```bash
ao spawn <project> \
  --prompt "<task prompt from worker-prompt-template.md>" \
  --system-prompt-file <path-to-worker-system-prompt>
```

**Worker prompt construction:**
1. Fill `./worker-prompt-template.md` with task-specific content
2. Set `SKILL_TO_LOAD` to the skill the worker must use
3. Paste full task text (never make worker read the plan file)
4. Set working directory to the project's worktree path

### Dispatch Strategy

Read the plan's task dependency graph:
- **Independent tasks**: Dispatch in parallel (one `ao spawn` per task)
- **Sequential tasks**: Dispatch one at a time, wait for DONE before next
- **Deploy/E2E**: Always single-worker, sequential (deploy first, then E2E)

### Monitoring Workers

After dispatching, poll worker status:

```bash
ao status <session-id>
```

**Activity states to handle:**
- `active` / `working` → Continue waiting
- `idle` / `ready` → Worker may have finished, check output
- `waiting_input` → Worker is asking a question, provide answer via `ao send`
- `blocked` / `exited` → Worker failed, assess and handle

**Polling cadence:** Check every 2-5 minutes. Do not poll continuously — use the time for other coordination work.

**Timeout:** If a worker exceeds 30 minutes without state change, treat as BLOCKED.

### Handling Worker Reports

Workers report one of four statuses:

**DONE:** Task completed successfully. Collect output, proceed to next task or code review.

**DONE_WITH_CONCERNS:** Completed but flagged doubts. Read concerns before proceeding. Address correctness/scope concerns. Note observations for later.

**NEEDS_CONTEXT:** Worker needs more information. Provide missing context and send via `ao send`.

**BLOCKED:** Worker cannot complete. Assess:
1. Context problem → provide more context, re-dispatch
2. Reasoning problem → re-dispatch with more capable model
3. Task too large → break into smaller pieces, re-dispatch
4. External blocker → ESCALATED

## Code Review (BUILDING.CODE_REVIEWING)

After all workers report DONE:

1. Load `summ:requesting-code-review`
2. For each worker's PR:
   a. Read the diff: `gh pr diff <pr-url>`
   b. Compare against the task spec from the plan
   c. Check for: missing requirements, extra work, code quality
3. If issues found:
   - Document specific issues per PR
   - Transition back to BUILDING.TDD_IMPLEMENTING
   - Dispatch fix workers with specific review feedback
   - increment loopCount
4. If all PRs pass:
   - Transition to DELIVERING.DEPLOYING

**Never** skip code review. **Never** proceed with unfixed issues.
