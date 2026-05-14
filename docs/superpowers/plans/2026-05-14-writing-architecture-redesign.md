# Writing-Architecture Skill Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summ:subagent-driven-development (recommended) or summ:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the writing-architecture skill to produce stable, newcomer-oriented project knowledge documents instead of code navigation maps.

**Architecture:** Complete rewrite of both SKILL.md and SKILL.zh.md with a new 6-section structure (Project Positioning → Design Philosophy → Core Concepts → System Operation → Module Responsibilities → Architecture Constraints). The command wrapper gets a description update.

**Tech Stack:** Markdown skill files, bash test runner

---

## File Structure

| File | Responsibility |
|------|---------------|
| `skills/writing-architecture/SKILL.md` | English skill definition — complete rewrite |
| `skills/writing-architecture/SKILL.zh.md` | Chinese skill definition — complete rewrite |
| `commands/write-architecture.md` | Slash command wrapper — description update |

---

## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Rewrite SKILL.md (English) | `skills/writing-architecture/SKILL.md` | M | New 6-section structure, rules, checklist |
| 2 | Rewrite SKILL.zh.md (Chinese) | `skills/writing-architecture/SKILL.zh.md` | M | Same content in Chinese |
| 3 | Update command description | `commands/write-architecture.md` | S | Align description with new positioning |
| 4 | Verify skills load | `skills/writing-architecture/SKILL.md`, `skills/writing-architecture/SKILL.zh.md` | S | Run test to confirm skill loads |

---

### Batch 1 (Tasks 1-4)

### Task 1: Rewrite SKILL.md (English)

**Files:**
- Rewrite: `skills/writing-architecture/SKILL.md`

- [ ] **Step 1: Write the new SKILL.md**

Replace the entire file with content reflecting the new design. The file must contain:

**Frontmatter** (unchanged name, updated description):
```yaml
---
name: writing-architecture
description: Use when creating or revising ARCHITECTURE.md — a stable project knowledge document for newcomer onboarding, contributor reference, and AI agent context. Skip for projects under ~1k lines where CLAUDE.md alone suffices, or for user-facing docs (README, guides).
---
```

**Section: Overview** — reposition from "code navigation map" to "project knowledge document":
- ARCHITECTURE.md is a stable knowledge document that helps newcomers build a mental model, contributors recall design intent, and AI agents understand project constraints.
- It answers "why is it designed this way?" not "where is the code?"
- Core principle: write the knowledge you'd want on day one of joining the project.

**Section: When to Use** — same triggers as current, unchanged logic.

