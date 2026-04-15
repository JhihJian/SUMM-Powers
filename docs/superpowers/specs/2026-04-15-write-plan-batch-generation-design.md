# Write-Plan Batch Generation Design

**Goal:** Add batch generation to the writing-plans skill so large plans are generated in controlled batches instead of a single monolithic output, preventing quality degradation, inconsistencies, and generation interruptions.

**Architecture:** Two-phase generation — first produce a task index with complexity estimates, then generate detailed task content in dynamically-sized batches. No new skills or files; only modify the existing writing-plans SKILL.md.

**Scope:** Single skill file change. No changes to executing-plans, brainstorming, or other skills.

---

## Problem

When writing-plans generates a large plan (many tasks, complex code), a single-response generation causes:
- Quality degradation in later tasks (vague descriptions, placeholders)
- Inconsistencies between early and late tasks (mismatched function names, types)
- Context window pressure leading to truncation
- Abnormal generation interruptions

The brainstorming phase already produces a spec/skeleton, so write-plan is filling in details — it doesn't need to invent structure from scratch.

## Solution: Two-Phase Generation

### Phase 1: Task Index

After the plan header and file structure sections, generate a task index table before any detailed task content:

```markdown
## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Project setup | `package.json`, `tsconfig.json` | S | Init project structure |
| 2 | Data models | `src/models/*.ts` | L | 4 model files, core types |
| 3 | API routes | `src/routes/*.ts` | M | CRUD endpoints |
| ... | ... | ... | ... | ... |

Complexity: S = ~50 lines, M = ~150 lines, L = ~300+ lines of task content
Batch budget: each batch targets ≤ 3M equivalent (1L=2M=3S)
```

Purpose:
- Forces upfront planning of all tasks before writing any detailed content
- Provides complexity estimates that drive batch sizing
- Gives a quick overview for the self-review phase

### Phase 2: Batch Generation

Generate detailed task content in batches. Each batch contains one or more complete tasks. Batch size is determined by the complexity budget:

**Batch budget rules:**
- Each batch targets ≤ 3M complexity equivalent
- Equivalence: 1L = 2M = 3S
- Examples: 3M per batch, or 1L+1S, or 1L (alone), or 5S

**Generation flow:**
1. Write plan header (unchanged)
2. Write file structure section (unchanged)
3. Write task index table
4. For each batch:
   - Write `---` separator followed by `### Batch N (Tasks X-Y)` heading
   - Generate full detailed content for each task in the batch
   - Continue immediately to next batch (no user confirmation, no inter-batch review)
5. Write self-review section (unchanged)
6. Save plan file

**What stays the same:**
- Plan header format
- File structure section
- Individual task format (files, steps, code blocks)
- Self-review checklist
- Execution handoff

**What changes:**
- Task index table added after file structure
- Tasks are generated in batches with batch separators (markdown headings, not HTML comments)
- Self-review runs once at the end across all batches (not per-batch)

## Changes to SKILL.md

Add a new section "Batch Generation" between "File Structure" and "Task Structure" with the two-phase process. Update "Plan Structure" to show the new index table and batch markers. No other sections need modification.

### Specific insertions:

1. **New section "Batch Generation"** after "File Structure" (~25 lines):
   - Phase 1: task index description and format
   - Phase 2: batch rules, budget calculation, flow
   - Always-on (no threshold check)

2. **Update "Plan Structure"** section to include:
   - Task index table in the template
   - Batch markers in the template

3. **Update "Self-Review"** section:
   - Add check: "Does the task index match the actual tasks generated?"
   - Existing checks remain unchanged

## What This Does NOT Change

- No new skills, files, or dependencies
- No changes to executing-plans, brainstorming, or other skills
- No user interaction changes (still write-plan → save → execution handoff)
- No changes to task format or step granularity
- No inter-batch pausing or user confirmation
