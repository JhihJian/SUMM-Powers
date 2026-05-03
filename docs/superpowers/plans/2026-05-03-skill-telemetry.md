# Skill Invocation Telemetry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summ:subagent-driven-development (recommended) or summ:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add automatic telemetry collection for Skill tool invocations via Claude Code hooks, with a CLI tool for querying and analyzing usage patterns.

**Architecture:** Hooks (PreToolUse/PostToolUse) intercept Skill tool calls and write JSONL events to local files. SessionStart generates a session ID. A `summ-stats` CLI reads the JSONL logs and produces text reports.

**Tech Stack:** Bash, jq, JSONL

---

## File Structure

| File | Responsibility |
|------|---------------|
| `hooks/hooks.json` | Hook configuration — add PreToolUse/PostToolUse entries for Skill matcher |
| `hooks/session-start` | Extend to generate session ID and write to telemetry state files |
| `hooks/skill-telemetry` | Collection script — reads stdin JSON from hooks, writes JSONL events |
| `scripts/summ-stats` | CLI query tool — reads JSONL logs, outputs text reports |
| `tests/telemetry/test-skill-telemetry.sh` | Unit tests for the collection script |
| `tests/telemetry/test-summ-stats.sh` | Unit tests for the CLI tool |
| `tests/telemetry/test-session-start-telemetry.sh` | Tests for session ID generation in session-start |
| `~/.claude/skill-telemetry/config.json` | Runtime config (created by session-start) |
| `~/.claude/skill-telemetry/logs/*.jsonl` | Daily log files (created by skill-telemetry) |
| `~/.claude/skill-telemetry/sessions-index.json` | Session index (created by session-start) |
| `~/.claude/skill-telemetry/.current-session` | Current session ID file (created by session-start) |

---

## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Telemetry config + directory init | `hooks/session-start` | M | Add init_telemetry() function to session-start |
| 2 | Collection script (skill-telemetry) | `hooks/skill-telemetry`, `tests/telemetry/test-skill-telemetry.sh` | L | Two modes (pre/post), JSONL writing, duration calculation |
| 3 | Hook configuration | `hooks/hooks.json` | S | Add PreToolUse/PostToolUse entries |
| 4 | summ-stats CLI: summary | `scripts/summ-stats`, `tests/telemetry/test-summ-stats.sh` | M | summary subcommand with --from/--to filters |
| 5 | summ-stats CLI: session + recent + paths | `scripts/summ-stats`, `tests/telemetry/test-summ-stats.sh` | L | Three more subcommands, path chain analysis |
| 6 | Log rotation | `scripts/summ-stats` | S | Delete old log files based on config retention_days |

---

### Batch 1 (Tasks 1-3)

### Task 1: Telemetry Config + Directory Init

**Files:**
- Modify: `hooks/session-start`
- Create: `tests/telemetry/test-session-start-telemetry.sh`

Add a `init_telemetry` function to `hooks/session-start` that runs on every SessionStart. This function:
1. Creates `~/.claude/skill-telemetry/` directory tree if missing
2. Writes default `config.json` if missing
3. Generates a session ID (8-char hex from `/dev/urandom`) and writes to `.current-session`
4. Updates `sessions-index.json` with the new session entry

**The `init_telemetry` function to add at the end of `hooks/session-start` (before the JSON output logic):**

```bash
init_telemetry() {
    local telem_dir="${HOME}/.claude/skill-telemetry"
    local log_dir="${telem_dir}/logs"

    # Create directories
    mkdir -p "$log_dir"

    # Write default config if missing
    if [ ! -f "${telem_dir}/config.json" ]; then
        cat > "${telem_dir}/config.json" << 'TELEMCFG'
{"enabled":true,"retention_days":90,"log_dir":"~/.claude/skill-telemetry/logs"}
TELEMCFG
    fi

    # Check if telemetry is enabled
    local enabled
    enabled=$(jq -r '.enabled // true' "${telem_dir}/config.json" 2>/dev/null || echo "true")
    if [ "$enabled" != "true" ]; then
        return 0
    fi

    # Generate session ID (8-char hex)
    local session_id
    session_id=$(od -An -tx1 -N4 /dev/urandom | tr -d ' \n')

    # Write current session file
    printf '%s' "$session_id" > "${telem_dir}/.current-session"

    # Update sessions index
    local index_file="${telem_dir}/sessions-index.json"
    local now_ts
    now_ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [ ! -f "$index_file" ]; then
        printf '{"sessions":{}}' > "$index_file"
    fi

    local today
    today=$(date -u +"%Y-%m-%d")

    # Use temp file for atomic update
    local tmp_index
    tmp_index=$(mktemp)
    jq --arg sid "$session_id" \
       --arg ts "$now_ts" \
       --arg file "${today}.jsonl" \
       '.sessions[$sid] = {"started": $ts, "last_activity": $ts, "skills_invoked": 0, "files": [$file]}' \
       "$index_file" > "$tmp_index" && mv "$tmp_index" "$index_file"
}
```

