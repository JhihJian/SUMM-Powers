# mattpocock/skills → SUMM-Powers 集成分析

> 来源项目: https://github.com/mattpocock/skills (commit as of 2026-04-28)
> 分析日期: 2026-04-28

## 背景

mattpoclock/skills 是一个面向真实工程实践的 agent 技能库，核心哲学是"小、可组合、可适配"。
与 SUMM-Powers 的对比：

| 维度 | SUMM-Powers | mattpoclock/skills |
|------|-------------|-------------------|
| 设计哲学 | 完整工作流管线（brainstorm → plan → execute → review） | 独立可组合的工程实践技能 |
| 覆盖范围 | 端到端开发流程 | 日常工程实践 + 领域建模 |
| 领域建模 | 无 | CONTEXT.md + ADR 系统 |
| 架构关注 | 无专用技能 | improve-codebase-architecture |
| 测试哲学 | 严格 RED-GREEN-REFACTOR | 垂直切片 + deep modules |
| 调试方法 | 4阶段根因分析 | 反馈循环优先（10种构建方法） |
| Token 优化 | `less` 技能（文档压缩） | `caveman` 模式（对话压缩） |
| 任务分发 | subagent-driven / executing-plans | to-issues（→ GitHub Issues） |

## A. 全新技能

### A1. Domain Language 系统 (`grill-with-docs` + `CONTEXT.md`)

**来源**: `grill-with-docs`, `DOMAIN-AWARENESS.md`, `CONTEXT-FORMAT.md`, `ADR-FORMAT.md`

**核心价值**: 建立项目共享语言，解决 agent 通讯中的术语不一致问题。

**关键机制**:
- `CONTEXT.md`: 项目根目录的领域术语表，定义核心概念和关系
- `CONTEXT-MAP.md`: 多上下文项目指向各子领域的 CONTEXT.md
- `docs/adr/`: Architecture Decision Records，记录难以逆转的架构决策
- 内联更新: 讨论中确认术语时立即更新 CONTEXT.md，不等最后批量处理
- ADR 三条件: 难逆转 + 没上下文会困惑 + 真实权衡 → 才创建 ADR
- 所有工程技能都引用 DOMAIN-AWARENESS.md，实现统一的领域感知

**SUMM 差距**: SUMM 的 brainstorming 产出静态 spec 文档，没有持续维护的领域语言。
没有 CONTEXT.md 机制，也没有 ADR 系统。所有技能之间缺少共享的项目术语基础。

**融合建议**: 创建 `domain-language` 技能，包含 CONTEXT.md/ADR 的创建和维护指南。
将 DOMAIN-AWARENESS 作为所有工程技能的可选前置。

---

### A2. 架构改善技能 (`improve-codebase-architecture`)

**来源**: `improve-codebase-architecture`, `LANGUAGE.md`, `DEEPENING.md`, `INTERFACE-DESIGN.md`

**核心价值**: 系统化发现代码库中的架构摩擦，将"浅模块"重构为"深模块"。

**关键概念**:
- **Module**: 任何有接口和实现的东西（函数、类、包、切片）
- **Depth**: 接口背后的行为量。深 = 高杠杆（小接口，大行为）
- **Seam**: 接口存在的位置，可以在不修改代码的情况下改变行为的地方
- **Leverage**: 调用者从深度获得的好处
- **Locality**: 维护者从深度获得的好处（变更、bug、知识集中在一处）
- **Deletion test**: 想象删除模块——如果复杂度消失，它是传递层；如果复杂度分散到 N 个调用者，它在赚它的份额

**流程**: 探索（找摩擦点） → 呈现候选改善 → 用户选择 → 深入讨论设计

**SUMM 差距**: SUMM 没有任何架构层面的技能。现有技能关注"做什么"和"怎么做"，
不关注"怎么组织"。

**融合建议**: 创建 `improve-architecture` 技能，用 SUMM 风格重写。
术语体系（depth/leverage/locality/seam）非常有价值，应保留。

---

### A3. 极简通讯模式 (`caveman`)

**来源**: `caveman`

**核心价值**: 约 75% token 节省，保持技术准确性。

**关键规则**:
- 丢弃: 冠词、填充词、客套话、犹豫语
- 保持: 技术术语精确、代码块不变、错误引用精确
- 模式: `[thing] [action] [reason]. [next step].`
- 持久化: 一旦激活，每条回复都生效
- 自动清晰例外: 安全警告、不可逆操作确认、多步骤序列

**与 SUMM `less` 的区别**: `less` 压缩文档展示（1-1-3-1 格式），`caveman` 压缩日常对话。

**融合建议**: 可创建新技能，或增强现有 `less` 技能增加对话压缩模式。

---

### A4. 计划转 Issues (`to-issues`)

**来源**: `to-issues`

**核心价值**: 将计划/PRD 分解为可独立认领的 GitHub Issues。

**关键概念**:
- **Tracer bullet**: 每个切面是穿过所有层的垂直切片，不是单层的水平切片
- **HITL vs AFK**: HITL（需人工交互）vs AFK（可自主完成）
- **依赖顺序**: 先创建阻塞者，这样可以在后续 issue 中引用真实 issue 编号

