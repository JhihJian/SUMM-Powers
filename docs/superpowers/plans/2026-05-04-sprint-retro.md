# Sprint Retro Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summ:subagent-driven-development (recommended) or summ:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a standalone `retro` skill with cross-session pattern accumulation that analyzes work processes and generates GitHub issues for continuous improvement.

**Architecture:** Three new files only — no modifications to existing skills. The skill reads git history, plan/spec files, and a `.claude/retro-history.md` state file to perform five-dimension analysis and generate structured reports with optional GitHub issue creation.

**Tech Stack:** Markdown skill definition, Bash test script, `gh` CLI for issue creation.

---

## File Structure

| File | Responsibility |
|------|---------------|
| `commands/retro.md` | Slash command wrapper — invokes `summ:retro` skill |
| `skills/retro/state-schema.md` | Template for `.claude/retro-history.md` state file |
| `skills/retro/SKILL.md` | Main skill definition — workflow, analysis dimensions, report format, issue generation |
| `tests/claude-code/test-retro.sh` | Structural test — verifies SKILL.md frontmatter, sections, and state schema |

No existing files modified. Zero invasion.

---

## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Command wrapper | `commands/retro.md` | S | Thin wrapper following existing pattern |
| 2 | State schema template | `skills/retro/state-schema.md` | S | Template + field rules |
| 3 | Structural test (TDD baseline) | `tests/claude-code/test-retro.sh` | M | Verify frontmatter, all 5 dimensions, report format, issue logic, state schema |
| 4 | Main SKILL.md | `skills/retro/SKILL.md` | L | Complete skill: workflow, analysis, report, issue generation |
| 5 | Verify + commit | All | S | Run test, verify pass, commit |

---

### Batch 1 (Tasks 1-3)

### Task 1: Command Wrapper

**Files:**
- Create: `commands/retro.md`

- [ ] **Step 1: Create the command file**

```markdown
---
description: "Use the summ:retro skill for work process retrospective — analyzes plan vs actual, detects cross-session patterns, and generates GitHub issues for continuous improvement"
---

Invoke the summ:retro skill and follow it exactly as presented to you

ARGUMENTS: Pass through any arguments (e.g. '--since <ref>' for specific commit range, '--full' for goal-loop history analysis) to the skill
```

- [ ] **Step 2: Verify file structure**

Run: `cat commands/retro.md`
Expected: File exists with YAML frontmatter containing `description:` and body invoking `summ:retro`

- [ ] **Step 3: Commit**

```bash
git add commands/retro.md
git commit -m "feat: add /retro slash command wrapper"
```

---

### Task 2: State Schema Template

**Files:**
- Create: `skills/retro/state-schema.md`

- [ ] **Step 1: Create the state schema file**

```markdown
# Retro History State File Schema

This file defines the format for `.claude/retro-history.md`, which the retro skill reads and writes each run.

## Template

```markdown
# Retro History

## Pattern Library
<!-- 跨 retro 积累的重复模式，由分析引擎维护 -->
<!-- 格式: - [P<id>] <模式描述> (出现 <N> 次, 首次: <date>, 最近: <date>) -->
<!-- 状态标记: ⚠️ active | ✓ resolved | 👁️ observing -->

## Retros

### Retro <N> — <date>
**Scope:** <plan name 或 "manual session">
**Base commit:** <sha>
**Head commit:** <sha>

#### Plan vs Actual
| # | 计划任务 | 估算复杂度 | 实际规模 | 偏差 | 原因 |
|---|---------|-----------|---------|------|------|
| 1 | <task desc> | S/M/L | <commits + diff lines> | underestimated/overestimated/missed/extra | <why> |

Note: "实际规模" 用 commit 数量和 diff 行数度量（AI 代理无真实时间概念）。

#### Findings
- **[F1]** <发现描述> → 类型: 流程改进|技能缺陷|Bug|技能优化

#### Patterns Detected
- 模式匹配: [P<N>] 第 <N> 次出现
- 新模式: [P<new>] <描述>

