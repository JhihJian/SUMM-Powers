# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SUMM-Powers is a fork of [obra/superpowers](https://github.com/obra/superpowers) — a skills-based development workflow system for coding agents (Claude Code, Gemini CLI, Copilot CLI). Skills are markdown documents that guide agent behavior through structured workflows (TDD, brainstorming, debugging, code review, etc.).

The fork tracks upstream via cherry-pick sync (see `.upstream-sync` for the anchor commit).

## Repository Structure

- `skills/<name>/SKILL.md` — Skill definitions. Each skill is a self-contained markdown file with YAML frontmatter (`name`, `description`). Skills are loaded via the `Skill` tool at runtime.
- `commands/` — Slash command definitions (thin wrappers that invoke the corresponding skill).
- `agents/` — Agent definitions for subagent dispatch (e.g., `code-reviewer.md`).
- `hooks/` — SessionStart hook (`hooks/session-start`) that injects the `using-summ` skill content into every new session. Platform detection handles Claude Code, Cursor, and Copilot CLI.
- `.claude-plugin/` — Plugin manifest (`plugin.json`) and marketplace registration (`marketplace.json`).
- `tests/` — Test suites organized by test type (see Testing below).
- `docs/superpowers/specs/` — Design specs produced by brainstorming workflow.
- `docs/superpowers/plans/` — Implementation plans produced by writing-plans workflow.
- `external-skills/` — Deprecated; external skills now load into `skills/ext-<id>/` (gitignored).
- `skills/brainstorming/scripts/` — WebSocket brainstorm server (Node.js) for real-time visual companion.

## Testing

Tests use `claude -p` (headless mode) to verify skills load correctly and agents follow them.

```bash
# Run all fast tests
./tests/claude-code/run-skill-tests.sh

# Run integration tests (10-30 min)
./tests/claude-code/run-skill-tests.sh --integration

# Run a single test
./tests/claude-code/run-skill-tests.sh --test test-subagent-driven-development.sh

# Verbose output
./tests/claude-code/run-skill-tests.sh --verbose

# Brainstorm server tests (Node.js)
cd tests/brainstorm-server && npm test
```

Test helpers in `tests/claude-code/test-helpers.sh` provide `run_claude`, `assert_contains`, `assert_not_contains`, `assert_count`, `assert_order`.

## Key Architecture Concepts

### Skill System
Skills are discovered at session start via the `using-summ` skill injected by the SessionStart hook. The hook reads `skills/using-summ/SKILL.md` and injects it as context. All other skills are loaded on-demand via the `Skill` tool.

### Workflow Pipeline
The core development workflow flows through skills in order: `brainstorming` → `using-git-worktrees` → `writing-plans` → `executing-plans`/`subagent-driven-development` → `requesting-code-review` → `finishing-a-development-branch`. `test-driven-development` applies during implementation; `systematic-debugging` applies during debugging.

### Subagent-Driven Development
The `subagent-driven-development` skill dispatches fresh subagents per task with two-stage review: spec compliance first, then code quality. Reviewer prompts live alongside the skill in `spec-reviewer-prompt.md` and `code-quality-reviewer-prompt.md`.

### Batch Plan Generation
`writing-plans` uses batch generation — first produces a task index with complexity estimates, then generates detailed content in batches (token budget ≤3M per batch).

### Upstream Sync
`skills/upstream-sync/` handles cherry-pick-based sync from `obra/superpowers`. Sync records are in `docs/upstream-sync-records.md`.

## Writing New Skills

Follow `skills/writing-skills/SKILL.md` — it applies TDD to documentation: write pressure test scenarios, verify baseline failure, write the skill, verify compliance, refactor. Each skill needs a `SKILL.md` with YAML frontmatter (`name`, `description`).

## Conventions

- Shell scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- All text files use LF line endings (enforced by `.gitattributes`).
- Plugin version is in `.claude-plugin/plugin.json` — follows pattern `<upstream-version>-summ.<fork-version>`.
- The brainstorm server in `skills/brainstorming/scripts/` is a Node.js WebSocket server; Windows compatibility requires foreground mode (no `nohup`/`disown`).
- Design specs go to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.
- Implementation plans go to `docs/superpowers/plans/`.
