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

### Step 5: Generate Report

Output a structured report:

```
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
