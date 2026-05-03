# Health Check Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summ:subagent-driven-development (recommended) or summ:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a project health check skill that runs 9 check items across fast/full modes and generates a Markdown health report.

**Architecture:** Single SKILL.md with structured checklist — each check item has its own section with instructions, status criteria, and output format. A structural test validates the skill loads and contains all required sections.

**Tech Stack:** Markdown skill definition, bash structural test (grep-based), slash command wrapper.

---

## File Structure

| File | Responsibility |
|------|---------------|
| `skills/health-check/SKILL.md` | Main skill definition — frontmatter, overview, fast/full modes, 9 check items, report format, project adaptation |
| `commands/health-check.md` | Slash command wrapper — delegates to skill |
| `tests/claude-code/test-health-check.sh` | Structural verification — frontmatter validity, all 9 check sections present, report format section exists, mode instructions exist |

---

## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Create structural test | `tests/claude-code/test-health-check.sh` | M | TDD: test first, validate all 9 sections + frontmatter |
| 2 | Create SKILL.md | `skills/health-check/SKILL.md` | L | Full skill content with all 9 checks, two modes, report format |
| 3 | Create slash command | `commands/health-check.md` | S | Thin wrapper delegating to skill |
| 4 | Verify and commit | `tests/claude-code/test-health-check.sh` | S | Run test, commit |

---

### Batch 1 (Tasks 1-2)

### Task 1: Create Structural Test

**Files:**
- Create: `tests/claude-code/test-health-check.sh`

- [ ] **Step 1: Write the test file**

```bash
#!/usr/bin/env bash
# Test: Health Check Skill structural verification
# Verifies SKILL.md has valid frontmatter, all 9 check sections, mode instructions, and report format
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILLS_DIR="$(cd "$SCRIPT_DIR/../../skills" && pwd)"
SKILL_FILE="$SKILLS_DIR/health-check/SKILL.md"

echo "=== Test: Health Check Skill ==="
echo ""

# ============================================================
# Layer 1: Frontmatter verification
# ============================================================

echo "--- Layer 1: Frontmatter ---"
echo ""

# Test 1: SKILL.md exists
echo "Test 1: SKILL.md exists..."
if [ ! -f "$SKILL_FILE" ]; then
    echo "  [FAIL] skills/health-check/SKILL.md does not exist"
    exit 1
fi
echo "  [PASS] SKILL.md exists"

# Test 2: Valid YAML frontmatter with name
echo "Test 2: frontmatter has 'name: health-check'..."
name_line=$(head -5 "$SKILL_FILE" | grep "^name:" || true)
if [ -z "$name_line" ]; then
    echo "  [FAIL] Missing 'name:' in frontmatter"
    exit 1
fi
if ! echo "$name_line" | grep -q "health-check"; then
    echo "  [FAIL] name is not 'health-check'"
    exit 1
fi
echo "  [PASS] frontmatter name is health-check"

# Test 3: frontmatter has description
echo "Test 3: frontmatter has description..."
if ! head -10 "$SKILL_FILE" | grep -q "^description:"; then
    echo "  [FAIL] Missing 'description:' in frontmatter"
    exit 1
fi
echo "  [PASS] frontmatter has description"

# ============================================================
# Layer 2: Check items verification
# ============================================================

echo ""
echo "--- Layer 2: Check items (9 total) ---"
echo ""

check_items=(
    "提交状态\|Commit Status"
    "分支同步\|Branch Sync"
    "代码-文档一致性\|Code-Doc Consistency"
    "文档完整性\|Doc Completeness"
    "技能完整性\|Skill Integrity"
    "构建验证\|Build Verification"
    "单元测试\|Unit Tests"
    "E2E"
    "依赖健康\|Dependency Health"
)

i=4
for item in "${check_items[@]}"; do
    echo "Test $i: Check item '$item' exists..."
    if ! grep -qi "$item" "$SKILL_FILE"; then
        echo "  [FAIL] Missing check item: $item"
        exit 1
    fi
    echo "  [PASS] Check item '$item' found"
    i=$((i + 1))
done

# ============================================================
# Layer 3: Mode and report verification
# ============================================================

echo ""
echo "--- Layer 3: Modes and report ---"
echo ""

# Test 13: Fast mode instructions
echo "Test $i: Fast mode instructions exist..."
if ! grep -qi "fast" "$SKILL_FILE"; then
    echo "  [FAIL] Missing fast mode instructions"
    exit 1
fi
echo "  [PASS] Fast mode instructions found"
i=$((i + 1))

# Test 14: Full mode instructions
echo "Test $i: Full mode instructions exist..."
if ! grep -qi "full" "$SKILL_FILE"; then
    echo "  [FAIL] Missing full mode instructions"
    exit 1
fi
echo "  [PASS] Full mode instructions found"
i=$((i + 1))

# Test 15: Report format section
echo "Test $i: Report format section exists..."
if ! grep -qi "报告\|report" "$SKILL_FILE"; then
    echo "  [FAIL] Missing report format section"
    exit 1
fi
echo "  [PASS] Report format section found"
i=$((i + 1))

# Test 16: PASS/WARN/FAIL/SKIP status definitions
echo "Test $i: Status definitions (PASS/WARN/FAIL/SKIP)..."
for status in "PASS" "WARN" "FAIL" "SKIP"; do
    if ! grep -q "$status" "$SKILL_FILE"; then
        echo "  [FAIL] Missing status definition: $status"
        exit 1
    fi
done
echo "  [PASS] All status definitions found"
i=$((i + 1))

# Test 17: Project adaptation section
echo "Test $i: Project adaptation section..."
if ! grep -qi "project.*adapt\|项目.*适配\|probes\|detect.*package" "$SKILL_FILE"; then
    echo "  [FAIL] Missing project adaptation instructions"
    exit 1
fi
echo "  [PASS] Project adaptation section found"

echo ""
echo "=== All tests passed ==="
```

