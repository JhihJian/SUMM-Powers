# Mocking Guide

**Load this reference when:** deciding whether to mock a dependency, setting up test doubles, or when mock setup feels more complex than the test itself.

## Overview

Mocks isolate the code under test from external or slow dependencies. Used correctly, they make tests fast and deterministic. Used incorrectly, they test the mocks instead of the code.

**Core principle:** Mock at the boundary, not at the seams of your own code.

**If the mock setup is harder than the code under test, you're mocking the wrong thing.**

## Decision Tree

Follow this tree for every dependency before mocking:

```
Is it external (network, filesystem, database, third-party API)?
  YES → Mock it. Isolate from external failure and slowness.
  NO ↓

Is it slow (>100ms per call)?
  YES → Mock at the lowest level (the slow part only, not everything around it).
  NO ↓

Is it non-deterministic (time, random, UUID)?
  YES → Inject the source. Pass a clock or random function as a parameter.
  NO ↓

Is it another module in your codebase?
  YES → Use the real implementation. You want integration coverage.
  NO ↓

Is it code you're currently developing (doesn't exist yet)?
  YES → Use the real implementation. Write the minimal code to make the test pass.
  NO → Re-examine the dependency. Default to using the real implementation.
```

**Default: Don't mock.** Only mock when you have a concrete reason.

## When to Mock

### External Services

Mock to isolate from network failures, rate limits, and API costs.

```typescript
// ✅ GOOD: Mock the external HTTP call
test('fetches user profile', async () => {
  const mockApi = {
    get: vi.fn().mockResolvedValue({ data: { name: 'Alice', id: '123' } })
  };
  const service = new UserService(mockApi);

  const profile = await service.getProfile('123');

  expect(profile.name).toBe('Alice');
  expect(mockApi.get).toHaveBeenCalledWith('/users/123');
});
```

### Slow Operations

Mock at the lowest level — the slow part, not the entire module.

```typescript
// ✅ GOOD: Mock only the slow filesystem call
test('reads config and parses it', () => {
  const mockFs = { readFileSync: vi.fn().mockReturnValue('{"port": 3000}') };
  const config = loadConfig(mockFs);

  expect(config.port).toBe(3000);
});

// ❌ BAD: Mocking the entire config module
vi.mock('config'); // Now you're not testing the parsing logic at all
```

### Non-Deterministic Sources

Inject a controllable source rather than mocking.

```typescript
// ✅ GOOD: Inject random source
function generateCouponCode(prefix: string, random: () => number): string {
  const suffix = Math.floor(random() * 1e6).toString().padStart(6, '0');
  return `${prefix}-${suffix}`;
}

test('generates coupon with deterministic suffix', () => {
  const alwaysHalf = () => 0.5;
  expect(generateCouponCode('SAVE', alwaysHalf)).toBe('SAVE-500000');
});
```

## When NOT to Mock

### Internal Modules

Your own code should be tested with real implementations for integration coverage.

```typescript
// ✅ GOOD: Use real validator
test('rejects invalid email', () => {
  const result = validateEmail('not-an-email');
  expect(result.valid).toBe(false);
});

// ❌ BAD: Mocking your own validator
vi.mock('./validator');
// Now you're testing that the mock works, not that validation works
```

### Module Under Test

Never mock the thing you're testing.

```typescript
// ❌ BAD: Mocking the system under test
const service = { process: vi.fn().mockResolvedValue('done') };
await service.process(order);
expect(service.process).toHaveBeenCalled();
// This proves nothing — the mock always returns 'done'

// ✅ GOOD: Test the real implementation
const service = new OrderProcessor(gateway);
const result = await service.process(order);
expect(result.status).toBe('processed');
```

### Data Structures and Pure Functions

They have no dependencies and are deterministic. Just call them.

```typescript
// ✅ GOOD: Test pure function directly
test('calculates cart total', () => {
  const items = [{ price: 10 }, { price: 20 }];
  expect(calculateTotal(items)).toBe(30);
});

// ❌ BAD: Why would you mock this?
const items = vi.fn().mockReturnValue([{ price: 10 }, { price: 20 }]);
```

## Mocking Levels

From best to worst:

| Level | Description | When to Use | Example |
|-------|-------------|-------------|---------|
| **Interface mock** | Mock an interface/protocol. Production code depends on abstraction. | Always preferred. Cleanest separation. | `new UserService(mockPaymentGateway)` where `PaymentGateway` is an interface |
| **Function injection** | Pass test function as callback or parameter. | When full interface is overkill. Simple functions. | `retry(fn, { delay: () => 100 })` |
| **Module mock** | Replace entire module via test framework (`vi.mock`, `jest.mock`). | When dependency is hardcoded but module-level. Last resort for internal code. | `vi.mock('./database')` |
| **Method stub** | Replace individual methods on real objects (`vi.spyOn`). | Quick fixes, legacy code. Fragile. | `vi.spyOn(db, 'query').mockResolvedValue(rows)` |

**Prefer higher levels.** If you're reaching for `vi.spyOn` or `vi.mock`, ask whether the code could instead accept the dependency through its interface.

## Mock Maintenance Cost

| Mock Type | How It Breaks | Fix Cost | Signal to Improve |
|-----------|--------------|----------|-------------------|
| **Interface mock** | Interface signature changes. Rare if well-designed. | Low — update mock to match new interface. | Good — mock and interface evolve together. |
| **Function injection** | Parameter list changes. | Low — add/remove parameter. | Acceptable for simple cases. |
| **Module mock** | Internal implementation changes. Mock doesn't match real module anymore. | Medium — must update mock to match new internals. | Warning — code is coupled to module internals. |
| **Method stub** | Method renamed, removed, or behavior changes. Test passes but doesn't match reality. | High — fragile, breaks on refactor. | Red flag — redesign to use interface injection. |

**Rule of thumb:** If mock maintenance exceeds 10% of test code, the interface needs redesign.

## Quick Reference

| Situation | Action |
|-----------|--------|
| External API call | Mock the HTTP client or API interface |
| Database query | Mock at the repository interface, not the DB driver |
| Filesystem access | Inject a file reader interface or use an in-memory FS |
| `Date.now()` | Pass current time as a parameter |
| `Math.random()` | Pass a random function as a parameter |
| UUID generation | Pass an ID generator function |
| Network request | Mock the transport layer |
| Slow computation | Mock only the slow part, not surrounding logic |
| Your own module | Use the real implementation |
| Code under test | NEVER mock — test the real thing |
| Pure function | Just call it — no mock needed |
| Third-party library (pure logic) | Use the real library |
| Third-party library (I/O or stateful) | Wrap in interface, mock the interface |

## Red Flags

- Mock setup is longer than the test assertion
- Test only verifies that mocks were called (`expect(mock).toHaveBeenCalled()`)
- Removing the mock makes the test fail for the wrong reason
- You mock your own code (not external dependencies)
- Multiple tests share complex mock state
- Mock returns data that the real implementation never would
- You reach for `vi.spyOn` before trying constructor injection

**When you see these: Stop. Read `interface-design-for-testability.md` in this directory. Fix the interface.**
