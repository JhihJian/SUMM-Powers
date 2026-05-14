# Writing-Architecture Skill Redesign

Date: 2026-05-14
Status: Approved

## Problem

The current `writing-architecture` skill treats ARCHITECTURE.md as a code navigation map — it answers "where does X live?" and "what does this file do?". This is insufficient for its purpose:

1. **Wrong positioning**: Newcomers need to understand "why", not just "where". A file location doesn't help you understand the system.
2. **Content too shallow**: The structure generates surface-level descriptions without building a mental model.
3. **Not stable enough**: Despite rules against listing files, the structure is still organized around directory layout — which changes frequently.
4. **Missing key sections**: No coverage of design philosophy, domain concepts, or system operation flow.

## Design Decision

Redesign ARCHITECTURE.md as a **project knowledge document** — stable, top-level knowledge that helps newcomers build a mental model, contributors recall context, and AI agents understand project intent.

Reference: Stripe-style architecture docs (design philosophy + domain concepts + system story).

### Target Audience

1. **Newcomers** — need to build a mental model from zero
2. **Contributors** — need to quickly recall design intent
3. **AI agents** — need design constraints and domain knowledge to avoid violating project intent

### What "Stable" Means

The document should contain information that remains valid across:
- Adding/removing files
- Refactoring module internals
- Adding new skills/features
- Dependency updates

It should NOT contain anything that changes per-release or per-feature.

## New Structure (6 Sections)

### 1. Project Positioning

3-8 lines: what the project is, what problem it solves, who it serves.

**Stability criterion**: Only changes if the project's target user or core problem changes.

### 2. Design Philosophy

3-7 principles: name + one-line explanation + the reasoning behind the choice.

Focus on "why choose A over B" decisions, not module-level implementation details.

**Stability criterion**: Only changes if the project undergoes a fundamental direction change.

### 3. Core Concepts

5-10 domain-specific concepts: name + definition + relationships to other concepts.

Only include concepts where "you cannot understand the project without understanding this."

**Stability criterion**: Concepts form the project's abstract skeleton. Implementation can change; concepts don't.

### 4. System Operation

2-4 end-to-end scenarios: trigger → flow through core concepts → output.

Focus on the flow path, not internal implementation of each step.

**Stability criterion**: Only changes if the system's fundamental operation mode changes.

### 5. Module Responsibilities

Per top-level module (2-4 lines each): design intent + responsibility boundary.

Answers "why does this module exist" and "what is it responsible for", NOT "what files are inside."

Key files or types are named for symbol search, but internal files are not enumerated.

**Stability criterion**: Module responsibilities rarely change once the project matures.

### 6. Architecture Constraints

- **Layer boundaries**: what each side doesn't know about the other
- **Invariants**: cross-module rules, especially "absence" invariants ("X never depends on Y")
- **Design constraints**: intentional limitations ("skills are pure text, never executable code")

**Stability criterion**: Architecture constraints are often established at project creation.

## Changes from Current Skill

### Removed

- Separate "Layer Boundaries" section → merged into "Architecture Constraints"
- Separate "Core Invariants" section → merged into "Architecture Constraints"
- "Cross-Cutting Concerns" section (testing, build) → belongs in CLAUDE.md or CONTRIBUTING.md, not stable knowledge
- "Encourage symbol search" tip → overly specific formatting instruction

### Repositioned

- "Code Map" → "Module Responsibilities": from "what files are here" to "why does this module exist"
- "Bird's Eye View" → "Project Positioning": from data flow description to problem/solution framing

### Added

- "Design Philosophy" section
- "Core Concepts" section
- "System Operation" section
- Stability criterion per section

## Rules

### Do

- Name important files, modules, and types for symbol search
- Call out architectural invariants, especially absence-type ("X never depends on Y")
- Describe boundaries explicitly — what each side doesn't know
- Keep it under 120 lines
- Only include stable facts
- Answer "why" before "what"

### Don't

- Don't link to files — links go stale; use names for symbol search
- Don't enumerate internal files — name 2-3 key items, summarize the rest
- Don't include version numbers, hashes, or per-release values
- Don't explain how modules work internally — that's inline documentation
- Don't write a second README — this is for contributors, not users
- Don't include testing/build conventions — those belong in CLAUDE.md

## Quality Checklist

- [ ] Project positioning: newcomer understands "what is this" in 30 seconds?
- [ ] Design philosophy: each principle explains "why this direction"?
- [ ] Core concepts: covers everything you "can't understand the project without"?
- [ ] System operation: at least one end-to-end scenario?
- [ ] Module responsibilities: each module has "why it exists" and "responsibility boundary"?
- [ ] Architecture constraints: absence-type invariants explicitly stated?
- [ ] Stability: no version numbers, hashes, or file enumerations?
- [ ] Length: under 120 lines?
- [ ] No links, only names for symbol search?

## Affected Files

- `skills/writing-architecture/SKILL.md` — rewrite with new structure
- `skills/writing-architecture/SKILL.zh.md` — rewrite with new structure (Chinese)
- `commands/write-architecture.md` — may need description update