**SUMM 差距**: SUMM 的 `writing-plans` 产出 Markdown 格式的计划，
没有与 GitHub Issues 的集成。

**融合建议**: 创建 `plan-to-issues` 技能，与 SUMM 的计划格式集成。

---

### A5. Git 安全护栏 (`git-guardrails-claude-code`)

**来源**: `git-guardrails-claude-code`, `scripts/block-dangerous-git.sh`

**核心价值**: PreToolUse hook 阻止危险 git 操作。

**阻止的操作**: `git push`, `git reset --hard`, `git clean -f`, `git branch -D`,
`git checkout .`, `git restore .`

**SUMM 差距**: SUMM 没有操作安全层面的技能。

**融合建议**: 可直接作为新技能引入，或整合到 `update-config` 技能中。

---

### A6. 上下文提升 (`zoom-out`)

**来源**: `zoom-out`

**核心价值**: 让 agent "退后一步"展示更宏观的模块关系。极简（约 5 行有效指令）。

**融合建议**: 太小不足以单独成为技能，可考虑作为 `less` 技能的一个触发模式。

---

## B. 现有技能增强

### B1. 增强 `systematic-debugging` ← `diagnose`

**可借鉴内容**:

1. **10种反馈循环构建方法**（按优先级排序）:
   - 失败测试 → curl/HTTP 脚本 → CLI 调用 → Headless 浏览器 →
   - 重放捕获的 trace → 抛弃式 harness → 属性/模糊循环 → 二分 harness →
   - 差分循环 → HITL bash 脚本

2. **Hypothesis 必须可证伪**: "如果 X 是原因，那么改变 Y 会使 bug 消失/改变 Z 会使之恶化"

3. **Tagged debug logs**: `[DEBUG-a4f2]` 前缀，结束时一个 grep 清理

4. **非确定性 bug 策略**: 目标不是 100% 复现，而是提高复现率到可调试水平

5. **Phase gating**: 不完成当前阶段不进入下一阶段

6. **性能回归分支**: 日志通常是错的，应该先建立基线测量再二分

**融合方式**: 将这些内容补充到 `systematic-debugging/SKILL.md`，
可创建 `feedback-loops.md` 作为参考文件。

---

### B2. 增强 `test-driven-development` ← `tdd`

**可借鉴内容**:

1. **垂直切片反模式**: 不要一次写完所有测试再写实现（水平切片）。
   应该一个测试→一个实现→重复（垂直切片/tracer bullet）。

2. **Deep modules 概念**: 小接口、深实现。测试验证行为而非实现。

3. **Interface design for testability**: 设计接口时就考虑可测试性

4. **Refactoring candidates**: 专门的 refactoring 检查清单

5. **Mocking 指南**: 何时 mock、何时不用 mock 的精确指南

**融合方式**: 将垂直切片反模式补充到 TDD SKILL.md。
将 deep-modules、interface-design、mocking 指南作为参考文件。

---

### B3. 增强 `writing-skills` ← `write-a-skill`

**可借鉴内容**:

1. **100行上限原则**: SKILL.md 控制在 100 行内，详细内容拆到独立文件

2. **Progressive disclosure**: 快速启动 → 工作流 → 高级特性（链接到独立文件）

3. **Description field 精确写法**: 1024 字符上限，第一句做什么，
   第二句 "Use when [具体触发器]"。给出好/坏示例对比。

4. **脚本添加判断**: 确定性操作 → 添加脚本。重复生成相同代码 → 添加脚本。

**融合方式**: 将这些原则补充到 `writing-skills/SKILL.md` 的相关部分。

---

### B4. 增强 `brainstorming` ← `grill-with-docs`

**可借鉴内容**:

1. **内联文档更新**: 讨论中确认术语时立即更新 CONTEXT.md

2. **挑战现有语言**: 用户用词与 CONTEXT.md 冲突时立即指出

3. **模糊语言锐化**: 用户用模糊术语时提出精确定义

4. **具体场景压力测试**: 发明边缘场景，迫使用户精确化概念边界

5. **代码交叉验证**: 用户说"这个工作方式是 X"时检查代码是否一致

**融合方式**: 在 brainstorming 中增加"领域语言检查"步骤，
有 CONTEXT.md 时激活领域感知功能。

---

## C. 设计理念借鉴

### C1. Domain-Aware Development

所有工程技能都引用同一个 `DOMAIN-AWARENESS.md`，实现统一的领域感知。
这是一种"技能间共享状态"的模式——CONTEXT.md 成为技能系统的共享知识库。

### C2. Deep Modules 术语体系

统一使用 depth/leverage/locality/seam，而非模糊的"component/service/boundary"。
精确的术语让讨论更高效，减少误解。

### C3. Progressive Disclosure

SKILL.md 控制在 100 行内，详细内容拆到独立文件（`INTERFACE-DESIGN.md`,
`DEEPENING.md`, `LANGUAGE.md` 等）。agent 只在需要时读取详细内容。

### C4. Feedback Loop First

