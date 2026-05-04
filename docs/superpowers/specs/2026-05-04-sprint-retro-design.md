# Sprint Retro Skill Design

> Date: 2026-05-04
> Status: Draft

## Problem

SUMM-Powers 工作流覆盖了从创意到部署的完整 pipeline，但缺少对**工作过程本身**的反思能力。现有技能中：

- `value-proof` 审查交付物 vs 需求
- `health` 审查项目结构健康度
- `goal-loop` 有迭代记录但没有元认知反思

缺少跨迭代的模式识别和持续改进机制——这正是 Scrum Sprint Retrospective 的核心价值。

## Design

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     retro skill                          │
│                                                         │
│  ┌──────────┐   ┌──────────────┐   ┌────────────────┐  │
│  │  数据采集  │──▶│  分析引擎     │──▶│  报告 + Issues │  │
│  └──────────┘   └──────────────┘   └────────────────┘  │
│       │                │                    │            │
│       ▼                ▼                    ▼            │
│  git log         retro-history.md     gh issue create   │
│  plans/          (跨会话状态)          (确认后)          │
│  specs/          模式识别                               │
│  skill files     趋势追踪                               │
└─────────────────────────────────────────────────────────┘
```

Three components:

1. **Data Collector** — gathers work evidence from git history, plan files, spec files
2. **Analysis Engine** — compares plan vs actual, reads historical retro records for pattern recognition
3. **Output** — generates structured report, extracts actionable issues, creates after user confirmation

### State File Schema

Path: `.claude/retro-history.md` (gitignored, append-only)

```markdown
# Retro History

## Pattern Library
<!-- 跨 retro 积累的重复模式，由分析引擎维护 -->
<!-- 格式: - [P<id>] <模式描述> (出现 <N> 次, 首次: <date>, 最近: <date>) -->

## Retros

### Retro 1 — <date>
**Scope:** <plan name 或 "manual session">
**Base commit:** <sha>
**Head commit:** <sha>

#### Plan vs Actual
| # | 计划任务 | 估算复杂度 | 实际规模 | 偏差 | 原因 |
|---|---------|-----------|---------|------|------|

Note: "实际规模" 用 commit 数量和 diff 行数度量（AI 代理无真实时间概念）。

#### Findings
- **[F1]** <发现描述> → 类型: <流程|技能缺陷|Bug|技能优化>

#### Patterns Detected
- 模式匹配: [P1] 第 N 次出现
- 新模式: [P<new>] <描述>

#### Actions Taken
- Issue #<N>: <title> — <status: created|skipped|merged>
```

Key design points:

- **Pattern Library** lives at the top, shared across all retros
- **Individual Retro entries** are append-only, never modify past entries
- **Findings** classified into 4 types: process improvement, skill gap, bug/tech debt, skill optimization
- File is project-local, gitignored (same as `goal-loop-state.md`)

### Analysis Engine

#### Phase 1: Data Collection

| Source | Method | Output |
|--------|--------|--------|
| Git history | `git log <base>..<head>` + `git diff --stat` | commit list, change stats, hot files |
| Plan files | Read matching plan from `docs/superpowers/plans/` | task list, complexity estimates |
| Spec files | Read matching spec from `docs/superpowers/specs/` | original requirements, design intent |

When no plan/spec exists (manual trigger or unplanned work): git-only analysis, skip plan-vs-actual.

#### Phase 2: Current Round Analysis

Five analysis dimensions:

| Dimension | What it checks | Issue type |
|-----------|---------------|------------|
| **Plan Accuracy** | Planned tasks vs actual commits, estimated vs actual diff size | Process improvement |
| **Skill Coverage** | Which skills were invoked, skipped, or missing | Skill gap |
| **Code Patterns** | High-frequency changed files, repeatedly modified modules | Bug/tech debt |
| **Workflow Efficiency** | False starts, retries, rework (inferred from commit messages) | Process improvement |
| **Skill Quality** | Actual effect of skill usage (e.g., did TDD actually write tests first?) | Skill optimization |

**Plan Accuracy logic:**
- Read plan task list with complexity labels (S/M/L)
- Read git diff, associate changes to tasks by commit message or file path
- Compare: claimed completion vs code evidence
- Deviation types: `underestimated`, `overestimated`, `missed` (planned but not done), `extra` (unplanned work)

#### Phase 3: Cross-Session Pattern Recognition

Read Pattern Library from `retro-history.md`, compare with current findings:

- **Existing pattern match:** Current findings hit P1, P2... → increment count, update latest date
- **New pattern:** Similar finding appears 2+ retros → promote to Pattern
- **Pattern decay:** Pattern not hit in 30+ days → mark as `resolved`
- **Action tracking:** Issues created by previous retro still open? (`gh issue view`) → mark as `stale`

### Report Format

```
## Retro Report — <date>

