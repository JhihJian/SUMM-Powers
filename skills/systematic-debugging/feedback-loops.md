# Feedback Loop Construction

## Overview

Debugging is building a feedback loop that tells you what's wrong. The faster and tighter your feedback loop, the faster you find the bug. A good feedback loop runs in under 10 seconds and tells you exactly which component failed.

**Core principle:** Building the right feedback loop = bug 90% fixed. If you can reproduce the problem on demand with clear output, the fix is usually obvious.

## Escalation Rule

If a method doesn't reveal the bug in **10 minutes**, escalate to the next method. Time spent spinning on a weak feedback loop is time wasted.

## The 10 Methods (Fastest to Most Expensive)

### 1. Failing Test

**When to use:** Bug is in code you control, can be expressed as a test case.

**Why first:** Runs in milliseconds, fully automated, persists as regression guard.

```python
# test_auth.py
def test_login_with_expired_token_returns_401():
    token = create_expired_token(user_id=42)
    response = client.post("/login", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 401
    assert "expired" in response.json()["error"].lower()
```

**Escalation:** If the bug only manifests in a running system (not isolated logic), move to method 2.

### 2. curl / HTTP Script

**When to use:** Bug is in an HTTP API, microservice, or web endpoint.

**Why second:** Seconds to write, runs against real system, captures exact request/response.

```bash
#!/usr/bin/env bash
set -euo pipefail

# reproduce-bug.sh — Reproduce the auth token refresh bug
TOKEN=$(curl -s http://localhost:8080/login \
  -d '{"user":"test","pass":"test"}' | jq -r '.token')

echo "=== Token: $TOKEN ==="

# Use token after it should have expired
sleep 2

RESPONSE=$(curl -sv http://localhost:8080/refresh \
  -H "Authorization: Bearer $TOKEN" 2>&1)

echo "=== Response ==="
echo "$RESPONSE"
echo "$RESPONSE" | grep "HTTP/"
echo "$RESPONSE" | grep "401\|403\|200"
```

**Escalation:** If the bug requires browser-specific behavior (cookies, redirects, JavaScript), move to method 5.

### 3. CLI Invocation

**When to use:** Bug is in a CLI tool, build script, or command-line program.

**Why third:** Direct invocation with debug flags, no HTTP overhead, immediate output.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Reproduce the build config merge bug
CONFIG_DIR=$(mktemp -d)
trap 'rm -rf "$CONFIG_DIR"' EXIT

cat > "$CONFIG_DIR/base.json" <<'JSON'
{"compilerOptions": {"strict": true, "target": "es2020"}}
JSON

cat > "$CONFIG_DIR/override.json" <<'JSON'
{"compilerOptions": {"strict": false}}
JSON

echo "=== Merging configs ==="
./build-tool merge --base "$CONFIG_DIR/base.json" \
  --override "$CONFIG_DIR/override.json" --verbose

echo "=== Checking output ==="
./build-tool show-config --merged | grep -i strict
```

**Escalation:** If the bug requires complex UI interaction or visual rendering, move to method 5.

### 4. Headless Browser Script

**When to use:** Bug requires browser environment (DOM rendering, JavaScript execution, cookies, redirects) but not manual interaction.

**Why fourth:** Automates browser without human involvement, captures screenshots and console output.

```javascript
// reproduce-ui-bug.js — Run with: node reproduce-ui-bug.js
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  // Capture console messages
  const logs = [];
  page.on('console', msg => logs.push(`${msg.type()}: ${msg.text()}`));

  await page.goto('http://localhost:3000/login');
  await page.fill('#username', 'testuser');
  await page.fill('#password', 'testpass');
  await page.click('#login-button');

  // Wait for either success or error
  await page.waitForTimeout(2000);

  // Screenshot for visual verification
  await page.screenshot({ path: 'debug-screenshot.png' });

  console.log('=== Console logs ===');
  logs.forEach(l => console.log(l));

  console.log('=== Current URL ===');
  console.log(page.url());

  console.log('=== Error visible? ===');
  const errorEl = await page.$('.error-message');
  console.log(errorEl ? await errorEl.textContent() : 'No error element found');

  await browser.close();
})();
```

**Escalation:** If the bug is timing-dependent or only shows up under specific race conditions, move to method 5.

### 5. Replay Captured Trace

**When to use:** Bug happened in production/staging and you have logs, traces, or network captures to replay.

**Why fifth:** Uses real production data, bypasses "can't reproduce locally" entirely.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Replay a production request from access logs that caused a 500
# Extract the failing request from logs
REQUEST=$(grep 'POST /api/orders.*500' /var/log/app/access.log | tail -1)

echo "=== Failing request ==="
echo "$REQUEST"

# Extract the request body from the trace
BODY=$(cat traces/request-body-$(echo "$REQUEST" | grep -oP 'request_id=\K[a-f0-9]+').json)

echo "=== Replaying against local ==="
curl -sv http://localhost:8080/api/orders \
  -X POST \
  -H "Content-Type: application/json" \
  -d "$BODY" 2>&1 | tee replay-output.txt

echo "=== Checking for 500 ==="
grep "HTTP/1.1 500" replay-output.txt && echo "BUG REPRODUCED" || echo "Bug not reproduced"
```

