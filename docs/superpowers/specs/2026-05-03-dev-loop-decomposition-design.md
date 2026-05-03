# dev-loop Decomposition Design

**Date:** 2026-05-03
**Status:** Approved
**Replaces:** 2026-04-30-dev-loop-design.md, 2026-05-02-dev-loop-observability-design.md

## Problem

dev-loop skill is over-engineered. It wraps the entire existing SUMM pipeline (brainstorming → writing-plans → subagent-driven-development → code-review → finishing-a-development-branch) inside a 9-state state machine, forcing a rigid master/worker separation that conflicts with how Claude Code actually works. The result is:

- Duplicates what other skills already do instead of composing with them
- State machine is the wrong abstraction for LLM — no persistence, unreliable execution
- Hard dependency on Agent-Orchestrator despite claiming to be mechanism-agnostic
- loopCount is a blunt instrument that escalates on minor issues
- Design spec, pressure tests, and SKILL.md contradict each other on brainstorming inclusion

## Decision

Decompose dev-loop into two small, single-responsibility skills that plug into the existing pipeline after `finishing-a-development-branch`. Delete dev-loop entirely.

New pipeline:

```
brainstorming → writing-plans → subagent-driven-development → code-review → finishing-a-development-branch → [deploy-and-verify] → [value-proof]
```

Square brackets = optional, agent decides based on context.

## What to Keep from dev-loop

| dev-loop concept | Where it goes |
|---|---|
| DEPLOY.md reading + deployment execution | `deploy-and-verify` skill |
| Post-deploy smoke test / E2E | `deploy-and-verify` skill |
| Requirement vs diff comparison | `value-proof` skill |
| Structured pass/partial/mismatch report | `value-proof` skill |
| Master/worker separation | **Drop** — agent decides when to dispatch subagents |
| State machine + loopCount | **Drop** — LLM can't reliably maintain state |
| init.sh + agent-orchestrator.yaml generation | **Drop** — too coupled to AO |
| Observability (JSONL events) | **Drop** — complexity without proven value |
| Brainstorming as a phase | **Already handled** by brainstorming skill |

## New Skill 1: `deploy-and-verify`

**Location:** `skills/deploy-and-verify/SKILL.md`

**Trigger:** User mentions deployment, deploy, verify, 上线, 验证. Or agent judges deployment is the natural next step after `finishing-a-development-branch`.

**Single file, ~80-100 lines. No sub-files, no scripts.**

### Workflow

1. **Find deployment config** — read `DEPLOY.md` from project root. If missing, offer to create a template (reuse the template from existing deploy skill).
2. **Execute deployment** — run the deploy commands from DEPLOY.md. Use Bash tool directly — no worker dispatch required.
3. **Verify deployment** — check for verification commands:
   - DEPLOY.md defines `verify` or `e2e` commands → run them
   - `package.json` has `test:e2e` script → run it
   - Deployed a HTTP service → `curl` the health endpoint
   - None of the above → report "no verification configured, deployment status unknown"
4. **Report results** — structured output:
   - Deploy status: SUCCESS / FAILED
   - Verify status: PASSED / FAILED / SKIPPED (no tests configured)
   - Access URL or endpoint (if applicable)
   - If FAILED: error output and suggested next step

### Principles

- No automatic retry. Report failure, let agent/human decide.
- No state machine. Linear steps.
- Works with just Claude Code. Agent-Orchestrator is optional.
- Reuses DEPLOY.md convention from existing `deploy` skill.

## New Skill 2: `value-proof`

**Location:** `skills/value-proof/SKILL.md`

**Trigger:** User asks to verify delivery against requirements, check completeness, value proof. Or agent judges final acceptance is needed after deploy-and-verify.

**Single file, ~60-80 lines. No sub-files.**

### Workflow

1. **Identify the requirement** — find the original requirement from:
   - Design spec in `docs/superpowers/specs/`
   - Implementation plan in `docs/superpowers/plans/`
   - User's original message in conversation
   - Ask user if none found
2. **Read the diff** — `git diff <base>..<head> --stat` for overview, then `git diff <base>..<head>` for details.
3. **Evaluate per requirement point**:
   - Is there code evidence that this point is implemented?
   - Mark each point: EVIDENCED / NO_EVIDENCE / PARTIAL
4. **Check scope** — are there changes NOT related to any requirement point?
5. **Report**:
   - **PASS** — every point EVIDENCED, no unrelated changes
   - **PARTIAL** — some points missing evidence; list the gaps
   - **MISMATCH** — implementation direction differs from requirement
   - **SCOPE_CREEP** — significant unrelated changes found
   - Include: requirement points with evidence status, files changed summary, recommended next action

### Principles

- Report only. No automatic re-plan or re-implement.
- No loopCount. Agent reads the report and decides what to do next.
- Reads actual diff, not just reports from previous phases.

## Files to Delete

```
skills/dev-loop/                              (entire directory)
docs/superpowers/specs/2026-04-30-dev-loop-design.md
docs/superpowers/specs/2026-05-02-dev-loop-observability-design.md
docs/superpowers/plans/2026-04-30-dev-loop-skill.md
docs/superpowers/plans/2026-04-30-dev-loop-e2e-test-plan.md
docs/superpowers/examples/dev-loop-agent-orchestrator.yaml
```

## Files to Create

```
skills/deploy-and-verify/SKILL.md
skills/value-proof/SKILL.md
```

## Files to Update

- `CLAUDE.md` — update repository structure and workflow pipeline description
- `tests/claude-code/` — remove any dev-loop specific tests, add basic load tests for new skills

## Out of Scope

- Merging init.sh logic into deploy skill (can be done separately if needed)
- E2E test framework integration (Playwright, Cypress) — just run existing commands
- Monitoring/alerting integration
- Automated rollback on deploy failure
