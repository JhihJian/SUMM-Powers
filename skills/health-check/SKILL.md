---
name: health-check
description: Perform comprehensive project health checks with fast (read-only) and full (build/test/dependency) modes, generating detailed Markdown reports with actionable suggestions
---

# Health Check Skill

## Overview

This skill performs comprehensive health checks on your project and generates a detailed Markdown report. The health check is **report-only** — it will never block your workflow or make automatic changes to your codebase. The report highlights issues, warnings, and suggestions to help you maintain project health.

## Modes

| Mode | Description | Checks | Duration |
|------|-------------|--------|----------|
| **Fast** | Default mode; read-only checks only | 1-5 (Commit, Branch, Code-Doc, Doc, Skill) | < 1 minute |
| **Full** | Includes build, test, and dependency checks | All 9 checks | 2-10 minutes |

**Usage:**
- Fast mode (default): Just run the skill normally
- Full mode: Specify "full mode" or "run full health check" when invoking

## Workflow

1. **Determine mode** — Default to Fast unless "full mode" is requested
2. **Detect project type** — Identify package.json, Cargo.toml, go.mod, pyproject.toml, etc.
3. **Run checks** — Execute each check based on mode
4. **Generate report** — Create Markdown report with summary and details
5. **Show summary** — Display key findings and suggestions

## Check Items

### 1. 提交状态 (Commit Status) — FAST

**Purpose:** Verify clean working directory and recent activity

**Check Instructions:**
```bash
# Check for uncommitted changes
git status --short

# Check for recent commits (within last 7 days)
git log --since="7 days ago" --oneline | head -5

# Check for untracked files (excluding .git/ and node_modules/)
git ls-files --others --exclude-standard | head -10
```

**PASS Criteria:**
- No uncommitted changes (empty `git status --short`)
- At least one commit within the last 7 days
- No untracked files (or only expected files like .env.example)

**WARN Criteria:**
- Uncommitted changes present
- No commits within the last 7 days (but within 30 days)
- Few untracked files (< 5)

**FAIL Criteria:**
- No commits within the last 30 days
- Many untracked files (≥ 10)

**SKIP Criteria:**
- Not a git repository

---

### 2. 分支同步 (Branch Sync) — FAST

**Purpose:** Verify branch synchronization with remote and identify stale branches

**Check Instructions:**
```bash
# Check current branch ahead/behind status
git rev-list --left-right --count HEAD...@{u} 2>/dev/null || echo "No upstream"

# List all branches with last commit date
git for-each-ref --format='%(refname:short) %(committerdate:relative)' refs/heads/

# Check for stale branches (no commits in 90+ days)
git for-each-ref --format='%(refname:short) %(committerdate:relative)' refs/heads/ | grep -E "[89][0-9] days ago|[0-9]+ (months|years) ago"
```

**PASS Criteria:**
- Current branch is up-to-date with remote (no ahead/behind)
- No stale branches (all branches active within 90 days)

**WARN Criteria:**
- Current branch ahead or behind remote by 1-5 commits
- 1-2 stale branches present

**FAIL Criteria:**
- Current branch ahead or behind remote by > 5 commits
- 3+ stale branches present
- No remote configured

**SKIP Criteria:**
- Not a git repository
- No remote configured

---

### 3. 代码-文档一致性 (Code-Doc Consistency) — FAST

**Purpose:** Verify code and documentation stay in sync

**Check Instructions:**
```bash
# Find code files (based on project type)
if [ -f "package.json" ]; then
  find src/ -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" 2>/dev/null | head -20
elif [ -f "Cargo.toml" ]; then
  find src/ -name "*.rs" 2>/dev/null | head -20
elif [ -f "go.mod" ]; then
  find . -name "*.go" -not -path "./vendor/*" 2>/dev/null | head -20
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  find . -name "*.py" -not -path "./venv/*" -not -path "./.venv/*" 2>/dev/null | head -20
fi

# Find documentation files
find . -name "*.md" -not -path "./node_modules/*" -not -path "./target/*" -not -path "./.git/*" 2>/dev/null | head -20

# Check for outdated TODO/FIXME comments
grep -r "TODO\|FIXME" --include="*.ts" --include="*.js" --include="*.rs" --include="*.go" --include="*.py" . 2>/dev/null | head -10
```

