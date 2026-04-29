---
name: grill-me
description: "Use when user wants quick decision validation — asks probing questions to explore a decision tree without producing docs. Say 'grill me', '烤我', '帮我验证'. Skip when user needs full design (use brainstorming) or has clear plan (use to-do-it)."
---

# Grill Me — 轻量烤问

快速决策验证。持续追问直到决策树的每个分支都被探索。不产出文档。

## When to Use

用户说以下任意一个:
- "grill me"、"烤我一下"、"帮我验证这个想法"
- 需要在两个选项间做选择
- 需要验证一个设计决策是否合理

**Skip when:**
- 需要完整设计方案 → 用 `brainstorming`
- 已有明确方案要实现 → 用 `to-do-it` 或 `writing-plans`
- 需要团队共识的决策 → grill-me 是个人思考工具

## Questioning Strategy

按优先级依次使用:

1. **假设挖掘** — "你假设了 X，如果 Y 呢？"
2. **边界条件** — "这个方案在 Z 情况下会怎样？"
3. **替代方案** — "为什么不选 W？"
4. **连锁效应** — "做了 X 之后，对 A/B/C 有什么影响？"
5. **收敛确认** — "所以你的核心决策是 P，条件是 Q，对吗？"

## Rules

- 每次只问一个问题
- 不假设任何上下文，从用户描述出发
- 用户已有明确答案的不重复追问
- 用户想清楚了就主动结束: "这个决策已经想清楚了，建议直接进入实现"
- 不触发 writing-plans、不创建 spec 文档、不创建 SUMM-Todo 任务

## Termination

grill-me 在以下情况结束:
- 用户说 "够了"、"OK"、"确认"
- 决策树的所有分支都已探索完毕
- 用户已明确做出决策

结束后建议下一步: "进入实现" 或 "用 brainstorming 做完整设计"

## Anti-Patterns

| Thought | Reality |
|---------|---------|
| "应该产出设计文档" | 对话即结果，不产出文档 |
| "应该像 brainstorming 一样全面" | grill-me 聚焦单一决策点 |
| "追问到每个细节" | 用户有明确答案的不再追问 |

## Key Principles

- **Single focus** — 一次只验证一个决策
- **No artifacts** — 不创建文件、不提交 git
- **Know when to stop** — 用户想清楚了就结束，不过度追问