#### Actions Taken
- Issue #<N>: <title> — created|skipped|merged
```

## Field Rules

- **Pattern Library**: Maintained by the analysis engine. Each pattern has an auto-incremented ID (P1, P2, ...). Count and dates are updated on match. Patterns not matched in 30+ days are marked `✓ resolved`. Patterns matched only once are marked `👁️ observing`.
- **Retro entries**: Append-only. Never modify past retro entries. Each retro gets an auto-incremented number.
- **Plan vs Actual**: Only populated when a matching plan file is found. When no plan exists, this section contains "No plan file found — git-only analysis."
- **Findings**: Each finding has a unique ID within the retro (F1, F2, ...) and a type classification. Types: 流程改进 (process), 技能缺陷 (skill gap), Bug (bug/tech debt), 技能优化 (skill optimization).
- **Patterns Detected**: Lists which known patterns matched and any new patterns discovered. New patterns are promoted from observing to active after appearing in 2+ retros.
- **Actions Taken**: Records which GitHub issues were created, skipped (duplicate), or merged from this retro.
```

- [ ] **Step 2: Verify file structure**

Run: `cat skills/retro/state-schema.md`
Expected: File exists with Template section containing the full markdown template and Field Rules section.

- [ ] **Step 3: Commit**

```bash
git add skills/retro/state-schema.md
git commit -m "feat: add retro state schema template"
```

---

### Task 3: Structural Test (TDD Baseline)

**Files:**
- Create: `tests/claude-code/test-retro.sh`

This test is written FIRST and will FAIL until Task 4 implements SKILL.md. This is the TDD baseline.

- [ ] **Step 1: Write the structural test**

