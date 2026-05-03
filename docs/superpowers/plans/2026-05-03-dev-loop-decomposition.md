# dev-loop Decomposition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summ:subagent-driven-development (recommended) or summ:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Delete the over-engineered dev-loop skill and replace it with two small, single-responsibility skills (deploy-and-verify, value-proof) that compose with the existing SUMM pipeline.

**Architecture:** Straightforward delete-and-create. Two new skill files, each a single SKILL.md (~80 lines). Delete dev-loop directory and 5 related docs. Update CLAUDE.md pipeline description.

**Tech Stack:** Markdown skill files only. No code, no scripts, no tests to run.

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `skills/deploy-and-verify/SKILL.md` | Create | Deploy execution + post-deploy verification |
| `skills/value-proof/SKILL.md` | Create | Requirement vs delivery comparison |
| `skills/dev-loop/SKILL.md` | Delete | — |
| `skills/dev-loop/master-prompt.md` | Delete | — |
| `skills/dev-loop/worker-prompt-template.md` | Delete | — |
| `skills/dev-loop/pressure-test-scenarios.md` | Delete | — |
| `skills/dev-loop/scripts/init.sh` | Delete | — |
| `skills/dev-loop/scripts/validate.sh` | Delete | — |
| `docs/superpowers/specs/2026-04-30-dev-loop-design.md` | Delete | — |
| `docs/superpowers/specs/2026-05-02-dev-loop-observability-design.md` | Delete | — |
| `docs/superpowers/plans/2026-04-30-dev-loop-skill.md` | Delete | — |
| `docs/superpowers/plans/2026-04-30-dev-loop-e2e-test-plan.md` | Delete | — |
| `docs/superpowers/examples/dev-loop-agent-orchestrator.yaml` | Delete | — |
| `CLAUDE.md` | Modify | Update pipeline description and dev-loop references |

---

## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Create deploy-and-verify skill | `skills/deploy-and-verify/SKILL.md` | M | Extract deploy+verify from dev-loop |
| 2 | Create value-proof skill | `skills/value-proof/SKILL.md` | M | Extract value proof from dev-loop |
| 3 | Delete dev-loop and related docs | 12 files | S | Clean removal |
| 4 | Update CLAUDE.md | `CLAUDE.md` | S | Pipeline description + remove dev-loop refs |

Complexity: S = ~50 lines, M = ~150 lines. Total: 2M + 2S = well under budget.
Single batch: all 4 tasks.

---

### Batch 1 (Tasks 1-4)

### Task 1: Create deploy-and-verify Skill

**Files:**
- Create: `skills/deploy-and-verify/SKILL.md`

- [ ] **Step 1: Create the skill file**

```markdown
---
name: deploy-and-verify
description: Use when deploying an application and verifying the deployment works — reads DEPLOY.md, executes deployment, runs smoke tests or E2E tests, reports structured results. Triggers on "deploy", "deploy and verify", "上线", "验证", or after finishing a development branch.
---

# deploy-and-verify: Deploy and Verify

Deploy the application and verify the deployment works.

**Trigger:** User asks to deploy, deploy and verify, 上线, 验证. Or agent judges deployment is the natural next step after `finishing-a-development-branch`.

## Workflow

### 1. Read Deployment Config

Read `DEPLOY.md` from the project root. If it exists, extract:
- Deploy commands (the steps under "Deployment" section)
- Verification commands or URLs (health endpoints, E2E test commands)
- Environment info (ports, URLs)

If `DEPLOY.md` does not exist:
- Check if the `deploy` skill's template is appropriate — offer to create `DEPLOY.md` using that template
- If user declines, proceed with best-effort deployment (look for `package.json` scripts, `docker-compose.yml`, `Makefile` targets)

### 2. Execute Deployment

Run the deploy commands from DEPLOY.md (or discovered equivalents) using Bash tool directly.

**Pre-deploy cleanup:** If the deploy involves starting a server, kill any existing process on the target port first:
```bash
lsof -ti:$PORT | xargs kill -9 2>/dev/null; true
```

**Execute each deploy step sequentially.** If any step fails, stop and report.

### 3. Verify Deployment

After deployment succeeds, verify it works. Try in order — use the first that applies:

1. **DEPLOY.md has verification commands** → run them
2. **`package.json` has `test:e2e` script** → run `npm run test:e2e`
3. **Deployed a HTTP service** → `curl` the health/root endpoint
4. **None of the above** → report "SKIPPED: no verification configured"

### 4. Report Results

Report structured results:

```
## Deploy & Verify Results