**Scope:** <plan name 或 session scope>
**Range:** <base-commit>..<head-commit> (<N> commits)
**Pattern Hits:** <M> known patterns, <K> new

### Plan vs Actual Summary
| Metric | Value |
|--------|-------|
| Planned tasks | <N> |
| Completed | <N> |
| Deviations | <underestimated: N, overestimated: N, missed: N, extra: N> |
| Change scale | <+N/-N> lines, <N> files |

### Findings

#### 流程改进 / 技能缺陷 / Bug技术债 / 技能优化
| # | Finding | Pattern | Suggestion |
|---|---------|---------|------------|

### Pattern Trends
- [P1] <desc> — 4th occurrence ⚠️ worsening
- [P2] <desc> — 30 days absent ✓ likely resolved
- [P<new>] <desc> — new, under observation

### Suggested Issues

> Confirm which to create: (enter numbers like 1,3,4 or all)

1. **[process]** <title>
   <body preview>
```

### Issue Generation

**Filtering rules:**
- Duplicate open issue exists (`gh issue list`) → skip
- Pattern appeared only once → mark as "observe", don't create issue
- Pattern appeared 2+ times → strongly recommend creating issue
- Bug/tech debt → recommend regardless of frequency

**Issue template:**
```markdown
## Source
- Retro: <date>
- Finding: F<N>
- Pattern: [P<N>] (seen <N> times)

## Description
<from finding and suggestion>

## Evidence
<specific evidence: commit, file, data>

## Suggested Action
<from analysis engine>
```

Auto-assigned labels: `retro`, `process`/`skill`/`bug`/`enhancement`.

**Creation:** After user confirms, execute `gh issue create` for each selected issue.

### Integration Points

**Position in Workflow Pipeline:**

```
brainstorming → worktree → writing-plans → execution →
code-review → finishing-branch → (deploy-and-verify) →
value-proof → ★ retro ★
```

Positioned after `value-proof`. Rationale: retro reflects on the work process after deliverables are verified.

### Trigger Mechanism

Manual only. No auto-trigger, no modification to other skills.

```
/retro                    — analyze latest complete work cycle
/retro --since <ref>      — analyze specific commit range
/retro --full             — include goal-loop history analysis
```

Zero invasion: retro is a standalone skill that only reads existing files and git history.

### Dependencies

| Dependency | Purpose | Fallback |
|------------|---------|----------|
| `gh` CLI | Create issues | Report-only mode |
| `git` | Data collection | Cannot run |
| `docs/superpowers/plans/` | Plan-vs-actual analysis | Git-only analysis |
| `.claude/retro-history.md` | Pattern recognition | Initialize fresh (first retro) |

### Interactions with Existing Skills

| Skill | Interaction |
|-------|-------------|
| `value-proof` | Precedes retro; its report can be retro input |
| `goal-loop` | Retro can analyze goal-loop state file (`--full` mode) |
| `health` | Retro findings may suggest health check but don't invoke it |
| `writing-plans` | Retro's plan-accuracy findings feed back into plan improvement |

## Scope

One skill: `skills/retro/SKILL.md`
One state schema: `skills/retro/state-schema.md` (template for `.claude/retro-history.md`)
One command: `commands/retro.md` (slash command wrapper)

Generic skill — applicable to any project using SUMM workflow. Issue target repo is the current project's git remote.