```bash
#!/usr/bin/env bash
# Test: Retro Skill structural verification
# Verifies SKILL.md has valid frontmatter, all 5 analysis dimensions, report format,
# issue generation logic, and state schema consistency
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILLS_DIR="$(cd "$SCRIPT_DIR/../../skills" && pwd)"
SKILL_FILE="$SKILLS_DIR/retro/SKILL.md"
SCHEMA_FILE="$SKILLS_DIR/retro/state-schema.md"

echo "=== Test: Retro Skill ==="
echo ""

# ============================================================
# Layer 1: File existence and frontmatter
# ============================================================

echo "--- Layer 1: Files and frontmatter ---"
echo ""

# Test 1: SKILL.md exists
echo "Test 1: SKILL.md exists..."
if [ ! -f "$SKILL_FILE" ]; then
    echo "  [FAIL] skills/retro/SKILL.md does not exist"
    exit 1
fi
echo "  [PASS] SKILL.md exists"

# Test 2: Valid YAML frontmatter with name
echo "Test 2: frontmatter has 'name: retro'..."
name_line=$(head -5 "$SKILL_FILE" | grep "^name:" || true)
if [ -z "$name_line" ]; then
    echo "  [FAIL] Missing 'name:' in frontmatter"
    exit 1
fi
if ! echo "$name_line" | grep -q "retro"; then
    echo "  [FAIL] name is not 'retro'"
    exit 1
fi
echo "  [PASS] frontmatter name is retro"

# Test 3: frontmatter has description
echo "Test 3: frontmatter has description..."
if ! head -10 "$SKILL_FILE" | grep -q "^description:"; then
    echo "  [FAIL] Missing 'description:' in frontmatter"
    exit 1
fi
echo "  [PASS] frontmatter has description"

# Test 4: state-schema.md exists
echo "Test 4: state-schema.md exists..."
if [ ! -f "$SCHEMA_FILE" ]; then
    echo "  [FAIL] skills/retro/state-schema.md does not exist"
    exit 1
fi
echo "  [PASS] state-schema.md exists"

# ============================================================
# Layer 2: Five analysis dimensions
# ============================================================

echo ""
echo "--- Layer 2: Five analysis dimensions ---"
echo ""

dimensions=(
    "Plan Accuracy"
    "Skill Coverage"
    "Code Pattern"
    "Workflow Efficiency"
    "Skill Quality"
)

i=5
for dim in "${dimensions[@]}"; do
    echo "Test $i: Analysis dimension '$dim' exists..."
    if ! grep -qi "$dim" "$SKILL_FILE"; then
        echo "  [FAIL] Missing analysis dimension: $dim"
        exit 1
    fi
    echo "  [PASS] Dimension '$dim' found"
    i=$((i + 1))
done

# ============================================================
# Layer 3: Workflow steps
# ============================================================

echo ""
echo "--- Layer 3: Workflow steps ---"
echo ""

workflow_steps=(
    "Data Collection\|数据采集\|Phase 1"
    "Analysis\|分析引擎\|Phase 2"
    "Pattern Recognition\|模式识别\|Pattern"
    "Report\|报告"
    "Issue\|Issue"
)

for step in "${workflow_steps[@]}"; do
    echo "Test $i: Workflow step matching '$step' exists..."
    if ! grep -qi "$step" "$SKILL_FILE"; then
        echo "  [FAIL] Missing workflow step: $step"
        exit 1
    fi
    echo "  [PASS] Workflow step found"
    i=$((i + 1))
done

# ============================================================
# Layer 4: Report format and issue generation
# ============================================================

echo ""
echo "--- Layer 4: Report and issues ---"
echo ""

# Test: Report format section
echo "Test $i: Report format section exists..."
if ! grep -qi "retro report\|报告格式" "$SKILL_FILE"; then
    echo "  [FAIL] Missing report format section"
    exit 1
fi
echo "  [PASS] Report format section found"
i=$((i + 1))

# Test: Four finding types
echo "Test $i: Four finding types (流程/技能缺陷/Bug/技能优化)..."
finding_types=("流程" "技能缺陷" "Bug" "技能优化")
for ftype in "${finding_types[@]}"; do
    if ! grep -q "$ftype" "$SKILL_FILE"; then
        echo "  [FAIL] Missing finding type: $ftype"
        exit 1
    fi
done
echo "  [PASS] All four finding types found"
i=$((i + 1))

# Test: gh issue create mentioned
echo "Test $i: Issue creation via gh CLI..."
if ! grep -qi "gh issue create\|gh issue" "$SKILL_FILE"; then
    echo "  [FAIL] Missing gh issue create instructions"
    exit 1
fi
echo "  [PASS] gh issue create instructions found"
i=$((i + 1))

# Test: Pattern Library in schema
echo "Test $i: Pattern Library in state schema..."
if ! grep -qi "pattern library" "$SCHEMA_FILE"; then
    echo "  [FAIL] Missing Pattern Library in state schema"
    exit 1
fi
echo "  [PASS] Pattern Library found in state schema"

echo ""
echo "=== All tests passed ==="
```

- [ ] **Step 2: Make test executable and run to verify failure**

```bash
chmod +x tests/claude-code/test-retro.sh
bash tests/claude-code/test-retro.sh
```

Expected: FAIL with "skills/retro/SKILL.md does not exist" (Test 1). This confirms the test is correctly validating the skill structure.

- [ ] **Step 3: Commit**

```bash
git add tests/claude-code/test-retro.sh
git commit -m "test: add structural test for retro skill (TDD baseline)"
```

---

### Batch 2 (Task 4)

### Task 4: Main SKILL.md

**Files:**
- Create: `skills/retro/SKILL.md`

This is the core implementation. The skill is a structured markdown document that guides the agent through the entire retro workflow.

- [ ] **Step 1: Create the skill file with frontmatter and overview**

