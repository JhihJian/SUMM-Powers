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
