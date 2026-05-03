# Deploy-and-Verify Decoupling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summ:subagent-driven-development (recommended) or summ:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Decouple `deploy-and-verify` from `finishing-a-development-branch` so it can be triggered from multiple completion points.

**Architecture:** Each upstream skill gains an optional hook to `deploy-and-verify` at its completion point. The deploy-and-verify skill itself gets a broader trigger description and a rewritten Integration section. No new skills created; only markdown content changes in 5 existing SKILL.md files.

**Tech Stack:** Markdown skill files only. No code, no tests, no build step.

---

## File Structure

| File | Responsibility |
|------|---------------|
| `skills/deploy-and-verify/SKILL.md` | Rewrite Integration + Trigger sections |
| `skills/subagent-driven-development/SKILL.md` | Update flow graph + Integration section |
| `skills/executing-plans/SKILL.md` | Update Step 5 completion flow |
| `skills/to-do-it/SKILL.md` | Add deployment suggestion at completion |
| `skills/finishing-a-development-branch/SKILL.md` | Update Integration section |

## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Update deploy-and-verify SKILL.md | `skills/deploy-and-verify/SKILL.md` | S | Rewrite Trigger + Integration |
| 2 | Update subagent-driven-development SKILL.md | `skills/subagent-driven-development/SKILL.md` | M | Flow graph + Integration |
| 3 | Update executing-plans SKILL.md | `skills/executing-plans/SKILL.md` | S | Step 5 + Integration |
| 4 | Update to-do-it SKILL.md | `skills/to-do-it/SKILL.md` | S | Add deployment suggestion |
| 5 | Update finishing-a-development-branch SKILL.md | `skills/finishing-a-development-branch/SKILL.md` | S | Update Integration |

Complexity: S = ~50 lines, M = ~150 lines

---

### Batch 1 (Tasks 1-5)

### Task 1: Update deploy-and-verify SKILL.md

**Files:**
- Modify: `skills/deploy-and-verify/SKILL.md`

- [ ] **Step 1: Update the Trigger line**

Replace the current Trigger line:

```
**Trigger:** User asks to deploy, deploy and verify, 上线, 验证. Or agent judges deployment is the natural next step after `finishing-a-development-branch`.
```

With:

```
**Trigger:** User asks to deploy, deploy and verify, 上线, 验证. Or agent judges deployment is the natural next step after implementation completes — subagent tasks done, plan execution done, simple task done, or branch finish.
```

- [ ] **Step 2: Rewrite the Integration section**

Replace the current Integration section:

```
## Integration

**Works after:** `finishing-a-development-branch`
**Works before:** `value-proof` (optional)
**Uses convention from:** `deploy` skill (DEPLOY.md)

**Relationship with `deploy` skill:** The `deploy` skill handles DEPLOY.md awareness and maintenance — it reminds you to update DEPLOY.md when infra changes. This skill (`deploy-and-verify`) handles actual deployment execution and verification. Use `deploy` for context, `deploy-and-verify` for action.

**If deployment is not needed** (e.g., library package, skill-only repo): skip this skill and go directly to `value-proof` or simply declare the work done.
```

With:

```
## Integration

**Triggered by (any of):**
- **subagent-driven-development** — after all tasks complete and two-stage review passes
- **executing-plans** — after all batches complete
- **to-do-it** — after simple task completes (suggestion only, not automatic)
- **finishing-a-development-branch** — after branch finish (optional, still valid)
- **Manual** — user says "deploy", "上线", "验证"

**Works before:** `value-proof` (optional)
**Uses convention from:** `deploy` skill (DEPLOY.md)

**Relationship with `deploy` skill:** The `deploy` skill handles DEPLOY.md awareness and maintenance — it reminds you to update DEPLOY.md when infra changes. This skill (`deploy-and-verify`) handles actual deployment execution and verification. Use `deploy` for context, `deploy-and-verify` for action.

**If deployment is not needed** (e.g., library package, skill-only repo): skip this skill and go directly to `value-proof` or simply declare the work done.
```

- [ ] **Step 3: Verify changes**

Read `skills/deploy-and-verify/SKILL.md` and confirm:
- Trigger line mentions all 4 trigger points (subagent, plan, simple task, branch finish)
- Integration section lists all 5 trigger sources
- Core 4-step workflow is untouched