**PASS Criteria:**
- Documentation files exist and are recently modified (within 30 days)
- No TODO/FIXME comments older than 60 days
- README.md exists and mentions key features

**WARN Criteria:**
- Documentation files exist but not recently modified (30-90 days)
- 1-5 TODO/FIXME comments present
- README.md missing or outdated

**FAIL Criteria:**
- No documentation files found
- Many TODO/FIXME comments (≥ 10)
- README.md completely missing

**SKIP Criteria:**
- No code files detected

---

### 4. 文档完整性 (Doc Completeness) — FAST

**Purpose:** Verify required documentation files exist and are complete

**Check Instructions:**
```bash
# Check for required documentation
for doc in README.md CONTRIBUTING.md LICENSE CHANGELOG.md .github/CONTRIBUTING.md docs/CLAUDE.md CLAUDE.md; do
  if [ -f "$doc" ]; then
    echo "✓ $doc exists"
    wc -l "$doc" | awk '{print "  Lines:", $1}'
  else
    echo "✗ $doc missing"
  fi
done

# Check for API docs (if applicable)
if [ -f "package.json" ]; then
  [ -d "docs/api" ] && echo "✓ API docs exist" || echo "✗ API docs missing"
fi
```

**PASS Criteria:**
- README.md exists with ≥ 20 lines
- At least one of: CONTRIBUTING.md or .github/CONTRIBUTING.md
- LICENSE file exists

**WARN Criteria:**
- README.md exists but < 20 lines
- CONTRIBUTING.md missing
- CHANGELOG.md missing

**FAIL Criteria:**
- README.md missing
- LICENSE file missing

**SKIP Criteria:**
- N/A (always run)

---

### 5. 技能完整性 (Skill Integrity) — FAST

**Purpose:** Validate SKILL.md frontmatter and structure (for SUMM-Powers projects)

**Check Instructions:**
```bash
# Find all SKILL.md files
find skills/ -name "SKILL.md" 2>/dev/null

# Validate frontmatter for each SKILL.md
for skill in skills/*/SKILL.md; do
  if [ -f "$skill" ]; then
    echo "Checking $skill:"
    grep -E "^name:|^description:" "$skill" || echo "  ✗ Missing frontmatter"
    # Check for required sections
    grep -q "## Overview" "$skill" && echo "  ✓ Overview section" || echo "  ✗ Missing Overview"
  fi
done
```

**PASS Criteria:**
- All SKILL.md files have valid frontmatter (name and description)
- All SKILL.md files have Overview section

**WARN Criteria:**
- Some SKILL.md files missing recommended sections
- Minor frontmatter inconsistencies

**FAIL Criteria:**
- SKILL.md files missing frontmatter
- SKILL.md files missing name or description

**SKIP Criteria:**
- No skills/ directory found (not a SUMM-Powers project)

---

### 6. 构建验证 (Build Verification) — FULL

**Purpose:** Verify project builds successfully

**Check Instructions:**
```bash
# Project-type specific build commands
if [ -f "package.json" ]; then
  npm run build 2>&1 || yarn build 2>&1 || pnpm build 2>&1
elif [ -f "Cargo.toml" ]; then
  cargo build --release 2>&1
elif [ -f "go.mod" ]; then
  go build ./... 2>&1
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  python -m build 2>&1 || pip install -e . 2>&1
elif [ -f "Makefile" ]; then
  make build 2>&1
fi
```

**PASS Criteria:**
- Build completes successfully (exit code 0)
- No build warnings or errors

**WARN Criteria:**
- Build completes but with warnings
- Build takes longer than expected (> 2 minutes)

**FAIL Criteria:**
- Build fails with errors
- No build command found

