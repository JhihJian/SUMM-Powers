# Goal Loop: 目标驱动迭代循环技能设计

**日期**: 2026-05-02
**状态**: Approved

## 概述

Goal Loop 是一个目标驱动的持续改进技能。用户提供一个高层目标（如"优化代码质量"、"改进 UI 体验"），技能在单会话内自动迭代：每轮分析当前状态、选择最高价值的改进项、执行、自评，直到目标达成或迭代上限。

**定位**：介于 dev-loop（完整交付流水线）和 ralph-loop（无结构重复）之间。适用于有明确目标但不涉及完整开发交付流程的持续改进场景。

**不适用于**：
- 从零构建新功能 → 用 `summ:dev-loop`
- 一次性小任务 → 用 `summ:to-do-it`
- 调试问题 → 用 `summ:systematic-debugging`

## 触发方式

```
/goal-loop "优化项目代码质量"
/goal-loop "改进 UI 交互体验" --max-iterations 15
/goal-loop "将测试覆盖率提升到 80%" --max-iterations 20
```

参数：
- `<goal>`（必填）：目标描述，用自然语言
- `--max-iterations`（可选）：最大迭代轮数，默认 10

## 核心循环

```
初始化 → [评估 → 自评停止条件 → 选择改进项 → 执行 → 记录] × N → 完成/中止
```

每轮只做**一个**改进项，防止范围蔓延。

## 状态文件

路径：`.claude/goal-loop-state.md`（项目级，加入 gitignore）

```markdown
# Goal Loop State

## Goal
<用户输入的目标文字>

## Status: ACTIVE | COMPLETED | ABORTED

## Iteration: 3/10

## Improvement Backlog
- [x] 修复 lint 警告 (iter 1)
- [x] 重构 utils 模块 (iter 2)
- [ ] 增加单元测试覆盖
- [ ] 优化错误处理

## Iteration History
### Iteration 1 — 修复 lint 警告
- Action: 修复 lint 警告
- Skill used: summ:test-driven-development
- Result: 23 warnings fixed

### Iteration 2 — 重构 utils 模块
- Action: 重构 utils 模块
- Skill used: summ:improve-architecture
- Result: utils 拆分为 3 个聚焦模块
```

## 迭代流程

每轮迭代按以下步骤执行：

### 步骤 1：读取/创建状态文件

- 第一轮：创建状态文件，写入目标和默认配置
- 后续轮：读取状态文件，恢复上下文

### 步骤 2：评估当前状态

- 扫描代码库，对照目标分析当前完成度
- 重新排列 improvement backlog 优先级
- 发现新的改进项加入 backlog
- 移除不再相关的改进项

### 步骤 3：自评停止条件

回答三个问题：

1. **目标达成**：用户的原始目标是否已经满足？
2. **无副作用**：改进过程中没有引入新的问题？
3. **收益递减**：继续迭代的边际收益是否还值得？

三条全部通过 → 标记 COMPLETED，输出总结。
任一不通过 → 继续迭代。

### 步骤 4：选择本轮改进项

- 从 backlog 取优先级最高的一项
- 确定使用的 SUMM 技能（参考技能映射表，但 agent 可根据实际情况调整）

默认技能映射：

| 改进项类型 | 推荐技能 |
|---|---|
| 代码质量/架构改进 | `summ:improve-architecture` |
| 功能开发/Bug 修复 | `summ:test-driven-development` |
| 调试/问题排查 | `summ:systematic-debugging` |
| 代码审查 | `summ:requesting-code-review` |
| 简单小任务 | `summ:to-do-it` |

### 步骤 5：执行改进

- 通过 Skill tool 加载对应技能
- 在当前会话内直接执行改进工作
- 完成后提交代码变更（保证原子性）

### 步骤 6：记录本轮结果

- 更新状态文件：递增迭代计数、标记 backlog 项、添加迭代历史
- 标记本轮改进项为完成或调整

### 步骤 7：检查迭代上限

- 未达上限 → 回到步骤 2
- 达到上限 → 标记 ABORTED，输出当前进展和剩余 backlog 建议

## Completion Promise

当自评通过时，输出：

```
<goal-loop-complete>
目标已达成：[一句话总结]
总迭代轮数：N
关键改进：
- [改进项 1]
- [改进项 2]
- ...
</goal-loop-complete>
```

## 行为约束

- 每轮只做**一个**改进项
- 每轮必须**提交代码**（原子性，方便回滚）
- 状态文件每轮更新（可追溯）
- 达到上限时**不丢弃进度**——输出当前进展和剩余建议
- 不与 dev-loop 冲突：如果检测到 `docs/superpowers/plans/` 下有活跃的 dev-loop 计划，提示用户先完成或中止

## 文件结构

```
skills/goal-loop/
├── SKILL.md              # 技能定义（核心逻辑）
└── state-schema.md       # 状态文件模板参考

commands/goal-loop/       # 斜杠命令定义
```

## 与其他技能的关系

```
brainstorming → goal-loop  （只需持续改进，不需要完整交付）
dev-loop                   （需要从 spec 到交付的完整流程）
ralph-loop                 （外部插件，简单重复，无目标追踪）
```

goal-loop 不依赖 brainstorming 的输出——它接收的是一个目标文字而非设计 spec。但如果用户想先做设计再持续改进，可以先跑 brainstorming 再跑 goal-loop。
