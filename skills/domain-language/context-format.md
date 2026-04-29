# CONTEXT.md Format Guide

## Overview

CONTEXT.md is a living glossary at the project root. It defines the shared language that humans and agents use when discussing the project.

**Core principle:** If two people (or agents) might use different words for the same thing, it needs an entry here.

## File Location

- **Single-context project:** `CONTEXT.md` at project root
- **Multi-context project:** `CONTEXT-MAP.md` at root, pointing to sub-domain `CONTEXT.md` files

## Structure

```markdown
# [Project Name] Domain Language

> Last updated: [date]
> Update rule: Update inline during discussions. Don't batch updates.

## Core Concepts

### [Term]
**Definition:** One sentence that would make sense to a new team member.
**Examples:** Concrete usage examples (1-3).
**See also:** Related terms in this glossary.

## Relationships

- [Term A] is a type of [Term B]
- [Term C] uses [Term D] to accomplish [goal]

## Boundaries (what things are NOT)

- [Term X] does NOT include [common misconception]
- [Term Y] is different from [Term Z] because [reason]
```

## Entry Rules

### When to Add an Entry

1. **Ambiguity detected:** Two people use different words for the same concept
2. **Jargon introduced:** A domain-specific term that outsiders wouldn't know
3. **Boundary dispute:** "Does X include Y?" — write it down
4. **Concept named:** You gave something a name during design discussion
5. **Agent confusion:** An agent used the wrong term or misunderstood context

### When NOT to Add

- Common programming terms (function, class, variable)
- Terms already well-defined in the framework/language docs
- Implementation details that may change (prefer concepts)

### Entry Quality Check

Each entry should pass:
- **Newcomer test:** Would someone new to the project understand it?
- **Ambiguity test:** Could two people read it and mean different things?
- **Stability test:** Is this a concept, not an implementation detail?

## Evolution Rules

1. **Inline updates:** When a term is clarified in discussion, update CONTEXT.md immediately. Don't wait.
2. **Bold additions:** New terms get added as they're named.
3. **Strikethrough removals:** Don't delete old terms immediately — strike them through with a note pointing to the replacement. Remove after 30 days.
4. **Never stale:** If you're not sure a term is still accurate, mark it with `⚠️ verify` — don't leave it silently wrong.

## CONTEXT-MAP.md (Multi-Context Projects)

When a project spans multiple bounded contexts (e.g., payment processing + user management + inventory):

```markdown
# Context Map

> Each sub-domain has its own CONTEXT.md. This map shows how they connect.

## Contexts

| Context | Location | Core Terms | Owner |
|---------|----------|------------|-------|
| Payments | `services/payment/CONTEXT.md` | Transaction, Settlement, Refund | Payment team |
| Users | `services/user/CONTEXT.md` | Account, Profile, Permission | Identity team |
| Inventory | `services/inventory/CONTEXT.md` | Stock, SKU, Reservation | Supply team |

## Shared Terms

Terms that appear across contexts (must be consistent):

- **Order:** Used by Payments (as payment trigger) and Inventory (as fulfillment unit). Same ID, different lifecycle.

## Translation Rules

| Payment Term | Inventory Term | Meaning |
|-------------|---------------|---------|
| Transaction | Reservation | Locking funds/stock for a pending order |
```

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| Writing a novel per entry | Nobody reads it | One sentence definition + examples |
| Only updating at sprint end | Terms drift during sprint | Update inline, during discussion |
| Including implementation details | Details change; concepts don't | Define the "what," not the "how" |
| Copy-pasting framework docs | Redundant and stale | Link to docs instead |
| Skipping "Boundaries" section | Misunderstandings thrive in ambiguity | Explicitly state what things are NOT |
