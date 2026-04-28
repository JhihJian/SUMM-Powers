# Changelog

## 5.0.7-summ.1.8 (2026-04-28)

### Added

- **lint-skills.sh**: Automated skill format and quality validation. Checks frontmatter (name/description required, directory name match, naming convention, description length), markdown link integrity, top-level heading, line count warning (>300 lines), usage trigger guidance, and actionable placeholder detection. Supports `-v` (verbose) and `-q` (quiet) modes, single-skill targeting, and CI exit codes.
- **skill-template.md**: Standardized template for new skills with sections: When to Use, When NOT to Use, Process (with DOT flowchart), Common Scenarios, Anti-Patterns, Key Principles.
- **mattpocock/skills integration analysis**: Comprehensive gap analysis at `docs/superpowers/specs/2026-04-28-mattpocock-skills-integration-analysis.md` identifying 16 improvement opportunities across new skills (A1-A9), existing skill enhancements (B1-B4), and infrastructure (D1-D3).

### Changed

- **VERSION.md**: Added full version roadmap from v1.8 through v2.3 with dependency graph.

## 5.0.7-summ.1.7 (2026-04-21)

### Added

- **upstream-sync skill**: Cherry-pick-based upstream sync workflow with commit categorization (8 categories), conflict resolution priority, self-review checklist, and self-improvement loop that refines exclusion rules after each sync.
- **Upstream sync records**: `docs/upstream-sync-records.md` tracks sync history with per-commit categorization tables and self-review notes.

### Changed

- **skill-finder**: Improved external skill discovery and loading.
- **using-summ**: Minor updates to skill discovery documentation.

## 5.0.7-summ.1.6 (2026-04-15)

### Added

- **Batch generation for writing-plans**: Two-phase plan generation — first produce a task index with complexity estimates (S/M/L), then generate detailed task content in dynamically-sized batches (≤3M budget per batch). Prevents quality degradation, inconsistencies, and generation interruptions on large plans. Always-on (no threshold check).

### Changed

- **Self-review checklist**: Added "Index consistency" check to verify task index matches actual generated tasks.

## 5.0.7-summ.1.5 (2026-04-13)

### Upstream Sync (v5.0.4–v5.0.7)

Cherry-picked from [obra/superpowers](https://github.com/obra/superpowers) up to commit `1f20bef`.

### Fixed

- **Inline self-review**: Replace subagent review loops with lightweight inline self-review. Single-pass plan review with raised issue bar.
- **Brainstorm server restructure**: Separate content and state into peer directories. Fix owner-PID lifecycle monitoring for cross-platform reliability.
- **Brainstorm server on Windows**: Auto-detect Windows/Git Bash (`OSTYPE=msys*`, `MSYSTEM`) and switch to foreground mode, fixing silent server failure caused by `nohup`/`disown` process reaping. (fixes #737, based on #740)
- **Brainstorm owner-PID on Windows**: Skip `BRAINSTORM_OWNER_PID` lifecycle monitoring on Windows/MSYS2 where the PID namespace is invisible to Node.js. ([#770](https://github.com/obra/superpowers/issues/770))
- **Copilot CLI platform detection**: Add Copilot CLI detection to sessionStart context injection.
- **stop-server.sh reliability**: Verify the server process actually died before reporting success. Escalates to `SIGKILL` if needed. ([#723](https://github.com/obra/superpowers/issues/723))

### Not Synced (upstream only)

The following upstream fixes exist but are not yet synced to SUMM-Powers:

- Portable shebangs (`#!/usr/bin/env bash`) — [#700](https://github.com/obra/superpowers/pull/700)
- POSIX-safe hook script (`$0` vs `BASH_SOURCE`) — [#553](https://github.com/obra/superpowers/pull/553)
- Bash 5.3+ hook hang (`printf` vs heredoc) — [#572](https://github.com/obra/superpowers/pull/572)
- Cursor-compatible hooks — [#709](https://github.com/obra/superpowers/pull/709)
- OpenCode plugin auto-register and path fixes
- SessionStart hook `--resume` fix

### Known Issues

(None currently tracked.)
