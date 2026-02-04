# Design: Rename Superpowers to SUMM

**Date:** 2026-02-04
**Status:** Approved
**Repository:** https://github.com/JhihJian/SUMM-Powers

## Overview

Forked from `obra/superpowers`, this project needs to be renamed to SUMM with consistent branding across all files.

## Naming Changes

| Old | New |
|-----|-----|
| `superpowers:brainstorming` | `summ:brainstorming` |
| `superpowers:writing-plans` | `summ:writing-plans` |
| `superpowers:executing-plans` | `summ:executing-plans` |
| `superpowers:using-git-worktrees` | `summ:using-git-worktrees` |
| `superpowers:finishing-a-development-branch` | `summ:finishing-a-development-branch` |
| `superpowers:subagent-driven-development` | `summ:subagent-driven-development` |
| `superpowers:code-reviewer` | `summ:code-reviewer` |
| `superpowers:test-driven-development` | `summ:test-driven-development` |
| `superpowers:systematic-debugging` | `summ:systematic-debugging` |
| `superpowers:verification-before-completion` | `summ:verification-before-completion` |
| `using-superpowers` (directory) | `using-summ` |

## Files to Update

### Plugin Configuration
- `.claude-plugin/marketplace.json` - marketplace name
- `.claude-plugin/plugin.json` - plugin name, homepage, repository

### Commands (3 files)
- `commands/brainstorm.md`
- `commands/write-plan.md`
- `commands/execute-plan.md`

### Skills (all SKILL.md files with namespace references)
- `skills/brainstorming/SKILL.md`
- `skills/executing-plans/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/writing-skills/SKILL.md`
- `skills/systematic-debugging/SKILL.md`
- `skills/requesting-code-review/SKILL.md`

### Documentation
- `README.md`
- `docs/testing.md`

### Scripts
- `hooks/session-start.sh`

### Directory Rename
- `skills/using-superpowers/` → `skills/using-summ/`

## New URLs
- Homepage: https://github.com/JhihJian/SUMM-Powers
- Repository: https://github.com/JhihJian/SUMM-Powers
- Issues: https://github.com/JhihJian/SUMM-Powers/issues
