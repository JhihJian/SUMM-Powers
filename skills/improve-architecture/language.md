# Architecture Terminology

## Overview

Precise terms make architecture discussions efficient. "This module is too shallow" is actionable; "this module is bad" is not.

All modules have these properties. The question is whether they're serving the codebase well.

## Core Terms

### Module

Any unit of code with an interface and implementation: function, class, package, service, vertical slice.

The architecture skill works at any granularity. Don't limit "module" to "class."

### Depth

How much behavior is hidden behind the interface relative to the interface's size.

```
Deep:   interface has 2 methods, implementation handles 50 edge cases
Shallow: interface has 10 methods, each passes through to another layer
```

**Deep is generally better.** Callers get power from simple calls. Maintainers change internals freely.

### Leverage

What callers gain from a module's depth. A module with high leverage solves a real problem for its callers with minimal API surface.

```
High leverage: fs.readFile(path) → handles encoding, buffering, errors, platform differences
Low leverage:  fs.open() + fs.seek() + fs.read() + fs.close() → caller manages everything
```

**Ask:** "If I deleted this module, would callers have to reinvent complex behavior, or just move a few lines around?"

### Locality

What maintainers gain from depth. High locality means changes to the module's behavior stay inside the module.

```
High locality: Change readFile's buffering → zero caller changes
Low locality:  Change read()'s contract → every caller must update
```

**Ask:** "When this module's requirements change, how many other files need to change?"

### Seam

The boundary where interface meets implementation. The point where behavior can be swapped without modifying callers.

```
Good seam: callers depend on Database interface
           swap PostgreSQL → Redis without touching callers
Bad seam:  callers import PostgreSQLClient directly
           swap requires touching every caller
```

**Seams enable change.** Modules without seams resist change.

### Deletion Test

A thought experiment: imagine removing the module entirely. Where does the complexity go?

```
If complexity vanishes     → module was a pass-through (not earning its keep)
If complexity scatters     → module was providing real locality
If callers can't function  → module was providing real leverage
```

## Composite Patterns

### Pass-Through Module

Interface and implementation are nearly identical. Delegates to another layer without adding behavior.

```
// Pass-through: adds no value
function getUser(id) {
  return repository.getUser(id);
}
```

**Fix:** Remove it or deepen it (add validation, caching, transformation).

### God Module

One module with too many responsibilities. Depth is high but leverage is scattered — callers use different subsets.

```
// God module: does everything
class UserManager {
  authenticate(), authorize(), create(), delete(),
  changePassword(), sendEmail(), logActivity(),
  generateReport(), syncWithCRM()...
}
```

**Fix:** Split by caller need. Each resulting module should serve a coherent set of callers.

### Accidental Distribution

Behavior that should be deep is scattered across multiple shallow modules. No single module has enough depth to provide leverage.

```
// Scattered: "validation" is spread across 5 files
validateInput.ts → sanitize.ts → checkRules.ts → transform.ts → persist.ts
// Each file does one trivial thing; together they form a fragile pipeline
```

**Fix:** Merge into a single deep module with a coherent interface.

## Measurement Heuristics

| Metric | How to Measure | Target |
|--------|---------------|--------|
| Interface size | Count public methods/functions | Fewer = deeper |
| Call site complexity | Lines of caller code needed to use the module | Less = more leverage |
| Change radius | Files modified for a typical requirement change | Fewer = more locality |
| Test count ratio | Tests per public method | Higher = more depth |

## Cross-Reference

For testing-specific applications of these concepts, see `skills/test-driven-development/deep-modules.md`.
