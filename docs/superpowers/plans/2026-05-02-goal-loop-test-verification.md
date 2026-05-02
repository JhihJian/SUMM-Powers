# Goal Loop Test Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summ:subagent-driven-development (recommended) or summ:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the two-layer test verification suite for goal-loop: 9 fast unit tests + 6 integration test scenarios with fixtures.

**Architecture:** Test fixtures are static Python projects under `tests/claude-code/test-goal-loop-fixtures/`. Fast unit tests follow the existing `test-subagent-driven-development.sh` pattern (run_claude + assert_contains). Integration tests create temp copies of fixtures, run goal-loop with `claude -p`, then verify state files and git history.

**Tech Stack:** Bash scripts using existing test-helpers.sh (`run_claude`, `assert_contains`, `assert_not_contains`, `assert_count`, `assert_order`), Python fixture projects with ruff/pylint.

**Spec:** `docs/superpowers/specs/2026-05-02-goal-loop-test-plan-design.md`

---

## File Structure

| File | Responsibility |
|------|---------------|
| `tests/claude-code/test-goal-loop.sh` | Fast unit tests — 9 test cases verifying agent understands SKILL.md rules |
| `tests/claude-code/test-goal-loop-fixtures/scenario-a-lint/pyproject.toml` | Ruff config for lint scenario |
| `tests/claude-code/test-goal-loop-fixtures/scenario-a-lint/src/main.py` | Python file with 15+ lint violations |
| `tests/claude-code/test-goal-loop-fixtures/scenario-a-lint/src/utils.py` | Additional Python file with lint violations |
| `tests/claude-code/test-goal-loop-fixtures/scenario-b-duplication/pyproject.toml` | Ruff config for duplication scenario |
| `tests/claude-code/test-goal-loop-fixtures/scenario-b-duplication/src/utils.py` | Python file with 3 groups of duplicate code blocks |
| `tests/claude-code/test-goal-loop-fixtures/scenario-c-clean/pyproject.toml` | Ruff config for clean scenario |
| `tests/claude-code/test-goal-loop-fixtures/scenario-c-clean/src/main.py` | Clean Python file (zero lint errors) |
| `tests/claude-code/test-goal-loop-fixtures/scenario-d-monolith/pyproject.toml` | Flask monolith app config |
| `tests/claude-code/test-goal-loop-fixtures/scenario-d-monolith/app.py` | Single-file Flask app with 5-6 routes |
| `tests/claude-code/test-goal-loop-fixtures/scenario-e-error-handling/pyproject.toml` | Ruff config for error handling scenario |
| `tests/claude-code/test-goal-loop-fixtures/scenario-e-error-handling/src/service.py` | Python file with bare except/pass patterns |
| `tests/claude-code/test-goal-loop-integration.sh` | Integration tests — 6 scenarios with state file verification |

---

## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Create test fixtures (all 5 scenarios) | `tests/claude-code/test-goal-loop-fixtures/**/*` | M | 5 Python projects with intentional issues |
| 2 | Create fast unit test script | `tests/claude-code/test-goal-loop.sh` | M | 9 test cases following existing pattern |
| 3 | Create integration test script | `tests/claude-code/test-goal-loop-integration.sh` | L | 6 scenarios with state file verification |

---

### Batch 1 (Tasks 1-2)

### Task 1: Create test fixtures

**Files:**
- Create: `tests/claude-code/test-goal-loop-fixtures/scenario-a-lint/pyproject.toml`
- Create: `tests/claude-code/test-goal-loop-fixtures/scenario-a-lint/src/main.py`
- Create: `tests/claude-code/test-goal-loop-fixtures/scenario-a-lint/src/utils.py`
- Create: `tests/claude-code/test-goal-loop-fixtures/scenario-b-duplication/pyproject.toml`
- Create: `tests/claude-code/test-goal-loop-fixtures/scenario-b-duplication/src/utils.py`
- Create: `tests/claude-code/test-goal-loop-fixtures/scenario-c-clean/pyproject.toml`
- Create: `tests/claude-code/test-goal-loop-fixtures/scenario-c-clean/src/main.py`
- Create: `tests/claude-code/test-goal-loop-fixtures/scenario-d-monolith/pyproject.toml`
- Create: `tests/claude-code/test-goal-loop-fixtures/scenario-d-monolith/app.py`
- Create: `tests/claude-code/test-goal-loop-fixtures/scenario-e-error-handling/pyproject.toml`
- Create: `tests/claude-code/test-goal-loop-fixtures/scenario-e-error-handling/src/service.py`

- [ ] **Step 1: Create scenario-a-lint (多 lint 问题)**

```bash
mkdir -p tests/claude-code/test-goal-loop-fixtures/scenario-a-lint/src
```