**Escalation:** If no traces are available or the bug is in complex internal logic, move to method 6.

### 6. Disposable Test Harness

**When to use:** Bug is in complex internal logic, algorithm, or state machine that needs targeted isolation.

**Why sixth:** Build a minimal wrapper that exercises just the buggy component with controlled inputs.

```python
#!/usr/bin/env python3
"""Disposable harness for debugging the order state machine."""

from order_processor import OrderStateMachine

def main():
    # Minimal reproduction of the stuck-order bug
    machine = OrderStateMachine()

    # Sequence that produces the stuck state
    order = machine.create_order(items=["widget"], customer_id=1)
    print(f"Created: state={order.state}")

    order = machine.process_payment(order, amount=9.99)
    print(f"After payment: state={order.state}")

    order = machine.cancel_payment(order, reason="timeout")
    print(f"After cancel: state={order.state}")

    # This is where it gets stuck — should be CANCELLED, stays PROCESSING
    order = machine.timeout_order(order)
    print(f"After timeout: state={order.state}")

    if order.state == "PROCESSING":
        print("\nBUG CONFIRMED: Order stuck in PROCESSING after cancel+timeout")
        print(f"Internal flags: {order._internal_flags}")
    else:
        print(f"\nNo bug: state is {order.state}")

if __name__ == "__main__":
    main()
```

**Escalation:** If the bug only appears with random/unexpected inputs you haven't thought of, move to method 7.

### 7. Property-Based / Fuzz Loop

**When to use:** Bug is triggered by unexpected inputs, edge cases, or combinations you haven't considered.

**Why seventh:** Generates inputs automatically, finds edge cases humans miss.

```python
from hypothesis import given, strategies as st
from order_processor import OrderStateMachine

# Fuzz the state machine — find inputs that cause invalid states
@given(
    customer_id=st.integers(min_value=1, max_value=999999),
    amounts=st.lists(st.floats(min_value=0.01, max_value=99999.99), max_size=10),
    actions=st.lists(st.sampled_from(["pay", "cancel", "timeout", "refund"]), max_size=5),
)
def test_state_machine_never_stuck(customer_id, amounts, actions):
    machine = OrderStateMachine()
    order = machine.create_order(items=["widget"], customer_id=customer_id)

    for action, amount in zip(actions, amounts + [0] * len(actions)):
        try:
            if action == "pay":
                order = machine.process_payment(order, amount=amount)
            elif action == "cancel":
                order = machine.cancel_payment(order, reason="fuzz")
            elif action == "timeout":
                order = machine.timeout_order(order)
            elif action == "refund":
                order = machine.refund_order(order, amount=amount)
        except Exception:
            pass  # Expected — invalid transitions throw

    # Invariant: order is never stuck in PROCESSING
    assert order.state != "PROCESSING", (
        f"Stuck order! customer={customer_id}, actions={actions}, "
        f"internal_flags={order._internal_flags}"
    )

# Run with: pytest test_fuzz.py --hypothesis-seed=42
```

**Escalation:** If you need to narrow down exactly which change introduced the bug, move to method 8.

### 8. Bisection Harness

**When to use:** Bug appeared recently and you need to find exactly which commit introduced it.

**Why eighth:** Binary search through commits is O(log n), guarantees finding the introducing commit.

```bash
#!/usr/bin/env bash
set -euo pipefail

# bisect-bug.sh — Find which commit broke the order state machine
# Usage: git bisect start && git bisect bad HEAD && git bisect good <last-known-good> && git bisect run ./bisect-bug.sh

# Build
npm run build 2>&1 >/dev/null

# Run the reproduction test
if npm test -- --testPathPattern="order-state-machine" 2>&1 | grep -q "PASS"; then
    echo "GOOD: test passes"
    exit 0
else
    echo "BAD: test fails"
    exit 1
fi
```