Then call `init_telemetry` before the JSON output section (after reading `using_summ_content`, around line 18). Add the call:

```bash
# Initialize telemetry (after PLUGIN_ROOT is set)
init_telemetry
```

- [ ] **Step 1: Write the test**

Create `tests/telemetry/test-session-start-telemetry.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Use a temp dir for test telemetry data
TELEM_TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TELEM_TEST_DIR"' EXIT

# Override HOME to isolate telemetry
export HOME="$TELEM_TEST_DIR"

# Source the init_telemetry function directly from session-start
# We'll extract and test just the function
source "${PROJECT_ROOT}/hooks/session-start" --source-only 2>/dev/null || true

# Since session-start is a script (not a library), test via execution
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/telemetry/test-session-start-telemetry.sh`
Expected: FAIL — `init_telemetry` function doesn't exist yet

- [ ] **Step 3: Add `init_telemetry` to session-start**

Add the `init_telemetry` function (code above) to `hooks/session-start` after the `escape_for_json` function (around line 31). Add the call `init_telemetry` right before the platform detection `if` block (around line 46).

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/telemetry/test-session-start-telemetry.sh`
Expected: All 4 assertions PASS

- [ ] **Step 5: Commit**

```bash
git add hooks/session-start tests/telemetry/test-session-start-telemetry.sh
git commit -m "feat(telemetry): add session ID generation and telemetry dir init to SessionStart hook"
```

---

### Task 2: Collection Script (skill-telemetry)

**Files:**
- Create: `hooks/skill-telemetry`
- Create: `tests/telemetry/test-skill-telemetry.sh`

This is the core collection script. It runs in two modes (`pre` and `post`) invoked by the PreToolUse/PostToolUse hooks. It reads JSON from stdin, extracts fields, and appends a JSONL record to the daily log file.

**`hooks/skill-telemetry`:**

```bash
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
TELEM_DIR="${HOME}/.claude/skill-telemetry"
LOG_DIR="${TELEM_DIR}/logs"
CONFIG="${TELEM_DIR}/config.json"
SESSION_FILE="${TELEM_DIR}/.current-session"
INDEX_FILE="${TELEM_DIR}/sessions-index.json"

# Read config
enabled=$(jq -r '.enabled // true' "$CONFIG" 2>/dev/null || echo "true")
if [ "$enabled" != "true" ]; then
    exit 0
fi

# Read session ID
session_id=""
if [ -f "$SESSION_FILE" ]; then
    session_id=$(cat "$SESSION_FILE")
fi

# Ensure log dir exists
mkdir -p "$LOG_DIR"

# Read stdin JSON
input_json=$(cat)

# Extract skill name from input
skill_name=$(printf '%s' "$input_json" | jq -r '.tool_input.skill // .tool_input.name // "unknown"' 2>/dev/null || echo "unknown")

# Current timestamp
ts=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

# Today's log file (UTC)
today=$(date -u +"%Y-%m-%d")
log_file="${LOG_DIR}/${today}.jsonl"

if [ "$MODE" = "pre" ]; then
    # Extract args summary (truncate to 200 chars)
    args_summary=$(printf '%s' "$input_json" | jq -r '.tool_input.args // ""' 2>/dev/null | head -c 200)

    # Write invoked event
    jq -n \
        --arg ts "$ts" \
        --arg sid "$session_id" \
        --arg skill "$skill_name" \
        --arg args "$args_summary" \
        '{ts: $ts, session_id: $sid, event: "invoked", skill: $skill, args_summary: $args, duration_ms: null}' \
        >> "$log_file"