调试技能把"构建反馈循环"作为核心能力，而非修复本身。
"构建了正确的反馈循环 = bug 90% 已修复"的理念很有启发性。

---

## 优先级建议

### 优先批（高价值 + 高可行性）

1. **A1**: Domain Language 系统 — 最有价值的新能力
2. **A2**: 架构改善技能 — 填补 SUMM 架构层面的空白
3. **B1**: 调试增强 — 反馈循环构建方法极大提升调试效率
4. **B2**: TDD 增强 — 垂直切片反模式和 deep modules 概念

### 后续批

5. **A3**: 极简通讯模式 — token 节省显著但非核心能力
6. **A4**: 计划转 Issues — 与 GitHub 工作流集成
7. **B3**: 技能编写增强 — 渐进式改进
8. **B4**: Brainstorming 增强 — 依赖 A1 先落地

### 可选

9. **A5**: Git 安全护栏 — 实用但范围小
10. **A6**: 上下文提升 — 太小，可合并到其他技能
11. **A7**: 轻量烤问 — 填补"快速思考验证"的空白
12. **A8**: Issue 生命周期管理 — 完善项目管理工作流
13. **A9**: 对话转 PRD — 补全 brainstorming → PRD 的链路

### 基础设施批

14. **D1**: 技能格式校验 — 自动化质量保障
15. **D2**: 质量检查脚本 — CI 可集成
16. **D3**: 技能写作模板 — 统一格式

---

## D. 基础设施与质量保障

### D1. 技能格式校验

**问题**: 当前没有自动化手段验证 SKILL.md 是否符合规范。格式错误只能在运行时发现。

**关键检查项**:
- frontmatter 必填字段: `name`（小写字母+数字+连字符）、`description`（≤1024 字符）
- 文件名规范: 目录名 = `name` 字段值
- 有效性: description 中引用的文件路径是否存在
- bucket 一致性: engineering/productivity/misc 中的技能是否在 plugin.json 和 bucket README 中都有条目

**融合建议**: 创建 `scripts/lint-skills.sh`，可本地运行也可接入 CI。

---

### D2. 质量检查脚本

**问题**: plugin.json 与实际技能目录可能不同步，引用链接可能失效。

**关键检查项**:
- plugin.json 中的每个路径对应一个存在的 SKILL.md
- 每个 bucket README 中列出的技能对应一个存在的目录
- SKILL.md 中引用的辅助文件（如 `scripts/`、`references/`）确实存在
- personal/deprecated 目录中的技能不在 plugin.json 中

**融合建议**: 与 D1 合并为统一的 `scripts/lint-skills.sh`。

---

### D3. 技能写作模板

**问题**: 现有技能结构不统一——部分有 dot 图、部分纯文本；反模式说明和实用示例缺失。

**模板结构**:
```
---
name: skill-name
description: Use when [具体触发条件]. Skip when [排除条件].
---

# 标题

## 触发条件（何时使用）

## 流程

## 常见场景（至少 2 个示例）

## 何时不适用

## 反模式（常见错误）
```

**融合建议**: 将模板写入 `writing-skills/SKILL.md` 的参考部分，同时更新现有技能逐步对齐。

---

## 补充技能分析

### A7. 轻量烤问 (`grill-me`)

**来源**: `grill-me`

**核心价值**: 不依赖文档上下文的快速"烤问"模式。适用于非代码场景或轻量级决策验证。

**关键机制**:
- 持续追问直到决策树的每个分支都被探索
- 不假设任何上下文，纯对话驱动
- 适用于: 设计选择、架构决策、功能规划、甚至非技术决策

**与 SUMM brainstorming 的区别**: brainstorming 是重量级流程（有 checklist、设计文档输出、阶段门控），
`grill-me` 是即时性的——不需要产出文档，目标是"让用户想清楚"。

**融合建议**: 可作为独立轻量技能，或作为 brainstorming 的"快速模式"触发器。

---

### A8. Issue 生命周期管理 (`github-triage`)

**来源**: `github-triage`

**核心价值**: 基于 label 状态机管理 GitHub issues 的完整生命周期。

**关键概念**:
- Label 即状态: 通过标签组合表示 issue 当前所处阶段
- 自动化转换: 定义 label 之间的合法转换规则
- 优先级管理: urgency + impact 的二维评估

**SUMM 差距**: SUMM 完全没有 issue 生命周期管理的技能。`to-issues` 创建 issues 但不管理后续状态。

**融合建议**: 创建 `triage-issues` 技能，与 `plan-to-issues`(A4) 配合形成完整的 issue 工作流。

---

### A9. 对话转 PRD (`to-prd`)

**来源**: `to-prd`

**核心价值**: 将对话中已讨论的内容合成为 PRD，直接提交为 GitHub issue。
不需要额外的面试环节——直接从已有对话中提炼。

**与 SUMM brainstorming 的关系**: brainstorming 产出 spec 文件，但没有自动转为 PRD/issue 的能力。
`to-prd` 补全了这个链路: brainstorming → spec → PRD → GitHub issue。

**融合建议**: 可作为 brainstorming 的后置步骤，或作为 `writing-plans` 的前置步骤。
