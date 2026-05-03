#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Isolated telemetry dir
TELEM_TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TELEM_TEST_DIR"' EXIT
export HOME="$TELEM_TEST_DIR"

TELEM_DIR="${TELEM_TEST_DIR}/.claude/skill-telemetry"
LOG_DIR="${TELEM_DIR}/logs"
mkdir -p "$LOG_DIR"

# Set up config and session
echo '{"enabled":true,"retention_days":90,"log_dir":"~/.claude/skill-telemetry/logs"}' > "${TELEM_DIR}/config.json"
echo 'test1234' > "${TELEM_DIR}/.current-session"
echo '{"sessions":{"test1234":{"started":"2026-05-03T14:00:00Z","last_activity":"2026-05-03T14:00:00Z","skills_invoked":0,"files":["2026-05-03.jsonl"]}}}' > "${TELEM_DIR}/sessions-index.json"

SKILL_TELEMETRY="${PROJECT_ROOT}/hooks/skill-telemetry"

echo "Testing skill-telemetry script..."

# Test 1: pre mode writes invoked event
assert_pre_invoked() {
    echo '{"tool_input":{"skill":"summ:brainstorming","args":"test prompt here"}}' \
        | bash "$SKILL_TELEMETRY" pre

    local log_file="${LOG_DIR}/$(date -u +%Y-%m-%d).jsonl"
    if [ -f "$log_file" ]; then
        local event
        event=$(jq -r '.event' < <(tail -1 "$log_file"))
        local skill
        skill=$(jq -r '.skill' < <(tail -1 "$log_file"))
        local sid
        sid=$(jq -r '.session_id' < <(tail -1 "$log_file"))
        if [ "$event" = "invoked" ] && [ "$skill" = "summ:brainstorming" ] && [ "$sid" = "test1234" ]; then
            echo "  [PASS] pre mode writes correct invoked event"
        else
            echo "  [FAIL] pre mode event mismatch: event=$event skill=$skill sid=$sid"
            return 1
        fi
    else
        echo "  [FAIL] log file not created"
        return 1
    fi
}

# Test 2: post mode writes completed event with duration
assert_post_completed() {
    echo '{"tool_input":{"skill":"summ:brainstorming"}}' \
        | bash "$SKILL_TELEMETRY" post

    local log_file="${LOG_DIR}/$(date -u +%Y-%m-%d).jsonl"
    local last_event
    last_event=$(tail -1 "$log_file")
    local event
    event=$(jq -r '.event' <<< "$last_event")

    if [ "$event" = "completed" ]; then
        echo "  [PASS] post mode writes completed event"
    else
        echo "  [FAIL] post mode event: $event"
        return 1
    fi
}

# Test 3: args_summary truncated to 200 chars
assert_args_truncation() {
    local log_file="${LOG_DIR}/$(date -u +%Y-%m-%d).jsonl"
    rm -f "$log_file"

    local long_args
    long_args=$(python3 -c "print('x' * 300)")
    echo "{\"tool_input\":{\"skill\":\"test:skill\",\"args\":\"${long_args}\"}}" \
        | bash "$SKILL_TELEMETRY" pre

    local args_len
    args_len=$(jq -r '.args_summary | length' < <(tail -1 "$log_file"))
    if [ "$args_len" -le 200 ]; then
        echo "  [PASS] args_summary truncated to <= 200 chars (got $args_len)"
    else
        echo "  [FAIL] args_summary not truncated: $args_len chars"
        return 1
    fi
}

# Test 4: disabled config exits early
assert_disabled() {
    echo '{"enabled":false}' > "${TELEM_DIR}/config.json"

    local log_file="${LOG_DIR}/$(date -u +%Y-%m-%d).jsonl"
    local before_lines
    before_lines=$(wc -l < "$log_file" 2>/dev/null || echo "0")

    echo '{"tool_input":{"skill":"summ:test"}}' | bash "$SKILL_TELEMETRY" pre

    local after_lines
    after_lines=$(wc -l < "$log_file" 2>/dev/null || echo "0")

    if [ "$before_lines" = "$after_lines" ]; then
        echo "  [PASS] disabled config skips logging"
    else
        echo "  [FAIL] logged despite disabled"
        return 1
    fi

    # Restore config
    echo '{"enabled":true,"retention_days":90}' > "${TELEM_DIR}/config.json"
}

assert_pre_invoked
assert_post_completed
assert_args_truncation
assert_disabled
echo "Done."
