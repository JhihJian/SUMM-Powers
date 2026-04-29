# Deepening Shallow Modules

## Overview

Deepening is making a module's interface smaller and its hidden behavior larger. The goal: callers do less, the module does more.

**Warning:** Deepening requires understanding all callers. Don't deepen in isolation — you may remove functionality that callers depend on.

## Diagnosis: Is This Module Shallow?

Run these checks in order:

1. **Deletion test:** Remove the module. Does complexity vanish (shallow) or scatter (deep)?
2. **Interface count:** More than 5-7 public methods? Likely too wide.
3. **Caller pattern:** Do callers always call methods A+B+C together? Those should be one method.
4. **Pass-through ratio:** What percentage of methods just delegate? >50% → shallow.
5. **Knowledge spread:** Does one concept require touching multiple modules? → accidental distribution.

## Deepening Tactics

### Tactic 1: Combine Related Methods

When callers always call methods together, combine them.

```typescript
// Before: callers must remember the sequence
const handle = db.connect();
const tx = db.beginTransaction(handle);
const result = db.query(tx, sql);
db.commit(tx);
db.disconnect(handle);

// After: one method, deep implementation
const result = db.query(sql); // handles connect, transaction, commit, disconnect
```

### Tactic 2: Hide Default Behavior

When most callers use the same default, make it the default.

```typescript
// Before: every caller specifies format
parse(input, 'json', { strict: true, encoding: 'utf-8' });

// After: sensible defaults, override when needed
parse(input); // defaults: json, strict, utf-8
parse(input, { format: 'yaml' }); // override only what differs
```

### Tactic 3: Elevate Patterns to the Interface

When callers repeatedly implement the same pattern on top of a module, the module should absorb it.

```typescript
// Before: every caller writes retry logic
for (let i = 0; i < 3; i++) {
  try {
    return await api.call(endpoint);
  } catch (e) {
    if (i === 2) throw e;
    await sleep(1000 * Math.pow(2, i));
  }
}

// After: module handles retry
return await api.call(endpoint); // built-in exponential backoff
```

### Tactic 4: Remove Pass-Through Layers

If a module just delegates without adding behavior, remove it.

```typescript
// Before: pass-through service
class UserService {
  getUser(id) { return this.repo.getUser(id); }
  save(user) { return this.repo.save(user); }
}

// After: callers use repository directly (or deepen the service)
// Option A: Remove service, use repo
// Option B: Deepen service with real behavior (validation, events, caching)
```

### Tactic 5: Absorb Scattered Behavior

When one concept is split across multiple files, merge them.

```typescript
// Before: validation split across pipeline
input → sanitize → validate → transform → persist

// After: deep module absorbs pipeline
store(input) // internally: sanitize + validate + transform + persist
```

## Trade-offs

Deepening is not always right. Consider:

| Situation | Better Shallow | Better Deep |
|-----------|---------------|-------------|
| Multiple distinct callers with different needs | Let callers compose | Module anticipates needs |
| Performance-critical hot path | Caller controls details | Module optimizes internally |
| Unstable API / rapid prototyping | Keep surface area small | Stabilize before deepening |
| Learning/educational code | Explicit > hidden | Hide complexity for production code |

## Verification

After deepening, verify:

1. **Caller code got simpler.** Count lines before/after at call sites.
2. **Tests still pass.** Deepening changes internals, not behavior.
3. **Interface shrank.** Public method count should decrease.
4. **No hidden coupling.** The module doesn't make assumptions about specific callers.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| Deepening without reading callers | Breaks unknown use cases | Audit all callers first |
| Making interface "flexible" with 20 options | Width is not depth | Combine into meaningful methods |
| Hiding critical behavior | Callers can't debug | Deep ≠ opaque; log, expose diagnostics |
| Over-deepening | Module becomes a god object | Split when module serves unrelated callers |
