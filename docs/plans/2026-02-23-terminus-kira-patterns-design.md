# Terminus-Kira 设计模式集成方案

> **For Claude:** REQUIRED SUB-SKILL: Use summ:executing-plans to implement this plan task-by-task.

**Goal:** 将 terminus-kira 的严格完成验证和防助手行为设计融入 SUMM-Powers 技能体系

**Architecture:** 按角色分层 — 设计者技能引用共享原则文件，执行者技能通过 verification-before-completion 门控注入不可逆提交框架

---

## 改动范围

| 改动 | 文件 | 内容 |
|------|------|------|
| 新增 | `docs/design-principles.md` | 三条设计原则（通用化/重新规划/轻量级） |
| 修改 | `skills/verification-before-completion/SKILL.md` | +不可逆提交框架 +多角度检查提醒 |
| 修改 | `skills/brainstorming/SKILL.md` | +一行引用 design-principles |
| 修改 | `skills/writing-plans/SKILL.md` | +一行引用 design-principles |

## 信息流向

```
设计阶段:
  brainstorming ──引用──→ docs/design-principles.md
  writing-plans ──引用──→ docs/design-principles.md

执行阶段:
  executing-plans ──经过──→ verification-before-completion (含不可逆提交)
  subagent implementer ──经过──→ verification-before-completion
  to-do-it (执行/验证阶段) ──经过──→ verification-before-completion
```

---

## Task 1: 创建 `docs/design-principles.md`

**Files:**
- Create: `docs/design-principles.md`

**Step 1: 创建设计原则文件**

```markdown
# Design Principles

设计阶段的三条核心原则。所有设计类技能（brainstorming、writing-plans、to-do-it 设计阶段）必须遵守。

## 1. Generalization Rule（通用化规则）

解决方案必须通用，禁止硬编码。

- 不要为特定输入定制逻辑，要处理一般情况
- 不要用 magic number，提取为常量或配置
- 问自己："如果输入变了，这个方案还能工作吗？"

## 2. Replanning Guidance（允许重新规划）

发现方向错误时，允许推翻当前方案从头重新规划。

- 沉没成本不是继续的理由
- 如果当前方案需要越来越多的 workaround，停下来重新评估
- 重新规划的成本几乎总是低于强行推进

## 3. Lightweight First（轻量级方案优先）

优先选择最简单的能解决问题的方案。

- 能用标准库就不引入第三方依赖
- 能用简单数据结构就不设计复杂抽象
- 复杂度必须有对应的收益来证明
```

**Step 2: Commit**

```bash
git add docs/design-principles.md
git commit -m "docs: add design principles for design-phase skills"
```

---

## Task 2: 增强 `verification-before-completion`

**Files:**
- Modify: `skills/verification-before-completion/SKILL.md`

**Step 1: 在 "The Gate Function" 部分之后插入两个新 section**

插入内容：

```markdown
## Irreversible Submission（不可逆提交）

把完成声明视为不可逆操作。没有第二次机会，没有撤销。

- 你有无限次迭代机会，但只有一次提交机会
- 不要提交部分结果期待反馈 — 没有人会给你反馈
- 不要"试一试看看行不行" — 提交前你必须确信

**Red Flag:** 如果你心里想"差不多了，先提交看看"，你还没准备好。

## Multi-Perspective Check（多角度检查）

验证通过后，快速从三个角度审视：

- **测试工程师：** 边界情况和异常路径覆盖了吗？
- **QA：** 与现有功能的交互会出问题吗？
- **发起任务的用户：** 这真的是他要的东西吗？

不需要逐项标记，但在声明完成前过一遍这三个视角。
```

**Step 2: Commit**

```bash
git add skills/verification-before-completion/SKILL.md
git commit -m "feat: add irreversible submission and multi-perspective check to verification skill"
```

---

## Task 3: brainstorming 和 writing-plans 引用设计原则

**Files:**
- Modify: `skills/brainstorming/SKILL.md` — 在 "Key Principles" 列表末尾加一条
- Modify: `skills/writing-plans/SKILL.md` — 在 "Remember" 列表末尾加一条

**Step 1: brainstorming/SKILL.md**

在 Key Principles 部分最后一条之后加入：

```markdown
- **Follow design principles** - 方案必须符合 `docs/design-principles.md` 中的三条原则（通用化、允许重新规划、轻量级优先）。评估方案时用这三条作为筛选标准。
```

**Step 2: writing-plans/SKILL.md**

在 Remember 部分最后一条之后加入：

```markdown
- Follow `docs/design-principles.md` — 通用化（禁止硬编码）、允许重新规划、轻量级方案优先
```

**Step 3: Commit**

```bash
git add skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md
git commit -m "feat: reference design principles in brainstorming and writing-plans skills"
```
