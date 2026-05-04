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