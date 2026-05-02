# Goal Loop State File Schema

This file defines the format for `.claude/goal-loop-state.md`, which the goal-loop skill reads and writes each iteration.

## Template

```markdown
# Goal Loop State

## Goal
<user-provided goal text, copied verbatim from command>

## Status: ACTIVE
<!-- One of: ACTIVE | COMPLETED | ABORTED -->

## Iteration: 1/<max-iterations>
<!-- Increment the first number each iteration -->

## Improvement Backlog
<!-- Ordered by priority (highest first). Mark [x] when completed. -->
- [ ] <improvement item description>

## Iteration History
<!-- Add a new section after each iteration. -->
### Iteration N — <one-line summary>
- Action: <what was done>
- Skill used: summ:<skill-name>
- Result: <outcome summary>
- Files changed: <list of modified/created files>
```

## Field Rules

- **Goal**: Never modify after initialization. This is the anchor for self-evaluation.
- **Status**: Only transitions forward: ACTIVE → COMPLETED or ACTIVE → ABORTED. Never back to ACTIVE.
- **Iteration**: Format is `current/max`. Increment current by 1 after each iteration. Never modify max.
- **Improvement Backlog**: Re-prioritize each iteration. Add new items discovered during assessment. Remove items that became irrelevant. Mark `[x]` for completed items with `(iter N)` annotation.
- **Iteration History**: Append-only. Never edit past iterations.
```