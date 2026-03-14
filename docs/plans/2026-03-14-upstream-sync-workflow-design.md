# Upstream Sync Workflow Design

## Overview

This document defines the workflow for syncing the SUMM-Powers fork with the upstream [obra/superpowers](https://github.com/obra/superpowers) repository while maintaining independent development.

## Goals

- Keep SUMM-Powers as an independent derivative with custom features (SUMM-Todo integration)
- Periodically sync with upstream to adopt valuable improvements
- Handle conflicts case-by-case with careful evaluation
- Maintain clear version tracking for both upstream and custom changes

## Version Numbering

**Format:** `v<upstream-version>-summ.<custom-version>`

**Example:** `v5.0.2-summ.1.1`
- `5.0.2` = Upstream baseline version
- `1.1` = Independent SUMM version (free to evolve)

**Evolution Examples:**

| Scenario | Version Change |
|----------|----------------|
| Minor custom update | v5.0.2-summ.1.1 → v5.0.2-summ.1.2 |
| Major custom update | v5.0.2-summ.1.2 → v5.0.2-summ.2.0 |
| Sync to new upstream | v5.0.2-summ.2.0 → v5.0.3-summ.2.1 |
| Upstream + custom update | v5.0.3-summ.2.1 → v5.0.3-summ.2.2 |

**Files to Update:**
- `.claude-plugin/plugin.json` - `version` field
- `.claude-plugin/marketplace.json` - `version` field

## One-Time Setup

```bash
# Add upstream remote
git remote add upstream https://github.com/obra/superpowers.git

# Verify configuration
git remote -v
# origin    git@github.com:Jhihjian/SUMM-Powers.git (fetch)
# upstream  https://github.com/obra/superpowers.git (fetch)
```

## Sync Workflow

**Steps for each sync:**

```bash
# 1. Ensure clean working directory
git status

# 2. Create backup branch (safety net)
git branch backup-$(date +%Y%m%d)

# 3. Fetch latest upstream
git fetch upstream

# 4. Preview changes (decide whether to proceed)
git log HEAD..upstream/main --oneline
git diff HEAD upstream/main --stat

# 5. Execute merge
git merge upstream/main

# 6. Resolve conflicts case-by-case
# Git will mark conflicted files
# Options:
#   - git checkout --ours <file>    # Keep your version
#   - git checkout --theirs <file>  # Use upstream version
#   - Manual edit                   # Combine both changes

# 7. Test and verify
# Run tests or manually verify functionality

# 8. Update version and commit
# Edit plugin.json and marketplace.json
git commit -am "chore: sync upstream v5.0.x"
```

## Sync Frequency

**Recommended triggers:**

| Condition | Priority | Notes |
|-----------|----------|-------|
| Upstream new release | High | Check RELEASE-NOTES.md for value |
| Security/bug fixes | High | Verify if affects your usage |
| New features/improvements | Medium | Sync based on need |
| Major refactoring | Low | Wait for stability |

**Frequency recommendation:**
- **Ideal:** Check every 1-2 months
- **Minimum:** Sync quarterly to avoid excessive drift

**Quick check command:**
```bash
git fetch upstream && git log HEAD..upstream/main --oneline
```

## Documentation

### UPSTREAM-SYNC.md

Create a sync log to track history:

```markdown
# Upstream Sync Log

## 2026-03-14 - Sync to v5.0.2
- Merged 101 commits from obra/superpowers
- Conflicts resolved:
  - skills/writing-plans/SKILL.md: kept SUMM-Todo integration
  - skills/executing-plans/SKILL.md: merged upstream context isolation
- New features adopted:
  - Subagent context isolation
  - Zero-dep brainstorm server
- Version: v5.0.2-summ.1.1
```

### README.md Addition

Add fork description:

```markdown
## About This Fork

This is a customized fork of [obra/superpowers](https://github.com/obra/superpowers)
with SUMM-Todo integration.

- Upstream version: v5.0.2
- SUMM version: v5.0.2-summ.1.1
```

## Summary

1. Add `upstream` remote pointing to obra/superpowers
2. Use version format: `v<upstream>-summ.<custom>`
3. Periodic merge with backup branches
4. Case-by-case conflict evaluation
5. Document sync history in UPSTREAM-SYNC.md