```markdown
---
name: retro
description: Use when performing a work process retrospective — analyzes plan vs actual, detects cross-session patterns in .claude/retro-history.md, generates structured reports, and creates GitHub issues for continuous improvement. Triggers on "retro", "retrospective", "回顾", "复盘". Manual trigger only via /retro.
---

# Retro: Work Process Retrospective

## Overview

Analyze completed work to extract process insights, detect recurring patterns, and generate actionable improvements as GitHub issues. Powered by cross-session state accumulation in `.claude/retro-history.md`.

**Core principle:** Reflect on HOW work was done, not just WHAT was delivered. `value-proof` checks the product; `retro` checks the process.

**Announce at start:** "I'm using the retro skill to perform a work process retrospective."

## Trigger

Manual only:
```
/retro                    — analyze latest complete work cycle
/retro --since <ref>      — analyze specific commit range
/retro --full             — include goal-loop history analysis
```

Zero invasion — this skill reads files only and never modifies other skills.
```

- [ ] **Step 2: Add the workflow section**

Append to the same file:

```markdown
## Workflow

```
┌──────────────────────────────────────────────┐
│  STEP 1: Determine Scope                     │
│  Find base/head commits, locate plan/spec    │
└──────────────────┬───────────────────────────┘
                   │
                   v
┌──────────────────────────────────────────────┐
│  STEP 2: Collect Data                        │
│  git log, git diff, plan files, spec files   │
└──────────────────┬───────────────────────────┘
                   │
                   v
┌──────────────────────────────────────────────┐
│  STEP 3: Five-Dimension Analysis             │
│  Plan Accuracy, Skill Coverage, Code         │
│  Patterns, Workflow Efficiency, Skill Quality│
└──────────────────┬───────────────────────────┘
                   │
                   v
┌──────────────────────────────────────────────┐
│  STEP 4: Pattern Recognition                 │
│  Read .claude/retro-history.md, match        │
│  findings to known patterns, detect new ones │
└──────────────────┬───────────────────────────┘
                   │
                   v
┌──────────────────────────────────────────────┐
│  STEP 5: Generate Report                     │
│  Structured report with findings,            │
│  pattern trends, suggested issues            │
└──────────────────┬───────────────────────────┘
                   │
                   v
┌──────────────────────────────────────────────┐
│  STEP 6: User Confirms Issues                │
│  User selects which issues to create         │
│  gh issue create for each selected           │
└──────────────────┬───────────────────────────┘
                   │
                   v
┌──────────────────────────────────────────────┐
│  STEP 7: Update State File                   │
│  Append retro entry to .claude/retro-history │
│  Update Pattern Library                      │
└──────────────────────────────────────────────┘
```
```

- [ ] **Step 3: Add Step 1 (Determine Scope)**

```markdown
### Step 1: Determine Scope

Determine the commit range to analyze.

**If `--since <ref>` provided:** base = `<ref>`, head = `HEAD`.

**Otherwise, find the last completed work cycle:**

```bash
# Find the most recent plan commit (if exists)
git log --oneline --all -- "docs/superpowers/plans/" | head -1

# Find the most recent spec commit
git log --oneline --all -- "docs/superpowers/specs/" | head -1

# Default: last 20 commits on current branch
git log --oneline -20
```

Determine base and head:
- If a plan file exists matching the current work: base = commit before the plan was created
- If on a feature branch: base = merge-base with main, head = HEAD
- Fallback: ask user "What commit range should I analyze?"

**Locate plan/spec files:**
```bash
# Check for matching plan
ls docs/superpowers/plans/ 2>/dev/null | tail -5

# Check for matching spec
ls docs/superpowers/specs/ 2>/dev/null | tail -5
```

If found, note the file paths for Step 2.
```

- [ ] **Step 4: Add Step 2 (Collect Data)**

```markdown
### Step 2: Collect Data

Gather evidence from three sources.

**Git history:**
```bash
# Commit list with messages
git log <base>..<head> --oneline

# Change statistics
git diff <base>..<head> --stat

# Full diff (for detailed analysis)
git diff <base>..<head>

# Per-commit breakdown
git log <base>..<head> --format="%h %s" --shortstat

