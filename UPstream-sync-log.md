# Upstream Sync Log

## 2026-03-14 - Sync to v5.0.2

- Merged 101 commits from obra/superpowers
- Conflicts resolved:
  - `.codex/*`, `.opencode/*` - Kept deleted (SUMM focuses on Claude Code only)
  - `hooks/session-start.sh` - Kept SUMM version (upstream deleted this file)
  - `skills/executing-plans/SKILL.md` - Merged upstream context isolation + SUMM-Todo integration
  - `skills/writing-plans/SKILL.md` - Merged upstream changes + SUMM-Todo integration
  - `README.md` - Added "About This Fork" section
  - `RELEASE-NOTES.md` - Updated with new version format

### New features adopted:
- Zero-dependency brainstorm server
- Subagent context isolation principle
- Spec review loop in brainstorming
- Visual companion for brainstorming

### Version: v5.0.2-summ.1.1
