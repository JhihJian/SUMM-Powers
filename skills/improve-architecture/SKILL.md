---
name: improve-architecture
description: Use when the codebase feels hard to change, when small features require touching many files, or when you want to systematically improve module structure. Explores friction points and deepens shallow modules. Skip when codebase is small or recently architected.
---

# Improve Codebase Architecture

Find and fix architectural friction — "small changes require touching many files."

## When to Activate

- Features require touching 5+ files for simple changes
- "Quick fix" keeps growing in scope
- Copy-paste patterns across the codebase
- Adding a feature requires understanding unrelated modules

## Prerequisites

- Read `CONTEXT.md` if present (domain terminology). If not present, invoke `domain-language` skill to create an initial CONTEXT.md before proceeding.
- Review `language.md` for depth, leverage, locality, seam definitions

## Workflow

### Phase 1: Explore (Find Friction)

Pick a recent change or feature request. Trace through the code:

1. **Map the change path:** Which files were modified for the last 3-5 features?
2. **Count touch points:** How many files per change? >5 → architectural smell
3. **Find pass-throughs:** Modules that delegate without adding behavior
4. **Find scattered concepts:** One concept split across multiple files
5. **Run the deletion test:** For suspect modules, ask "if I deleted this, where does complexity go?"

**Output:** A list of friction points with file paths and symptoms.

### Phase 2: Present Candidates

For each friction point, present:

```
**[Module/file path]**
- Symptom: [what's slow/painful about changing this]
- Diagnosis: [shallow/scattered/pass-through/god-module]
- Current interface: [N public methods/functions]
- Proposed direction: [what deepening would look like in 1-2 sentences]
- Estimated caller impact: [how many call sites affected]
```

**Do NOT implement yet.** Present 2-5 candidates and let the user choose.

### Phase 3: User Selects

The user picks which friction point(s) to address. For each selection:

1. **Confirm scope:** "This will affect [N] callers. OK to proceed?"
2. **Choose tactic:** Refer to `deepening.md` for appropriate tactic
3. **Plan the change:** List files to modify and expected interface changes

### Phase 4: Deep Dive

Implement the architectural improvement using TDD:

1. **Write tests for current behavior** (if not already covered)
2. **Refactor interface** (combine methods, hide defaults, absorb patterns)
3. **Update callers** to use new interface
4. **Run full test suite** to verify no regressions
5. **Update CONTEXT.md** if new terms or boundaries emerged
6. **Consider ADR** if the change meets the three-condition gate (see `skills/domain-language/adr-format.md`)

### Phase 5: Verify Improvement

After deepening, measure:

- File count for a typical change (should decrease)
- Public interface size (should decrease)
- Test coverage of the module (should stay the same or increase)

## Decision Framework

```
Found friction point?
├─ Is it actively causing pain?
│  └─ NO → Document, don't fix. Not all shallow modules need deepening.
│  └─ YES → Is the module stable (not actively changing)?
│     └─ NO → Wait. Let it stabilize before refactoring.
│     └─ YES → Proceed with deepening.
```

## Reference Files

- **`language.md`** — Terminology: module, depth, leverage, locality, seam, deletion test
- **`deepening.md`** — 5 deepening tactics with code examples, trade-offs, verification

## Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Refactoring without reading callers | Audit all callers before changing interface |
| Deepening everything at once | One module per session; verify improvement |
| Ignoring test pain | Hard-to-test = shallow; deepen first |
| No measurement before/after | Count files touched and methods exposed |