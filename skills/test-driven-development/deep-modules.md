# Deep Modules

**Load this reference when:** designing interfaces, struggling with test complexity, or noticing your module has too many exposed methods.

## Overview

A deep module has a simple interface but rich functionality. A shallow module has a complex interface with little functionality underneath. Deep modules reduce cognitive load for callers and simplify testing.

**Core principle:** The best modules provide powerful capabilities through minimal surface area.

**Following TDD naturally produces deep modules** because you write the interface you wish existed first.

## Key Concepts

### Depth

Depth is the ratio of interface simplicity to implementation complexity. A deep module hides complexity behind a small, clean API.

```
Depth = Functionality provided / Interface surface area
```

- **Deep**: Few methods, each doing a lot. Callers think "that was easy."
- **Shallow**: Many methods, each doing little. Callers think "I have to call what, in what order?"

### Leverage

What callers gain from a module. High leverage means callers accomplish a lot with a few calls.

- **High leverage**: `fs.readFile('config.json')` — one call, full file contents.
- **Low leverage**: `fs.open()`, `fs.seek()`, `fs.read()`, `fs.close()` — four calls for the same result.

### Locality

What maintainers gain from a module. High locality means changes stay inside the module without rippling to callers.

- **High locality**: Changing the retry algorithm inside `retryOperation()` — callers unaffected.
- **Low locality**: Changing the argument order of `processStep2()` — callers break.

### Seam

The boundary where interface meets implementation. A clean seam lets you test each side independently.

- **Clean seam**: Interface describes WHAT, tests verify HOW independently.
- **Dirty seam**: Interface leaks HOW, tests coupled to implementation details.

### Deletion Test

Imagine deleting the module. Where does the complexity go?

- **Deep module deleted**: Complexity scatters everywhere — callers must each reimplement the logic. The module was valuable.
- **Shallow module deleted**: Little changes — callers already did most of the work. The module added little value.

## Testing Deep vs Shallow Modules

### Deep Module: Easy to Test

```typescript
// ✅ GOOD: Deep module — simple interface, rich behavior
class EmailService {
  constructor(private transporter: Transporter) {}

  async send(to: string, subject: string, body: string): Promise<void> {
    await this.transporter.send({
      to,
      subject,
      body,
      headers: { 'X-Mailer': 'MyApp/1.0' }
    });
  }
}

// Test is straightforward — one method, clear inputs/outputs
test('sends email via transporter', async () => {
  const mockTransport = { send: vi.fn().mockResolvedValue(undefined) };
  const service = new EmailService(mockTransport);

  await service.send('user@test.com', 'Hello', 'Body');

  expect(mockTransport.send).toHaveBeenCalledWith({
    to: 'user@test.com',
    subject: 'Hello',
    body: 'Body',
    headers: { 'X-Mailer': 'MyApp/1.0' }
  });
});
```

### Shallow Module: Hard to Test

```typescript
// ❌ BAD: Shallow module — lots of exposed plumbing
class EmailService {
  constructor(
    private transporter: Transporter,
    private validator: Validator,
    private templater: Templater,
    private rateLimiter: RateLimiter
  ) {}

  validateAddress(email: string): boolean { /* ... */ }
  formatHeaders(headers: Record<string, string>): string { /* ... */ }
  applyTemplate(template: string, data: object): string { /* ... */ }
  checkRateLimit(userId: string): Promise<boolean> { /* ... */ }
  buildMessage(to: string, subject: string, body: string): Message { /* ... */ }
  send(message: Message): Promise<void> { /* ... */ }
}

// Test is complex — must wire up many dependencies, test many methods
test('sends email', async () => {
  // Must set up 4 collaborators
  const validator = { validate: vi.fn().mockReturnValue(true) };
  const templater = { render: vi.fn().mockReturnValue('rendered') };
  const rateLimiter = { check: vi.fn().mockResolvedValue(true) };
  const transporter = { send: vi.fn().mockResolvedValue(undefined) };
  const service = new EmailService(transporter, validator, templater, rateLimiter);

  // Must call methods in correct order
  const addr = service.validateAddress('user@test.com');
  expect(addr).toBe(true);
  const html = service.applyTemplate('template', {});
  const msg = service.buildMessage('user@test.com', 'Hello', html);
  await service.send(msg);

  // Many assertions across many methods
  expect(validator.validate).toHaveBeenCalled();
  expect(templater.render).toHaveBeenCalled();
  expect(transporter.send).toHaveBeenCalled();
});
```