Create `tests/claude-code/test-goal-loop-fixtures/scenario-a-lint/pyproject.toml`:

```toml
[project]
name = "scenario-a-lint"
version = "0.1.0"
requires-python = ">=3.10"

[tool.ruff]
line-length = 88
select = ["E", "F", "W", "I", "N", "UP", "B", "A", "C4", "SIM"]
```

Create `tests/claude-code/test-goal-loop-fixtures/scenario-a-lint/src/main.py`:

```python
import os
import sys
import json
import unused_module
from typing import List, Dict, Optional


def calculate_sum(data):
    result = 0
    for i in range(len(data)):
        result = result + data[i]
    return result


def process_user(name, age, email, phone, address, city, country, zipcode):
    user_info = {}
    user_info["name"] = name
    user_info["age"] = age
    user_info["email"] = email
    user_info["phone"] = phone
    user_info["address"] = address
    user_info["city"] = city
    user_info["country"] = country
    user_info["zipcode"] = zipcode
    return user_info


def get_config_value(config_dict, key, default_value=None):
    if config_dict != None:
        if key in config_dict:
            return config_dict[key]
    return default_value


class UserManager:
    def __init__(self):
        self.users = []

    def add_user(self, user):
        self.users.append(user)

    def remove_user(self, user):
        if user in self.users:
            self.users.remove(user)

    def find_user(self, name):
        for user in self.users:
            if user["name"] == name:
                return user
        return None

    def get_all_names(self):
        names = []
        for user in self.users:
            names.append(user["name"])
        return names


def format_output(data, pretty=False, indent=2, sort_keys=False):
    if pretty == True:
        return json.dumps(data, indent=indent, sort_keys=sort_keys)
    return json.dumps(data)


def validate_email(email):
    if "@" in email:
        if "." in email.split("@")[1]:
            return True
    return False
```

Create `tests/claude-code/test-goal-loop-fixtures/scenario-a-lint/src/utils.py`:

```python
import hashlib
import base64
import datetime
from typing import Any


def hash_password(password):
    return hashlib.md5(password.encode()).hexdigest()


def encode_data(data):
    encoded = base64.b64encode(data.encode())
    return encoded.decode()


def get_timestamp():
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def parse_config(config_string):
    result = {}
    lines = config_string.split("\n")
    for line in lines:
        if "=" in line:
            key = line.split("=")[0].strip()
            value = line.split("=")[1].strip()
            result[key] = value
    return result


def flatten_list(nested_list):
    flat = []
    for sublist in nested_list:
        for item in sublist:
            flat.append(item)
    return flat
```

- [ ] **Step 2: Create scenario-b-duplication (重复代码)**

```bash
mkdir -p tests/claude-code/test-goal-loop-fixtures/scenario-b-duplication/src
```

Create `tests/claude-code/test-goal-loop-fixtures/scenario-b-duplication/pyproject.toml`:

```toml
[project]
name = "scenario-b-duplication"
version = "0.1.0"
requires-python = ">=3.10"
```

Create `tests/claude-code/test-goal-loop-fixtures/scenario-b-duplication/src/utils.py`:

```python
def format_user_report(users):
    lines = []
    lines.append("ID | Name | Email | Status")
    lines.append("---|------|-------|--------")
    for user in users:
        status = "Active" if user["active"] else "Inactive"
        line = f"{user['id']} | {user['name']} | {user['email']} | {status}"
        lines.append(line)
    return "\n".join(lines)


def format_order_report(orders):
    lines = []
    lines.append("ID | Customer | Amount | Status")
    lines.append("---|----------|--------|--------")
    for order in orders:
        status = "Fulfilled" if order["fulfilled"] else "Pending"
        line = f"{order['id']} | {order['customer']} | {order['amount']} | {status}"
        lines.append(line)
    return "\n".join(lines)


def format_product_report(products):
    lines = []
    lines.append("ID | Name | Price | In Stock")
    lines.append("---|------|-------|----------")
    for product in products:
        status = "Yes" if product["in_stock"] else "No"
        line = f"{product['id']} | {product['name']} | {product['price']} | {status}"
        lines.append(line)
    return "\n".join(lines)


def calculate_order_total(orders):
    total = 0
    for order in orders:
        if order["quantity"] > 0 and order["price"] > 0:
            subtotal = order["quantity"] * order["price"]
            tax = subtotal * 0.1
            total = total + subtotal + tax
    return total


def calculate_invoice_total(invoices):
    total = 0
    for invoice in invoices:
        if invoice["hours"] > 0 and invoice["rate"] > 0:
            subtotal = invoice["hours"] * invoice["rate"]
            tax = subtotal * 0.1
            total = total + subtotal + tax
    return total


def validate_email(email):
    if not email or "@" not in email:
        return False
    parts = email.split("@")
    if len(parts) != 2:
        return False
    if not parts[0] or not parts[1]:
        return False
    return True


def validate_phone(phone):
    if not phone or len(phone) < 10:
        return False
    digits = "".join(c for c in phone if c.isdigit())
    if len(digits) < 10:
        return False
    return True
```