# Hot files (most changed)
git log <base>..<head> --pretty=format: --name-only | sort | uniq -c | sort -rn | head -10
```

**Plan file (if found):**
Read the plan from `docs/superpowers/plans/`. Extract:
- Task list with complexity labels (S/M/L)
- Task descriptions and acceptance criteria

**Spec file (if found):**
Read the spec from `docs/superpowers/specs/`. Extract:
- Original requirements
- Design decisions and their rationale

**Goal-loop state (if `--full`):**
Read `.claude/goal-loop-state.md` if it exists. Extract iteration history and improvement backlog.

**State history:**
Read `.claude/retro-history.md` if it exists. Extract Pattern Library and previous retro entries.
```

- [ ] **Step 5: Add Step 3 (Five-Dimension Analysis)**

```markdown
### Step 3: Five-Dimension Analysis

Analyze the collected data across five dimensions. Each dimension produces findings classified into one of four types: 流程改进 (process), 技能缺陷 (skill gap), Bug (bug/tech debt), 技能优化 (skill optimization).

#### Dimension 1: Plan Accuracy

**Only when a plan file was found.** Skip if no plan.

Compare planned tasks against actual git changes:

| Check | Method |
|-------|--------|
| Task completion | For each planned task, search git diff for code evidence (file paths, function names mentioned in the task) |
| Complexity accuracy | Compare estimated S/M/L against actual diff size: S ≈ <50 lines, M ≈ 50-200 lines, L ≈ >200 lines |
| Missing tasks | Planned tasks with no commit or diff evidence |
| Extra work | Commits/changes not explained by any planned task |

**Deviation types:**
- `underestimated` — actual diff much larger than estimated complexity
- `overestimated` — actual diff much smaller than estimated complexity
- `missed` — planned but no evidence of implementation
- `extra` — implemented but not in plan

**Finding type:** 流程改进

#### Dimension 2: Skill Coverage

Analyze which skills were used during the work cycle:

| Check | Method |
|-------|--------|
| Skills invoked | Search commit messages for skill names (e.g., "using brainstorming", "TDD", "writing-plans") |
| Skills skipped | If a plan references a workflow (e.g., TDD), did the commits follow it? |
| Skills missing | Based on the work done, were there skills that SHOULD have been used but weren't? |

**Finding type:** 技能缺陷

#### Dimension 3: Code Patterns

Detect code-level issues from the diff:

| Check | Method |
|-------|--------|
| Hot files | Files changed 3+ times in the range → possible unstable module |
| Large diffs | Single files with >300 lines changed → may need splitting |
| Repeated patterns | Similar code changes across multiple files → missing abstraction |
| TODO/FIXME accumulation | New TODO/FIXME comments added → tech debt |

**Finding type:** Bug / 技术债

#### Dimension 4: Workflow Efficiency

Analyze the work process for inefficiencies:

| Check | Method |
|-------|--------|
| Rework detection | Commits that revert or redo previous changes (keywords: "fix", "revert", "redo", "correct") |
| False starts | Commits that add then remove the same code |
| Commit quality | Commit messages following conventions vs vague messages ("wip", "fix", "update") |
| Batch size | Very large commits (>500 lines) → possible lack of incremental commits |

**Finding type:** 流程改进

#### Dimension 5: Skill Quality

Evaluate how effectively skills were applied:

| Check | Method |
|-------|--------|
| TDD compliance | If TDD was used, are test commits before implementation commits? |
| Review quality | If code review was done, were review comments addressed? |
| Plan adherence | Did execution follow the plan or diverge significantly? |
| Spec alignment | Does the final code match the spec's design decisions? |

**Finding type:** 技能优化
```

- [ ] **Step 6: Add Step 4 (Pattern Recognition)**