**Escalation:** If the bug involves a difference between two systems/versions/environments, move to method 9.

### 9. Differential Loop

**When to use:** Bug manifests differently between two environments (dev vs prod, v1 vs v2, system A vs system B).

**Why ninth:** Side-by-side comparison eliminates environmental variables, shows exact differences.

```bash
#!/usr/bin/env bash
set -euo pipefail

# differential.sh — Compare output between two API versions
INPUT='{"user":"test","action":"process"}'

echo "=== V1 Response ==="
V1=$(curl -s http://localhost:8080/v1/process -d "$INPUT" | tee /tmp/v1.json)
echo ""

echo "=== V2 Response ==="
V2=$(curl -s http://localhost:8080/v2/process -d "$INPUT" | tee /tmp/v2.json)
echo ""

echo "=== Diff ==="
diff <(jq -S . /tmp/v1.json) <(jq -S . /tmp/v2.json) || true
echo ""

echo "=== Status codes ==="
curl -s -o /dev/null -w "V1: %{http_code}\n" http://localhost:8080/v1/process -d "$INPUT"
curl -s -o /dev/null -w "V2: %{http_code}\n" http://localhost:8080/v2/process -d "$INPUT"
```

**Escalation:** If the bug requires human judgment to detect (visual glitches, UX issues, subjective quality), move to method 10.

### 10. HITL Bash Script (Human-in-the-Loop)

**When to use:** Bug requires human judgment — visual rendering, audio quality, complex multi-step interaction, or subjective assessment.

**Why last:** Involves a human, so slowest loop. Use only when automated detection is impossible.

```bash
#!/usr/bin/env bash
set -euo pipefail

# hitl-visual-check.sh — Human-in-the-loop visual regression check
echo "=== Building test environment ==="
npm run build
npm run serve &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null' EXIT
sleep 2

echo "=== Opening browser for visual check ==="
echo "Check these specific things:"
echo "  1. Navigation menu alignment"
echo "  2. Mobile responsive layout (resize to 375px)"
echo "  3. Dark mode toggle behavior"
echo ""
open http://localhost:3000 2>/dev/null || xdg-open http://localhost:3000 2>/dev/null || true

echo -n "Does the layout look correct? [y/n]: "
read -r ANSWER

if [[ "$ANSWER" == "y" ]]; then
    echo "PASS: Visual check approved"
    exit 0
else
    echo "FAIL: Visual issue detected"
    echo -n "Describe the issue: "
    read -r ISSUE
    echo "Issue: $ISSUE"
    exit 1
fi
```

## Anti-Pattern Table

| Wrong Loop | Problem | Use Instead |
|---|---|---|
| Manually clicking in browser every test | Slow, not repeatable | Method 4 (Headless Browser Script) |
| Adding print statements and re-running app | No isolation, slow cycle | Method 1 (Failing Test) or Method 6 (Disposable Harness) |
| Reading logs hoping to spot the bug | Passive, not interactive | Method 2 (curl Script) to actively reproduce |
| Guessing the fix and deploying to staging | Expensive, slow feedback | Method 6 (Disposable Harness) locally first |
| Re-running full test suite each time | Slow, unfocused | Method 1 (Failing Test) targeting just the bug |
| Asking QA to test each hypothesis | Human bottleneck | Method 7 (Fuzz Loop) for automated exploration |
| Comparing screenshots by eye | Subjective, error-prone | Method 9 (Differential Loop) with pixel diff |
| Restarting the server after each change | Slow cycle time | Method 6 (Disposable Harness) or hot-reload |

## Quick Selection Guide

```
Is it a logic bug in code you control?
  Yes -> Failing Test (Method 1)
  No -> Is it an HTTP API?
    Yes -> curl Script (Method 2)
    No -> Is it a CLI tool?
      Yes -> CLI Invocation (Method 3)
      No -> Does it need a browser?
        Yes -> Headless Browser (Method 4)
        No -> Do you have production traces?
          Yes -> Replay Trace (Method 5)
          No -> Is it complex internal logic?
            Yes -> Disposable Harness (Method 6)
            No -> Is it triggered by edge cases?
              Yes -> Fuzz Loop (Method 7)
              No -> Did it appear recently?
                Yes -> Bisection (Method 8)
                No -> Is it a difference between systems?
                  Yes -> Differential (Method 9)
                  No -> HITL Script (Method 10)
```
