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

### 设计原则

集成测试不只是验证"跑通了"，而是系统性地覆盖四条验证轴：
1. **多场景覆盖** — 不同类型的目标触发不同的迭代路径
2. **逐轮状态验证** — 每轮迭代后检查状态文件的精确变化
3. **边界场景** — 目标已达成、迭代上限、改进引入新问题
4. **上下文恢复** — 状态文件是否足以在上下文丢失后继续循环

### 测试场景

#### 场景 A：多轮迭代 + 逐轮状态验证（核心路径）

**目标**："修复所有 lint 问题"
**测试项目**：Python 项目，多个文件共 15+ 个 lint 问题（未使用导入、缺少类型注解、过长函数），配置 ruff。
**max-iterations**: 5

**验证点**：

| 验证阶段 | 检查内容 |
|----------|---------|
| 初始化后 | 状态文件已创建，Status = ACTIVE，Iteration = 1/5，Goal 包含用户原始目标 |
| 每轮迭代后 | Iteration 计数递增（1→2→3...），Iteration History 追加新条目，Backlog 至少一个 `[x]` 标记 |
| Backlog 演化 | 新发现的改进项出现在 Backlog 中（不只是初始扫描结果），优先级有调整 |
| 每轮 commit | `git log` 新增至少一个 commit，commit message 与当前改进项相关 |
| 完成时 | 输出包含 `<goal-loop-complete>`，Status = COMPLETED，所有 Backlog 项 `[x]` |

**逐轮状态验证脚本模式**：
```bash
# 在 goal-loop 运行后，解析状态文件验证每轮
STATE_FILE="$TEST_DIR/.claude/goal-loop-state.md"

# 提取迭代计数
iter_count=$(grep -c "^### Iteration" "$STATE_FILE")
assert_count "$iter_count" "至少 2 轮迭代" 2

# 验证迭代计数递增（从 history section 提取）
# 验证 backlog 项从 [ ] 变为 [x]

# 验证 git commits 数量 >= iter_count
commit_count=$(git -C "$TEST_DIR" log --oneline | wc -l)
```

#### 场景 B：代码结构优化（不同迭代路径）

**目标**："优化代码结构，减少重复"
**测试项目**：一个 `utils.py` 包含 3 组重复代码块（每组 10-15 行），并有 copy-paste 函数。
**max-iterations**: 3

**验证点**：
- agent 识别出重复代码并加入 Backlog
- 使用 `summ:improve-architecture` 或 `summ:to-do-it` 执行（非 tdd，因为是重构）
- 每轮消除一组重复
- 完成后代码行数减少、功能不变（无副作用）
- Status = COMPLETED

#### 场景 C：目标已达成（0 轮完成）

**目标**："修复所有 lint 问题"
**测试项目**：干净的 Python 项目，零 lint 错误。
**max-iterations**: 5

**验证点**：
- 状态文件创建，Iteration = 1/5
- agent 评估后立即自评通过（Step 3 三个问题全 pass）
- Status = COMPLETED，Iteration history 仅 1 条（"no work needed"）
- 输出包含 `<goal-loop-complete>`
- 无代码 commit（无需改动）

#### 场景 D：迭代上限触发（ABORTED）

**目标**："完全重构整个项目架构为微服务"
**测试项目**：单体 Flask 应用（5-6 个路由），架构问题显著。
**max-iterations**: 2（故意设低以触发上限）

**验证点**：
- 状态文件 Iteration 达到 2/2
- Status = ABORTED
- 输出包含 "progress" 或 "remaining" 或 "backlog"（不丢弃进度建议）
- Backlog 仍有 `[ ]` 未完成项
- 至少 1 次 git commit（已完成的工作保留）
- 无 `<goal-loop-complete>` promise

#### 场景 E：改进引入新问题（自评失败 + 回退修复）

**目标**："改进错误处理"
**测试项目**：Python 项目，函数用裸 `except:` 和 `pass` 处理错误，缺少有意义的错误信息。
**max-iterations**: 4

**验证点**：
- 第 1 轮：agent 改进错误处理，但可能改变了函数签名或引入了新 import
- 自评 Step 3 问题 2（无副作用）应检测到潜在问题
- 如果 agent 检测到副作用：Backlog 新增修复项，继续迭代
- 如果 agent 顺利完成：最终代码同时满足错误处理改进 + 无回归
- 状态文件的 Iteration History 中能看到自我检查的痕迹

#### 场景 F：上下文压缩恢复

**目标**："增加测试覆盖率"
**测试项目**：Python 项目，3 个无测试的函数。
**max-iterations**: 4

**验证策略**：这个场景验证状态文件是真正的"唯一真相来源"。

**验证点**：
- 模拟方式：goal-loop 运行完成后，启动一个新的 `claude -p` 会话
- 新会话 prompt："读取 `.claude/goal-loop-state.md`，告诉我当前 goal-loop 的状态——目标是什么、迭代到第几轮、已完成和未完成的改进项是什么"
- 新会话的回答必须与状态文件内容一致（证明状态文件可被独立解读）
- 关键信息不丢失：Goal 文字、Iteration 计数、Backlog 完成状态、History 条目数

### 超时设置

| 场景 | 超时 | 原因 |
|------|------|------|
| A（核心路径）| 600s | 多轮迭代 + lint 扫描 + 修复 |
| B（代码重构）| 600s | 重构需要更多推理 |
| C（0 轮完成）| 120s | 应该很快完成 |
| D（迭代上限）| 300s | 2 轮就停止 |
| E（自评失败）| 600s | 需要额外的修复轮次 |
| F（上下文恢复）| 300s | 主要是读取验证 |

### 运行顺序

场景按依赖关系排序：
1. C（最快，验证基本机制）→ 如果失败，后续测试无意义
2. A（核心路径，逐轮验证）→ 验证主循环正确性
3. B（不同迭代路径）→ 验证非 lint 场景
4. D（ABORTED）→ 验证上限处理
5. E（自评失败）→ 验证自评机制
6. F（上下文恢复）→ 验证状态文件持久性

每个场景独立运行，前一个失败不阻塞后续（但输出警告）。

## 文件结构

```
tests/claude-code/
├── test-goal-loop.sh                     # 快速单元测试（9 个用例）
├── test-goal-loop-integration.sh         # 集成测试（6 个场景）
└── test-goal-loop-fixtures/              # 测试项目模板
    ├── scenario-a-lint/                  # 多 lint 问题的 Python 项目
    │   ├── pyproject.toml
    │   └── src/
    ├── scenario-b-duplication/           # 重复代码项目
    │   ├── pyproject.toml
    │   └── src/
    ├── scenario-c-clean/                 # 干净项目（零问题）
    │   ├── pyproject.toml
    │   └── src/
    ├── scenario-d-monolith/              # 单体应用项目
    │   ├── pyproject.toml
    │   └── app.py
    └── scenario-e-error-handling/        # 糟糕的错误处理
        ├── pyproject.toml
        └── src/
```

## 运行方式

```bash
# 快速测试（约 5 分钟）
./tests/claude-code/run-skill-tests.sh --test test-goal-loop.sh

# 集成测试（30-60 分钟，6 个场景）
./tests/claude-code/run-skill-tests.sh --integration --test test-goal-loop-integration.sh

# 单个集成场景（开发调试用）
INTEGRATION_SCENARIO=A ./tests/claude-code/run-skill-tests.sh --integration --test test-goal-loop-integration.sh

# 全部 goal-loop 测试
./tests/claude-code/run-skill-tests.sh --test test-goal-loop.sh && \
./tests/claude-code/run-skill-tests.sh --integration --test test-goal-loop-integration.sh
```