elif [ "$MODE" = "post" ]; then
    # Calculate duration: find most recent invoked event for same skill+session
    duration_ms="null"
    if [ -f "$log_file" ] && [ -n "$session_id" ]; then
        invoked_ts=$(jq -r "select(.session_id == \"$session_id\" and .skill == \"$skill_name\" and .event == \"invoked\") | .ts" "$log_file" 2>/dev/null | tail -1)
        if [ -n "$invoked_ts" ] && [ "$invoked_ts" != "null" ]; then
            # Parse timestamps and compute diff (milliseconds)
            invoked_epoch=$(date -d "$invoked_ts" +%s%3N 2>/dev/null || echo "0")
            now_epoch=$(date -d "$ts" +%s%3N 2>/dev/null || echo "0")
            if [ "$invoked_epoch" != "0" ] && [ "$now_epoch" != "0" ]; then
                duration_ms=$((now_epoch - invoked_epoch))
            fi
        fi
    fi

    # Write completed event
    jq -n \
        --arg ts "$ts" \
        --arg sid "$session_id" \
        --arg skill "$skill_name" \
        --argjson dur "$duration_ms" \
        '{ts: $ts, session_id: $sid, event: "completed", skill: $skill, args_summary: null, duration_ms: $dur}' \
        >> "$log_file"
fi

# Update sessions index (increment skills_invoked for pre events)
if [ "$MODE" = "pre" ] && [ -f "$INDEX_FILE" ] && [ -n "$session_id" ]; then
    now_ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    tmp_index=$(mktemp)
    jq --arg sid "$session_id" \
       --arg ts "$now_ts" \
       --arg file "${today}.jsonl" \
       'if .sessions[$sid] then .sessions[$sid].skills_invoked += 1 | .sessions[$sid].last_activity = $ts else .sessions[$sid] = {"started": $ts, "last_activity": $ts, "skills_invoked": 1, "files": [$file]} end' \
       "$INDEX_FILE" > "$tmp_index" && mv "$tmp_index" "$INDEX_FILE"
fi
```

- [ ] **Step 1: Write the test**

Create `tests/telemetry/test-skill-telemetry.sh`:

```bash
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
    # Reset log
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
    # Overwrite config
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/telemetry/test-skill-telemetry.sh`
Expected: FAIL — `hooks/skill-telemetry` doesn't exist yet

- [ ] **Step 3: Create `hooks/skill-telemetry`**

Write the script (full code above). Make it executable: `chmod +x hooks/skill-telemetry`

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/telemetry/test-skill-telemetry.sh`
Expected: All 4 assertions PASS

- [ ] **Step 5: Commit**

```bash
git add hooks/skill-telemetry tests/telemetry/test-skill-telemetry.sh
git commit -m "feat(telemetry): add skill-telemetry collection script with pre/post modes"
```

---

### Task 3: Hook Configuration

**Files:**
- Modify: `hooks/hooks.json`

Add PreToolUse and PostToolUse entries to `hooks/hooks.json`. The final file should be:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start",
            "async": false
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" skill-telemetry pre",
            "async": true
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" skill-telemetry post",
            "async": true
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 1: Verify hook JSON is valid**

Run: `jq . hooks/hooks.json > /dev/null && echo "Valid JSON"`
Expected: "Valid JSON"

- [ ] **Step 2: Update hooks.json**

Replace the entire file content with the JSON above.

- [ ] **Step 3: Verify again**

Run: `jq '.hooks | keys' hooks/hooks.json`
Expected: `["PostToolUse", "PreToolUse", "SessionStart"]`

- [ ] **Step 4: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat(telemetry): add PreToolUse/PostToolUse hooks for Skill telemetry"
```

---

### Batch 2 (Tasks 4-6)

### Task 4: summ-stats CLI — summary Command

**Files:**
- Create: `scripts/summ-stats`
- Create: `tests/telemetry/test-summ-stats.sh`

The `summ-stats` CLI tool. This task implements the `summary` subcommand with optional `--from`/`--to` date filters.

**`scripts/summ-stats` (initial version with summary only):**

```bash
#!/usr/bin/env bash
set -euo pipefail

