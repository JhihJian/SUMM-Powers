---
name: zoom-out
description: "Use when user says 'zoom out', '退后一步', '看看大局' — shows macro-level module relationships and current position in the architecture. Skip for single-file changes or when user already has full picture."
---

# Zoom Out — 上下文提升

从细节中退后一步，展示宏观模块关系。帮用户看见盲区。

## When to Use

用户说以下任意一个:
- "zoom out"、"退后一步"、"看看大局"、"整体架构"、"宏观视角"
- 反复修改同一区域却没进展时

**Skip when:**
- 单文件改动，无需宏观视角
- 用户已清楚全貌

## Output Format

固定三段结构:

### 1. 当前位置

2-3 句话: 正在做什么，在项目整体中的位置。

### 2. 模块关系

简化的依赖/关系图。规则:
- 节点不超过 8 个
- 层级不超过 3 层
- 只展示直接相关模块，省略间接依赖

### 3. 建议下一步

基于宏观视角的 1-2 个建议。聚焦用户可能忽略的:
- 未考虑的依赖影响
- 更优的改动顺序
- 可复用的现有模块

## Rules

- 纯只读，不修改任何文件
- 不重复用户已知信息，只展示盲区
- 有 CONTEXT.md 时引用其术语体系
- 依赖 `grep`、`find`、`git log` 探索项目结构

## Anti-Patterns

| Thought | Reality |
|---------|---------|
| "展示完整架构图" | 只展示与当前工作相关的部分 |
| "分析每个模块" | 聚焦直接依赖和影响范围 |
| "建议全面重构" | 只建议与当前工作相关的下一步 |

## Key Principles

- **Relevant only** — 只展示与当前工作相关的模块关系
- **Blind spot focused** — 用户不知道的比已知的更有价值
- **Actionable** — 建议必须是可执行的具体步骤