- [ ] **Step 2: Make test executable and run (expect FAIL)**

Run: `chmod +x tests/claude-code/test-health-check.sh && bash tests/claude-code/test-health-check.sh`
Expected: FAIL — `skills/health-check/SKILL.md` does not exist

- [ ] **Step 3: Commit test**

```bash
git add tests/claude-code/test-health-check.sh
git commit -m "test: add structural test for health-check skill (TDD baseline)"
```

---

### Task 2: Create SKILL.md

**Files:**
- Create: `skills/health-check/SKILL.md`

- [ ] **Step 1: Create skill directory**

Run: `mkdir -p skills/health-check`

- [ ] **Step 2: Write SKILL.md**

```markdown
---
name: health-check
description: Use when user asks to check project status, health, or readiness — runs 9 check items and generates a Markdown health report
---

# Health Check

Run project health checks and generate a Markdown report. Report only — no blocking.

## Modes

| Mode | Trigger | Checks |
|------|---------|--------|
| Fast (default) | `/health-check` or "检查项目状态" | 5 read-only checks |
| Full | `/health-check full` or "完整检查" | All 9 checks |

Fast mode takes seconds. Full mode runs builds and tests.

## Workflow

1. **Determine mode** — if user says "full" or "完整", run full mode; otherwise fast mode
2. **Detect project type** — probe for `package.json` / `Cargo.toml` / `go.mod` / `pyproject.toml` / `pom.xml` / `build.gradle` / `Makefile` / `skills/*/SKILL.md` (skills project)
3. **Run checks** in order below, collecting results per item
4. **Generate report** — write Markdown to `docs/health-report-YYYY-MM-DD.md`
5. **Show summary** — output the summary table to terminal

## Check Items

Each check produces one of: `PASS`, `WARN`, `FAIL`, `SKIP`.

### 1. 提交状态 (Commit Status) — FAST

**Check:** Run `git status --short`. Count untracked files, unstaged modifications, staged changes.

**Criteria:**
- PASS: clean working tree
- WARN: uncommitted changes present (list count by type)

### 2. 分支同步 (Branch Sync) — FAST

**Check:**
- For current branch: `git rev-list --left-right --count HEAD...@{upstream}` (ahead/behind)
- List local branches with no commits in 30+ days: `git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short) %(committerdate:unix)'` then filter

**Criteria:**
- PASS: ahead/behind ≤ 5, no stale branches
- WARN: ahead/behind > 5 or stale branches exist (list them)

### 3. 代码-文档一致性 (Code-Doc Consistency) — FAST

**Check:** Based on detected project type:
- **Node/TS:** Compare exported functions/classes in `src/` with documentation in `docs/` or `README.md`. Check if README API section lists all exported symbols.
- **Skills project:** Compare skills listed in `skills/*/SKILL.md` name fields against references in `using-summ/SKILL.md` skill list.
- **General:** Check if code comments reference files/modules that don't exist, or if README mentions features not found in code.

**Criteria:**
- PASS: consistent or no detectable public API
- WARN: inconsistencies found (list each: undocumented symbol, stale doc reference)

### 4. 文档完整性 (Doc Completeness) — FAST

**Check:** Verify these files exist and are non-empty:

**Critical docs:**
- `README.md`
- `CLAUDE.md` (or equivalent agent config)

**Non-critical docs:**
- `CHANGELOG.md` or `CHANGELOG`
- `LICENSE` or `LICENSE.md`
- Per-module docs where applicable

**Criteria:**
- PASS: all docs present and non-empty
- FAIL: critical doc missing
- WARN: non-critical doc missing (list which)

### 5. 技能完整性 (Skill Integrity) — FAST, skills-project only

**Check:** For each `skills/*/SKILL.md`:
- Has YAML frontmatter delimited by `---`
- Has `name:` field (non-empty)
- Has `description:` field (non-empty, ≥10 characters)

**Criteria:**
- PASS: all skills valid
- FAIL: skill missing frontmatter or name
- WARN: description too short (<10 chars)
- SKIP: no `skills/` directory

### 6. 构建验证 (Build Verification) — FULL

**Check:** Run the appropriate build command:
- Node: `npm run build` or `npx tsc --noEmit`
- Rust: `cargo build`
- Go: `go build ./...`
- Python: `python -m build` or skip if no build step
- Make: `make`

**Criteria:**
- PASS: build succeeds (exit 0)
- FAIL: build fails (show error output)
- SKIP: no build step detected

### 7. 单元测试 (Unit Tests) — FULL

**Check:** Run test suite with coverage:
- Node: `npx jest --coverage` or `npm test -- --coverage`
- Rust: `cargo test`
- Go: `go test ./... -cover`
- Python: `pytest --cov`
- Bash: `bats` or project-specific test runner

Collect: total tests, passed, failed, skipped, line coverage percentage.

**Criteria:**
- PASS: 0 failures, coverage ≥ 80%
- WARN: 0 failures, coverage < 80%
- FAIL: any test failures (list failing tests)
- SKIP: no test framework detected

### 8. E2E 测试 (E2E Tests) — FULL

**Check:** Run E2E/integration test suite:
- Node: `npm run test:e2e` or `npx playwright test` or `npx cypress run`
- Rust: `cargo test --test '*'`
- Go: `go test ./tests/... -tags=e2e`
- Python: `pytest tests/e2e/`

Collect: same metrics as unit tests.

**Criteria:**
- PASS: 0 failures, coverage ≥ 80% (if measurable)
- WARN: 0 failures, coverage < 80%
- FAIL: any test failures
- SKIP: no E2E test config (not required — this is advisory)

### 9. 依赖健康 (Dependency Health) — FULL

**Check:** Run dependency audit:
- Node: `npm audit` (vulnerabilities), `npm outdated` (stale)
- Rust: `cargo audit`
- Go: `go list -m -json all` (check for updates)
- Python: `pip-audit` or `safety check`

**Criteria:**
- PASS: no vulnerabilities, no severely outdated deps
- WARN: outdated dependencies (list count and severity)
- FAIL: known vulnerabilities (list CVE or advisory)
- SKIP: no dependency manager detected

## Report Format

Generate the report at `docs/health-report-YYYY-MM-DD.md` with this structure:

```
# 项目健康报告

> 生成时间: YYYY-MM-DD HH:MM
> 项目: [project name from git remote or directory]
> 分支: [current branch]
> 模式: fast / full
> 检查项: N 项

## 汇总

| 状态 | 数量 |
|------|------|
| PASS | X |
| WARN | X |
| FAIL | X |
| SKIP | X |

## 检查结果

### [检查项名称] — [状态]
- [具体发现和数据]
- [覆盖率信息，如适用]

## 建议操作

[仅列出 WARN 和 FAIL 项的修复建议，每项 1-2 句]
```

After writing the file, output the summary table to the terminal so the user sees the result immediately.

## Project Adaptation

On first run, detect project type by checking for these files in order:

1. `package.json` → Node.js project
2. `Cargo.toml` → Rust project
3. `go.mod` → Go project
4. `pyproject.toml` / `setup.py` / `requirements.txt` → Python project
5. `pom.xml` → Java/Maven project
6. `build.gradle` → Java/Gradle project
7. `Makefile` → Make-based project
8. `skills/*/SKILL.md` → Skills project (SUMM-Powers pattern)

If multiple detected, use the primary one (first in the list above). If none recognized, SKIP build/test/dependency checks and only run the 5 fast-mode checks.

## Status Definitions

| Status | Meaning |
|--------|---------|
| PASS | Check passed, no issues |
| WARN | Non-critical issue detected, attention recommended |
| FAIL | Critical issue detected, should be fixed |
| SKIP | Check not applicable or tooling not available |
```

