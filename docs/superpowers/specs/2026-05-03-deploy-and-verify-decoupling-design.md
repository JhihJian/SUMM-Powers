# Deploy-and-Verify Decoupling Design

> Date: 2026-05-03
> Status: Draft

## Problem

`deploy-and-verify` is currently wired as a downstream step of `finishing-a-development-branch`. This assumes every workflow goes through branch isolation, but users often develop directly on main or skip the finishing flow. The skill becomes unreachable in those scenarios.

## Goal

Decouple `deploy-and-verify` from `finishing-a-development-branch` so it can be triggered from multiple completion points: after subagent tasks, after plan execution, after simple tasks, or manually.

## Approach

Option A (chosen): Decouple into an independently triggerable skill. Keep existing skill structure, only loosen the dependency. Each upstream skill adds deploy-and-verify as an optional next step at its completion point.

## Changes

### 1. deploy-and-verify SKILL.md

**Integration section** — replace current content with:

```
**Triggered by (any of):**
- **subagent-driven-development** — after all tasks complete and two-stage review passes
- **executing-plans** — after all batches complete
- **to-do-it** — after simple task completes (suggestion only, not automatic)
- **finishing-a-development-branch** — after branch finish (optional, still valid)
- **Manual** — user says "deploy", "上线", "验证"

**Works before:** value-proof (optional)
**Uses convention from:** deploy skill (DEPLOY.md)
```

**Trigger line** — update to include broader triggers:

```
**Trigger:** User asks to deploy, deploy and verify, 上线, 验证. Or agent judges deployment is the natural next step after implementation completes (subagent tasks done, plan execution done, or simple task done).
```

No changes to the core 4-step workflow (read config → deploy → verify → report).

### 2. subagent-driven-development SKILL.md

**Flow graph** — change the terminal node:

- Before: `Dispatch final code reviewer → Use summ:finishing-a-development-branch`
- After: `Dispatch final code reviewer → Check deployability → deploy-and-verify or finishing-a-development-branch`

The "check deployability" decision: if project has `DEPLOY.md` or a clearly deployable target (HTTP service, docker-compose, etc.), offer deploy-and-verify first. Otherwise skip to finishing.

**Integration section** — add `summ:deploy-and-verify` as a subsequent skill option.

### 3. executing-plans SKILL.md

**Step 5** — currently jumps directly to `finishing-a-development-branch`. Change to:

1. If project has deployable target → offer `deploy-and-verify` first
2. Then → `finishing-a-development-branch`

### 4. to-do-it SKILL.md

**Completion section** — add a suggestion after task completion:

```
If project has a DEPLOY.md or deployable target, suggest: "Done! Want to deploy and verify?"
```

This is a prompt only — never automatic.

### 5. finishing-a-development-branch SKILL.md

**Integration section** — add `deploy-and-verify` as an optional follow-up skill. No longer the sole entry point.

## Files to Modify

| File | Change |
|------|--------|
| `skills/deploy-and-verify/SKILL.md` | Rewrite Integration + Trigger |
| `skills/subagent-driven-development/SKILL.md` | Update flow graph + Integration |
| `skills/executing-plans/SKILL.md` | Update Step 5 |
| `skills/to-do-it/SKILL.md` | Add deployment suggestion |
| `skills/finishing-a-development-branch/SKILL.md` | Update Integration |

## Not In Scope

- No new skills created
- No changes to deploy skill (DEPLOY.md convention)
- No changes to value-proof
- No automated retry logic
