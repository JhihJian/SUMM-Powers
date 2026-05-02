---
name: dev-loop
description: Use when automating a full development lifecycle from requirement to delivery — orchestrates planning, TDD implementation, code review, deployment, E2E verification, and value proof in a closed loop with automatic recovery on failure
---

# dev-loop: Development Delivery Closed-Loop

Automate the full lifecycle of a development requirement: planning, TDD implementation, code review, deployment, E2E verification, and value proof — with loop-back on failure and escalation when stuck.

**Input:** A confirmed design spec (produced by `summ:brainstorming`). dev-loop does not include brainstorming — run brainstorming separately before invoking dev-loop.

**Core principle:** You are a master agent. Your job is to dispatch workers, review their output, and make decisions. You do not write code, run commands, or edit files directly. Instead you delegate execution to worker agents.

## Dispatching Workers

Master delegates execution to workers. Use whichever mechanism is available in your environment:

- **Agent tool** (Claude Code built-in): `Agent` tool with a descriptive prompt — preferred when running inside Claude Code
- **ao spawn** (Agent-Orchestrator CLI): `ao spawn <project> --prompt "<worker prompt>"` — use when running in an AO-managed environment
- **Other**: any mechanism that creates an isolated agent session with its own context

Regardless of mechanism, every worker dispatch needs:
1. A clear task description (what to implement)
2. The SUMM skill to load (how to work)
3. Working directory (where to work)
4. Report format (how to report back)

Worker prompt template: `skills/dev-loop/worker-prompt-template.md`

## Setup

Before first use, run the init script on your target project:

```bash
bash skills/dev-loop/scripts/init.sh /path/to/project --name my-project
```

This generates `agent-orchestrator.yaml`, `.claude/settings.json`, and `DEPLOY.md`.

## Workflow State Machine

```
Phase              Sub-state                  Actor
──────────────────────────────────────────────────────────────
PLANNING           PLAN_WRITING               Master Agent

BUILDING           TDD_IMPLEMENTING           Worker × N (Master dispatches)
                   CODE_REVIEWING             Master Agent

DELIVERING         DEPLOYING                  Worker (Master dispatches)
                   E2E_VERIFYING              Worker (Master dispatches)

VALIDATING         VALUE_PROVING              Master Agent
                   COMPLETING                 Master Agent
```

### Transition Rules

```
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
  → PLANNING.PLAN_WRITING     [requirement misunderstood → re-plan]
  → BUILDING.TDD_IMPLEMENTING [partial implementation]

VALIDATING.COMPLETING
  → DONE                      [evidence archived, human notified]
```

**Every loop-back increments loopCount.** Initial value is 1 (first pass). When loopCount reaches maxLoops (default: 3), transition to ESCALATED regardless of failure type.

## Phase Instructions

### PLANNING.PLAN_WRITING

Do these steps in order:

1. Load `summ:writing-plans` via the Skill tool
2. Read the design spec from your prompt
3. Write the plan to `docs/superpowers/plans/`
4. The plan MUST include: task list with IDs, dependency graph, and which SUMM skill each task uses

### BUILDING.TDD_IMPLEMENTING

Do these steps in order:

1. Read the plan file. Extract the task list.
2. Identify which tasks can run in parallel (no dependencies) and which must be sequential.
3. For **each task**, construct a worker prompt using `skills/dev-loop/worker-prompt-template.md`:
   - **Task title:** from the plan
   - **Task description:** paste the full text from the plan (do not tell worker to read a file)
   - **Skill to load:** `summ:test-driven-development`
   - **Working directory:** current project path
4. **Dispatch worker(s)** using your available mechanism:
   - Parallel tasks: dispatch multiple workers at once
   - Sequential tasks: wait for each to finish before dispatching the next
5. Wait for all workers to complete. Collect their output.
6. Check what changed: read `git diff main..HEAD` in the project directory.
7. Transition to CODE_REVIEWING.

**If a worker reports BLOCKED:** assess the cause. Context problem → provide context and re-dispatch. External blocker → ESCALATED. Mixed DONE/BLOCKED → proceed with completed tasks, handle blocked ones separately.

### BUILDING.CODE_REVIEWING

Do these steps in order:

1. Load `summ:requesting-code-review` via the Skill tool.
2. Read the diff: `git diff main..HEAD` in the project directory.
3. Compare each changed file against the task spec from the plan. Check:
   - All requirements from the task spec are implemented?
   - Any files changed that are NOT related to the task? (scope creep)
   - Any existing files deleted that should not be?
4. **If issues found:**
   - Write a specific list of issues per task
   - Go back to TDD_IMPLEMENTING step 3, but fill the worker prompt with fix instructions instead of the original task
   - loopCount++
5. **If all pass:** transition to DELIVERING.DEPLOYING.

### DELIVERING.DEPLOYING

Do these steps in order:

1. Read `DEPLOY.md` from the project.
2. Construct a deploy worker prompt:
   - **Task title:** "Deploy the application"
   - **Task description:** port cleanup command + full content of DEPLOY.md
   - **Skill to load:** `summ:deploy`
   - **Working directory:** current project path
3. Dispatch one deploy worker.
4. Wait for completion. Read the worker output.
5. Check: "Server running" or equivalent → success. Error → failure.
6. **Success:** record deploy URL as evidence, transition to E2E_VERIFYING.
7. **Failure:** transition back to BUILDING.TDD_IMPLEMENTING with fix instructions, loopCount++.

### DELIVERING.E2E_VERIFYING

Do these steps in order:

1. Read the E2E strategy from the plan (which tests to run, expected results).
2. Construct an E2E worker prompt:
   - **Task title:** "Run E2E verification"
   - **Task description:** deploy URL + exact test commands + expected outcomes
   - **Skill to load:** none (E2E workers follow prompt instructions directly)
   - **Working directory:** current project path
3. Dispatch one E2E worker.
4. Wait for completion. Read the worker output.
5. Check: all tests pass → success. Any fail → collect failure details.
6. **Success:** transition to VALUE_PROVING.
7. **Failure:** transition back to BUILDING.TDD_IMPLEMENTING with bug details, loopCount++.

### VALIDATING.VALUE_PROVING

Do these steps in order:

1. Re-read the original requirement from your prompt.
2. Read the actual diff: `git diff main..HEAD --stat` then `git diff main..HEAD`.
3. For each requirement point, check if the diff contains evidence that it is satisfied.
4. Check for scope creep: are there changes NOT related to any requirement point?
5. **PASS:** every requirement has evidence, no unrequested changes → transition to COMPLETING.
6. **GAP (misunderstood):** what was built doesn't match what was asked → transition to PLANNING.PLAN_WRITING, loopCount++.
7. **GAP (partial):** some requirement points have no evidence → transition to BUILDING.TDD_IMPLEMENTING, loopCount++.

### VALIDATING.COMPLETING

1. Write a value proof document to `docs/superpowers/` containing: requirement text, plan summary, implementation summary (files changed, key decisions), test results, deploy info, and evaluation.
2. Notify human with: summary, PR links, deploy URL, value proof location.

### ESCALATION

1. Compile diagnostic report: requirement, number of loops, what failed at each loop, what was tried, current state.
2. Notify human with full report.
3. Pause — do not continue until human responds.

**Triggers:** loopCount ≥ maxLoops, worker BLOCKED and unresolvable, or indeterminate failure.