- [ ] **Step 3: Run structural test**

Run: `bash tests/claude-code/test-health-check.sh`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add skills/health-check/SKILL.md
git commit -m "feat: add health-check skill — 9 check items, fast/full modes, Markdown report"
```

---

### Batch 2 (Tasks 3-4)

### Task 3: Create Slash Command

**Files:**
- Create: `commands/health-check.md`

- [ ] **Step 1: Write command file**

```markdown
---
description: "Use the summ:health-check skill for project health checking and report generation"
---

Invoke the summ:health-check skill and follow it exactly as presented to you

ARGUMENTS: Pass through any arguments (e.g. 'full' for full mode) to the skill
```

- [ ] **Step 2: Commit**

```bash
git add commands/health-check.md
git commit -m "feat: add /health-check slash command"
```

---

### Task 4: Verify and Final Commit

**Files:**
- Verify: `tests/claude-code/test-health-check.sh`

- [ ] **Step 1: Run full test suite**

Run: `bash tests/claude-code/test-health-check.sh`
Expected: All tests PASS — `=== All tests passed ===`

- [ ] **Step 2: Verify skill loads via claude**

Run: `claude -p "Load the health-check skill and confirm it has 9 check items" --no-input 2>&1 | head -20`
Expected: Agent confirms skill loaded with 9 check items

- [ ] **Step 3: Verify files are committed**

Run: `git status --short`
Expected: Clean working tree (all files committed in previous tasks)