```markdown
### Step 4: Pattern Recognition

Cross-reference current findings with historical patterns from `.claude/retro-history.md`.

**If `.claude/retro-history.md` does not exist:** Skip pattern matching. All findings are "new observations". Initialize the state file in Step 7.

**If it exists:**

1. Read the Pattern Library section at the top of the file
2. For each current finding, check if it matches an existing pattern (P1, P2, ...)
3. Matching criteria: same finding type AND same root cause area (e.g., "plan estimation" or "TDD compliance")

**Pattern lifecycle:**

| State | Condition | Action |
|-------|-----------|--------|
| `👁️ observing` | Pattern appeared once | No issue recommended. Wait for second occurrence. |
| `⚠️ active` | Pattern appeared 2+ times | Strongly recommend creating an issue. |
| `✓ resolved` | Pattern not matched in 30+ days | Mark as resolved. Mention in trends. |

**New pattern detection:**
- Current finding does NOT match any existing pattern
- Tag as `[P<next>] 👁️ observing` in Pattern Library
- First occurrence → no issue recommended, just report

**Stale issue check:**
For each pattern with previously created issues:
```bash
gh issue view <issue-number> --json state,title 2>/dev/null
```
If still open after previous retro → mark as `stale` in report.
```

- [ ] **Step 7: Add Step 5 (Generate Report)**

```markdown
### Step 5: Generate Report

Output a structured report:

```markdown
## Retro Report — <date>

**Scope:** <plan name 或 session scope>
**Range:** <base>..<head> (<N> commits, <+X/-Y> lines, <Z> files)
**Pattern Status:** <M> active patterns, <K> resolved, <N> new observations

### Plan vs Actual Summary
| Metric | Value |
|--------|-------|
| Planned tasks | <N> (or "No plan found") |
| Completed | <N> |
| Deviations | underestimated: N, overestimated: N, missed: N, extra: N |
| Change scale | <+N/-N> lines across <N> files |

### Findings

#### 流程改进
| # | Finding | Pattern | Evidence | Suggestion |
|---|---------|---------|----------|------------|

#### 技能缺陷
| # | Finding | Pattern | Evidence | Suggestion |
|---|---------|---------|----------|------------|

#### Bug / 技术债
| # | Finding | Pattern | Evidence | Suggestion |
|---|---------|---------|----------|------------|

#### 技能优化
| # | Finding | Pattern | Evidence | Suggestion |
|---|---------|---------|----------|------------|

### Pattern Trends
- [P<N>] <desc> — <N>th occurrence ⚠️ worsening / stable
- [P<N>] <desc> — <N> days absent ✓ likely resolved
- [P<N>] <desc> — new 👁️ under observation

### Stale Issues
| Issue | Pattern | Open since | Status |
|-------|---------|-----------|--------|

### Suggested Issues

> Review and confirm which to create (enter numbers or 'all'):
```

The report is shown to the user. Proceed to Step 6 for issue confirmation.
```

- [ ] **Step 8: Add Step 6 (User Confirms Issues)**

```markdown
### Step 6: User Confirms Issues

Present suggested issues and wait for user confirmation.

**Issue filtering (applied before presenting):**

1. **Dedup check:** Run `gh issue list --label retro --state open` to find existing retro issues. Skip findings that duplicate open issues.
2. **Frequency gate:** Findings matching a pattern with count = 1 (`👁️ observing`) → mark as "observe, not creating issue". Do not suggest.
3. **Frequency gate:** Findings matching a pattern with count ≥ 2 (`⚠️ active`) → strongly recommend creating issue.
4. **Bug/tech debt exception:** Bug and tech debt findings → recommend regardless of pattern count.
5. **`gh` not available:** Skip all issue creation. Report-only mode.

**For each suggested issue, prepare:**

Title: `[retro][<type>] <short description>`
Body:
```markdown
## Source
- Retro: <date>
- Finding: F<N>
- Pattern: [P<N>] (seen <N> times)

## Description
<from finding description>

## Evidence
<specific evidence from analysis>

## Suggested Action
<from finding suggestion>
```

Labels: `retro`, `<type-label>` where type-label is one of: `process`, `skill`, `bug`, `enhancement`

**User interaction:**
```
Suggested issues:

1. [retro][process] Plan complexity estimates consistently underestimated
2. [retro][skill] No structured debugging used for error handling failures
3. [retro][bug] Hot file: src/auth/handler.ts changed 5 times

