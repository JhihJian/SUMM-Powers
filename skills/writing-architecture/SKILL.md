---
name: writing-architecture
description: Use when creating or revising ARCHITECTURE.md — a stable project knowledge document for newcomer onboarding, contributor reference, and AI agent context. Skip for projects under ~1k lines where CLAUDE.md alone suffices, or for user-facing docs (README, guides).
---

# Writing ARCHITECTURE.md

## Overview

ARCHITECTURE.md is a stable project knowledge document. It helps newcomers build a mental model, contributors recall design intent, and AI agents understand project constraints. It answers "why is it designed this way?" — not "where is the code?"

**Core principle:** Write the knowledge you'd want on day one of joining the project — the things that take months to learn organically and rarely change once understood.

## When to Use

- Creating ARCHITECTURE.md for a new or existing project
- Revising an existing ARCHITECTURE.md (revisit a couple times per year, not per commit)
- Skip when: project is under ~1k lines, CLAUDE.md already covers architecture adequately

## Structure

Every ARCHITECTURE.md should contain these sections in order:

### 1. Project Positioning

3-8 lines describing what the project is, what problem it solves, and who it serves. A reader should understand the system's purpose after this section alone.

**Stability criterion:** Only changes if the project's target user or core problem changes.

### 2. Design Philosophy

3-7 design principles. Each principle has: a name, a one-line explanation, and the reasoning behind the choice. Focus on "why choose A over B" decisions, not module-level implementation details.

**Stability criterion:** Only changes if the project undergoes a fundamental direction change.

### 3. Core Concepts

5-10 domain-specific concepts that readers must understand to work with the project. Each concept has: a name, a one-sentence definition, and its relationship to other concepts. Only include concepts where "you cannot understand the project without understanding this."

**Stability criterion:** Concepts form the project's abstract skeleton. Implementation can change; concepts don't.

### 4. System Operation

2-4 end-to-end scenarios showing how the system works. Each scenario: what triggers it, what core concepts it flows through, what it produces. Focus on the flow path, not internal implementation of each step.

**Stability criterion:** Only changes if the system's fundamental operation mode changes.

### 5. Module Responsibilities

For each top-level directory or major module, 2-4 lines describing: its design intent (why it exists) and its responsibility boundary (what it owns vs. what it delegates). Name key files or types for symbol search. Do not enumerate internal files.

**Stability criterion:** Module responsibilities rarely change once the project matures.

### 6. Architecture Constraints

- **Layer boundaries:** For each boundary, state what each side does NOT know about the other
- **Invariants:** Cross-module rules, especially "absence" invariants ("X never depends on Y")
- **Design constraints:** Intentional limitations ("skills are pure text, never executable code")

Even monolithic projects have conceptual layers (entry point → business logic → data). Describe those. If the project genuinely has no layers, explain why that's intentional.

**Stability criterion:** Architecture constraints are often established at project creation.

## Rules

### Do

- **Name important files, modules, and types.** Use exact names so readers can symbol-search them.
- **Call out architectural invariants.** Especially things that are absent from the code — "nothing in layer X depends on layer Y" is invisible when reading layer X.
- **Describe boundaries explicitly.** State what each layer doesn't know about its neighbors.
- **Keep it short.** Target 80-120 lines. Every recurring contributor has to read it.
- **Only include stable facts.** Avoid version numbers, specific commit hashes, or details that change per release.
- **Answer "why" before "what".** Design intent is more valuable than structural description.

### Don't

- **Don't link to files.** Links go stale. Use file names and let readers search.
- **Don't enumerate internal files.** "Contains helper prompts" is enough — don't list every prompt file name.
- **Don't include version-specific values.** "Version follows pattern X" is stable; "current version is 5.0.7" is not.
- **Don't explain how modules work internally.** That's inline documentation or separate docs. This document says what things ARE and WHY they exist, not HOW they operate.
- **Don't write a second README.** This is for contributors, not users. Focus on project knowledge, not feature descriptions.
- **Don't include testing/build conventions.** Those belong in CLAUDE.md or CONTRIBUTING.md, not in stable architecture knowledge.

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Skipping design philosophy | Newcomers miss the "why" behind decisions | Always include 3-7 principles with reasoning |
| Core concepts reads like a glossary | Definitions without relationships don't build a mental model | Include how concepts relate to each other |
| System operation explains internals | Should show flow path, not implementation | Describe trigger → flow → output, not how each step works |
| Module responsibilities become file listings | Backsliding to old code map behavior | Focus on design intent, name only 2-3 key items |
| Including version numbers or hashes | Changes every release, doc becomes wrong | Describe the pattern or convention instead |
| Writing for users instead of contributors | Wrong audience — this is project knowledge | Focus on design intent, not feature descriptions |
| "My project has no architecture constraints" | Even simple projects have intentional limitations | Describe what the project deliberately does NOT do |

## Quality Checklist

Before finishing, verify:

- [ ] Project positioning: newcomer understands "what is this" in 30 seconds?
- [ ] Design philosophy: each principle explains "why this direction"?
- [ ] Core concepts: covers everything you "can't understand the project without"?
- [ ] System operation: at least one end-to-end scenario?
- [ ] Module responsibilities: each module has "why it exists" and "responsibility boundary"?
- [ ] Architecture constraints: absence-type invariants explicitly stated?
- [ ] Stability: no version numbers, hashes, or file enumerations?
- [ ] Length: under 120 lines?
- [ ] No links, only names for symbol search?
