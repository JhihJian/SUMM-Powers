# 架构

本文档描述 SUMM-Powers 的高层架构。如果你想参与贡献或导航代码库，这里就是起点。

遇到文中提到的文件名或模块名时，建议用 symbol search 查找——既能定位目标，也能发现相关的同名实体。

## 全局概览

SUMM-Powers 是一个面向编码代理（Claude Code、Gemini CLI、Copilot CLI）的技能驱动开发工作流系统。一个 **技能（skill）** 是一份 Markdown 文档，引导代理完成结构化的工作流程——TDD、头脑风暴、调试、代码审查等。

系统运行分为三个阶段：

1. **会话启动** — SessionStart 钩子读取 `skills/using-summ/SKILL.md` 并注入到代理的上下文中。这教会代理如何发现和调用其他技能。
2. **按需加载** — 当任务匹配某个技能时，代理调用 `Skill` 工具在运行时加载该技能的完整指令。
3. **执行** — 代理遵循技能的工作流。部分技能会派发子代理进行并行工作；其余则顺序执行。

本项目是 [obra/superpowers](https://github.com/obra/superpowers) 的 fork，通过 cherry-pick 方式跟踪上游。锚点提交记录在 `.upstream-sync` 中。

## 代码地图

### `skills/` — 技能定义

每个子目录是一个技能，包含一个带有 YAML 前置元数据（`name`、`description`）和技能正文的 `SKILL.md` 文件。技能是本项目的核心。

部分技能附带辅助文件（reviewer prompt、实现模板、WebSocket 服务器等），它们与 `SKILL.md` 同目录存放。

按角色分类的主要技能：
- **守门人**：`using-summ/` — 会话启动时加载，教会代理如何使用技能系统
- **工作流管线**：`brainstorming/` → `using-git-worktrees/` → `writing-plans/` → `executing-plans/` 或 `subagent-driven-development/` → `requesting-code-review/` → `finishing-a-development-branch/`
- **实现阶段**：`test-driven-development/`、`systematic-debugging/`
- **工具类**：`skill-finder/`、`health/`、`less/`、`zoom-out/`、`grill-me/`

架构不变量：每个技能都是自包含的。技能之间从不导入或依赖彼此的内部实现。

### `commands/` — 斜杠命令

薄封装层。每个文件是一行代码，通过 `Skill` 工具调用对应的技能。

架构不变量：命令不包含任何逻辑。它们的存在是因为斜杠命令在某些平台上是用户侧的入口点，它们完全委托给技能系统。

### `agents/` — 代理定义

定义子代理角色的 Markdown 文件（如 `code-reviewer.md`）。当主代理通过 Agent 工具派生子代理时加载。每个代理都有包含 `name`、`description` 和 `model` 的 YAML 前置元数据。

### `hooks/session-start` — 会话启动钩子

每个代理会话的入口点。它：
1. 读取 `skills/using-summ/SKILL.md`
2. 将其包装在 `EXTREMELY_IMPORTANT` 上下文块中
3. 以平台特定格式输出 JSON（Claude Code、Cursor 或 Copilot CLI）
4. 在 `~/.claude/skill-telemetry/` 中初始化会话遥测

架构不变量：该钩子是一个 bash 脚本，除 `jq` 外无其他外部依赖。它必须保持快速——每次会话启动时都会运行。

架构不变量：平台检测通过环境变量完成（`CLAUDE_PLUGIN_ROOT`、`CURSOR_PLUGIN_ROOT`、`COPILOT_CLI`）。每个平台获得不同的 JSON 输出格式。

### `.claude-plugin/` — 插件清单

`plugin.json` 定义插件标识和版本。版本遵循 `<上游版本>-summ.<fork版本>` 的模式。`marketplace.json` 处理市场注册。

### `tests/` — 测试套件

按测试类型组织：
- `claude-code/` — 使用 `claude -p`（无头模式）的 Shell 测试。`run-skill-tests.sh` 是运行器；`test-helpers.sh` 提供断言
- `brainstorm-server/` — WebSocket 头脑风暴服务器的 Node.js 测试
- 其他目录测试特定技能行为（`explicit-skill-requests/`、`skill-triggering/`、`subagent-driven-dev/`、`telemetry/`）

### `docs/` — 设计与规划产物

- `docs/superpowers/specs/` — 头脑风暴工作流产出的设计规格（`YYYY-MM-DD-<主题>-design.md`）
- `docs/superpowers/plans/` — 编写计划工作流产出的实施计划
- `docs/upstream-sync-records.md` — 上游同步操作日志

### `scripts/` — 开发者工具

`lint-skills.sh` 校验技能文件；`skill-template.md` 是新技能模板；`summ-stats` 生成使用统计。

## 层边界

系统由三层组成，每层只知道下一层的接口，不知道其实现：

```
钩子层（hooks/session-start）
  ↓ 读取文件、输出 JSON，不知道 skill 内容
命令层（commands/）
  ↓ 调用 Skill tool，不知道 skill 实现
技能层（skills/）
  ← 自包含的 Markdown，不知道上层如何调用它
```

- 钩子不知道技能的内容——它只负责把 `using-summ/SKILL.md` 的原文搬进上下文。
- 命令不知道技能的实现——它只调 `Skill` 工具并传入技能名。
- 技能不知道自己被谁调用——无论是用户手动触发、命令转发、还是子代理加载，技能的行为一致。

代理定义（`agents/`）独立于这三层。它由技能在运行时通过 Agent tool 按需派发，不参与启动链。

### 物理布局说明

`skills/brainstorming/scripts/` 下有一个 WebSocket 服务器，用于实时可视化头脑风暴。它在物理上嵌在 skill 目录里（因为只服务于该技能），但在逻辑上是一个独立进程。修改它时不需要理解技能系统的其他部分。

## 核心不变量

- **技能是 Markdown，不是代码。** 没有运行时或解释器。代理读取 Markdown 并遵循它。
- **技能是发现的，不是导入的。** `using-summ` 技能教授发现启发式。代理根据任务上下文决定加载哪个技能。
- **命令是透传的。** 所有逻辑都在技能中。
- **钩子是无状态的。** 它读取文件、输出 JSON、然后退出。没有守护进程，没有后台进程（遥测初始化除外）。
- **平台差异是表面性的。** 只有 `hooks/session-start` 中的 JSON 输出格式因平台而异。技能和命令与平台无关。

## 横切关注点

### 上游同步

`skills/upstream-sync/` 管理从 `obra/superpowers` 基于 cherry-pick 的同步。该流程读取 `.upstream-sync` 获取锚点提交，cherry-pick 新提交，并将结果记录在 `docs/upstream-sync-records.md` 中。

### 测试策略

测试在无头模式下运行 `claude -p` 并对代理的文本输出进行断言。它们验证技能正确加载、代理遵循指令、技能触发启发式按预期工作。这里没有传统意义上的单元测试——"单元"是代理在给定技能下的行为。

### 技能编写工作流

新技能遵循 `skills/writing-skills/SKILL.md`，它将 TDD 应用于文档：先写压力测试场景，验证其失败，再编写技能，验证其通过，最后重构。
