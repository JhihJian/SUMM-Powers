#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Use a temp dir for test telemetry data
TELEM_TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TELEM_TEST_DIR"' EXIT

# Override HOME to isolate telemetry
export HOME="$TELEM_TEST_DIR"

# Run session-start and check side effects
export CLAUDE_PLUGIN_ROOT="${PROJECT_ROOT}"
output=$("${PROJECT_ROOT}/hooks/session-start" 2>/dev/null) || true

# Test 1: telemetry directory created
assert_telemetry_dir() {
    if [ -d "${TELEM_TEST_DIR}/.claude/skill-telemetry" ]; then
        echo "  [PASS] telemetry directory created"
    else
        echo "  [FAIL] telemetry directory not created"
        return 1
    fi
}

# Test 2: config.json exists with defaults
assert_config_json() {
    local config="${TELEM_TEST_DIR}/.claude/skill-telemetry/config.json"
    if [ -f "$config" ] && jq -e '.enabled == true and .retention_days == 90' "$config" >/dev/null 2>&1; then
        echo "  [PASS] config.json has correct defaults"
    else
        echo "  [FAIL] config.json missing or incorrect"
        cat "$config" 2>/dev/null
        return 1
    fi
}

# Test 3: .current-session exists and is 8 hex chars
assert_session_id() {
    local sf="${TELEM_TEST_DIR}/.claude/skill-telemetry/.current-session"
    if [ -f "$sf" ]; then
        local sid
        sid=$(cat "$sf")
        if [[ "$sid" =~ ^[0-9a-f]{8}$ ]]; then
            echo "  [PASS] session ID is 8-char hex: $sid"
        else
            echo "  [FAIL] session ID format wrong: $sid"
            return 1
        fi
    else
        echo "  [FAIL] .current-session not created"
        return 1
    fi
}

# Test 4: sessions-index.json has entry
assert_sessions_index() {
    local idx="${TELEM_TEST_DIR}/.claude/skill-telemetry/sessions-index.json"
    if [ -f "$idx" ] && jq -e '.sessions | length == 1' "$idx" >/dev/null 2>&1; then
        echo "  [PASS] sessions-index.json has 1 session"
    else
        echo "  [FAIL] sessions-index.json missing or wrong"
        cat "$idx" 2>/dev/null
        return 1
    fi
}

# Run all tests
echo "Testing session-start telemetry init..."
assert_telemetry_dir
assert_config_json
assert_session_id
assert_sessions_index
echo "Done."