- [ ] **Step 3: Create scenario-c-clean (干净项目)**

```bash
mkdir -p tests/claude-code/test-goal-loop-fixtures/scenario-c-clean/src
```

Create `tests/claude-code/test-goal-loop-fixtures/scenario-c-clean/pyproject.toml`:

```toml
[project]
name = "scenario-c-clean"
version = "0.1.0"
requires-python = ">=3.10"

[tool.ruff]
line-length = 88
select = ["E", "F", "W", "I", "N", "UP", "B", "A", "C4", "SIM"]
```

Create `tests/claude-code/test-goal-loop-fixtures/scenario-c-clean/src/main.py`:

```python
"""Clean Python module with no lint issues."""


def calculate_sum(numbers: list[int]) -> int:
    """Return the sum of a list of integers."""
    return sum(numbers)


def format_user(user: dict) -> str:
    """Format a user dictionary as a display string."""
    return f"{user['name']} ({user['email']})"
```

- [ ] **Step 4: Create scenario-d-monolith (单体应用)**

```bash
mkdir -p tests/claude-code/test-goal-loop-fixtures/scenario-d-monolith
```

Create `tests/claude-code/test-goal-loop-fixtures/scenario-d-monolith/pyproject.toml`:

```toml
[project]
name = "scenario-d-monolith"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = ["flask>=3.0"]
```

Create `tests/claude-code/test-goal-loop-fixtures/scenario-d-monolith/app.py`:

```python
from flask import Flask, request, jsonify
import sqlite3
import hashlib
import json

app = Flask(__name__)

DATABASE = "app.db"


def get_db():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn


@app.route("/users", methods=["GET"])
def get_users():
    conn = get_db()
    cursor = conn.execute("SELECT * FROM users")
    users = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(users)


@app.route("/users", methods=["POST"])
def create_user():
    data = request.get_json()
    conn = get_db()
    hashed_pw = hashlib.md5(data["password"].encode()).hexdigest()
    conn.execute(
        "INSERT INTO users (name, email, password) VALUES (?, ?, ?)",
        (data["name"], data["email"], hashed_pw),
    )
    conn.commit()
    conn.close()
    return jsonify({"status": "created"}), 201


@app.route("/users/<int:user_id>", methods=["GET"])
def get_user(user_id):
    conn = get_db()
    cursor = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    user = cursor.fetchone()
    conn.close()
    if user:
        return jsonify(dict(user))
    return jsonify({"error": "not found"}), 404


@app.route("/orders", methods=["GET"])
def get_orders():
    conn = get_db()
    user_id = request.args.get("user_id")
    if user_id:
        cursor = conn.execute("SELECT * FROM orders WHERE user_id = ?", (user_id,))
    else:
        cursor = conn.execute("SELECT * FROM orders")
    orders = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(orders)


@app.route("/orders", methods=["POST"])
def create_order():
    data = request.get_json()
    conn = get_db()
    total = sum(item["price"] * item["quantity"] for item in data["items"])
    conn.execute(
        "INSERT INTO orders (user_id, items, total) VALUES (?, ?, ?)",
        (data["user_id"], json.dumps(data["items"]), total),
    )
    conn.commit()
    conn.close()
    return jsonify({"status": "created", "total": total}), 201


@app.route("/report/sales", methods=["GET"])
def sales_report():
    conn = get_db()
    cursor = conn.execute(
        "SELECT user_id, SUM(total) as total_sales FROM orders GROUP BY user_id"
    )
    report = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(report)


if __name__ == "__main__":
    app.run(debug=True)
```

- [ ] **Step 5: Create scenario-e-error-handling (糟糕的错误处理)**

```bash
mkdir -p tests/claude-code/test-goal-loop-fixtures/scenario-e-error-handling/src
```

Create `tests/claude-code/test-goal-loop-fixtures/scenario-e-error-handling/pyproject.toml`:

```toml
[project]
name = "scenario-e-error-handling"
version = "0.1.0"
requires-python = ">=3.10"
```

Create `tests/claude-code/test-goal-loop-fixtures/scenario-e-error-handling/src/service.py`:

```python
import json
import sqlite3


def read_config(path):
    f = open(path)
    data = json.load(f)
    f.close()
    return data


def save_user(user_data):
    try:
        conn = sqlite3.connect("app.db")
        conn.execute(
            "INSERT INTO users (name, email) VALUES (?, ?)",
            (user_data["name"], user_data["email"]),
        )
        conn.commit()
    except:
        pass


def fetch_user(user_id):
    try:
        conn = sqlite3.connect("app.db")
        cursor = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,))
        return cursor.fetchone()
    except:
        pass


def update_user(user_id, updates):
    try:
        conn = sqlite3.connect("app.db")
        sets = ", ".join(f"{k} = ?" for k in updates.keys())
        values = list(updates.values()) + [user_id]
        conn.execute(f"UPDATE users SET {sets} WHERE id = ?", values)
        conn.commit()
    except:
        pass


def delete_user(user_id):
    try:
        conn = sqlite3.connect("app.db")
        conn.execute("DELETE FROM users WHERE id = ?", (user_id,))
        conn.commit()
    except:
        pass


def process_payment(amount, card_number, expiry):
    try:
        if amount <= 0:
            return False
        result = charge_card(card_number, amount)
        return result
    except:
        pass


def send_notification(user_id, message):
    try:
        user = fetch_user(user_id)
        if user:
            deliver_email(user["email"], message)
    except:
        pass


def batch_import(records):
    results = []
    for record in records:
        try:
            save_user(record)
            results.append("ok")
        except:
            results.append("error")
    return results
```

- [ ] **Step 6: Verify all fixtures exist**

Run: `find tests/claude-code/test-goal-loop-fixtures -type f | sort`
Expected: 11 files across 5 scenario directories.

- [ ] **Step 7: Commit**

```bash
git add tests/claude-code/test-goal-loop-fixtures/
git commit -m "test(goal-loop): add integration test fixtures for 5 scenarios"
```

---

### Task 2: Create fast unit test script

**Files:**
- Create: `tests/claude-code/test-goal-loop.sh`

- [ ] **Step 1: Create the test script**

Create `tests/claude-code/test-goal-loop.sh` with the following content:

```bash
#!/usr/bin/env bash
# Test: goal-loop skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: goal-loop skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the goal-loop skill? Describe its purpose briefly." 30)

if assert_contains "$output" "goal-loop\|Goal Loop\|Goal loop" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "iterat\|循环\|循环" "Mentions iteration"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify default max-iterations
echo "Test 2: Default max-iterations..."

output=$(run_claude "In the goal-loop skill, what is the default maximum number of iterations if the user does not specify --max-iterations?" 30)

if assert_contains "$output" "10" "Default is 10"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify self-evaluation three questions
echo "Test 3: Self-evaluation criteria..."

output=$(run_claude "In the goal-loop skill, what are the three self-evaluation questions that determine if the goal is met? List all three." 30)

if assert_contains "$output" "goal.*met\|met.*goal\|目标.*达成\|达成.*目标" "Criterion 1: goal met"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "side.?effect\|副作用\|no.*new.*problem\|regression" "Criterion 2: no side effects"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "continu\|收益\|diminish\|worth.*continu\|worthwhile" "Criterion 3: worth continuing"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify skill mapping
echo "Test 4: Skill mapping for architecture items..."

output=$(run_claude "In the goal-loop skill, which SUMM skill should be loaded for an architecture or structure improvement item?" 30)

if assert_contains "$output" "improve-architecture" "Architecture maps to improve-architecture"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify one item per iteration constraint
echo "Test 5: One item per iteration..."

output=$(run_claude "In the goal-loop skill, how many improvement items should be executed per iteration? Is it one or multiple?" 30)

if assert_contains "$output" "one\b\|single\|1 item\|一个" "One item per iteration"; then
    : # pass
else
    exit 1
fi

if assert_not_contains "$output" "multiple.*item\|several.*item\|all.*item\|多个.*改进" "Not multiple items"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify state file path
echo "Test 6: State file path..."

output=$(run_claude "In the goal-loop skill, what is the exact file path of the state file that tracks iteration progress?" 30)

if assert_contains "$output" "\.claude/goal-loop-state\.md" "Correct state file path"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 7: Verify completion promise format
echo "Test 7: Completion promise format..."

output=$(run_claude "In the goal-loop skill, what XML tag format does the completion promise use when the goal is met?" 30)

if assert_contains "$output" "goal-loop-complete" "Completion promise tag"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 8: Verify iteration limit handling
echo "Test 8: Iteration limit handling (ABORTED)..."

output=$(run_claude "In the goal-loop skill, what happens when the maximum iteration limit is reached but the goal is not yet fully met? What is the status set to?" 30)

if assert_contains "$output" "ABORTED" "Status set to ABORTED"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "progress\|remaining\|backlog\|建议\|suggest" "Progress preserved with suggestions"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 9: Verify dev-loop conflict detection
echo "Test 9: Dev-loop conflict detection..."

output=$(run_claude "In the goal-loop skill, what does the pre-flight check look for before starting the loop? What potential conflict does it detect?" 30)

if assert_contains "$output" "dev-loop\|dev_loop" "Detects dev-loop"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "plan" "Mentions plans"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All goal-loop skill tests passed ==="
```

