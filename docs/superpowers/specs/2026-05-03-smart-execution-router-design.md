# Smart Execution Router

**Date:** 2026-05-03
**Status:** Draft

## Problem

After completing an implementation plan, the writing-plans skill presents two execution options:

1. Subagent-Driven (recommended)
2. Inline Execution

This choice interrupts the flow and forces a decision the user has never found meaningful. Inline Execution is a fallback for platforms without subagent support — yet it's presented as an equal option on every run. The interruption adds friction without adding value.

## Solution

Replace the manual choice with an automatic execution router. After the plan is saved, the system analyzes plan characteristics, selects the optimal execution strategy, outputs a one-line notification, and starts execution immediately.

## Execution Router Logic

Default to Subagent-Driven. Inline Execution is only used when the platform lacks subagent support (e.g., lightweight terminal environments).

There is no reason for Claude Code to ever use Inline Execution — subagents are always available. The routing logic does not need to analyze plan characteristics (task count, dependencies, complexity) to decide. Just use Subagent-Driven.

## Notification Format

Replaces the current "Which approach?" prompt. No question, no waiting.

```
Plan complete and saved to `docs/superpowers/plans/<filename>.md`.

Starting Subagent-Driven execution — 5 tasks, fresh subagent per task with two-stage review.
```

On platforms without subagent support, the notification says "Starting batch execution" instead.

## Files Changed

### 1. `skills/writing-plans/SKILL.md` — Execution Handoff section (lines 265-283)

**Current behavior:** Presents two options, waits for user choice, then invokes the selected skill.

**New behavior:** Runs router logic, outputs notification, immediately invokes the selected skill.

The "Execution Handoff" section is rewritten to:
1. Output strategy notification
2. Invoke Subagent-Driven (or Inline if subagents unavailable) without waiting

### 2. `skills/executing-plans/SKILL.md` — Repositioned as internal fallback

**Changes:**
- `description` frontmatter: changed to indicate this is an internal fallback, not a user-facing option
- Remove line 16 ("Tell your human partner that Superpowers works much better with access to subagents...") — no longer relevant since users don't choose this
- Add header note: this skill is invoked automatically by the execution router in writing-plans
- Core execution logic (batch execution + checkpoints) remains unchanged

### 3. `skills/subagent-driven-development/SKILL.md` — Decision tree updated

**Changes:**
- "When to Use" section: replace the current three-question decision tree with a note that this skill is the default execution strategy, selected automatically by the router in writing-plans
- Remove the comparison with executing-plans (lines 34-38) — users no longer need to understand the distinction
- Core process (fresh subagent per task + two-stage review) remains unchanged

## What Doesn't Change

- `executing-plans` skill logic — batch execution with checkpoints works the same
- `subagent-driven-development` skill logic — fresh subagent per task + two-stage review works the same
- Plan file format — no changes to how plans are written
- All downstream skills (finishing-a-development-branch, verification, etc.)

## Future Considerations

- **User override:** If users later want to force a specific strategy, this could be supported via a command (e.g., `/fast` to switch to Inline Execution mid-plan). Not included in this design to avoid reintroducing the interruption point that motivated this change.
- **Routing telemetry:** Tracking which strategy was chosen and why could help refine the routing logic over time.