- [ ] **Step 4: Commit**

```bash
git add skills/deploy-and-verify/SKILL.md
git commit -m "refactor: decouple deploy-and-verify from finishing-a-development-branch

Rewrite trigger and integration to support multiple entry points:
subagent-driven-development, executing-plans, to-do-it, and manual.

via [HAPI](https://hapi.run)

Co-Authored-By: HAPI <noreply@hapi.run>"
```

### Task 2: Update subagent-driven-development SKILL.md

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

- [ ] **Step 1: Update the flow graph terminal nodes**

In the `dot` digraph, replace these two nodes:

```
"Dispatch final code reviewer subagent for entire implementation" [shape=box];
"Use summ:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];
```

With:

```
"Dispatch final code reviewer subagent for entire implementation" [shape=box];
"Project has deployable target (DEPLOY.md, docker-compose, HTTP service)?" [shape=diamond];
"Use summ:deploy-and-verify" [shape=box style=filled fillcolor=lightyellow];
"Use summ:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];
```

Then replace the terminal edges:

```
"More tasks remain?" -> "Dispatch final code reviewer subagent for entire implementation" [label="no"];
"Dispatch final code reviewer subagent for entire implementation" -> "Use summ:finishing-a-development-branch";
```

With:

```
"More tasks remain?" -> "Dispatch final code reviewer subagent for entire implementation" [label="no"];
"Dispatch final code reviewer subagent for entire implementation" -> "Project has deployable target (DEPLOY.md, docker-compose, HTTP service)?";
"Project has deployable target (DEPLOY.md, docker-compose, HTTP service)?" -> "Use summ:deploy-and-verify" [label="yes"];
"Project has deployable target (DEPLOY.md, docker-compose, HTTP service)?" -> "Use summ:finishing-a-development-branch" [label="no"];
"Use summ:deploy-and-verify" -> "Use summ:finishing-a-development-branch";
```

- [ ] **Step 2: Update the Integration section**

Replace:

```
**Required workflow skills:**
- **summ:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **summ:writing-plans** - Creates the plan this skill executes
- **summ:requesting-code-review** - Code review template for reviewer subagents
- **summ:finishing-a-development-branch** - Complete development after all tasks

**Subagents should use:**
- **summ:test-driven-development** - Subagents follow TDD for each task

**Fallback (internal):**
- **summ:executing-plans** - Auto-invoked on platforms without subagent support
```

With:

```
**Required workflow skills:**
- **summ:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **summ:writing-plans** - Creates the plan this skill executes
- **summ:requesting-code-review** - Code review template for reviewer subagents
- **summ:deploy-and-verify** - Deploy and verify after all tasks complete (if project has deployable target)
- **summ:finishing-a-development-branch** - Complete development after all tasks

**Subagents should use:**
- **summ:test-driven-development** - Subagents follow TDD for each task

**Fallback (internal):**
- **summ:executing-plans** - Auto-invoked on platforms without subagent support
```

- [ ] **Step 3: Verify changes**

Read `skills/subagent-driven-development/SKILL.md` and confirm:
- Flow graph has the deployability decision diamond
- Both deploy-and-verify and finishing-a-development-branch are reachable
- Integration section lists deploy-and-verify before finishing
- The rest of the skill (per-task loop, review stages) is untouched

- [ ] **Step 4: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "refactor: add deploy-and-verify as optional step after subagent tasks

After final code review, check if project has a deployable target.
If yes, run deploy-and-verify before finishing-a-development-branch.

