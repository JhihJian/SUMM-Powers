# Interface Design for Testability

**Load this reference when:** struggling to write tests because setup is complex, outputs are hard to observe, or dependencies can't be controlled.

## Overview

Testable code is well-designed code. When code is hard to test, the design is telling you something. This reference maps testing pain to design fixes.

**Core principle:** If you can't test it easily, the interface is wrong.

**TDD makes this a feedback loop, not an afterthought.** When the test is hard to write, you fix the design immediately — not weeks later.

## Testability Checklist

Before writing any module, ask these four questions:

### 1. Can I create it with test data?

```typescript
// ✅ GOOD: Accept data through constructor or parameters
function formatCurrency(amount: number, currency: string): string {
  return new Intl.NumberFormat('en', { style: 'currency', currency }).format(amount);
}

test('formats USD', () => {
  expect(formatCurrency(42, 'USD')).toBe('$42.00');
});

// ❌ BAD: Hardcoded data source, can't control input
class PriceDisplayer {
  private prices = fetchFromDatabase(); // Can't test without real DB
  format(itemId: string): string { /* ... */ }
}
```

### 2. Can I observe the result?

```typescript
// ✅ GOOD: Returns the result
function calculateDiscount(price: number, loyaltyTier: string): number {
  const rates = { bronze: 0.05, silver: 0.10, gold: 0.15 };
  return price * (rates[loyaltyTier] ?? 0);
}

test('gold gets 15% off', () => {
  expect(calculateDiscount(100, 'gold')).toBe(15);
});

// ❌ BAD: Side effect only, nothing to observe
function applyDiscount(order: Order): void {
  order.total -= order.total * getDiscountRate(order.userId);
  // How do I assert the right discount was applied?
  // Must inspect order.total and know original value
}
```

### 3. Can I control time and randomness?

```typescript
// ✅ GOOD: Inject time source
function isExpired(issuedAt: Date, now: Date, ttlMs: number): boolean {
  return now.getTime() - issuedAt.getTime() > ttlMs;
}

test('detects expired token', () => {
  const issued = new Date('2025-01-01');
  const now = new Date('2025-01-02');
  expect(isExpired(issued, now, 86_400_000)).toBe(true);
});

// ❌ BAD: Hidden time dependency
function isExpired(issuedAt: Date, ttlMs: number): boolean {
  return Date.now() - issuedAt.getTime() > ttlMs; // Can't control "now"
}
```

### 4. Can I replace dependencies?

```typescript
// ✅ GOOD: Dependency injected
class OrderProcessor {
  constructor(private paymentGateway: PaymentGateway) {}

  async process(order: Order): Promise<Receipt> {
    const charge = await this.paymentGateway.charge(order.total);
    return { orderId: order.id, chargeId: charge.id };
  }
}

test('processes order via gateway', async () => {
  const gateway = { charge: vi.fn().mockResolvedValue({ id: 'ch_123' }) };
  const processor = new OrderProcessor(gateway);
  const receipt = await processor.process({ id: 'o1', total: 99 });
  expect(receipt.chargeId).toBe('ch_123');
});

// ❌ BAD: Dependency hardcoded inside
class OrderProcessor {
  async process(order: Order): Promise<Receipt> {
    const gateway = new StripeGateway(process.env.API_KEY!); // Can't replace
    const charge = await gateway.charge(order.total);
    return { orderId: order.id, chargeId: charge.id };
  }
}
```

## Design Patterns for Testability

### Dependency Injection

Pass collaborators through the constructor or function parameters.

```typescript
// ❌ BAD: Creates dependency inside
class UserService {
  async getUser(id: string) {
    const db = new Database(); // Can't replace in test
    return db.query('SELECT * FROM users WHERE id = ?', [id]);
  }
}

// ✅ GOOD: Receives dependency from outside
class UserService {
  constructor(private db: Database) {}

  async getUser(id: string) {
    return this.db.query('SELECT * FROM users WHERE id = ?', [id]);
  }
}
```

### Pure Functions

