#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TELEM_TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TELEM_TEST_DIR"' EXIT
export HOME="$TELEM_TEST_DIR"

TELEM_DIR="${TELEM_TEST_DIR}/.claude/skill-telemetry"
LOG_DIR="${TELEM_DIR}/logs"
mkdir -p "$LOG_DIR"

SUMM_STATS="${PROJECT_ROOT}/scripts/summ-stats"

# Create test data
cat > "${LOG_DIR}/2026-05-03.jsonl" << 'TESTDATA'
{"ts":"2026-05-03T14:32:01.000Z","session_id":"sess0001","event":"invoked","skill":"summ:brainstorming","args_summary":"test","duration_ms":null}
{"ts":"2026-05-03T14:35:22.000Z","session_id":"sess0001","event":"completed","skill":"summ:brainstorming","args_summary":null,"duration_ms":201000}
{"ts":"2026-05-03T14:36:00.000Z","session_id":"sess0001","event":"invoked","skill":"summ:writing-plans","args_summary":"test plan","duration_ms":null}
{"ts":"2026-05-03T14:38:00.000Z","session_id":"sess0001","event":"completed","skill":"summ:writing-plans","args_summary":null,"duration_ms":120000}
{"ts":"2026-05-03T14:40:00.000Z","session_id":"sess0002","event":"invoked","skill":"summ:brainstorming","args_summary":"test2","duration_ms":null}
{"ts":"2026-05-03T14:42:00.000Z","session_id":"sess0002","event":"completed","skill":"summ:brainstorming","args_summary":null,"duration_ms":120000}
{"ts":"2026-05-03T14:45:00.000Z","session_id":"sess0002","event":"invoked","skill":"summ:test-driven-development","args_summary":"test3","duration_ms":null}
TESTDATA

echo "Testing summ-stats summary..."

# Test 1: summary shows total invocations
assert_summary_total() {
    local output
    output=$(bash "$SUMM_STATS" summary 2>&1)
    if echo "$output" | grep -q "Total invocations: 4"; then
        echo "  [PASS] summary shows 4 total invocations"
    else
        echo "  [FAIL] expected 'Total invocations: 4'"
        echo "$output" | head -3
        return 1
    fi
}

# Test 2: summary shows unique skills count
assert_summary_unique() {
    local output
    output=$(bash "$SUMM_STATS" summary 2>&1)
    if echo "$output" | grep -q "Unique skills: 3"; then
        echo "  [PASS] summary shows 3 unique skills"
    else
        echo "  [FAIL] expected 'Unique skills: 3'"
        echo "$output" | grep "Unique"
        return 1
    fi
}

# Test 3: summary shows completion rate
assert_summary_completion() {
    local output
    output=$(bash "$SUMM_STATS" summary 2>&1)
    if echo "$output" | grep -q "Completion rate: 3/4"; then
        echo "  [PASS] summary shows completion rate 3/4"
    else
        echo "  [FAIL] expected 'Completion rate: 3/4'"
        echo "$output" | grep "Completion"
        return 1
    fi
}

assert_summary_total
assert_summary_unique
assert_summary_completion
echo "Done."