- [ ] **Step 2: Make executable**

Run: `chmod +x tests/claude-code/test-goal-loop.sh`

- [ ] **Step 3: Verify syntax**

Run: `bash -n tests/claude-code/test-goal-loop.sh`
Expected: No output (syntax check passes)

- [ ] **Step 4: Commit**

```bash
git add tests/claude-code/test-goal-loop.sh
git commit -m "test(goal-loop): add 9 fast unit tests for skill understanding"
```

---

### Batch 2 (Task 3)

### Task 3: Create integration test script

**Files:**
- Create: `tests/claude-code/test-goal-loop-integration.sh`

This is the largest task. The script runs 6 integration scenarios in sequence, each creating a temp copy of a fixture, running goal-loop via `claude -p`, and verifying state files and git history.

- [ ] **Step 1: Create the integration test script**

Create `tests/claude-code/test-goal-loop-integration.sh`:

```bash
#!/usr/bin/env bash
# Integration Test: goal-loop skill
# Executes real goal-loop cycles against test fixtures and verifies state files
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
FIXTURES_DIR="$SCRIPT_DIR/test-goal-loop-fixtures"

# Allow running single scenario via env var
RUN_SCENARIO="${INTEGRATION_SCENARIO:-}"

FAILED=0
TOTAL=0

run_scenario() {
    local scenario_id="$1"
    local scenario_name="$2"
    local fixture_dir="$3"
    local goal="$4"
    local max_iter="$5"
    local timeout_sec="$6"

    # Skip if specific scenario requested
    if [ -n "$RUN_SCENARIO" ] && [ "$RUN_SCENARIO" != "$scenario_id" ]; then
        echo "  Skipping scenario $scenario_id (filtered)"
        return 0
    fi

    TOTAL=$((TOTAL + 1))
    echo ""
    echo "========================================"
    echo " Scenario $scenario_id: $scenario_name"
    echo "========================================"
    echo "  Goal: $goal"
    echo "  Max iterations: $max_iter"
    echo "  Timeout: ${timeout_sec}s"
    echo ""

    # Create temp copy of fixture
    local test_dir
    test_dir=$(mktemp -d)
    trap "rm -rf '$test_dir'" RETURN

    cp -r "$FIXTURES_DIR/$fixture_dir/." "$test_dir/"
    cd "$test_dir"

    # Initialize git repo
    git init --quiet
    git config user.email "test@test.com"
    git config user.name "Test User"
    git add .
    git commit -m "Initial commit" --quiet

    local initial_commits
    initial_commits=$(git log --oneline | wc -l)

    # Run goal-loop
    echo "Running goal-loop..."
    local output
    output=$(timeout "$timeout_sec" claude -p \
        "Load the summ:goal-loop skill and follow it. Goal: $goal --max-iterations $max_iter" \
        --allowed-tools=all \
        --permission-mode bypassPermissions \
        2>&1) || {
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo "  [WARN] Scenario $scenario_id timed out after ${timeout_sec}s"
        fi
        # Don't exit — continue to verify what was produced
    }

    local scenario_failed=0

    # --- Common verifications ---
    local state_file="$test_dir/.claude/goal-loop-state.md"

    # Verify state file exists
    if [ -f "$state_file" ]; then
        echo "  [PASS] State file created"
    else
        echo "  [FAIL] State file not found"
        scenario_failed=$((scenario_failed + 1))
        # Can't do further state file checks
        echo "  Skipping remaining verifications (no state file)"
        if [ $scenario_failed -gt 0 ]; then
            FAILED=$((FAILED + scenario_failed))
            echo "  Scenario $scenario_id: FAILED ($scenario_failed issues)"
        fi
        return
    fi

    # Verify goal text in state file
    if grep -q "$goal" "$state_file" 2>/dev/null || grep -qi "$(echo "$goal" | head -c 30)" "$state_file"; then
        echo "  [PASS] Goal text present in state file"
    else
        echo "  [WARN] Goal text may not match exactly in state file"
    fi

    # --- Scenario-specific verifications ---
    case "$scenario_id" in
        A)
            verify_scenario_a "$test_dir" "$state_file" "$output" "$initial_commits"
            ;;
        B)
            verify_scenario_b "$test_dir" "$state_file" "$output" "$initial_commits"
            ;;
        C)
            verify_scenario_c "$test_dir" "$state_file" "$output" "$initial_commits"
            ;;
        D)
            verify_scenario_d "$test_dir" "$state_file" "$output" "$initial_commits"
            ;;
        E)
            verify_scenario_e "$test_dir" "$state_file" "$output" "$initial_commits"
            ;;
        F)
            verify_scenario_f "$test_dir" "$state_file" "$output" "$initial_commits"
            ;;
    esac
}

verify_scenario_a() {
    local test_dir="$1"
    local state_file="$2"
    local output="$3"
    local initial_commits="$4"
    local s_failed=0

    echo "  --- Scenario A: Multi-iteration + per-round state verification ---"

    # Verify at least 2 iterations
    local iter_count
    iter_count=$(grep -c "^### Iteration" "$state_file" 2>/dev/null || echo "0")
    if [ "$iter_count" -ge 2 ]; then
        echo "  [PASS] $iter_count iterations recorded"
    else
        echo "  [FAIL] Only $iter_count iteration(s) (expected >= 2)"
        s_failed=$((s_failed + 1))
    fi

    # Verify iteration history entries
    local history_count
    history_count=$(grep -c "Skill used:" "$state_file" 2>/dev/null || echo "0")
    if [ "$history_count" -ge 1 ]; then
        echo "  [PASS] $history_count iteration history entries with skill references"
    else
        echo "  [FAIL] No iteration history entries"
        s_failed=$((s_failed + 1))
    fi

    # Verify backlog has checked items
    if grep -q "\[x\]" "$state_file"; then
        echo "  [PASS] Backlog has completed items"
    else
        echo "  [FAIL] No completed backlog items"
        s_failed=$((s_failed + 1))
    fi

    # Verify git commits increased
    local final_commits
    final_commits=$(git -C "$test_dir" log --oneline | wc -l)
    if [ "$final_commits" -gt "$initial_commits" ]; then
        echo "  [PASS] $((final_commits - initial_commits)) new commits created"
    else
        echo "  [FAIL] No new commits"
        s_failed=$((s_failed + 1))
    fi

    # Verify COMPLETED or has progress
    if grep -q "COMPLETED" "$state_file"; then
        echo "  [PASS] Status = COMPLETED"
        if echo "$output" | grep -q "goal-loop-complete"; then
            echo "  [PASS] Completion promise emitted"
        else
            echo "  [WARN] Completion promise not found in output"
        fi
    else
        echo "  [INFO] Status not COMPLETED (may have more work to do)"
    fi

    FAILED=$((FAILED + s_failed))
}

verify_scenario_b() {
    local test_dir="$1"
    local state_file="$2"
    local output="$3"
    local initial_commits="$4"
    local s_failed=0

    echo "  --- Scenario B: Code structure optimization ---"

    # Verify iteration history exists
    local iter_count
    iter_count=$(grep -c "^### Iteration" "$state_file" 2>/dev/null || echo "0")
    if [ "$iter_count" -ge 1 ]; then
        echo "  [PASS] $iter_count iterations recorded"
    else
        echo "  [FAIL] No iterations recorded"
        s_failed=$((s_failed + 1))
    fi

    # Verify code was modified
    local final_commits
    final_commits=$(git -C "$test_dir" log --oneline | wc -l)
    if [ "$final_commits" -gt "$initial_commits" ]; then
        echo "  [PASS] Code changes committed"
    else
        echo "  [FAIL] No commits"
        s_failed=$((s_failed + 1))
    fi

    # Verify file size decreased (duplication removed)
    local orig_lines
    orig_lines=$(git -C "$test_dir" show HEAD:src/utils.py 2>/dev/null | wc -l || echo "999")
    local current_lines
    current_lines=$(wc -l < "$test_dir/src/utils.py" 2>/dev/null || echo "0")
    if [ "$current_lines" -lt "$orig_lines" ]; then
        echo "  [PASS] Code reduced from $orig_lines to $current_lines lines"
    else
        echo "  [INFO] Code lines: $current_lines (original: $orig_lines)"
    fi

    FAILED=$((FAILED + s_failed))
}

verify_scenario_c() {
    local test_dir="$1"
    local state_file="$2"
    local output="$3"
    local initial_commits="$4"
    local s_failed=0

    echo "  --- Scenario C: Goal already met (0 rounds) ---"

    # Should complete quickly with COMPLETED status
    if grep -q "COMPLETED" "$state_file"; then
        echo "  [PASS] Status = COMPLETED (goal already met)"
    else
        echo "  [FAIL] Status not COMPLETED"
        s_failed=$((s_failed + 1))
    fi

    # Should have completion promise
    if echo "$output" | grep -q "goal-loop-complete"; then
        echo "  [PASS] Completion promise emitted"
    else
        echo "  [FAIL] No completion promise"
        s_failed=$((s_failed + 1))
    fi

    # Should NOT have created extra commits (no work needed)
    local final_commits
    final_commits=$(git -C "$test_dir" log --oneline | wc -l)
    if [ "$final_commits" -eq "$initial_commits" ]; then
        echo "  [PASS] No extra commits (clean project needed no changes)"
    else
        echo "  [WARN] Extra commits created even though goal was already met"
    fi

    FAILED=$((FAILED + s_failed))
}

verify_scenario_d() {
    local test_dir="$1"
    local state_file="$2"
    local output="$3"
    local initial_commits="$4"
    local s_failed=0

    echo "  --- Scenario D: Iteration limit (ABORTED) ---"

    # Must be ABORTED
    if grep -q "ABORTED" "$state_file"; then
        echo "  [PASS] Status = ABORTED"
    else
        echo "  [FAIL] Status not ABORTED"
        s_failed=$((s_failed + 1))
    fi

    # Must NOT have completion promise
    if echo "$output" | grep -q "goal-loop-complete"; then
        echo "  [FAIL] Unexpected completion promise (should be ABORTED)"
        s_failed=$((s_failed + 1))
    else
        echo "  [PASS] No completion promise (correct for ABORTED)"
    fi

    # Backlog should have unchecked items
    if grep -q "\[ \]" "$state_file"; then
        echo "  [PASS] Remaining backlog items preserved"
    else
        echo "  [FAIL] No remaining backlog items"
        s_failed=$((s_failed + 1))
    fi

    # At least 1 commit (progress preserved)
    local final_commits
    final_commits=$(git -C "$test_dir" log --oneline | wc -l)
    if [ "$final_commits" -gt "$initial_commits" ]; then
        echo "  [PASS] Progress commits preserved ($((final_commits - initial_commits)) new)"
    else
        echo "  [WARN] No commits (may not have had time to start)"
    fi

    # Progress summary should exist
    if echo "$output" | grep -qi "progress\|remaining\|backlog\|suggest"; then
        echo "  [PASS] Output contains progress/remaining suggestions"
    else
        echo "  [WARN] Output may lack progress summary"
    fi

    FAILED=$((FAILED + s_failed))
}

verify_scenario_e() {
    local test_dir="$1"
    local state_file="$2"
    local output="$3"
    local initial_commits="$4"
    local s_failed=0

    echo "  --- Scenario E: Self-evaluation catches issues ---"

    # Verify iterations happened
    local iter_count
    iter_count=$(grep -c "^### Iteration" "$state_file" 2>/dev/null || echo "0")
    if [ "$iter_count" -ge 1 ]; then
        echo "  [PASS] $iter_count iterations recorded"
    else
        echo "  [FAIL] No iterations"
        s_failed=$((s_failed + 1))
    fi

    # Verify code was modified
    local final_commits
    final_commits=$(git -C "$test_dir" log --oneline | wc -l)
    if [ "$final_commits" -gt "$initial_commits" ]; then
        echo "  [PASS] Code changes committed"
    else
        echo "  [FAIL] No commits"
        s_failed=$((s_failed + 1))
    fi

    # Verify bare except patterns were improved
    if grep -q "except:" "$test_dir/src/service.py" || grep -q "except Exception" "$test_dir/src/service.py"; then
        echo "  [INFO] Some bare except patterns remain (may need more iterations)"
    else
        echo "  [PASS] Bare except patterns addressed"
    fi

    # Check iteration history for self-evaluation traces
    if grep -qi "side.?effect\|regression\|test\|verify\|check" "$state_file"; then
        echo "  [PASS] Iteration history shows self-evaluation activity"
    else
        echo "  [WARN] No self-evaluation traces in history"
    fi

    FAILED=$((FAILED + s_failed))
}

verify_scenario_f() {
    local test_dir="$1"
    local state_file="$2"
    local output="$3"
    local initial_commits="$4"
    local s_failed=0

    echo "  --- Scenario F: Context compaction recovery ---"

    # First: verify goal-loop produced results
    local iter_count
    iter_count=$(grep -c "^### Iteration" "$state_file" 2>/dev/null || echo "0")
    if [ "$iter_count" -ge 1 ]; then
        echo "  [PASS] $iter_count iterations recorded in state file"
    else
        echo "  [FAIL] No iterations in state file"
        s_failed=$((s_failed + 1))
    fi

    # Extract key info from state file
    local goal_text
    goal_text=$(grep -A1 "^## Goal" "$state_file" | tail -1 | xargs)
    local iteration_line
    iteration_line=$(grep "^## Iteration:" "$state_file" | head -1)
    local completed_items
    completed_items=$(grep -c "\[x\]" "$state_file" || echo "0")
    local pending_items
    pending_items=$(grep -c "\[ \]" "$state_file" || echo "0")

    echo "  [INFO] State file: goal='$goal_text', $iteration_line, $completed_items done, $pending_items pending"

    # Now: start a new claude session and ask it to read the state file
    echo "  Starting fresh session to verify state file readability..."
    local recovery_output
    recovery_output=$(timeout 60 claude -p \
        "Read the file at $test_dir/.claude/goal-loop-state.md and tell me: 1) What is the goal? 2) What iteration number did it reach? 3) How many backlog items are completed vs pending? Answer factually based only on the file contents." \
        2>&1) || true

    # Verify the recovery session understood the state
    if echo "$recovery_output" | grep -qi "goal\|目标"; then
        echo "  [PASS] Recovery session identified the goal"
    else
        echo "  [FAIL] Recovery session could not identify goal"
        s_failed=$((s_failed + 1))
    fi

    if echo "$recovery_output" | grep -q "[0-9]"; then
        echo "  [PASS] Recovery session extracted iteration counts"
    else
        echo "  [FAIL] Recovery session could not extract numbers"
        s_failed=$((s_failed + 1))
    fi

    if echo "$recovery_output" | grep -qi "complet\|done\|finish\|pending\|remain"; then
        echo "  [PASS] Recovery session identified backlog status"
    else
        echo "  [FAIL] Recovery session could not identify backlog status"
        s_failed=$((s_failed + 1))
    fi

    FAILED=$((FAILED + s_failed))
}

# =============================================
# Main execution
# =============================================

echo "========================================"
echo " Integration Test: goal-loop skill"
echo "========================================"
echo ""
echo "This test executes real goal-loop cycles and verifies:"
echo "  1. State file creation and evolution"
echo "  2. Iteration history accumulation"
echo "  3. Backlog management"
echo "  4. Completion/ABORTED handling"
echo "  5. Self-evaluation mechanism"
echo "  6. Context recovery via state file"
echo ""
echo "WARNING: This test may take 30-60 minutes."
echo ""

# Run scenarios in order (C first as quickest sanity check)
run_scenario C "Goal already met (0 rounds)" \
    "scenario-c-clean" \
    "修复所有 lint 问题" \
    5 120

run_scenario A "Multi-iteration with state verification" \
    "scenario-a-lint" \
    "Fix all lint issues in this Python project using ruff" \
    5 600

run_scenario B "Code structure optimization" \
    "scenario-b-duplication" \
    "优化代码结构，减少重复代码" \
    3 600

run_scenario D "Iteration limit (ABORTED)" \
    "scenario-d-monolith" \
    "完全重构整个项目架构为微服务" \
    2 300

run_scenario E "Self-evaluation catches issues" \
    "scenario-e-error-handling" \
    "改进所有函数的错误处理，使用有意义的异常而非 bare except 和 pass" \
    4 600

# Scenario F reuses scenario-a-lint fixture (tests state file recovery)
# Create a fresh copy for F
TEMP_F=$(mktemp -d)
cp -r "$FIXTURES_DIR/scenario-a-lint/." "$TEMP_F/"
cd "$TEMP_F"
git init --quiet
git config user.email "test@test.com"
git config user.name "Test User"
git add .
git commit -m "Initial commit" --quiet

# First run goal-loop briefly to produce a state file
timeout 300 claude -p \
    "Load the summ:goal-loop skill and follow it. Goal: Add unit tests for all functions --max-iterations 3" \
    --allowed-tools=all \
    --permission-mode bypassPermissions \
    2>&1 || true

# Then verify recovery
verify_scenario_f "$TEMP_F" "$TEMP_F/.claude/goal-loop-state.md" "" "1"
rm -rf "$TEMP_F"

# =============================================
# Summary
# =============================================

echo ""
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""
echo "Scenarios run: $TOTAL"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "STATUS: PASSED"
    echo "All integration tests passed!"
    exit 0
else
    echo "STATUS: FAILED ($FAILED issues across scenarios)"
    echo ""
    echo "Review the output above for details."
    exit 1
fi
```

- [ ] **Step 2: Make executable**

Run: `chmod +x tests/claude-code/test-goal-loop-integration.sh`

- [ ] **Step 3: Verify syntax**

Run: `bash -n tests/claude-code/test-goal-loop-integration.sh`
Expected: No output (syntax check passes)

- [ ] **Step 4: Verify test runner can find the test**

Run: `ls -la tests/claude-code/test-goal-loop*.sh`
Expected: Two files listed with executable permission.

- [ ] **Step 5: Commit**

```bash
git add tests/claude-code/test-goal-loop.sh tests/claude-code/test-goal-loop-integration.sh
git commit -m "test(goal-loop): add unit and integration test scripts"
```