Same inputs always produce same outputs. No side effects. No state.

```typescript
// ❌ BAD: Relies on mutable state
class Cart {
  items: Item[] = [];
  total = 0;

  addItem(item: Item): void {
    this.items.push(item);
    this.total += item.price; // Mutates state
  }
}
// Must inspect internal state after calling addItem

// ✅ GOOD: Returns new state, doesn't mutate
type Cart = { items: Item[]; total: number };

function addItem(cart: Cart, item: Item): Cart {
  return {
    items: [...cart.items, item],
    total: cart.total + item.price
  };
}
// Assert on return value directly
```

### Return Values Over Side Effects

Prefer `compute X` (returns result) over `do X` (mutates something).

```typescript
// ❌ BAD: Side effect — mutates input
function applyDiscounts(orders: Order[]): void {
  for (const order of orders) {
    order.total *= 0.9; // Caller must check mutation
  }
}

// ✅ GOOD: Returns new data
function calculateDiscounts(orders: Order[]): Order[] {
  return orders.map(o => ({ ...o, total: o.total * 0.9 }));
}
```

### Configurable Time Sources

Accept a clock or time function instead of calling `Date.now()` directly.

```typescript
// ❌ BAD: Hidden time
function generateSessionId(): string {
  return `sess_${Date.now()}_${Math.random()}`; // Non-deterministic
}

// ✅ GOOD: Injectable time and random
function generateSessionId(now: number, random: () => number): string {
  return `sess_${now}_${Math.floor(random() * 1e6)}`;
}

test('generates deterministic session ID', () => {
  const id = generateSessionId(1700000000000, () => 0.5);
  expect(id).toBe('sess_1700000000000_500000');
});
```

## Anti-Patterns

| Anti-Pattern | Description | Test Pain | Fix |
|-------------|-------------|-----------|-----|
| **Singleton** | Global instance, can't swap for test. `Database.getInstance()` | Can't isolate tests. Tests share state. | Pass instance through constructor. Use DI. |
| **`new` inside methods** | Creates collaborators inside business logic. `new HttpClient()` | Can't replace with test double. | Accept collaborator as parameter. |
| **Void methods with side effects** | `void process()` writes to DB, sends email, logs. | Can't observe result. Must check side channels. | Return a result. Keep side effects separate. |
| **Hidden time dependence** | Uses `Date.now()` or `System.currentTimeMillis()` internally. | Tests pass at some times, fail at others. | Accept time as a parameter. |
| **God constructor** | Constructor takes 10+ dependencies. `new Service(db, cache, queue, logger, config, ...)` | Test setup is enormous. Must mock everything. | Class does too much. Split responsibilities. |

## Design Feedback Loop

Testing difficulty maps directly to design problems. Use this diagnostic:

| Test Pain | Design Problem | Fix |
|-----------|---------------|-----|
| **Hard to set up** | Too coupled. Module knows too much about its collaborators. | Inject dependencies. Narrow the interface. |
| **Hard to assert** | Wrong return value. Method does work but returns `void` or something unhelpful. | Return the computed result. Separate computation from side effects. |
| **Fragile tests** | Testing implementation. Test knows about internal details. | Test through public interface only. If that's impossible, the public interface is wrong. |
| **Slow tests** | Real I/O in tests. Touching filesystem, network, or database. | Inject the I/O boundary. Use an interface for the slow part. |
| **Order-dependent tests** | Shared mutable state. Tests interfere with each other. | Use pure functions or fresh instances per test. |
| **Flaky tests** | Non-determinism. Time, randomness, concurrency. | Control all sources of non-determinism through injection. |

## Quick Reference

| When test is... | The design is... | Fix by... |
|-----------------|-----------------|-----------|
| Hard to set up | Too coupled | Dependency injection |
| Hard to assert | Wrong return type | Return meaningful values |
| Fragile | Testing internals | Test public interface |
| Slow | Real I/O | Inject I/O boundary |
| Order-dependent | Shared state | Pure functions or fresh instances |
| Flaky | Non-deterministic | Inject time/random sources |
