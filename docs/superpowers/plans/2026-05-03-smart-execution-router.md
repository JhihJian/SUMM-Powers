# Smart Execution Router Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summ:subagent-driven-development (recommended) or summ:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the manual execution choice in writing-plans with automatic routing — default to Subagent-Driven, auto-downgrade to Inline only when subagents unavailable.

**Architecture:** Three markdown skill files modified. No code, no new files. The router logic lives entirely in writing-plans's Execution Handoff section as instructions the AI follows.

**Tech Stack:** Markdown skill files

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `skills/writing-plans/SKILL.md` | Modify L265-283 | Replace choice prompt with auto-routing + notification |
| `skills/executing-plans/SKILL.md` | Modify L1-16 | Reposition as internal fallback, remove user-facing note |
| `skills/subagent-driven-development/SKILL.md` | Modify L14-38 | Simplify "When to Use" to reference auto-routing |

## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Rewrite Execution Handoff in writing-plans | `skills/writing-plans/SKILL.md` | S | Replace L265-283 |
| 2 | Reposition executing-plans as internal fallback | `skills/executing-plans/SKILL.md` | S | Update description + remove L16 |
| 3 | Simplify subagent-driven-development When to Use | `skills/subagent-driven-development/SKILL.md` | S | Replace L14-38 |

---

### Batch 1 (Tasks 1-3)

### Task 1: Rewrite Execution Handoff in writing-plans

**Files:**
- Modify: `skills/writing-plans/SKILL.md:265-283`

- [ ] **Step 1: Replace the Execution Handoff section**

Replace lines 265-283 (from `## Execution Handoff` to end of file) with:

```markdown
## Execution Handoff

After saving the plan, automatically start execution:

**Announce:**

"Plan complete and saved to `docs/superpowers/plans/<filename>.md`.

Starting Subagent-Driven execution — N tasks, fresh subagent per task with two-stage review."

**Then immediately invoke:** summ:subagent-driven-development

**Fallback:** If subagents are not available on this platform, use summ:executing-plans instead and announce "Starting batch execution — N tasks, direct execution with checkpoints."

**Do not ask the user to choose.** Default to Subagent-Driven. The executing-plans skill is an internal fallback, not a user-facing option.
```

- [ ] **Step 2: Verify the edit**

Run: `grep -n "Execution Handoff\|Which approach\|Subagent-Driven\|Inline Execution" skills/writing-plans/SKILL.md`
Expected: No "Which approach" or "Inline Execution" references in the handoff section. "Subagent-Driven" appears as the default.

- [ ] **Step 3: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "refactor(writing-plans): auto-route to Subagent-Driven, remove manual execution choice"
```

### Task 2: Reposition executing-plans as internal fallback

**Files:**
- Modify: `skills/executing-plans/SKILL.md`

- [ ] **Step 1: Update frontmatter description**

Change line 3 from:
```
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
```
to:
```
description: Internal fallback for plan execution when subagents are unavailable — invoked automatically by writing-plans, not intended for direct user selection
```

- [ ] **Step 2: Remove the user-facing note about subagents**

Remove line 16:
```
**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use summ:subagent-driven-development instead of this skill.
```

Replace with:
```
**Note:** This skill is invoked automatically by the execution router in writing-plans when subagents are unavailable. It is not intended for direct user selection.
```

- [ ] **Step 3: Verify the edit**

Run: `grep -n "Tell your human partner\|direct user selection\|Internal fallback" skills/executing-plans/SKILL.md`
Expected: "Tell your human partner" gone. "Internal fallback" in description. "direct user selection" in new note.

- [ ] **Step 4: Commit**

```bash
git add skills/executing-plans/SKILL.md
git commit -m "refactor(executing-plans): reposition as internal fallback, remove user-facing note"
```

### Task 3: Simplify subagent-driven-development When to Use

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

- [ ] **Step 1: Replace the "When to Use" section (lines 14-38)**

Replace lines 14-38 (from `## When to Use` through the `vs. Executing Plans` comparison) with:

```markdown
## When to Use

This is the default execution strategy, automatically selected by the execution router in writing-plans after an implementation plan is saved.

**Activation:**
- writing-plans completes → auto-invokes this skill → no user choice needed
- Only falls back to executing-plans on platforms without subagent support

You can also invoke this skill directly if you have an implementation plan ready.
```

- [ ] **Step 2: Verify the edit**

Run: `grep -n "When to Use\|digraph when_to_use\|vs. Executing Plans\|executing-plans\|auto-invokes" skills/subagent-driven-development/SKILL.md`
Expected: Old decision tree dot graph gone. "vs. Executing Plans" gone. "executing-plans" only mentioned as fallback. "auto-invokes" present.

- [ ] **Step 3: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "refactor(subagent-driven): simplify When to Use, reference auto-routing"
```
