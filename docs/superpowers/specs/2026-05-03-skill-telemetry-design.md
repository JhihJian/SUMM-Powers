# Skill Invocation Telemetry

> Date: 2026-05-03
> Status: Draft

## Problem

SUMM-Powers has no visibility into how skills are used. We cannot answer: which skills are invoked most, how long they take, what workflow paths users follow, or which skills fail. Without this data, optimizing the skill library is guesswork.

## Solution

A lightweight telemetry system that uses Claude Code's `PreToolUse`/`PostToolUse` hooks to automatically record Skill tool invocations into local JSONL files, with a CLI tool (`summ-stats`) for querying and analysis.

## Architecture

```
Claude Code Session
  │
  ├─ SessionStart hook
  │    └─ Generate session_id → ~/.claude/skill-telemetry/.current-session
  │
  ├─ Skill tool call
  │    ├─ PreToolUse hook (matcher: "Skill")
  │    │    └─ Record "invoked" event → logs/YYYY-MM-DD.jsonl
  │    ├─ Skill executes...
  │    └─ PostToolUse hook (matcher: "Skill")
  │         └─ Record "completed" event → logs/YYYY-MM-DD.jsonl
  │
  └─ User analysis
       └─ summ-stats summary / session / paths / recent
            └─ Reads logs/*.jsonl + sessions-index.json
```

## Data Collection

### Hook Configuration

Add to `hooks/hooks.json`:

```json
{
  "PreToolUse": [
    {
      "matcher": "Skill",
      "hooks": [{
        "type": "command",
        "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" skill-telemetry pre",
        "async": true
      }]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Skill",
      "hooks": [{
        "type": "command",
        "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" skill-telemetry post",
        "async": true
      }]
    }
  ]
}
```

Both hooks run async to avoid blocking skill execution.

### Collection Script: `hooks/skill-telemetry`

A bash script with two modes:

- **pre**: Reads JSON from stdin (contains `tool_name` and `tool_input`), extracts skill name and args, writes an `invoked` event.
- **post**: Reads JSON from stdin, writes a `completed` event. Calculates duration by matching the most recent `invoked` event for the same skill in the same session.

Session ID is read from `~/.claude/skill-telemetry/.current-session`.

### SessionStart Integration

Extend the existing SessionStart hook to generate a session ID (UUID via `uuidgen` or `od -x /dev/urandom | head -1 | tr -d ' '`), write it to `.current-session`, and create an entry in `sessions-index.json`.

### Record Format (JSONL)

Each line is one event:

```json
{
  "ts": "2026-05-03T14:32:01.123Z",
  "session_id": "a1b2c3d4",
  "event": "invoked",
  "skill": "summ:brainstorming",
  "args_summary": "user wants to track skill invocations",
  "duration_ms": null
}
```

```json
{
  "ts": "2026-05-03T14:35:22.456Z",
  "session_id": "a1b2c3d4",
  "event": "completed",
  "skill": "summ:brainstorming",
  "args_summary": null,
  "duration_ms": 201333
}
```

Fields:
- `ts`: ISO 8601 timestamp
- `session_id`: Links events within one conversation
- `event`: `invoked` or `completed`
- `skill`: Skill name (as passed to the Skill tool)
- `args_summary`: First 200 chars of args for `invoked`, null for `completed`
- `duration_ms`: Milliseconds between invoked and completed, null for `invoked`

## Data Storage

### Directory Layout

```
~/.claude/skill-telemetry/
├── logs/
│   ├── 2026-05-03.jsonl
│   ├── 2026-05-04.jsonl
│   └── ...
├── sessions-index.json
├── .current-session
└── config.json
```

### Daily Files

Logs are split by date (UTC). This keeps files small, makes time-range queries efficient, and simplifies cleanup.

### sessions-index.json

```json
{
  "sessions": {
    "a1b2c3d4": {
      "started": "2026-05-03T14:30:00Z",
      "last_activity": "2026-05-03T15:20:00Z",
      "skills_invoked": 5,
      "files": ["2026-05-03.jsonl"]
    }
  }
}
```

### config.json

```json
{
  "enabled": true,
  "retention_days": 90,
  "log_dir": "~/.claude/skill-telemetry/logs"
}
```

### Log Rotation

No independent cron. The `summ-stats` CLI tool checks for expired files on each run and deletes logs older than `retention_days`.

## CLI Tool: `summ-stats`

Location: `scripts/summ-stats`. Bash script using `jq` for JSON parsing.

### Commands

**`summ-stats summary [--from DATE] [--to DATE]`**

Overall statistics:
- Total invocations
- Unique skills used
- Top N skills by invocation count (with percentage)
- Average duration per skill
- Completion rate (completed / invoked ratio)

**`summ-stats session <session_id>`**

Full workflow trace for one session:
- Session start/end time
- Chronological list of skill invocations with timestamps and durations
- Total session duration

**`summ-stats paths [--from DATE] [--to DATE]`**

Workflow path analysis:
- Extracts sequential skill invocation chains per session
- Aggregates and ranks by frequency
- Shows top N most common workflow paths

**`summ-stats recent [--n COUNT]`**

Last N invocation records, most recent first.

### Output Format

Plain text tables in the terminal. No TUI or interactive mode.

## Implementation Scope

### Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `hooks/hooks.json` | Modify | Add PreToolUse/PostToolUse entries |
| `hooks/skill-telemetry` | Create | Collection script (pre/post modes) |
| `hooks/session-start` | Modify | Add session ID generation |
| `scripts/summ-stats` | Create | CLI query tool |
| `~/.claude/skill-telemetry/` | Create at runtime | Data directory |

### Out of Scope

- No modification to any SKILL.md files
- No external databases (SQLite, etc.)
- No remote reporting or network calls
- No collection of code content, file paths, or sensitive user data
- No TUI or interactive dashboard
- No cross-user analytics (single-user local data only)

## Privacy

- All data stays local on the user's machine
- Only skill names and truncated args are recorded — no code, file contents, or conversation text
- `config.json` allows disabling telemetry entirely (`"enabled": false`)
- Data auto-expires after `retention_days` (default 90)