**The difference:** The deep module has one method to test. The shallow module has six methods that must be called in the right order, requiring four collaborators. The deep module's test is 10 lines. The shallow module's test is 20+ lines and fragile.

## Deepening Shallow Modules

Four steps to transform a shallow module into a deep one:

### Step 1: Ask What the Caller Wants

Stop thinking about what the module does internally. Ask: "What does the caller want to accomplish?"

```
Before: "This module validates, formats, and sends emails."
After:  "The caller wants to send an email to someone."
```

### Step 2: Combine Methods

Merge methods that callers always invoke together into a single method.

```typescript
// Before: Three methods callers must call in sequence
validateAddress(email);
buildMessage(to, subject, body);
send(message);

// After: One method that does all three internally
send(to, subject, body);
```

### Step 3: Hide Internals

Move internal details behind the interface. If callers don't need to know about it, don't expose it.

```typescript
// Before: Caller must know about headers
service.formatHeaders({ 'X-Mailer': 'MyApp/1.0' });

// After: Module handles headers internally
service.send(to, subject, body);  // Headers added internally
```

### Step 4: Rename to Describe WHAT Not HOW

Method names should describe the outcome, not the process.

```typescript
// Before: Names describe steps (HOW)
validateAddress(), formatHeaders(), buildMessage(), transmit()

// After: Names describe outcomes (WHAT)
send(), sendBatch(), scheduleDelivery()
```

## Anti-Patterns

| Anti-Pattern | Description | How to Fix |
|-------------|-------------|------------|
| **God object** | One class does everything. 50+ methods. Test setup requires mocking the world. | Split by responsibility. Each class should have one reason to change. |
| **Pass-through** | Methods that just delegate to another object. No added value. `a.foo()` calls `b.foo()`. | Remove the middleman. Callers talk directly to the real object. |
| **Feature envy** | Method that uses another class more than its own. `EmailService.send()` spends all its time calling `Transport` methods. | Move the method to the class it envies. Or combine the classes. |
| **Shallow wrapper** | Thin layer over another API that adds no behavior. `class MyFS { readFile(p) { return fs.readFile(p); } }`. | Delete the wrapper. Use the underlying API directly. Or add real value (caching, validation, error handling). |

## Relation to TDD

TDD naturally produces deep modules because:

1. **You write the interface you wish existed first.** The test describes the desired API, not the implementation. This forces you to think about what callers need, not what you'll build.

2. **Each test cycle adds one behavior.** You never add methods "you might need." Every method exists because a test demanded it.

3. **Test difficulty signals shallow design.** If the test setup is complex, the interface is too. TDD's red phase catches this immediately.

4. **Refactoring consolidates.** The refactor phase merges methods, hides internals, and renames to describe outcomes — exactly the deepening steps above.

**The feedback loop:**

```
Hard to write test → Interface too complex → Simplify interface → Deepen module
```

If writing the test feels painful, the module is telling you it wants to be deeper. Listen to it.

## Quick Reference

| Signal | Meaning | Action |
|--------|---------|--------|
| Test setup is huge | Module is shallow | Combine methods, hide internals |
| Many mocks needed | Interface too wide | Reduce surface area |
| Must call methods in order | Exposed pipeline | Wrap pipeline in single method |
| Test breaks on refactor | Testing HOW not WHAT | Test through public interface only |
| Module feels trivial | Might be a pass-through | Add value or delete it |
