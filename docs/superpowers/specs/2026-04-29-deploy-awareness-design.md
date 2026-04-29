# Deploy Awareness Skill Design

**Date**: 2026-04-29
**Status**: Approved

## Problem

Claude Code 在开发过程中缺乏获取项目部署信息的标准渠道。当需要连接环境进行功能测试、了解服务依赖地址、或同步部署变更时，没有统一的文档规范来查询和更新这些信息。

## Solution

创建独立技能 `deploy`，定义 DEPLOY.md 作为项目部署信息的标准存放位置，并提供读取触发、更新提醒和模板三种行为。

## Skill Definition

**File**: `skills/deploy/SKILL.md`
**Name**: `deploy`
**Trigger**: 当用户提到测试环境、部署、CI/CD、服务地址、环境变量、配置变更等部署相关话题时，或当 Claude 修改了可能影响部署配置的文件时，或当需要环境进行功能测试时使用。当项目中存在 DEPLOY.md 时主动读取获取部署上下文。

## Three Core Behaviors

### 1. Read

**When to read DEPLOY.md:**

| Scenario | Example |
|----------|---------|
| User mentions test/deploy/environment | "deploy to staging", "what's the test env" |
| Need environment for functional testing | Feature development complete, need real environment to verify |
| Claude modified deployment-related files | docker-compose, CI config, .env, nginx etc. |
| User asks about service address or dependency | "where's the database", "Redis port" |

**Behavior:**

1. Check if `DEPLOY.md` exists at project root
2. **Exists** → Read and apply context to current task
3. **Not exists** → Remind user that DEPLOY.md can be created for better deployment awareness, offer template

### 2. Update Reminder

**Files that trigger update reminder:**

| Change Type | Typical Files | Suggest Update Section |
|-------------|--------------|----------------------|
| Container/Orchestration | `docker-compose*.yml`, `Dockerfile*`, `k8s/**` | Environments, Dependencies |
| CI/CD | `.github/workflows/*`, `Jenkinsfile`, `.gitlab-ci.yml` | Deployment |
| Environment Variables | `.env*`, `.env.example`, `config/*` | Configuration |
| Gateway/Proxy | `nginx*.conf`, `*.proxy`, `caddy*` | Environments |
| Infrastructure | `terraform/**`, `ansible/**`, `Pulumi.*` | All sections |
| Dependency Changes | new service deps in `package.json`, database drivers, etc. | Dependencies |

**Behavior:**

1. After editing files above, check if `DEPLOY.md` exists at project root
2. **Exists** → Remind: "These changes involve [category], suggest updating DEPLOY.md's [section]", and assist with update
3. **Not exists** → Silent, do not prompt creation (respect optional convention)

**Do NOT trigger for**: Pure business logic changes (React components, API handlers, etc.)

### 3. Template

When user asks to create DEPLOY.md or asks for a template, provide:

```markdown
# DEPLOY.md

## Environments

| Name | URL | Purpose |
|------|-----|---------|
| dev | http://localhost:3000 | local development |
| staging | https://staging.example.com | pre-release verification |
| prod | https://example.com | production |

## Deployment

- **Method**: [manual / CI/CD / GitOps]
- **Command/Pipeline**: [deploy command or pipeline name]
- **Rollback**: [rollback procedure]

## Dependencies

| Service | Address | Credentials |
|---------|---------|-------------|
| PostgreSQL | localhost:5432 | See `.env` |
| Redis | localhost:6379 | None |

## Configuration

- **Environment Variables**: [`.env.example` or description]
- **Config Files**: [key config file paths]

## Monitoring

- **Logs**: [log URL or access method]
- **Alerts**: [alert config or owner]
```

Design notes for template:
- Table-oriented for quick scanning and Claude parsing
- Credentials fields contain pointers (e.g., "See `.env`"), never actual secrets
- All sections optional — projects fill only what they have

## Design Principles

- **Optional convention**: DEPLOY.md is not required; skill degrades gracefully when absent
- **Self-contained**: Single SKILL.md file, no hooks, scripts, or companion files needed
- **Independent**: No coupling with other skills; future integration is done by referencing from other skills, not from within this skill
- **Trigger-driven**: Updates are prompted by specific file change patterns, not by guesswork

## File Structure

```
skills/deploy/
└── SKILL.md
```

## Out of Scope

- Git hook integration for automatic detection
- CI/CD validation of DEPLOY.md completeness
- Integration with verification-before-completion or finishing-a-development-branch
- Multi-project deployment orchestration