- **Deploy:** SUCCESS | FAILED
- **Verify:** PASSED | FAILED | SKIPPED
- **URL:** <access URL if applicable>
- **Evidence:** <command output showing success or failure>
```

If FAILED at deploy or verify stage:
- Include the error output
- Suggest a likely cause (code bug / config issue / infrastructure)
- Do NOT automatically retry — let agent/human decide next step

## Principles

- **Linear steps.** No state machine, no loop counting.
- **Report, don't retry.** Failure is information, not a trigger for automatic action.
- **Works with Claude Code alone.** No Agent-Orchestrator dependency.
- **Reuses DEPLOY.md convention** from the `deploy` skill.

## Red Flags

| Thought | Reality |
|---------|---------|
| "Deploy probably worked" | Verify with evidence — curl output, test results |
| "I'll skip verification" | Verification is the whole point of this skill |
| "Let me retry automatically" | Report failure, let agent/human decide |
| "I need ao spawn for this" | Use Bash tool directly — this is a single-agent operation |

## Integration

**Works after:** `finishing-a-development-branch`
**Works before:** `value-proof` (optional)
**Uses convention from:** `deploy` skill (DEPLOY.md)
```

- [ ] **Step 2: Commit**

```bash
git add skills/deploy-and-verify/SKILL.md
git commit -m "feat: add deploy-and-verify skill — deploy execution + post-deploy verification"
```

---

### Task 2: Create value-proof Skill

**Files:**
- Create: `skills/value-proof/SKILL.md`

- [ ] **Step 1: Create the skill file**

```markdown
---
name: value-proof
description: Use when verifying that a delivery matches its original requirement — compares requirement points against the actual code diff to produce a structured pass/partial/mismatch/scope-creep assessment. Triggers on "verify delivery", "value proof", "check completeness", "验收", or after deploy-and-verify.
---

# value-proof: Requirement vs Delivery Verification

Compare what was requested against what was delivered. Read the diff, check against the requirement, report gaps.

**Trigger:** User asks to verify delivery, check completeness, value proof, 验收. Or agent judges final acceptance is needed after `deploy-and-verify`.

## Workflow

### 1. Identify the Requirement

Find the original requirement. Try in order:

1. **Design spec** in `docs/superpowers/specs/` — look for the most recent spec matching the current work
2. **Implementation plan** in `docs/superpowers/plans/` — extract the goal and task list
3. **User's original message** — look back in conversation for the request that started this work
4. **Ask user** — if none of the above, ask "What was the original requirement?"

Extract discrete requirement points. If the requirement is a paragraph, break it into individual checkable points.

### 2. Read the Diff

Run these commands to understand what changed:

```bash
git diff <base>..<head> --stat
```

Then read the full diff for details:

```bash
git diff <base>..<head>
```

Determine `<base>` and `<head>`:
- If on a feature branch: base = `main`, head = current branch
- If working on main: base = last commit before work started, head = `HEAD`
- Ask user if unclear

### 3. Evaluate Per Requirement Point

For each requirement point, check: does the diff contain code evidence that this is implemented?

Mark each point:

| Status | Meaning |
|--------|---------|
| EVIDENCED | Code in the diff directly implements this point |
| PARTIAL | Some code exists but coverage is incomplete |
| NO_EVIDENCE | No code in the diff relates to this point |

**Be specific.** For each point, name the file(s) and function(s) that provide evidence. "Tests pass" is not evidence — code that implements the requirement is evidence.

### 4. Check Scope

Scan the diff for changes NOT related to any requirement point:
- Files changed that aren't explained by any requirement
- Features added that weren't requested
- Refactoring or cleanup mixed into the delivery

### 5. Report

```
## Value Proof Report

**Requirement:** <first 80 chars of requirement>
**Branch:** <branch> vs <base>
**Verdict:** PASS | PARTIAL | MISMATCH | SCOPE_CREEP

### Requirement Points

| # | Requirement | Status | Evidence |
|---|------------|--------|----------|
| 1 | <point> | EVIDENCED | <file:line or function> |
| 2 | <point> | NO_EVIDENCE | — |
| ... | ... | ... | ... |

### Scope Check

<If scope creep found: list the unrelated changes>
<If clean: "No unrelated changes detected">

### Recommended Next Action