**Section: Structure** — 6 sections in order:
1. **Project Positioning** — 3-8 lines: what the project is, what problem it solves. Stability: only changes if target user or core problem changes.
2. **Design Philosophy** — 3-7 principles with name + explanation + reasoning. Focus on "why A over B" decisions. Stability: only changes on fundamental direction change.
3. **Core Concepts** — 5-10 domain concepts with name + definition + relationships. Only "can't understand project without" concepts. Stability: concepts are the abstract skeleton.
4. **System Operation** — 2-4 end-to-end scenarios showing trigger → flow → output. Stability: only changes if operation mode changes.
5. **Module Responsibilities** — per module (2-4 lines): design intent + responsibility boundary. Name key files for symbol search but don't enumerate internals. Stability: module responsibilities rarely change.
6. **Architecture Constraints** — layer boundaries (what each side doesn't know), invariants (especially absence-type), design constraints (intentional limitations). Stability: constraints established at project creation.

**Section: Rules — Do:**
- Name important files, modules, and types for symbol search
- Call out architectural invariants, especially absence-type ("X never depends on Y")
- Describe boundaries explicitly — what each side doesn't know
- Keep it under 120 lines
- Only include stable facts
- Answer "why" before "what"

**Section: Rules — Don't:**
- Don't link to files — use names for symbol search
- Don't enumerate internal files — name 2-3 key items, summarize the rest
- Don't include version numbers, hashes, or per-release values
- Don't explain how modules work internally — that's inline documentation
- Don't write a second README — focus on contributor knowledge, not feature descriptions
- Don't include testing/build conventions — those belong in CLAUDE.md

**Section: Common Mistakes** — update table to reflect new structure:

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Skipping design philosophy | Newcomers miss the "why" behind decisions | Always include 3-7 principles with reasoning |
| Core concepts reads like a glossary | Definitions without relationships don't build a mental model | Include how concepts relate to each other |
| System operation explains internals | Should show flow path, not implementation | Describe trigger → flow → output, not how each step works |
| Module responsibilities become file listings | Backsliding to old code map behavior | Focus on design intent, name only 2-3 key items |
| Including version numbers or hashes | Changes every release, doc becomes wrong | Describe the pattern or convention instead |
| Writing for users instead of contributors | Wrong audience — this is project knowledge | Focus on design intent, not feature descriptions |
| "My project has no architecture constraints" | Even simple projects have intentional limitations | Describe what the project deliberately does NOT do |

**Section: Quality Checklist:**
- [ ] Project positioning: newcomer understands "what is this" in 30 seconds?
- [ ] Design philosophy: each principle explains "why this direction"?
- [ ] Core concepts: covers everything you "can't understand the project without"?
- [ ] System operation: at least one end-to-end scenario?
- [ ] Module responsibilities: each module has "why it exists" and "responsibility boundary"?
- [ ] Architecture constraints: absence-type invariants explicitly stated?
- [ ] Stability: no version numbers, hashes, or file enumerations?
- [ ] Length: under 120 lines?
- [ ] No links, only names for symbol search?

- [ ] **Step 2: Verify frontmatter parses correctly**

Run: `head -4 skills/writing-architecture/SKILL.md`
Expected: Valid YAML frontmatter with `name: writing-architecture` and description starting with "Use when creating or revising ARCHITECTURE.md"

- [ ] **Step 3: Commit**

### Task 2: Rewrite SKILL.zh.md (Chinese)

**Files:**
- Rewrite: `skills/writing-architecture/SKILL.zh.md`

- [ ] **Step 1: Write the new SKILL.zh.md**

Replace the entire file with Chinese translation of the new SKILL.md content. Must include:

**Frontmatter** (same as current with `language: zh`):
```yaml
---
name: writing-architecture
description: Use when creating or revising ARCHITECTURE.md — a stable project knowledge document for newcomer onboarding, contributor reference, and AI agent context. Skip for projects under ~1k lines where CLAUDE.md alone suffices, or for user-facing docs (README, guides).
language: zh
---
```

**Language directive** (unchanged): `**本文档要求使用中文编写输出。**`

All section content must be the Chinese equivalent of Task 1's SKILL.md:
- 概述 → 重新定位为"项目知识文档"
- 适用场景 → 不变
- 结构 → 6 个新章节（项目定位、设计哲学、核心概念、系统运转、模块职责、架构约束）
- 规则 → 更新后的应该做/不应该做
- 常见错误 → 更新后的表格
- 质量检查清单 → 更新后的检查项

Key translation notes:
- "Project Positioning" → "项目定位"
- "Design Philosophy" → "设计哲学"
- "Core Concepts" → "核心概念"
- "System Operation" → "系统运转"
- "Module Responsibilities" → "模块职责"
- "Architecture Constraints" → "架构约束"
- Keep English technical terms as-is (symbol search, ARCHITECTURE.md, SKILL.md, etc.)

- [ ] **Step 2: Verify frontmatter and language directive**

Run: `head -6 skills/writing-architecture/SKILL.zh.md`
Expected: Valid YAML with `language: zh`, followed by the Chinese language directive line.

- [ ] **Step 3: Commit**

### Task 3: Update command description

**Files:**
- Modify: `commands/write-architecture.md`

- [ ] **Step 1: Update description in frontmatter**

Current description: `"Use the summ:writing-architecture skill to write or revise ARCHITECTURE.md"`

Update to align with new positioning:
```yaml
---
description: "Use the summ:writing-architecture skill to write or revise ARCHITECTURE.md — a stable project knowledge document for newcomer onboarding"
---
```

Body content remains unchanged (`Invoke the summ:writing-architecture skill and follow it exactly as presented to you`).

- [ ] **Step 2: Commit**

### Task 4: Verify skills load

**Files:**
- Verify: `skills/writing-architecture/SKILL.md`
- Verify: `skills/writing-architecture/SKILL.zh.md`

- [ ] **Step 1: Run existing skill test**

Run: `cd /data/dev/SUMM/SUMM-Powers && ./tests/claude-code/run-skill-tests.sh --verbose 2>&1 | grep -i "writing-architecture\|PASS\|FAIL" || echo "No specific test found — verifying skill file structure instead"`

If no specific test exists for writing-architecture, verify manually:
- YAML frontmatter is valid
- File has all 6 required sections (grep for headings)
- No links in the content (grep for `](`)
- No placeholder patterns

- [ ] **Step 2: Verify both files are structurally consistent**

Run: `diff <(grep '^###' skills/writing-architecture/SKILL.md | sed 's/[0-9]\. //' | sed 's/^### //') <(grep '^###' skills/writing-architecture/SKILL.zh.md | sed 's/[0-9]\. //' | sed 's/^### //') && echo "Section structure mismatch" || echo "Sections differ (expected — EN vs ZH)"`
Then manually confirm both files have the same number and order of sections.

- [ ] **Step 3: Final commit (if any fixes needed)**
