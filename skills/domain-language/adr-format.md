# ADR Format Guide

## Overview

Architecture Decision Records (ADRs) capture decisions that are hard to reverse. They're not a journal of every choice — only the ones where context matters.

**Core principle:** If someone reading this in 6 months would make a different choice without the context, write an ADR.

## The Three-Condition Gate

Create an ADR ONLY when ALL THREE conditions are met:

1. **Hard to reverse:** Undoing this decision would take more than a day of work
2. **Context-dependent:** Someone without the full picture would choose differently
3. **Real trade-off:** There was a genuine alternative that you rejected for a specific reason

If any condition is missing, don't create an ADR:
- Easy to change → just change it, no document needed
- Obvious choice → no context to preserve
- No alternative → no trade-off to explain

## Directory Structure

```
docs/adr/
  0001-database-selection.md
  0002-authentication-strategy.md
  0003-caching-approach.md
  ...
  template.md
```

## Template

```markdown
# [NUMBER]. [TITLE]

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by [NUMBER]
**Decision makers:** [who was involved]

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Alternatives Considered

| Option | Pros | Cons | Why Rejected |
|--------|------|------|-------------|
| [Option A] (chosen) | ... | ... | — |
| [Option B] | ... | ... | [specific reason] |
| [Option C] | ... | ... | [specific reason] |

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive
- ...

### Negative
- ...

### Risks
- ...
```

## Status Lifecycle

```
Proposed → Accepted → (active)
                    → Deprecated (no longer relevant)
                    → Superseded by [newer ADR]
```

- **Proposed:** Under discussion, not yet decided
- **Accepted:** Decision made, being implemented
- **Deprecated:** No longer relevant (project changed direction)
- **Superseded:** Replaced by a newer ADR (link to the replacement)

## Writing Rules

1. **Context section:** Write for someone who doesn't know the project. Include the forces at play.
2. **Decision section:** State what you chose, not just what you rejected.
3. **Alternatives table:** Every alternative needs a "Why Rejected" — this is the most valuable part.
4. **Consequences:** Be honest about negatives. Future readers need the real trade-offs.
5. **No justification theater:** Don't write an ADR to justify a decision you've already committed to without real alternatives. If there was no genuine choice, there's no ADR.

## When to Update an Existing ADR

- **Don't rewrite.** If the decision changes, create a new ADR that supersedes the old one.
- **Addendums are OK.** If consequences turned out differently, add a dated addendum at the bottom.
- **Link forward.** When superseding, update the old ADR's status to "Superseded by [new number]."

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| ADR for every decision | Noise drowns signal | Apply three-condition gate |
| Writing ADRs after the fact | Context is already lost | Write during the decision |
| Vague alternatives | "Considered other options" is useless | Name each option, list pros/cons/reason |
| No negatives in consequences | Looks like justification, not analysis | Honest trade-offs only |
| Never deprecating | Stale ADRs mislead | Periodically review status |
