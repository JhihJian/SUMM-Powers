---
name: domain-language
description: Use when starting a new project, onboarding to a codebase, or when terminology ambiguity is causing confusion. Creates and maintains CONTEXT.md domain glossary and ADRs. Skip when no domain-specific terminology exists.
---

# Domain Language

Establish and maintain shared language for a project. When humans and agents use the same words for the same things, communication breaks down less.

## When to Activate

- New project starting (create initial CONTEXT.md)
- Onboarding to an existing project without CONTEXT.md
- Terminology confusion detected ("I think we mean different things by X")
- Making an architecture decision that meets the ADR three-condition gate

## Workflow

### 1. Check for Existing Context

```
ls CONTEXT.md CONTEXT-MAP.md docs/adr/ 2>/dev/null
```

- **Found CONTEXT.md:** Read it, verify terms are current
- **Not found:** Create one (see Step 2)
- **Found CONTEXT-MAP.md:** Multi-context project — read map, navigate to relevant sub-context

### 2. Create CONTEXT.md (if needed)

Create at project root using the format in `context-format.md`.

**Minimum viable CONTEXT.md:**

```markdown
# [Project] Domain Language

## Core Concepts

### [Most Important Term]
**Definition:** [One sentence]
**Examples:** [1-3 usage examples]
```

Start with 3-5 core concepts. Add more as discussion reveals them.

### 3. Inline Updates During Discussion

**This is the critical behavior.** When a term is clarified:

1. Stop and update CONTEXT.md immediately — don't batch
2. Add new terms as they're named
3. Mark uncertain terms with `⚠️ verify`
4. Cross-reference related terms in "See also"

### 4. ADR Creation (Conditional)

When making an architecture decision, apply the **three-condition gate** (see `adr-format.md`):

1. Hard to reverse? (undo > 1 day of work)
2. Context-dependent? (outsider would choose differently)
3. Real trade-off? (genuine alternative was rejected)

ALL THREE → create ADR in `docs/adr/NNNN-title.md`
ANY MISSING → no ADR needed

### 5. Verify Consistency

Before ending a domain-language session:

- Check that new terms are referenced from related terms
- Verify no contradictions between entries
- Ensure boundaries section exists for ambiguous terms
- Confirm ADR status is current (no stale "Proposed" entries)

## Integration with Other Skills

- **brainstorming:** Read CONTEXT.md at start; update inline during ideation
- **writing-plans:** Use defined terms in plan documents; note any new terms
- **writing-skills:** Use project domain terms in skill descriptions
- **improve-architecture:** Use depth/leverage/locality/seam terms consistently

## Reference Files

- **`context-format.md`** — CONTEXT.md structure, entry rules, evolution rules, CONTEXT-MAP.md format
- **`adr-format.md`** — ADR template, three-condition gate, status lifecycle

## Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Creating CONTEXT.md once and never updating | Update inline during every discussion |
| Writing a novel per entry | One sentence + examples |
| ADR for every decision | Apply three-condition gate strictly |
| Including implementation details | Define concepts, not code |