**SKIP Criteria:**
- Fast mode (not running full checks)

---

### 7. 单元测试 (Unit Tests) — FULL

**Purpose:** Verify unit tests pass and meet coverage thresholds

**Check Instructions:**
```bash
# Project-type specific test commands
if [ -f "package.json" ]; then
  npm test -- --coverage 2>&1 || yarn test --coverage 2>&1 || pnpm test --coverage 2>&1
  # Check coverage threshold (80%)
  cat coverage/coverage-summary.json 2>/dev/null | grep -o '"total".*"pct":[0-9.]*' || echo "No coverage data"
elif [ -f "Cargo.toml" ]; then
  cargo test 2>&1
  # Check coverage with tarpaulin if available
  cargo tarpaulin --out Stdout 2>&1 || echo "Coverage tool not installed"
elif [ -f "go.mod" ]; then
  go test ./... -cover 2>&1
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  python -m pytest --cov=. --cov-report=term-missing 2>&1
fi
```

**PASS Criteria:**
- All tests pass (exit code 0)
- Coverage ≥ 80% (if coverage data available)
- No skipped tests (or minimal skipped tests)

**WARN Criteria:**
- All tests pass but coverage 60-79%
- 1-5 tests skipped
- Some tests have long duration (> 1s each)

**FAIL Criteria:**
- One or more tests fail
- Coverage < 60%
- Many tests skipped (≥ 10)

**SKIP Criteria:**
- Fast mode (not running full checks)
- No test command found

---

### 8. E2E 测试 (E2E Tests) — FULL

**Purpose:** Verify end-to-end tests pass

**Check Instructions:**
```bash
# Project-type specific E2E test commands
if [ -f "package.json" ]; then
  npm run test:e2e 2>&1 || yarn test:e2e 2>&1 || pnpm test:e2e 2>&1 || npm run test:integration 2>&1
elif [ -f "Cargo.toml" ]; then
  cargo test --test '*' 2>&1
elif [ -f "go.mod" ]; then
  go test ./... -tags=integration 2>&1 || go test ./... -tags=e2e 2>&1
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  python -m pytest tests/e2e/ -v 2>&1 || python -m pytest tests/integration/ -v 2>&1
fi
```

**PASS Criteria:**
- All E2E tests pass (exit code 0)
- No timeouts or flaky test failures

**WARN Criteria:**
- All E2E tests pass but with warnings
- Some tests have long duration (> 10s each)

**FAIL Criteria:**
- One or more E2E tests fail
- Test suite times out
- No E2E test command found but E2E tests directory exists

**SKIP Criteria:**
- Fast mode (not running full checks)
- No E2E tests found (no tests/e2e/, tests/integration/, or test:e2e script)

---

### 9. 依赖健康 (Dependency Health) — FULL

**Purpose:** Audit dependencies for security vulnerabilities and outdated packages

**Check Instructions:**
```bash
# Project-type specific dependency audit
if [ -f "package.json" ]; then
  npm audit 2>&1 || yarn audit 2>&1 || pnpm audit 2>&1
  npm outdated 2>&1 || yarn outdated 2>&1 || pnpm outdated 2>&1
elif [ -f "Cargo.toml" ]; then
  cargo audit 2>&1 || cargo outdated 2>&1
  cargo update --dry-run 2>&1
elif [ -f "go.mod" ]; then
  go list -u -m all 2>&1
  go mod tidy 2>&1
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  pip-audit 2>&1 || safety check 2>&1
  pip list --outdated 2>&1
fi
```

**PASS Criteria:**
- No security vulnerabilities found
- No outdated dependencies (or only patch versions outdated)
- Dependency resolution successful

**WARN Criteria:**
- Low-severity vulnerabilities found
- 1-5 dependencies outdated (minor versions)
- Some dependencies have deprecation warnings

**FAIL Criteria:**
- High or critical severity vulnerabilities found
- Many dependencies outdated (≥ 10)
- Dependency resolution fails

**SKIP Criteria:**
- Fast mode (not running full checks)
- No package manager detected