TELEM_DIR="${HOME}/.claude/skill-telemetry"
LOG_DIR="${TELEM_DIR}/logs"

# Parse arguments
COMMAND="${1:-help}"
shift 2>/dev/null || true

FROM_DATE=""
TO_DATE=""

# Parse flags
while [ $# -gt 0 ]; do
    case "$1" in
        --from) FROM_DATE="$2"; shift 2 ;;
        --to) TO_DATE="$2"; shift 2 ;;
        --n) N_COUNT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

collect_log_files() {
    local from="${FROM_DATE:-}"
    local to="${TO_DATE:-}"

    if [ -n "$from" ] && [ -n "$to" ]; then
        # Use jq date comparison won't work on filenames, use find with day range
        local current="$from"
        while [ "$current" \< "$to" ] || [ "$current" = "$to" ]; do
            [ -f "${LOG_DIR}/${current}.jsonl" ] && cat "${LOG_DIR}/${current}.jsonl"
            current=$(date -d "$current + 1 day" +%Y-%m-%d 2>/dev/null || echo "")
            [ -z "$current" ] && break
        done
    elif [ -n "$from" ]; then
        cat "${LOG_DIR}"/*.jsonl 2>/dev/null | jq -r "select(.ts >= \"${from}\")"
    elif [ -n "$to" ]; then
        cat "${LOG_DIR}"/*.jsonl 2>/dev/null | jq -r "select(.ts <= \"${to}T23:59:59\")"
    else
        cat "${LOG_DIR}"/*.jsonl 2>/dev/null
    fi
}

cmd_summary() {
    local data
    data=$(collect_log_files)

    if [ -z "$data" ]; then
        echo "No telemetry data found."
        exit 0
    fi

    local total_invoked
    total_invoked=$(jq -s '[.[] | select(.event == "invoked")] | length' <<< "$data")

    local unique_skills
    unique_skills=$(jq -s '[.[] | select(.event == "invoked") | .skill] | unique | length' <<< "$data")

    local total_completed
    total_completed=$(jq -s '[.[] | select(.event == "completed")] | length' <<< "$data")

    echo "=== Skill Telemetry Summary ==="
    echo "Total invocations: ${total_invoked}"
    echo "Unique skills: ${unique_skills}"
    echo "Completion rate: ${total_completed}/${total_invoked} ($(jq -n --argj c "$total_completed" --argj i "$total_invoked" 'if $i == 0 then "N/A" else (($c / $i) * 100 | round | tostring + "%") end'))"

    echo ""
    echo "Top skills:"
    jq -s '[.[] | select(.event == "invoked")] | group_by(.skill) | map({skill: .[0].skill, count: length}) | sort_by(-.count) | .[0:10] | .[] | "  \(.skill)\t\(.count)\t(\((.count / ($total_invoked | tonumber) * 100) | round) %)"' \
        --argjson total_invoked "$total_invoked" <<< "$data" | jq -r .

    echo ""
    echo "Average duration:"
    jq -s '[.[] | select(.event == "completed" and .duration_ms != null)] | group_by(.skill) | map({skill: .[0].skill, avg_ms: (map(.duration_ms) | add / length)}) | .[] | "  \(.skill): \((.avg_ms / 1000 | round)s)"' <<< "$data" | jq -r .
}

case "$COMMAND" in
    summary) cmd_summary ;;
    help|--help|-h)
        echo "Usage: summ-stats <command> [options]"
        echo ""
        echo "Commands:"
        echo "  summary [--from DATE] [--to DATE]  Overall statistics"
        echo "  session <session_id>               Workflow trace for a session"
        echo "  paths [--from DATE] [--to DATE]    Common workflow path analysis"
        echo "  recent [--n COUNT]                 Last N invocations (default 20)"
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "Run 'summ-stats help' for usage."
        exit 1
        ;;
esac
```

- [ ] **Step 1: Write the test**

Create `tests/telemetry/test-summ-stats.sh`:

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/telemetry/test-summ-stats.sh`
Expected: FAIL — `scripts/summ-stats` doesn't exist yet

- [ ] **Step 3: Create `scripts/summ-stats`**

Write the script (full code above). Make executable: `chmod +x scripts/summ-stats`

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/telemetry/test-summ-stats.sh`
Expected: All 3 assertions PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/summ-stats tests/telemetry/test-summ-stats.sh
git commit -m "feat(telemetry): add summ-stats CLI with summary command"
```

---

### Task 5: summ-stats CLI — session, recent, paths Commands

**Files:**
- Modify: `scripts/summ-stats`
- Modify: `tests/telemetry/test-summ-stats.sh`

Add three more subcommands to `summ-stats`. Each uses `collect_log_files` from Task 4 plus command-specific `jq` queries.

**Add these functions to `scripts/summ-stats` before the `case` statement:**

```bash
cmd_session() {
    local sid="${1:-}"
    if [ -z "$sid" ]; then
        echo "Usage: summ-stats session <session_id>"
        exit 1
    fi

    local data
    data=$(collect_log_files)

    if [ -z "$data" ]; then
        echo "No telemetry data found."
        exit 0
    fi

    local session_data
    session_data=$(jq -s --arg sid "$sid" '[.[] | select(.session_id == $sid)]' <<< "$data")

    local count
    count=$(jq 'length' <<< "$session_data")

    if [ "$count" -eq 0 ]; then
        echo "No data for session: $sid"
        exit 0
    fi

    local started
    started=$(jq -r '[.[].ts] | sort | first' <<< "$session_data")
    local ended
    ended=$(jq -r '[.[].ts] | sort | last' <<< "$session_data")

    echo "=== Session: $sid ==="
    echo "Started: $started"
    echo "Last activity: $ended"
    echo "Events: $count"
    echo ""
    echo "Workflow trace:"
    jq -r 'sort_by(.ts) | .[] | "  \(.ts[11:19]) \(.skill) (\(.event)\(if .duration_ms then ", \((.duration_ms / 1000 | round))s" else "" end))"' <<< "$session_data"
}

cmd_recent() {
    local n="${N_COUNT:-20}"
    local data
    data=$(collect_log_files)

    if [ -z "$data" ]; then
        echo "No telemetry data found."
        exit 0
    fi

    echo "=== Recent ${n} invocations ==="
    jq -s --argjson n "$n" '
        sort_by(.ts) | reverse | .[0:$n] | .[] |
        "\(.ts) [\(.session_id[0:8])] \(.event) \(.skill)\(if .duration_ms then " (\((.duration_ms / 1000 | round))s)" else "" end)"
    ' <<< "$data" | head -"$n"
}

cmd_paths() {
    local data
    data=$(collect_log_files)

    if [ -z "$data" ]; then
        echo "No telemetry data found."
        exit 0
    fi

    echo "=== Workflow Paths (top 10) ==="
    jq -s '
        # Group by session, extract ordered invoked skills
        group_by(.session_id)
        | map(
            map(select(.event == "invoked") | .skill)
            # Dedupe consecutive same-skill invocations only
            | reduce .[] as $item ([]; if length == 0 or .[-1] != $item then . + [$item] else . end)
            | join(" → ")
            | select(length > 0)
        )
        | group_by(.)
        | map({path: .[0], count: length})
        | sort_by(-.count)
        | .[0:10]
        | .[]
        | "  \(.path)  (\(.count)x)"
    ' <<< "$data"
}
```

**Update the `case` statement to include new commands:**

```bash
case "$COMMAND" in
    summary) cmd_summary ;;
    session) cmd_session "$@" ;;
    recent) cmd_recent ;;
    paths) cmd_paths ;;
    help|--help|-h)
        echo "Usage: summ-stats <command> [options]"
        echo ""
        echo "Commands:"
        echo "  summary [--from DATE] [--to DATE]  Overall statistics"
        echo "  session <session_id>               Workflow trace for a session"
        echo "  paths [--from DATE] [--to DATE]    Common workflow path analysis"
        echo "  recent [--n COUNT]                 Last N invocations (default 20)"
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "Run 'summ-stats help' for usage."
        exit 1
        ;;
esac
```

- [ ] **Step 1: Add tests for new commands**

Append to `tests/telemetry/test-summ-stats.sh` (before the final `echo "Done."`):

```bash
# Test 4: session command shows workflow trace
assert_session_trace() {
    local output
    output=$(bash "$SUMM_STATS" session sess0001 2>&1)
    if echo "$output" | grep -q "summ:brainstorming" && echo "$output" | grep -q "summ:writing-plans"; then
        echo "  [PASS] session shows brainstorming and writing-plans"
    else
        echo "  [FAIL] session trace incomplete"
        echo "$output"
        return 1
    fi
}

# Test 5: recent command shows entries
assert_recent() {
    local output
    output=$(bash "$SUMM_STATS" recent --n 5 2>&1)
    if echo "$output" | grep -q "brainstorming" && echo "$output" | grep -q "writing-plans"; then
        echo "  [PASS] recent shows skill entries"
    else
        echo "  [FAIL] recent output missing skills"
        echo "$output"
        return 1
    fi
}

# Test 6: paths command shows workflow chains
assert_paths() {
    local output
    output=$(bash "$SUMM_STATS" paths 2>&1)
    if echo "$output" | grep -q "→"; then
        echo "  [PASS] paths shows arrow-separated chains"
    else
        echo "  [FAIL] paths output missing chains"
        echo "$output"
        return 1
    fi
}

assert_session_trace
assert_recent
assert_paths
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/telemetry/test-summ-stats.sh`
Expected: New assertions (4-6) FAIL — commands not implemented yet

- [ ] **Step 3: Add the three new functions to `scripts/summ-stats`**

Add `cmd_session`, `cmd_recent`, `cmd_paths` functions and update the `case` statement (code above).

- [ ] **Step 4: Run all tests**

Run: `bash tests/telemetry/test-summ-stats.sh`
Expected: All 6 assertions PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/summ-stats tests/telemetry/test-summ-stats.sh
git commit -m "feat(telemetry): add session, recent, paths subcommands to summ-stats"
```

---

### Task 6: Log Rotation

**Files:**
- Modify: `scripts/summ-stats`

Add a `rotate_logs` function that runs at the start of every `summ-stats` invocation. It reads `config.json` for `retention_days` and deletes log files older than that threshold.

**Add this function to `scripts/summ-stats` before the `collect_log_files` function:**

```bash
rotate_logs() {
    local config="${TELEM_DIR}/config.json"
    local retention_days
    retention_days=$(jq -r '.retention_days // 90' "$config" 2>/dev/null || echo "90")

    if [ ! -d "$LOG_DIR" ]; then
        return 0
    fi

    local cutoff
    cutoff=$(date -u -d "-${retention_days} days" +%Y-%m-%d 2>/dev/null || date -u -v-"${retention_days}"d +%Y-%m-%d 2>/dev/null || return 0)

    for f in "${LOG_DIR}"/*.jsonl; do
        [ -f "$f" ] || continue
        local file_date
        file_date=$(basename "$f" .jsonl)
        if [ "$file_date" \< "$cutoff" ]; then
            rm "$f"
        fi
    done
}
```

**Add the call** at the very start of the script, right after the `TELEM_DIR`/`LOG_DIR` variable assignments (before argument parsing):

```bash
# Rotate old logs on each run
rotate_logs
```

- [ ] **Step 1: Test rotation manually**

```bash
# Create a stale log file
export HOME=/tmp/telem-rotation-test
mkdir -p ~/.claude/skill-telemetry/logs
echo '{"enabled":true,"retention_days":90}' > ~/.claude/skill-telemetry/config.json
# Create a file dated 100 days ago
old_date=$(date -u -d "-100 days" +%Y-%m-%d)
echo '{"test":"old"}' > ~/.claude/skill-telemetry/logs/${old_date}.jsonl
# Run summ-stats
bash scripts/summ-stats summary 2>&1
# Verify old file deleted
if [ ! -f ~/.claude/skill-telemetry/logs/${old_date}.jsonl ]; then
    echo "[PASS] old log file rotated"
else
    echo "[FAIL] old log file still exists"
fi
# Cleanup
rm -rf /tmp/telem-rotation-test
```

Expected: "[PASS] old log file rotated"

- [ ] **Step 2: Commit**

```bash
git add scripts/summ-stats
git commit -m "feat(telemetry): add log rotation based on retention_days config"
```
