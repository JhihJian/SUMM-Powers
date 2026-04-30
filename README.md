# SUMM-Powers

SUMM-Powers 是一个面向编码智能体（Claude Code、Gemini CLI、Copilot CLI）的技能驱动开发工作流系统。项目通过融合三个上游仓库的精华，构建了一套完整的开发方法论：

- **[obra/superpowers](https://github.com/obra/superpowers)** — 核心骨架，提供完整的开发工作流管线
- **[mattpocock/skills](https://github.com/mattpocock/skills)** — 生产力增强，贡献快速验证与架构改进工具
- **[forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — 设计哲学，注入编码行为准则

当前版本：`v5.0.7-summ.2.2`（基于上游 v5.0.7 + SUMM 2.2 扩展）

## 三层吸收架构

### 第一层：obra/superpowers — 核心骨架

项目直接 fork 自 [obra/superpowers](https://github.com/obra/superpowers)，通过定期 cherry-pick 同步上游更新。这 14 个技能构成了完整的开发工作流管线：

| 技能 | 说明 |
|------|------|
| `brainstorming` | Socratic 设计探索，硬门控：无设计不编码 |
| `writing-plans` | 将设计拆解为 2-5 分钟的工程任务 |
| `executing-plans` | 批量执行计划 + 人工检查点 |
| `subagent-driven-development` | 每任务一个新子代理 + 两阶段审查 |
| `dispatching-parallel-agents` | 并行代理分派 |
| `test-driven-development` | RED-GREEN-REFACTOR 循环 |
| `systematic-debugging` | 4 阶段根因分析 |
| `verification-before-completion` | 证据先行，禁止空口声称完成 |
| `using-git-worktrees` | 隔离工作空间 |
| `requesting-code-review` | 代码审查分派 |
| `receiving-code-review` | 代码审查响应指南 |
| `finishing-a-development-branch` | 分支完成流程（merge/PR/keep/discard） |
| `writing-skills` | TDD 方式写技能文档 |
| `using-summ` | 入口技能（基于上游 `using-superpowers` 改造） |

**吸收方式：** Fork + cherry-pick 同步（同步记录见 [docs/upstream-sync-records.md](docs/upstream-sync-records.md)）

### 第二层：mattpocock/skills — 生产力增强

从 [mattpocock/skills](https://github.com/mattpocock/skills) 借鉴核心理念，用 SUMM 风格重新实现。所有借鉴技能均增加了中文触发词支持。

| 原始技能 | SUMM-Powers 对应 | 改造要点 |
|----------|------------------|----------|
| `caveman` | `less` | 超压缩沟通模式，省约 75% token。增加中文触发词："简洁模式"、"少说话多做事" |
| `grill-me` | `grill-me` | 快速决策验证，逐个问题探索决策树。增加中文触发词："烤我"、"帮我验证" |
| `improve-codebase-architecture` | `improve-architecture` | 基于 Ousterhout "深度模块" 理论的架构改进。精简词汇表，去掉附带文件 |
| `zoom-out` | `zoom-out` | 宏观视角展示模块关系。增加中文触发词："退后一步"、"看看大局" |
| `ubiquitous-language` (已废弃) | `domain-language` | 将 Matt 已废弃的 DDD 通用语言技能重新实现为 CONTEXT.md + ADR 管理 |

**吸收方式：** 概念移植 + 本土化重写

**未吸收的部分：** `triage`/`to-issues`/`to-prd`（用 SUMM-Todo 替代）、`diagnose`（与 `systematic-debugging` 重叠）、个人生态相关技能

### 第三层：andrej-karpathy-skills — 设计哲学

[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) 的 4 条编码原则没有作为独立技能存在，而是作为设计哲学渗透到工作流的多个环节：

| Karpathy 原则 | 在 SUMM-Powers 中的体现 |
|---------------|------------------------|
| **Think Before Coding** — 不假设、不隐藏困惑、呈现权衡 | `brainstorming` 的 Socratic 探索；`to-do-it` 的行为准则 |
| **Simplicity First** — 最少代码，不写投机性功能 | `to-do-it`："200 行能变 50 行就重写" |
| **Surgical Changes** — 只改必须改的 | `to-do-it` 的手术式变更原则 |
| **Goal-Driven Execution** — 定义成功标准，循环验证 | `verification-before-completion` 的证据先行；TDD 的 RED-GREEN 循环 |

**吸收方式：** 原则级内化

### SUMM-Powers 独创

非来自三个上游的独创技能：

- **`deploy`** — 部署环境管理（DEPLOY.md 驱动）
- **`summ-todo`** / **`to-do-it`** — 全局任务追踪 + 快速执行循环
- **`skill-finder`** — 从外部技能仓库搜索加载技能
- **`upstream-sync`** — 上游同步工具（cherry-pick 策略 + 自我改进）

## 工作流管线

```
brainstorming → using-git-worktrees → writing-plans → subagent-driven-development → requesting-code-review → finishing-a-development-branch
                                        ↓
                               test-driven-development（贯穿实现阶段）
                               systematic-debugging（贯穿调试阶段）
```

1. **brainstorming** — 激活于编码之前。通过提问提炼需求，分段展示设计供验证，保存设计文档。
2. **using-git-worktrees** — 设计批准后激活。在隔离工作空间创建新分支。
3. **writing-plans** — 拿到设计后激活。拆解为 2-5 分钟的工程任务，每任务含完整代码和验证步骤。
4. **subagent-driven-development** — 拿到计划后激活。每任务派发新子代理，两阶段审查（规格合规 + 代码质量）。
5. **test-driven-development** — 实现阶段激活。RED-GREEN-REFACTOR：先写失败测试 → 看它失败 → 写最少代码通过 → 提交。
6. **requesting-code-review** — 任务间激活。对照计划审查，按严重程度报告问题。
7. **finishing-a-development-branch** — 任务完成时激活。验证测试，提供 merge/PR/keep/discard 选项。

**智能体在任何任务前自动检查是否有相关技能需要触发。** 这是强制工作流，不是建议。

## 安装

### CLI 安装

先注册 marketplace：

```bash
claude plugin marketplace add https://github.com/JhihJian/SUMM-Powers
```

再安装插件：

```bash
claude plugin install summ@summ-dev
```

### 应用内安装

在 Claude Code 中，先注册 marketplace：

```bash
/plugin marketplace add JhihJian/SUMM-Powers
```

再从 marketplace 安装：

```bash
/plugin install summ@JhihJian/SUMM-Powers
```

### 验证安装

启动新会话，尝试触发技能（如 "帮我规划一个功能" 或 "debug 这个问题"），智能体应自动调用相关技能。

## 更新

```bash
/plugin update summ
```

## 版本历史

见 [RELEASE-NOTES.md](RELEASE-NOTES.md)。

## 许可证

MIT License — 见 LICENSE 文件。

## 链接

- **Issues**: https://github.com/JhihJian/SUMM-Powers/issues
- **仓库**: https://github.com/JhihJian/SUMM-Powers
- **上游**: https://github.com/obra/superpowers
