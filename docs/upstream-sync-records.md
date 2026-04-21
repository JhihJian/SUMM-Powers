# Upstream Sync Records (上游同步记录)

Tracking syncs from [obra/superpowers](https://github.com/obra/superpowers) to SUMM-Powers fork.

## Current Sync Point

- **Last synced upstream SHA**: `b557648` (formatting)
- **Last sync date**: 2026-04-21
- **Upstream has new commits since last sync**: No

## History

### 2026-04-21 Sync (Dry-run test)

- **Upstream range**: `917e5f5..b557648`
- **Commits analyzed**: 16
- **Cherry-picked**: 0 commits
- **Skipped**: 16 commits
- **Conflicts**: 0

### Skipped
| SHA | Message | Category | Reason |
|-----|---------|----------|--------|
| `b557648` | formatting | formatting | README formatting only |
| `9f42444` | formatting | formatting | README formatting only |
| `99e4c65` | reorder installs | formatting | README reorder only |
| `a5dd364` | README updates for Codex | docs | Codex-specific README content |
| `c4bbe65` | terminology cleanups | codex | sync-to-codex-plugin.sh |
| `34c17ae` | sync-to-codex: seed defaultPrompt | codex | sync-to-codex-plugin.sh |
| `f9b088f` | Merge PR #1165 | codex | Codex plugin tooling merge |
| `bc25777` | sync-to-codex: anchor EXCLUDES | codex | sync-to-codex-plugin.sh |
| `bcdd7fa` | sync-to-codex: exclude assets/ | codex | sync-to-codex-plugin.sh |
| `6149f36` | sync-to-codex: align plugin.json | codex | sync-to-codex-plugin.sh |
| `777a977` | sync-to-codex: mirror CODE_OF_CONDUCT | codex | sync-to-codex-plugin.sh |
| `da283df` | remove things we dont need | codex | sync-to-codex-plugin.sh |
| `ac1c715` | rewrites sync tool | codex | sync-to-codex-plugin.sh |
| `8c8c5e8` | adds codex plugin tooling | codex | sync-to-codex-plugin.sh |
| `a5d36b1` | remove vestigial CHANGELOG | refactor | We maintain our own CHANGELOG |
| `a569527` | Merge PR #1163 remove-stray-changelog | refactor | Same as a5d36b1 |

### Self-Review
- **What went well**: Categorization was fast — 14/16 commits auto-skipped by codex exclusion rule. The exclusion rules work as designed.
- **What could improve**: 16 commits in one batch was easy, but the skill lacks guidance for when upstream has 100+ commits (batch processing strategy). Also no explicit instruction for the "evaluate case-by-case" category to speed up decisions.
- **Strategy adjustments**: Add `scripts/sync-to-codex-plugin.sh` to explicit exclusion paths. Codify README-only changes as auto-skip when Codex-related.

---

### 2026-04-07 Sync

- **Upstream range**: `363923f..917e5f5` (v5.0.2 to v5.0.7)
- **Commits analyzed**: ~40+
- **Cherry-picked**: ~15 commits
- **Skipped**: ~25+ commits
- **Conflicts**: Multiple (resolved manually)
- **Sync commit**: `4016e61`

### Cherry-picked
- Portable shebangs (`#!/usr/bin/env bash`) for NixOS/FreeBSD/macOS
- POSIX-safe `$0` replacement for `BASH_SOURCE` (fixes dash error)
- Printf replacement for heredoc (fixes bash 5.3+ hang)
- SessionStart hook no longer fires on `--resume`
- Windows brainstorm server lifecycle improvements
- ESM/CommonJS module conflict resolution
- writing-skills frontmatter documentation fix
- Owner-PID lifecycle monitoring for cross-platform reliability
- Owner-PID false positive fix for different users
- Copilot CLI platform detection for sessionStart
- Brainstorm server content/state separation
- Review loop simplification

### Skipped
- Codex/OpenCode plugin tooling (Codex-specific)
- sync-to-codex-plugin infrastructure
- Code formatting-only changes
- Test infrastructure for OpenCode
- Codex native skills support

### Self-Review
- **What went well**: Cherry-pick approach worked well for selective syncing
- **What could improve**: Earlier sync frequency would reduce conflict complexity
- **Strategy adjustments**: Sync more frequently (monthly instead of per-release); auto-skip Codex/OpenCode commits

---

### 2026-03-14 Initial Sync

- **Upstream range**: Full merge from `27b93db` to `363923f` (v5.0.2)
- **Commits analyzed**: Full release
- **Method**: Merge commit (not cherry-pick)
- **Sync commit**: `468be96`

### Notes
- Initial fork sync was done via merge, not cherry-pick
- All subsequent syncs use cherry-pick approach for better control
