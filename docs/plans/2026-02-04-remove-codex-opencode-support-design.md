# Design: Removal of .codex and .opencode Support

**Date:** 2026-02-04
**Status:** Approved
**Author:** Claude (via brainstorming)

## Overview

Remove all platform compatibility code for .codex and .opencode, simplifying the project to be Claude Code-only. These integrations are loosely coupled and can be removed cleanly without affecting core functionality.

## Scope

### What Will Be Removed

1. **Directories**
   - `.codex/` - Complete directory with CLI script and installation guide
   - `.opencode/` - Complete directory with plugin and installation guide
   - `tests/opencode/` - Entire test suite for OpenCode

2. **Documentation Files**
   - `docs/README.codex.md` - Codex user guide
   - `docs/README.opencode.md` - OpenCode user guide
   - `docs/plans/2025-11-22-opencode-support-design.md` - Design document
   - `docs/plans/2025-11-22-opencode-support-implementation.md` - Implementation plan

3. **Documentation Modifications**
   - `README.md` - Remove lines 29-78 (multi-platform installation section)
   - `RELEASE-NOTES.md` - Remove all entries about OpenCode and Codex support
   - `skills/writing-skills/SKILL.md` - Remove Codex reference (line 12)

### What Will Be Retained

1. `lib/skills-core.js` - Shared utilities (kept for potential future use)
2. All core skills in `skills/`
3. Native Claude Code plugin functionality
4. Core skill loading mechanisms

## Execution Steps

1. Delete directories:
   ```bash
   rm -rf .codex .opencode tests/opencode
   ```

2. Delete documentation files:
   ```bash
   rm docs/README.codex.md docs/README.opencode.md
   rm docs/plans/2025-11-22-opencode-support-*.md
   ```

3. Edit `README.md` to remove lines 29-78

4. Fix `skills/writing-skills/SKILL.md` line 12

5. Clean up `RELEASE-NOTES.md` by removing platform-specific entries

6. Verify no remaining references to removed platforms

## Verification

After removal:
- Search for any remaining `.codex` or `.opencode` references
- Confirm Claude Code plugin still works
- Verify documentation has no broken links
- Ensure clean git status

## Impact

- **Files removed:** ~20+ files
- **Lines removed:** ~1,000+
- **Architecture simplified:** Single platform focus
- **Functionality preserved:** All core skills and Claude Code integration remain intact
