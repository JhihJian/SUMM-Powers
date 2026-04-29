# SUMM-Powers Version Roadmap

> 版本号格式: `<upstream-version>-summ.<fork-version>`
> 当前版本: `5.0.7-summ.2.0`

基于 [mattpocock/skills 集成分析](docs/superpowers/specs/2026-04-28-mattpocock-skills-integration-analysis.md) 制定。

---

## v1.8 — Skill Infrastructure (已完成)

> 计划文档: [D1-D3 Implementation Plan](docs/superpowers/plans/2026-04-28-skill-infrastructure-d1-d3.md)

| 编号 | 内容 | 状态 |
|------|------|------|
| D1 | `scripts/lint-skills.sh` — frontmatter 格式校验 (name/description 必填、目录名匹配、命名规范) | 已完成 |
| D2 | 链接验证 + 质量检查 (断链检测、行数告警、占位符检测) | 已完成 |
| D3 | `scripts/skill-template.md` — 标准化技能模板 (触发条件/流程/反模式) | 已完成 |

---

## v1.9 — Core Skill Enhancements (已完成)

> 计划文档: [v1.9 Implementation Plan](docs/superpowers/plans/2026-04-29-v1.9-core-skill-enhancements.md)

增强现有核心技能，不引入新依赖。

| 编号 | 内容 | 来源 | 状态 |
|------|------|------|------|
| B1 | `systematic-debugging` 增强 — 10 种反馈循环构建方法、可证伪假设、tagged debug logs、非确定性 bug 策略 | `diagnose` | 已完成 |
| B2 | `test-driven-development` 增强 — 垂直切片反模式、deep modules 概念、interface design for testability、mocking 指南 | `tdd` | 已完成 |

**依赖**: 无 (v1.8 的 lint 工具可用于验证增强后的 skill)

---

## v2.0 — Domain Language + Architecture (已完成)

> 计划文档: [v2.0 Implementation Plan](docs/superpowers/plans/2026-04-29-v2.0-domain-language-architecture.md)

引入领域语言系统和架构改善能力。范式级变更 — 后续所有 skill 都可引用 CONTEXT.md 术语体系。

| 编号 | 内容 | 来源 | 状态 |
|------|------|------|------|
| A1 | **Domain Language 系统** — `CONTEXT.md` 领域术语表、`CONTEXT-MAP.md` 多上下文映射、`docs/adr/` 架构决策记录、内联更新机制 | `grill-with-docs` + `DOMAIN-AWARENESS.md` | 已完成 |
| A2 | **架构改善技能** — `improve-codebase-architecture` skill，系统化发现浅模块并重构为深模块 (depth/leverage/locality/seam 术语体系) | `improve-codebase-architecture` | 已完成 |

**依赖**: A2 使用 A1 的术语体系，建议先完成 A1

---

## v2.1 — Domain-Awareness Integration

将 domain-awareness 模式整合到现有技能编写和头脑风暴流程中。

| 编号 | 内容 | 来源 |
|------|------|------|
| B3 | `writing-skills` 增强 — 100 行上限原则、progressive disclosure、description field 精确写法、脚本添加判断 | `write-a-skill` |
| B4 | `brainstorming` 增强 — 内联文档更新、挑战现有语言、模糊语言锐化、具体场景压力测试、代码交叉验证 | `grill-with-docs` |

**依赖**: v2.0 的 A1 Domain Language 系统

---

## v2.2 — Workflow Integration

工作流集成工具，补全 brainstorming → plan → PRD → issues 的完整链路。

| 编号 | 内容 | 来源 |
|------|------|------|
| A3 | **极简通讯模式** — 约 75% token 节省，caveman 模式 `[thing] [action] [reason]` | `caveman` |
| A4 | **计划转 Issues** — 将计划/PRD 分解为可独立认领的 GitHub Issues，tracer bullet 垂直切片 | `to-issues` |
| A9 | **对话转 PRD** — 将对话内容合成为 PRD，直接提交为 GitHub issue | `to-prd` |

**依赖**: A4 和 A9 与 `writing-plans` 技能集成

---

## v2.3 — Optional Extensions

可选扩展，按需拾取。

| 编号 | 内容 | 来源 | 备注 |
|------|------|------|------|
| A5 | Git 安全护栏 — PreToolUse hook 阻止危险 git 操作 | `git-guardrails-claude-code` | 范围小，可整合到 `update-config` |
| A7 | 轻量烤问 — 不依赖文档的快速决策验证 | `grill-me` | 可作为 brainstorming 的"快速模式" |
| A8 | Issue 生命周期管理 — 基于 label 状态机管理 GitHub issues | `github-triage` | 与 A4 配合形成完整 issue 工作流 |
| A6 | 上下文提升 — "退后一步"展示宏观模块关系 | `zoom-out` | 太小，合并到 `less` 技能作为触发模式 |

---

## Design Principles Borrowed

贯穿所有版本的设计理念:

| 理念 | 说明 | 应用 |
|------|------|------|
| Domain-Aware Development | 所有工程技能引用共享 CONTEXT.md | v2.0 起生效 |
| Deep Modules 术语体系 | 统一使用 depth/leverage/locality/seam | v1.9 (B2) 引入，v2.0 (A2) 深化 |
| Progressive Disclosure | SKILL.md ≤100 行，详细内容拆到独立文件 | v1.8 (D3 模板) 起生效 |
| Feedback Loop First | 调试 = 构建正确的反馈循环 | v1.9 (B1) 引入 |

---

## Dependency Graph

```
v1.8 D1-D3 Infrastructure (已完成)
 │
 ├─→ v1.9 B1+B2 Core Enhancements (已完成)
 │
 └─→ v2.0 A1 Domain Language (已完成) ──→ v2.1 B3+B4 Domain-Awareness Integration
      │
      └─→ v2.0 A2 Architecture (已完成)

v2.0 ──→ v2.2 A3+A4+A9 Workflow Integration

v2.0+ ──→ v2.3 A5+A7+A8+A6 Optional (any order)
```