---

## Report Format

Generate a Markdown report with the following structure:

```markdown
# Project Health Check Report

**Date:** [current date]
**Mode:** Fast / Full
**Project Type:** [detected type: Node.js / Rust / Go / Python / Other]
**Branch:** [current branch]

## Summary

| Metric | Value |
|--------|-------|
| Checks Passed | [N]/[total] |
| Checks with Warnings | [N] |
| Checks Failed | [N] |
| Checks Skipped | [N] |
| Overall Status | ✅ PASS / ⚠️ WARN / ❌ FAIL |

## Check Results

### 1. 提交状态 (Commit Status)
**Status:** ✅ PASS / ⚠️ WARN / ❌ FAIL / ⏭️ SKIP

**Details:**
- Uncommitted changes: [yes/no]
- Last commit: [date/ago]
- Untracked files: [count]

**Suggestions:** [actionable recommendations]

### 2. 分支同步 (Branch Sync)
**Status:** ✅ PASS / ⚠️ WARN / ❌ FAIL / ⏭️ SKIP

**Details:**
- Ahead/behind remote: [commits ahead / behind]
- Stale branches: [count]

**Suggestions:** [actionable recommendations]

[... repeat for all 9 checks ...]

## Recommendations

### High Priority
- [Critical issues requiring immediate attention]

### Medium Priority
- [Important issues to address soon]

### Low Priority
- [Nice-to-have improvements]

## Next Steps

1. [Specific action item 1]
2. [Specific action item 2]
3. [Specific action item 3]
```

---

## Project Adaptation

The health check automatically detects the project type and selects appropriate commands:

### Node.js Projects
- **Detection:** `package.json` present
- **Build:** `npm run build` / `yarn build` / `pnpm build`
- **Test:** `npm test` / `yarn test` / `pnpm test`
- **Coverage:** `--coverage` flag (Jest/Vitest)
- **Audit:** `npm audit` / `yarn audit` / `pnpm audit`
- **Outdated:** `npm outdated` / `yarn outdated` / `pnpm outdated`

### Rust Projects
- **Detection:** `Cargo.toml` present
- **Build:** `cargo build --release`
- **Test:** `cargo test`
- **Coverage:** `cargo tarpaulin` (if installed)
- **Audit:** `cargo audit` / `cargo outdated`
- **Update Check:** `cargo update --dry-run`

### Go Projects
- **Detection:** `go.mod` present
- **Build:** `go build ./...`
- **Test:** `go test ./... -cover`
- **E2E:** `go test ./... -tags=integration` or `-tags=e2e`
- **Outdated:** `go list -u -m all`
- **Tidy:** `go mod tidy`

### Python Projects
- **Detection:** `pyproject.toml`, `requirements.txt`, or `setup.py` present
- **Build:** `python -m build` or `pip install -e .`
- **Test:** `python -m pytest --cov=. --cov-report=term-missing`
- **E2E:** `pytest tests/e2e/` or `tests/integration/`
- **Audit:** `pip-audit` or `safety check`
- **Outdated:** `pip list --outdated`

### Generic Projects
- **Detection:** No package manager detected
- **Build:** Check for `Makefile` with `build` target
- **Test:** Check for `Makefile` with `test` target
- **Documentation:** Always run Fast mode checks

---

## Status Definitions

| Status | Meaning | Action Required |
|--------|---------|-----------------|
| ✅ **PASS** | Check completed successfully with no issues | None |
| ⚠️ **WARN** | Check completed but found minor issues | Review and address when convenient |
| ❌ **FAIL** | Check failed with significant issues | Address before next release |
| ⏭️ **SKIP** | Check was skipped (not applicable or mode-dependent) | None |

---

## Usage Examples

**Fast mode (default):**
```
/health-check
Run a health check
Check project health
```

**Full mode:**
```
/health-check full
Run a full health check
Check project health with build and tests
```

**Specific checks:**
```
Check commit status and branch sync
Verify documentation completeness
Run dependency audit
```
