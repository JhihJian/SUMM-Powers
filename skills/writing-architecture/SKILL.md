---
name: writing-architecture
description: Use when creating or revising an ARCHITECTURE.md document for a project. Skip for projects under ~1k lines where CLAUDE.md alone suffices, or when the request is about user-facing docs (README, guides).
---

# Writing ARCHITECTURE.md

## Overview

ARCHITECTURE.md bridges the gap between occasional contributors and core developers. The biggest difference is not writing code — it's finding where to write it. This document answers "where does X live?" and "what does the thing I'm looking at do?"

**Core principle:** A codemap is a map of a country, not an atlas of maps of its states.

## When to Use

- Creating ARCHITECTURE.md for a new or existing project
- Revising an existing ARCHITECTURE.md (revisit a couple times per year, not per commit)
- Skip when: project is under ~1k lines, CLAUDE.md already covers architecture adequately

## Structure

Every ARCHITECTURE.md should contain these sections in order:

### 1. Bird's Eye View

Describe the problem being solved and the high-level data flow in 5-10 lines. A reader should understand the system's purpose and how data moves through it after reading this section alone.

### 2. Code Map

For each top-level directory or major module:
- What it contains and its role (2-3 lines)
- Key files or types by name (but see rules below)
- Architectural invariants specific to this module

### 3. Layer Boundaries

Explicitly describe boundaries between layers. For each boundary, state what each side does NOT know about the other. This is the most valuable section for new contributors — boundaries constrain all possible implementations, but finding them by reading code is hard.

Even monolithic projects have conceptual layers (entry point → business logic → data). Describe those. If the project genuinely has no layers, explain why that's intentional.

### 4. Core Invariants

Cross-module invariants that hold across the entire system. Especially call out invariants expressed as absence ("X never depends on Y", "no module in layer A knows about layer B").

### 5. Cross-Cutting Concerns

Testing strategy, error handling, observability, build system — things that are everywhere and nowhere in particular.

## Rules

### Do

- **Name important files, modules, and types.** Use exact names so readers can symbol-search them.
- **Encourage symbol search.** Add a note near the top: "use symbol search to find mentioned entities."
- **Call out architectural invariants.** Especially things that are absent from the code — "nothing in layer X depends on layer Y" is invisible when reading layer X.
- **Describe boundaries explicitly.** State what each layer doesn't know about its neighbors.
- **Reflect on physical layout.** If logically related things aren't physically adjacent, note the tension and explain why.
- **Keep it short.** Target 80-120 lines. Every recurring contributor has to read it.
- **Only include stable facts.** Avoid version numbers, specific commit hashes, or details that change per release.

### Don't

- **Don't link to files.** Links go stale. Use file names and let readers search.
- **Don't explain HOW each module works.** That's inline documentation or separate docs. The codemap says what things ARE, not how they OPERATE.
- **Don't enumerate internal files.** "Contains helper prompts" is enough — don't list every prompt file name.
- **Don't include version-specific values.** "Version follows pattern X" is stable; "current version is 5.0.7" is not.
- **Don't write a second README.** This is for contributors, not users. Focus on code navigation, not feature descriptions.

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Codemap lists every file in a module | Map becomes an atlas — hard to maintain, goes stale | Name 2-3 key items, summarize the rest |
| No layer boundaries section | Most valuable info for newcomers is missing | Add explicit "X doesn't know about Y" statements |
| Including version numbers or hashes | Changes every release, doc becomes wrong | Describe the pattern or convention instead |
| Explaining implementation details | Belongs in inline docs, inflates the document | Only describe WHAT and WHERE, not HOW |
| Writing for users instead of contributors | Wrong audience — this is a contributor's map | Focus on code navigation, not feature descriptions |
| "My project has no layers" | Even monoliths have entry → logic → data | Describe conceptual layers; if truly flat, say why |
| "Listing more files helps readers find things" | Inflates doc, goes stale fast | Name 2-3 key items; readers use symbol search for the rest |

## Quality Checklist

Before finishing, verify:

- [ ] Bird's eye view: can a newcomer understand the system in 30 seconds?
- [ ] Codemap: can I answer "where does X live?" for every major module?
- [ ] Codemap: can I answer "what does this directory do?" for every top-level dir?
- [ ] Invariants: are absence invariants ("X never depends on Y") explicitly stated?
- [ ] Boundaries: does each boundary say what each side doesn't know?
- [ ] Stability: no version numbers, hashes, or values that change per release?
- [ ] Length: under 120 lines?
- [ ] No links, only names for symbol search?
- [ ] Physical layout tensions noted where they exist?
