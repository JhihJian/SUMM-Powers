# Health Check Skill Design Spec

> Date: 2026-05-03
> Status: Approved

## Overview

A skill that performs project health checks and generates a Markdown report. No blocking — report only. Supports two modes: fast (default, read-only checks) and full (includes build/test/dependency checks).

## Skill Metadata

- **Name:** `health-check`
- **Trigger:** User says "检查项目状态", "项目健康", "health check", or uses `/health-check`
- **Path:** `skills/health-check/SKILL.md`
- **Report output:** `docs/health-report-YYYY-MM-DD.md`

## Check Items

### Fast Mode (default) — 5 items

**1. 提交状态 (Commit Status)**
- Check: `git status` — untracked files, unstaged modifications, staged content
- PASS: clean working tree
- WARN: uncommitted changes present

**2. 分支同步 (Branch Sync)**
- Check: local vs remote ahead/behind count; local branches with no commits in 30+ days
- PASS: in sync, no stale branches
- WARN: ahead/behind > 5 or stale branches exist

**3. 代码-文档一致性 (Code-Doc Consistency)**
- Check: compare public APIs/config keys/exported symbols in code against documentation. Detect undocumented endpoints, documented-but-deleted features
- PASS: consistent or no public API
- WARN: inconsistencies found

**4. 文档完整性 (Doc Completeness)**
- Check: required docs exist and are non-empty — README, CHANGELOG, CLAUDE.md, per-module docs
- PASS: all present
- FAIL: critical docs missing (README, CLAUDE.md)
- WARN: non-critical docs missing

**5. 技能完整性 (Skill Integrity)** — project-specific
- Check: each `skills/*/SKILL.md` has valid YAML frontmatter (name, description), description non-empty
- PASS: all valid
- FAIL: frontmatter missing or invalid
- WARN: description too short (<10 chars)

### Full Mode — adds 4 items

**6. 构建验证 (Build Verification)**
- Check: run build command, confirm artifacts generated
- PASS: build succeeds
- FAIL: build fails
- SKIP: no build step detected

**7. 单元测试 (Unit Tests)**
- Check: run test suite + collect line coverage
- PASS: all tests pass, coverage >= threshold
- WARN: all pass but coverage < threshold (default 80%)
- FAIL: test failures
- SKIP: no test config detected

**8. E2E 测试 (E2E Tests)**
- Check: run E2E test suite + collect coverage if tool supports it
- PASS: all pass, coverage >= threshold
- WARN: all pass but coverage < threshold
- FAIL: test failures
- SKIP: no E2E test config (not required)

**9. 依赖健康 (Dependency Health)**
- Check: outdated deps and known vulnerabilities via `npm audit` / `pip audit` / equivalent
- PASS: no issues
- WARN: outdated dependencies
- FAIL: known vulnerabilities

## Execution Order

Dependencies determine order to avoid redundant work:

1. 提交状态 (git read)
2. 分支同步 (git read)
3. 代码-文档一致性 (read code + docs)
4. 文档完整性 (read docs)
5. 技能完整性 (read SKILL.md frontmatter)
6. 构建验证 (build, needed by tests)
7. 单元测试 (needs build)
8. E2E 测试 (needs build)
9. 依赖健康 (independent audit)

## Project Adaptation

The skill does not hardcode commands. On first run, it probes the project type:
- Detect `package.json` / `pom.xml` / `Cargo.toml` / `go.mod` / `pyproject.toml` / etc.
- Select appropriate test, build, and dependency commands for the detected project type
- Unrecognized project type → relevant checks marked SKIP

Coverage threshold defaults to 80%. Can be configured per-project if needed.

## Report Format

```markdown
# 项目健康报告

> 生成时间: YYYY-MM-DD HH:MM
> 项目: [project name]
> 分支: [current branch]
> 模式: fast / full
> 检查项: N 项 (PASS / WARN / FAIL / SKIP)

## 汇总

| 状态 | 数量 |
|------|------|
| PASS | 5 |
| WARN | 2 |
| FAIL | 1 |
| SKIP | 1 |

## 检查结果

### 提交状态 — WARN
- 3 个未提交修改
- 1 个未跟踪文件

### 单元测试 — WARN
- 42 passed, 0 failed, 2 skipped
- 覆盖率: 73.2% (阈值: 80%)

### ...

## 建议操作

(Only WARN and FAIL items, with suggested fix steps)
```

## Invoking

- `/health-check` — fast mode (5 read-only checks)
- `/health-check full` — full mode (all 9 checks)

## Out of Scope

- CI/CD integration scripts (can evolve later)
- Automated blocking or gating
- Historical trend tracking
- Scoring or grading system