Which to create? (enter numbers like 1,3 or 'all' or 'none')
```

After user confirms:
```bash
gh issue create --title "<title>" --body "<body>" --label "retro,<type>"
```

Show the result (issue URL) for each created issue.
```

- [ ] **Step 9: Add Step 7 (Update State File)**

```markdown
### Step 7: Update State File

Update `.claude/retro-history.md` to record this retro.

**If file does not exist:** Create it using the template from `skills/retro/state-schema.md`. Initialize Pattern Library as empty.

**Update Pattern Library:**
- For matched patterns: increment count, update "最近" date, keep state (`⚠️ active` / `👁️ observing` / `✓ resolved`)
- For new findings: add as `[P<next>] 👁️ observing` (first occurrence)
- For patterns not matched this retro: check if 30+ days since last match → mark `✓ resolved`

**Append retro entry:**
```markdown
### Retro <N> — <date>
**Scope:** <scope>
**Base commit:** <sha>
**Head commit:** <sha>

#### Plan vs Actual
<table from analysis>

#### Findings
<list of findings with IDs and types>

#### Patterns Detected
<patterns matched and new patterns>

#### Actions Taken
<issues created or skipped>
```

The state file is append-only for retro entries and maintained-in-place for the Pattern Library.

No `.gitignore` update needed — `.claude/` is already gitignored.
```

- [ ] **Step 10: Add Red Flags and Integration sections**

```markdown
## Red Flags

| Thought | Reality |
|---------|---------|
| "Everything went fine" | Every work cycle has at least one insight worth capturing |
| "I'll just check the diff" | Retro analyzes the PROCESS, not just the code changes |
| "No patterns found" | First retro has no history — that's expected, not a finding |
| "All findings need issues" | Observing patterns (count=1) don't need issues yet |
| "I'll modify the plan retroactively" | The state file is append-only for retro entries |

## Behavior Constraints

| Constraint | Reason |
|-----------|--------|
| **Read-only for external files** | Never modify plan files, spec files, or other skills |
| **Append-only for retro entries** | Past retros are immutable. Only Pattern Library is maintained |
| **User confirms before issue creation** | Issues are visible to others — require human approval |
| **No auto-trigger** | Retrospectives need willing participation |
| **Graceful degradation** | No `gh` → report-only. No plan → git-only analysis. No history → fresh start |

## Integration

**Position:** After `value-proof` in the workflow pipeline (manual trigger only)

**Interacts with:**
- `value-proof` — retro can reference its report as input
- `goal-loop` — `--full` flag analyzes goal-loop state file
- `health` — retro findings may suggest running health check
- `writing-plans` — plan accuracy findings feed back into plan improvement

**Does NOT modify:** Any existing skill file, command, or configuration.
```

- [ ] **Step 11: Verify skill file is complete**

Run: `wc -l skills/retro/SKILL.md`
Expected: 200+ lines, covering all sections from frontmatter through Integration.

- [ ] **Step 12: Commit**

```bash
git add skills/retro/SKILL.md
git commit -m "feat: add retro skill — work process retrospective with pattern accumulation"
```

---

### Batch 3 (Task 5)

### Task 5: Verify and Final Commit

**Files:**
- All from previous tasks

- [ ] **Step 1: Run the structural test**

```bash
bash tests/claude-code/test-retro.sh
```

Expected: All tests pass with `[PASS]` for each check.

- [ ] **Step 2: If test fails, fix the issue**

Check which test failed and fix the corresponding section in `skills/retro/SKILL.md` or `skills/retro/state-schema.md`.

- [ ] **Step 3: Verify all files exist and are committed**

```bash
git status
ls -la commands/retro.md skills/retro/SKILL.md skills/retro/state-schema.md tests/claude-code/test-retro.sh
```

Expected: All four files exist and are committed. Clean working tree.

- [ ] **Step 4: Final verification — skill loads via command**

The command file references `summ:retro`. Verify the skill name matches:

```bash
grep "^name:" skills/retro/SKILL.md
```

Expected: `name: retro`