via [HAPI](https://hapi.run)

Co-Authored-By: HAPI <noreply@hapi.run>"
```

### Task 3: Update executing-plans SKILL.md

**Files:**
- Modify: `skills/executing-plans/SKILL.md`

- [ ] **Step 1: Update Step 5**

Replace the current Step 5:

```
### Step 5: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work"
- **REQUIRED SUB-SKILL:** Use summ:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice
```

With:

```
### Step 5: Complete Development

After all tasks complete and verified:
1. If project has a deployable target (DEPLOY.md, docker-compose.yml, HTTP service):
   - Announce: "I'm using the deploy-and-verify skill to deploy and verify"
   - **OPTIONAL SUB-SKILL:** Use summ:deploy-and-verify
   - Follow that skill to deploy and verify
2. Announce: "I'm using the finishing-a-development-branch skill to complete this work"
3. **REQUIRED SUB-SKILL:** Use summ:finishing-a-development-branch
4. Follow that skill to verify tests, present options, execute choice
```

- [ ] **Step 2: Update the Integration section**

Replace:

```
**Required workflow skills:**
- **summ:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **summ:writing-plans** - Creates the plan this skill executes
- **summ:finishing-a-development-branch** - Complete development after all tasks
```

With:

```
**Required workflow skills:**
- **summ:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **summ:writing-plans** - Creates the plan this skill executes
- **summ:deploy-and-verify** - Deploy and verify after all tasks (if project has deployable target)
- **summ:finishing-a-development-branch** - Complete development after all tasks
```

- [ ] **Step 3: Verify changes**

Read `skills/executing-plans/SKILL.md` and confirm:
- Step 5 has the deployability check before finishing
- Integration section lists deploy-and-verify
- Steps 1-4 are untouched

- [ ] **Step 4: Commit**

```bash
git add skills/executing-plans/SKILL.md
git commit -m "refactor: add deploy-and-verify as optional step in executing-plans

Check for deployable target after all batches complete.
If found, run deploy-and-verify before finishing-a-development-branch.

via [HAPI](https://hapi.run)

Co-Authored-By: HAPI <noreply@hapi.run>"
```

### Task 4: Update to-do-it SKILL.md

**Files:**
- Modify: `skills/to-do-it/SKILL.md`

- [ ] **Step 1: Add deployment suggestion to Step 4**

In the "Verify and Complete" section (### 4. Verify and Complete), after the existing items, add a new step:

Replace:

```
### 4. Verify and Complete
1. Verify (tests/build/lint for code, installation for setup, config applied)
2. **Mark SUMM-Todo done** - `todo done <id> -m "Result of task"` (BLOCKING: cannot clear TodoWrite until done)
3. Summarize changes
4. Clear TodoWrite
```

With:

```
### 4. Verify and Complete
1. Verify (tests/build/lint for code, installation for setup, config applied)
2. **Mark SUMM-Todo done** - `todo done <id> -m "Result of task"` (BLOCKING: cannot clear TodoWrite until done)
3. Summarize changes
4. Clear TodoWrite
5. If project has a `DEPLOY.md` or clearly deployable target, suggest: "Done! Want to deploy and verify? (summ:deploy-and-verify)"
```

- [ ] **Step 2: Verify changes**

Read `skills/to-do-it/SKILL.md` and confirm:
- Step 4 has the deployment suggestion as item 5
- The suggestion is optional (suggest, don't auto-trigger)
- Rest of skill is untouched

- [ ] **Step 3: Commit**

```bash
git add skills/to-do-it/SKILL.md
git commit -m "refactor: suggest deploy-and-verify after simple task completion

Add optional deployment suggestion at end of to-do-it workflow.

via [HAPI](https://hapi.run)

Co-Authored-By: HAPI <noreply@hapi.run>"
```

### Task 5: Update finishing-a-development-branch SKILL.md

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md`

- [ ] **Step 1: Update the Integration section**

Replace:

```
## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 5) - After all batches complete

**Pairs with:**
- **using-git-worktrees** - Cleans up worktree created by that skill
```

With:

```
## Integration

**Called by:**
- **subagent-driven-development** - After all tasks complete (and deploy-and-verify if applicable)
- **executing-plans** - After all batches complete (and deploy-and-verify if applicable)

**Followed by (optional):**
- **deploy-and-verify** - If not already run before this skill

**Pairs with:**
- **using-git-worktrees** - Cleans up worktree created by that skill
```

- [ ] **Step 2: Verify changes**

Read `skills/finishing-a-development-branch/SKILL.md` and confirm:
- Integration lists updated caller descriptions
- deploy-and-verify appears as optional follow-up
- Core 4-option workflow (merge, PR, keep, discard) is untouched

- [ ] **Step 3: Commit**

```bash
git add skills/finishing-a-development-branch/SKILL.md
git commit -m "refactor: update finishing-a-development-branch integration

Add deploy-and-verify as optional follow-up. Update caller references.

via [HAPI](https://hapi.run)

Co-Authored-By: HAPI <noreply@hapi.run>"
```
