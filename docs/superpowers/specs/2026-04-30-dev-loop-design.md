# dev-loop: Development Delivery Closed-Loop Workflow

**Date:** 2026-04-30
**Status:** Design approved

## Goal

Automate the full lifecycle of a development requirement: from understanding the need, through TDD implementation, deployment, E2E verification, to value proof — with minimal human intervention. Human is involved only at escalation or post-hoc review.

## Context

SUMM-Powers provides skills for individual development activities (brainstorming, TDD, deployment, code review). Agent-Orchestrator (AO) provides infrastructure for spawning isolated agent sessions in worktrees. Currently these operate independently. This design connects them into a closed-loop workflow where a master agent orchestrates worker agents through a defined pipeline.

## Roles

| Role | Runtime | Responsibility |
|------|---------|----------------|
| Master Agent | AO session (role: orchestrator) | Flow control, decision-making, value proof, escalation |
| Worker Agent | AO session (ao spawn) | Execution: TDD, deployment, E2E testing |
| Human | Notification receiver | Escalation handling, post-hoc review |

**Constraint:** Master agent never writes code. It only coordinates and judges.

### Worker Dispatch Strategy

The master agent dispatches workers based on the plan's task decomposition:
- **Independent tasks**: Dispatched in parallel (one worker per task via `ao spawn`)
- **Sequential tasks**: Dispatched one at a time, next task starts after previous completes
- **Worker count**: Determined by the plan — typically one worker per leaf task in the dependency graph
- **Deploy/E2E workers**: Always single-worker (one deploy, one E2E verification)

## Workflow State Machine

### Phases and Sub-states

```
Phase (role)          Sub-state                  Actor
─────────────────────────────────────────────────────────────
PLANNING              BRAINSTORMING              Master Agent
                      PLAN_WRITING               Master Agent

BUILDING              TDD_IMPLEMENTING           Worker Agent × N (Master dispatches)
                      CODE_REVIEWING             Master Agent (reviews Worker output)

DELIVERING            DEPLOYING                  Worker Agent (Master dispatches)
                      E2E_VERIFYING              Worker Agent (Master dispatches)

VALIDATING            VALUE_PROVING              Master Agent (compares requirement vs delivery)
                      COMPLETING                 Master Agent (archives + notifies human)
```

### Transitions

```
PLANNING.BRAINSTORMING
  → PLANNING.PLAN_WRITING (brainstorming complete)

PLANNING.PLAN_WRITING
  → BUILDING.TDD_IMPLEMENTING (plan produced)

BUILDING.TDD_IMPLEMENTING
  → BUILDING.CODE_REVIEWING (all workers report DONE)
  → ESCALATED (worker BLOCKED and unresolvable)

BUILDING.CODE_REVIEWING
  → DELIVERING.DEPLOYING (all PRs approved)
  → BUILDING.TDD_IMPLEMENTING (review issues found, workers fix)

DELIVERING.DEPLOYING
  → DELIVERING.E2E_VERIFYING (deploy successful)
  → BUILDING.TDD_IMPLEMENTING (deploy failed, code/config fix needed)

DELIVERING.E2E_VERIFYING
  → VALIDATING.VALUE_PROVING (all E2E tests pass)
  → BUILDING.TDD_IMPLEMENTING (E2E tests fail, bug fix needed)

VALIDATING.VALUE_PROVING
  → VALIDATING.COMPLETING (value proof passes)
  → PLANNING.BRAINSTORMING (requirement misunderstood, loop back)
  → BUILDING.TDD_IMPLEMENTING (partial implementation missing, loop back)

VALIDATING.COMPLETING
  → DONE (materials archived, human notified)
```

### Loop-back Rules

| Failure source | Return target | Condition |
|----------------|---------------|-----------|
| Code review issues | BUILDING.TDD_IMPLEMENTING | Code quality or spec compliance problems |
| Deploy failure | BUILDING.TDD_IMPLEMENTING | Code or configuration issue |
| E2E test failure | BUILDING.TDD_IMPLEMENTING | Bugs found by tests |
| Value proof: requirement gap | PLANNING.BRAINSTORMING | Requirement was misunderstood |
| Value proof: missing features | BUILDING.TDD_IMPLEMENTING | Partial implementation |
| Loop count >= 3 | ESCALATED | Force human intervention |

