#!/usr/bin/env bash
set -euo pipefail

# Test: Does CONTEXT.md get proactively created?
# Scenarios:
#   1. Brainstorming a new feature → should now trigger domain-language (MODIFIED: expected to create)
#   2. Onboarding with terminology confusion → should create CONTEXT.md
#   3. Using domain-specific ambiguous terminology → should create CONTEXT.md
#   4. Explicitly triggering domain-language skill → should create CONTEXT.md

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

PASS=0
FAIL=0
TOTAL=0

run_test() {
    local test_name="$1"
    local test_dir="$2"
    local prompt="$3"
    local timeout="${4:-120}"
    local expected_file="$test_dir/CONTEXT.md"

    TOTAL=$((TOTAL + 1))
    echo ""
    echo "=== Test $TOTAL: $test_name ==="
    echo "Working dir: $test_dir"
    echo "Prompt: $prompt"
    echo "---"

    # Run claude in the test directory
    local output
    output=$(cd "$test_dir" && timeout "$timeout" claude -p "$prompt" --allowed-tools="Read,Glob,Grep,Write,Edit,Bash" 2>&1 || true)

    echo "Output (last 20 lines):"
    echo "$output" | tail -20
    echo "---"

    if [ -f "$expected_file" ]; then
        echo "[PASS] $test_name — CONTEXT.md was created"
        echo "Content:"
        cat "$expected_file"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $test_name — CONTEXT.md was NOT created"
        FAIL=$((FAIL + 1))
    fi
}

run_test_no_file() {
    local test_name="$1"
    local test_dir="$2"
    local prompt="$3"
    local timeout="${4:-120}"
    local expected_file="$test_dir/CONTEXT.md"

    TOTAL=$((TOTAL + 1))
    echo ""
    echo "=== Test $TOTAL: $test_name ==="
    echo "Working dir: $test_dir"
    echo "Prompt: $prompt"
    echo "---"

    local output
    output=$(cd "$test_dir" && timeout "$timeout" claude -p "$prompt" --allowed-tools="Read,Glob,Grep,Write,Edit,Bash" 2>&1 || true)

    echo "Output (last 20 lines):"
    echo "$output" | tail -20
    echo "---"

    # Also check if domain-language was mentioned in output
    if echo "$output" | grep -qi "domain.language\|CONTEXT.md"; then
        echo "[INFO] domain-language or CONTEXT.md was mentioned in output"
    fi

    if [ -f "$expected_file" ]; then
        echo "[UNEXPECTED] $test_name — CONTEXT.md was created (expected: no)"
        echo "Content:"
        cat "$expected_file"
    else
        echo "[EXPECTED] $test_name — CONTEXT.md was NOT created"
        PASS=$((PASS + 1))
    fi
}

# Create test project directories
echo "Setting up test projects..."

# --- Scenario 1: Brainstorming a new feature ---
SCENARIO1_DIR=$(mktemp -d)
mkdir -p "$SCENARIO1_DIR/src"
cat > "$SCENARIO1_DIR/src/main.py" << 'PYEOF'
class OrderProcessor:
    def process(self, order):
        self.validate(order)
        self.charge(order)
        self.fulfill(order)

    def validate(self, order):
        pass

    def charge(self, order):
        pass

    def fulfill(self, order):
        pass
PYEOF
cat > "$SCENARIO1_DIR/README.md" << 'EOF'
# Order System
A simple order processing system.
EOF

# --- Scenario 2: Onboarding ---
SCENARIO2_DIR=$(mktemp -d)
mkdir -p "$SCENARIO2_DIR/src" "$SCENARIO2_DIR/docs"
cat > "$SCENARIO2_DIR/src/app.ts" << 'TSEOF'
interface Pipeline {
  stages: Stage[];
  run(input: any): any;
}

class ETLProcessor implements Pipeline {
  stages: Stage[] = [];
  run(input: any) {
    return this.stages.reduce((data, stage) => stage.process(data), input);
  }
}
TSEOF
cat > "$SCENARIO2_DIR/README.md" << 'EOF'
# Data Pipeline
ETL pipeline for data transformation and loading.
EOF

# --- Scenario 3: Ambiguous terminology ---
SCENARIO3_DIR=$(mktemp -d)
mkdir -p "$SCENARIO3_DIR/src"
cat > "$SCENARIO3_DIR/src/service.go" << 'GOEOF'
package service

type Handler struct {
    processor Processor
}

func (h *Handler) Handle(msg Message) error {
    return h.processor.Process(msg)
}
GOEOF
cat > "$SCENARIO3_DIR/README.md" << 'EOF'
# Message Service
Message handling service with processors and handlers.
EOF

# --- Scenario 4: Explicit skill invocation ---
SCENARIO4_DIR=$(mktemp -d)
mkdir -p "$SCENARIO4_DIR/src"
cat > "$SCENARIO4_DIR/src/index.js" << 'JSEOF'
class EventBus {
  emit(event, data) { }
  on(event, handler) { }
}
JSEOF
cat > "$SCENARIO4_DIR/README.md" << 'EOF'
# Event System
Event-driven architecture demo.
EOF

# Cleanup function
cleanup() {
    rm -rf "$SCENARIO1_DIR" "$SCENARIO2_DIR" "$SCENARIO3_DIR" "$SCENARIO4_DIR"
}
trap cleanup EXIT

echo ""
echo "=========================================="
echo "Running 4 test scenarios..."
echo "=========================================="

# Test 1: Brainstorming — should now trigger domain-language for a new feature
run_test \
    "Scenario 1: Brainstorming a new feature in Order System" \
    "$SCENARIO1_DIR" \
    "I want to add a refund system to this Order System. The refund should support partial refunds and handle chargebacks differently from voluntary refunds. Can you help me brainstorm this?" \
    120

# Test 2: Onboarding with terminology confusion — should create CONTEXT.md
run_test \
    "Scenario 2: Onboarding to a Data Pipeline codebase" \
    "$SCENARIO2_DIR" \
    "I'm new to this Data Pipeline project. Can you help me understand how the ETL system works? I'm confused about the difference between stages, processors, and transformers in this codebase." \
    120

# Test 3: Terminology confusion — should create CONTEXT.md
run_test \
    "Scenario 3: Terminology confusion — handlers vs processors" \
    "$SCENARIO3_DIR" \
    "I'm confused about this codebase. Sometimes people say 'handler' and sometimes 'processor' — are these the same thing? Also, what's the difference between a 'message' and an 'event' in this system? Help me clarify the terminology." \
    120

# Test 4: Explicit domain-language skill invocation
run_test \
    "Scenario 4: Explicit domain-language skill invocation" \
    "$SCENARIO4_DIR" \
    "I need you to invoke the domain-language skill and set up CONTEXT.md for this Event System project. We need to define: event, emitter, handler, bus, and subscriber." \
    120

# Summary
echo ""
echo "=========================================="
echo "RESULTS: $PASS passed, $FAIL failed, $TOTAL total"
echo "=========================================="

if [ $FAIL -gt 0 ]; then
    echo ""
    echo "FINDING: CONTEXT.md is NOT proactively created in any scenario."
    echo "The domain-language skill requires explicit invocation."
    exit 1
fi

exit 0
