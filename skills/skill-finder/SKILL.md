---
name: skill-finder
description: Use when encountering complex or specialized work that requires domain expertise not covered by existing skills. Searches antigravity-awesome-skills repository for matching skills and loads them for use.
---

# Skill Finder (技能查找器)

## Overview

从 antigravity-awesome-skills 仓库搜索并加载专业技能。当遇到复杂或需要专业知识的工作，且当前没有对应的 skill 时，使用此技能查找并加载外部技能。

**核心功能**：
- 更新 antigravity-awesome-skills 仓库（git pull）
- 基于描述搜索匹配的技能
- 将选中的技能加载到 `external-skills/` 目录
- 支持 Skill 工具调用已加载的技能

## When to Use

**适用场景**：
- 需要特定领域专业知识（安全审计、游戏开发、数据分析等）
- 当前 SUMM-Powers 技能库没有覆盖的任务
- 用户明确要求查找特定类型的技能
- 遇到复杂任务需要专业指导

**不适用场景**：
- 当前技能已经能够覆盖的任务
- 简单的代码修改或配置任务
- 通用编程问题（使用现有技能即可）

## Configuration

技能查找器需要配置 antigravity-awesome-skills 的本地路径：

```
ANTIGRAVITY_SKILLS_PATH: /data/github/antigravity-awesome-skills
ANTIGRAVITY_SKILLS_REPO: https://github.com/sickn33/antigravity-awesome-skills
```

## The Process

### 1. Update Repository

首先更新 antigravity-awesome-skills 仓库以获取最新技能：

```bash
cd /data/github/antigravity-awesome-skills && git pull origin main
```

### 2. Search Skills Index

读取 `skills_index.json` 并基于用户描述搜索匹配的技能。搜索维度包括：
- `name` - 技能名称
- `description` - 技能描述
- `category` - 分类
- `tags` - 标签

搜索策略：
1. 精确匹配关键词
2. 模糊匹配描述内容
3. 按相关度排序结果

### 3. Present Results

展示匹配结果供用户选择：

```
找到 X 个匹配的技能：

[#] name - description
    Category: xxx | Risk: xxx | Source: xxx

[#] name - description
    Category: xxx | Risk: xxx | Source: xxx
...
```

**风险提示**：展示技能的 `risk` 级别（safe/unknown/critical），提醒用户注意安全。

### 4. Load Selected Skill

用户选择后，将技能复制到 `external-skills/` 目录：

```bash
# 源路径
SOURCE: /data/github/antigravity-awesome-skills/skills/<skill-id>/

# 目标路径
TARGET: /data/dev/SUMM-Powers/external-skills/<skill-id>/

# 复制命令
cp -r "$SOURCE" "$TARGET"
```

### 5. Usage Instructions

加载完成后，告知用户如何使用：

```
技能已加载: <skill-id>

调用方式：
- Skill 工具: summ:external:<skill-id>
- 斜杠命令: /summ:external:<skill-id>（如果已配置）

技能路径: external-skills/<skill-id>/SKILL.md
```

## External Skills Directory

外部技能存放在 `external-skills/` 目录：

```
external-skills/
├── .gitkeep
├── 007/
│   └── SKILL.md
├── security-audit/
│   └── SKILL.md
└── ...
```

**命名约定**：使用原始技能的 `id` 作为目录名。

## Integration

**调用已加载的外部技能**：

```
summ:external:<skill-id>
```

例如：加载了 `007` 技能后，使用 `summ:external:007` 调用。

## Example Usage

**用户输入**：
```
/summ:find-skill security audit penetration testing
```

**执行流程**：
1. git pull 更新仓库
2. 搜索 skills_index.json
3. 找到匹配：007, security-audit, pentest-guide...
4. 展示结果，用户选择 #1 (007)
5. 复制到 external-skills/007/
6. 提示：使用 `summ:external:007` 调用

## Key Principles

- **安全优先**：展示技能风险级别，提醒用户审慎使用 critical 级别技能
- **保留技能**：加载的技能保留在 external-skills/ 供后续使用
- **用中文沟通**：与用户交互使用中文
- **按需加载**：只在需要时才加载外部技能，避免膨胀

## Troubleshooting

| 问题 | 解决方案 |
|------|----------|
| git pull 失败 | 检查网络连接，或手动更新仓库 |
| 找不到匹配技能 | 尝试更通用的关键词，或查看 CATALOG.md |
| 技能加载失败 | 检查源技能目录结构是否完整 |
| 调用技能失败 | 确认技能已正确复制到 external-skills/ |