## Trigger Mechanism

**Current phase (manual):**
```bash
ao spawn my-project --prompt "实现需求：用户登录功能" \
  --system-prompt-file skills/dev-loop/master-prompt.md
```

**Future (automated via AO reactions):**
```yaml
reactions:
  issue-created:
    auto: true
    action: send-to-agent
    message: "Load skill summ:dev-loop and process this requirement"
```

## Worker Prompt Injection

Workers are spawned via `ao spawn` with a system prompt file that includes:

1. SUMM skill loading instruction ("You have SUMM, you MUST use the specified skill")
2. Task-specific skill to load (e.g., `summ:test-driven-development`)
3. Report format template (Status / Implementation / Tests / Files / Self-review)
4. Constraint: work only on assigned task, do not modify unrelated files

The master agent constructs the worker prompt by filling in the template with:
- Full task text from the plan
- Scene-setting context (dependencies, architecture)
- Working directory

## Workflow State Persistence

State is stored in `~/.agent-orchestrator/{project}/workflow-{id}.json`, consistent with AO's metadata system:

```json
{
  "workflowId": "wf-20260430-001",
  "requirement": "用户登录功能",
  "source": "issue-42",
  "currentPhase": "BUILDING",
  "currentSubState": "TDD_IMPLEMENTING",
  "loopCount": 1,
  "maxLoops": 3,
  "planFile": "docs/superpowers/plans/2026-04-30-user-login.md",
  "workerSessions": ["my-app-1", "my-app-2"],
  "evidence": [
    {"phase": "BUILDING", "type": "test-results", "summary": "12/12 passed"},
    {"phase": "DELIVERING", "type": "deploy-url", "url": "https://staging.example.com"}
  ]
}
```

## Value Proof Mechanism

The master agent evaluates completion by comparing:

1. **Original requirement** (from issue or conversation)
2. **Plan** (what was intended)
3. **Evidence collected**:
   - TDD test results (all pass?)
   - Code review results (approved?)
   - Deploy status (successful?)
   - E2E test results (all pass?)
4. **Diff** (what actually changed in the codebase)

Decision: Does the delivery satisfy the requirement? If yes, archive evidence and notify human. If no, diagnose the gap and loop back to the appropriate phase.

## Skills Used

| Phase | Skill | Used by |
|-------|-------|---------|
| PLANNING.BRAINSTORMING | `summ:brainstorming` | Master Agent |
| PLANNING.PLAN_WRITING | `summ:writing-plans` | Master Agent |
| BUILDING.TDD_IMPLEMENTING | `summ:test-driven-development` | Worker Agent |
| BUILDING.CODE_REVIEWING | `summ:requesting-code-review` | Master Agent |
| DELIVERING.DEPLOYING | `summ:deploy` | Worker Agent |
| DELIVERING.E2E_VERIFYING | (Playwright / API test execution, see E2E strategy below) | Worker Agent |
| VALIDATING.VALUE_PROVING | (built into dev-loop skill) | Master Agent |

## Deliverables

1. **`skills/dev-loop/SKILL.md`** — Complete closed-loop workflow skill with state machine, transition rules, loop-back logic, value proof
2. **`skills/dev-loop/master-prompt.md`** — Master agent system prompt (tells it to load and follow dev-loop skill)
3. **`skills/dev-loop/worker-prompt-template.md`** — Worker prompt template with skill injection and report format
4. **`agent-orchestrator.yaml` configuration** — Reaction rules and notifier setup

## E2E Verification Strategy

E2E tests are executed by a worker agent after deployment. The strategy depends on what exists in the project:

1. **Existing E2E tests**: If the project has Playwright/Cypress/API test suites, the worker runs them against the deployed environment and reports results.
2. **No existing tests**: The master agent includes E2E test creation as part of the plan (BUILDING phase). The TDD worker writes E2E tests alongside unit/integration tests.
3. **Manual API verification**: For API changes without test suites, the worker makes real API calls to verify behavior matches the requirement.

The plan produced in PLANNING.PLAN_WRITING must specify which E2E strategy applies and what test commands to run.

## Out of Scope

- Generic workflow engine (may extract shared patterns after 2-3 workflow skills exist)
- Automated triggering via AO reactions (manual trigger first, automate later)
- Multi-project coordination (single project per workflow instance)