<Based on verdict, suggest what to do>
```

### Verdict Definitions

- **PASS** — Every point EVIDENCED, no unrelated changes. Delivery satisfies the requirement.
- **PARTIAL** — Some points missing evidence. List the gaps so they can be addressed.
- **MISMATCH** — What was built doesn't match what was asked. The implementation direction is wrong.
- **SCOPE_CREEP** — Significant unrelated changes found alongside the requirement work.

## Principles

- **Report only.** No automatic re-plan or re-implement. The agent or human reads the report and decides.
- **Read actual code.** Don't trust reports from previous phases — read the diff yourself.
- **Be strict.** Every point must have evidence. "Close enough" is not PASS.
- **No loop counting.** This is a one-shot assessment.

## Red Flags

| Thought | Reality |
|---------|---------|
| "Tests pass, so it's done" | Tests prove correctness, not completeness |
| "The worker said it's done" | Verify against the requirement, not against reports |
| "Close enough" | Every point needs evidence |
| "I'll skip the scope check" | Scope creep is a real problem |

## Integration

**Works after:** `deploy-and-verify` (or directly after `finishing-a-development-branch` if no deployment needed)
**Uses:** `summ:verification-before-completion` mindset — evidence before claims
```

- [ ] **Step 2: Commit**

```bash
git add skills/value-proof/SKILL.md
git commit -m "feat: add value-proof skill — requirement vs delivery comparison"
```

---

### Task 3: Delete dev-loop and Related Docs

**Files:**
- Delete: `skills/dev-loop/` (entire directory)
- Delete: `docs/superpowers/specs/2026-04-30-dev-loop-design.md`
- Delete: `docs/superpowers/specs/2026-05-02-dev-loop-observability-design.md`
- Delete: `docs/superpowers/plans/2026-04-30-dev-loop-skill.md`
- Delete: `docs/superpowers/plans/2026-04-30-dev-loop-e2e-test-plan.md`
- Delete: `docs/superpowers/examples/dev-loop-agent-orchestrator.yaml`

- [ ] **Step 1: Delete all files**

```bash
git rm -r skills/dev-loop/
git rm docs/superpowers/specs/2026-04-30-dev-loop-design.md
git rm docs/superpowers/specs/2026-05-02-dev-loop-observability-design.md
git rm docs/superpowers/plans/2026-04-30-dev-loop-skill.md
git rm docs/superpowers/plans/2026-04-30-dev-loop-e2e-test-plan.md
git rm docs/superpowers/examples/dev-loop-agent-orchestrator.yaml
```

- [ ] **Step 2: Verify nothing references dev-loop**

```bash
grep -r "dev-loop" skills/ docs/superpowers/ CLAUDE.md --include="*.md" -l
```

Expected: only the decomposition design spec (`2026-05-03-dev-loop-decomposition-design.md`) and this plan file should appear. Any other matches need to be updated in Task 4.

- [ ] **Step 3: Commit**

```bash
git commit -m "refactor: remove dev-loop skill and related docs

Decomposed into deploy-and-verify and value-proof skills.
See docs/superpowers/specs/2026-05-03-dev-loop-decomposition-design.md"
```

---

### Task 4: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update Workflow Pipeline description**

Find the "### Workflow Pipeline" section (around line where it describes the pipeline). Change:

Old:
```
The core development workflow flows through skills in order: `brainstorming` → `using-git-worktrees` → `writing-plans` → `executing-plans`/`subagent-driven-development` → `requesting-code-review` → `finishing-a-development-branch`. `test-driven-development` applies during implementation; `systematic-debugging` applies during debugging.
```

New:
```
The core development workflow flows through skills in order: `brainstorming` → `using-git-worktrees` → `writing-plans` → `executing-plans`/`subagent-driven-development` → `requesting-code-review` → `finishing-a-development-branch` → `deploy-and-verify` (optional) → `value-proof` (optional). `test-driven-development` applies during implementation; `systematic-debugging` applies during debugging.
```

- [ ] **Step 2: Update Repository Structure — remove dev-loop entry, add new skills**

Find the `- `skills/<name>/SKILL.md`` bullet in Repository Structure. After it, verify there is no dev-loop specific entry. If there was a reference to `skills/brainstorming/scripts/` or dev-loop specific entries, remove them.

Find any line mentioning `dev-loop` in CLAUDE.md and update it. Specifically:
- Remove any reference to "dev-loop" in the skill system description
- The `Subagent-Driven Development` section should remain unchanged (it's a separate skill)
- The `Batch Plan Generation` section should remain unchanged

- [ ] **Step 3: Verify CLAUDE.md has no stale dev-loop references**

```bash
grep -i "dev-loop\|dev loop" CLAUDE.md
```

Expected: no matches.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md pipeline — replace dev-loop with deploy-and-verify and value-proof"
```
