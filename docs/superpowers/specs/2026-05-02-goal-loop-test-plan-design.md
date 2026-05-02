# Goal Loop 验证测试方案设计

**日期**: 2026-05-02
**状态**: Approved

## 概述

为 goal-loop 技能设计两层验证测试：快速单元测试验证 agent 正确理解技能规则，集成测试验证端到端迭代循环行为。

## 测试基础设施

- **运行器**: `tests/claude-code/run-skill-tests.sh`
- **工具函数**: `tests/claude-code/test-helpers.sh`（`run_claude`, `assert_contains`, `assert_not_contains`, `assert_order`）
- **执行方式**: `claude -p` headless 模式

## 第一层：快速单元测试

文件：`tests/claude-code/test-goal-loop.sh`

每个测试用 `run_claude` 向 agent 提问关于 goal-loop 技能的问题，用断言验证回答包含正确的关键概念。

### 测试用例

#### Test 1: 技能识别

```
Prompt: "What is the goal-loop skill? Describe its purpose briefly."
Assert: 输出包含 "goal-loop" 和 "iterat"（迭代）
```

#### Test 2: 迭代限制默认值

```
Prompt: "In the goal-loop skill, what is the default maximum number of iterations if the user doesn't specify --max-iterations?"
Assert: 输出包含 "10"
```

#### Test 3: 自评三问

```
Prompt: "In the goal-loop skill, what are the three self-evaluation questions that determine if the goal is met?"
Assert: 输出包含 "goal" + "side effect"（或 "副作用"）+ "continu"（或 "收益"）
```

#### Test 4: 技能映射

```
Prompt: "In the goal-loop skill, which SUMM skill should be loaded for an architecture improvement item?"
Assert: 输出包含 "improve-architecture"
```

#### Test 5: 每轮一项约束

```
Prompt: "In the goal-loop skill, how many improvement items should be executed per iteration?"
Assert: 输出包含 "one"（或 "1" 或 "single"）
Assert: 输出不包含 "multiple" 或 "several"
```

#### Test 6: 状态文件路径

```
Prompt: "In the goal-loop skill, what is the path of the state file?"
Assert: 输出包含 ".claude/goal-loop-state.md"
```

#### Test 7: Completion promise 格式

```
Prompt: "In the goal-loop skill, what format does the completion promise use when the goal is met?"
Assert: 输出包含 "goal-loop-complete"
```

#### Test 8: 迭代上限处理

```
Prompt: "In the goal-loop skill, what happens when the iteration limit is reached but the goal is not yet met?"
Assert: 输出包含 "ABORTED"
Assert: 输出包含 "progress" 或 "remaining" 或 "backlog"（不丢弃进度）
```

#### Test 9: dev-loop 冲突检测

```
Prompt: "In the goal-loop skill, what does the pre-flight check look for before starting the loop?"
Assert: 输出包含 "dev-loop" 和 "plan"
```

## 第二层：集成测试

文件：`tests/claude-code/test-goal-loop-integration.sh`

### 测试策略

创建一个有已知问题的简单测试项目，让 goal-loop 执行完整迭代循环，验证端到端行为。

### 测试项目设置

创建临时目录，包含：
- 一个有 lint 错误的简单 Python 文件（如未使用的导入、缺少 docstring）
- `pyproject.toml` 配置 ruff 作为 linter
- git 初始化

### 测试流程

1. **Setup**: `create_test_project` 创建临时项目
2. **Execute**: 运行 `claude -p` 触发 goal-loop（目标："修复所有 lint 问题"，限制 3 轮）
3. **Verify**:
   - 状态文件 `.claude/goal-loop-state.md` 已创建
   - 状态文件包含用户目标文字
   - 至少产生 1 次 git commit
   - 输出包含 `goal-loop-complete`（完成）或 `ABORTED`（达到上限）
   - 状态文件 Status 为 COMPLETED 或 ABORTED

### 超时

集成测试超时设为 600 秒（10 分钟），因为需要实际执行多轮迭代。

## 文件结构

```
tests/claude-code/
├── test-goal-loop.sh                 # 快速单元测试（9 个用例）
└── test-goal-loop-integration.sh     # 集成测试（1 个端到端用例）
```

## 运行方式

```bash
# 快速测试（约 5 分钟）
./tests/claude-code/run-skill-tests.sh --test test-goal-loop.sh

# 集成测试（10-30 分钟）
./tests/claude-code/run-skill-tests.sh --integration --test test-goal-loop-integration.sh

# 全部 goal-loop 测试
./tests/claude-code/run-skill-tests.sh --test test-goal-loop.sh && \
./tests/claude-code/run-skill-tests.sh --integration --test test-goal-loop-integration.sh
```
