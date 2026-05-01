#!/usr/bin/env bash
set -euo pipefail

# dev-loop init — set up a project for dev-loop workflow
# Usage: init.sh [PROJECT_PATH] [--branch BRANCH] [--name NAME]

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SOURCE="$SCRIPT_DIR/../.."

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[init]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
fail()  { echo -e "${RED}[fail]${NC} $*"; exit 1; }

# ── Defaults ────────────────────────────────────────────────────────────────
PROJECT_PATH=""
PROJECT_NAME=""
BRANCH="main"

# ── Usage ───────────────────────────────────────────────────────────────────
show_usage() {
  cat <<'EOF'
dev-loop init — set up a project for dev-loop workflow

Usage:
  init.sh [PROJECT_PATH] [options]

Options:
  --branch BRANCH   Default git branch (default: main)
  --name NAME       Project name (default: directory name)
  -h, --help        Show this help

Example:
  init.sh ~/my-project --branch develop --name my-app
EOF
  exit 0
}

# ── Parse args ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)   BRANCH="$2"; shift 2 ;;
    --name)     PROJECT_NAME="$2"; shift 2 ;;
    --help|-h)  show_usage ;;
    -*)         fail "Unknown option: $1" ;;
    *)          PROJECT_PATH="$1"; shift ;;
  esac
done

# ── Resolve project path ────────────────────────────────────────────────────
if [[ -z "$PROJECT_PATH" ]]; then
  PROJECT_PATH="$(pwd)"
fi
PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || fail "Directory not found: $PROJECT_PATH"

if [[ -z "$PROJECT_NAME" ]]; then
  PROJECT_NAME="$(basename "$PROJECT_PATH")"
fi

info "Initializing dev-loop for: $PROJECT_NAME"
info "Project path: $PROJECT_PATH"
info "Default branch: $BRANCH"
echo ""

# ── Step 1: Check prerequisites ─────────────────────────────────────────────
info "Checking prerequisites..."

command -v ao >/dev/null 2>&1 || fail "'ao' CLI not found. Install: https://github.com/nicepkg/ao"
ok "ao CLI found: $(ao --version 2>/dev/null || echo 'unknown')"

command -v claude >/dev/null 2>&1 || warn "'claude' CLI not found. dev-loop requires Claude Code."
command -v git >/dev/null 2>&1 || fail "'git' not found."

# ── Step 2: Detect SUMM plugin cache ────────────────────────────────────────
info "Detecting SUMM plugin cache..."

SUMM_CACHE_DIR=""
PLUGIN_BASE="$HOME/.claude/plugins/cache/summ-dev/summ"

if [[ -d "$PLUGIN_BASE" ]]; then
  # Find latest version
  LATEST_VERSION=""
  for dir in "$PLUGIN_BASE"/*/; do
    version="$(basename "$dir")"
    if [[ -z "$LATEST_VERSION" ]] || [[ "$version" > "$LATEST_VERSION" ]]; then
      LATEST_VERSION="$version"
    fi
  done
  if [[ -n "$LATEST_VERSION" ]]; then
    SUMM_CACHE_DIR="$PLUGIN_BASE/$LATEST_VERSION"
    ok "SUMM plugin cache: $SUMM_CACHE_DIR"
  fi
fi

if [[ -z "$SUMM_CACHE_DIR" ]]; then
  warn "SUMM plugin cache not found at $PLUGIN_BASE"
  warn "dev-loop skill sync will be skipped. Install SUMM plugin first."
fi

# ── Step 3: Sync dev-loop skill to plugin cache ─────────────────────────────
if [[ -n "$SUMM_CACHE_DIR" ]]; then
  CACHE_SKILLS="$SUMM_CACHE_DIR/skills"
  SOURCE_SKILLS="$SKILLS_SOURCE"

  MISSING=()
  for skill_name in dev-loop deploy; do
    if [[ ! -d "$CACHE_SKILLS/$skill_name" ]]; then
      MISSING+=("$skill_name")
    fi
  done

  if [[ ${#MISSING[@]} -gt 0 ]]; then
    info "Syncing missing skills to plugin cache: ${MISSING[*]}"
    for skill_name in "${MISSING[@]}"; do
      if [[ -d "$SOURCE_SKILLS/$skill_name" ]]; then
        cp -r "$SOURCE_SKILLS/$skill_name" "$CACHE_SKILLS/$skill_name"
        ok "Synced: $skill_name"
      else
        warn "Source skill not found: $skill_name (expected at $SOURCE_SKILLS/$skill_name)"
      fi
    done
  else
    ok "dev-loop and deploy skills already in cache"
  fi

  # Full sync check — only compare directories, skip . and ..
  DIFF="$(diff <(find "$SOURCE_SKILLS" -maxdepth 1 -type d -printf '%f\n' | grep -v '^\.\.*$' | sort) <(find "$CACHE_SKILLS" -maxdepth 1 -type d -printf '%f\n' | grep -v '^\.\.*$' | sort) 2>/dev/null || true)"
  if [[ -n "$DIFF" ]]; then
    MISSING_IN_CACHE=()
    while IFS= read -r line; do
      if [[ "$line" == "< "* ]]; then
        name="${line#< }"
        MISSING_IN_CACHE+=("$name")
      fi
    done <<< "$DIFF"

    if [[ ${#MISSING_IN_CACHE[@]} -gt 0 ]]; then
      warn "Skills in source but not in cache: ${MISSING_IN_CACHE[*]}"
      warn "Run: cp -r $SOURCE_SKILLS/<name> $CACHE_SKILLS/<name>"
    fi
  fi
fi

# ── Step 4: Generate agent-orchestrator.yaml ────────────────────────────────
AO_CONFIG="$PROJECT_PATH/agent-orchestrator.yaml"

if [[ -f "$AO_CONFIG" ]]; then
  warn "agent-orchestrator.yaml already exists — skipping"
  warn "Verify it has agentRules with SUMM skill loading instructions"
else
  info "Creating agent-orchestrator.yaml..."

  cat > "$AO_CONFIG" <<YAML
defaults:
  runtime: tmux
  agent: claude-code
  workspace: worktree

projects:
  ${PROJECT_NAME}:
    path: ${PROJECT_PATH}
    defaultBranch: ${BRANCH}
    agentRules: |
      You have SUMM. You MUST use the Skill tool to load skills before doing any work.

      ## If you are a MASTER agent (coordinator):
      1. Load skill summ:dev-loop immediately via the Skill tool
      2. Follow the dev-loop state machine exactly
      3. You NEVER write code, deploy, or run E2E tests yourself — dispatch workers via \`ao spawn\`
      4. Use \`ao status\` to monitor workers, \`ao send\` to communicate
      5. Escalate to human when loop count >= 3 or worker is blocked

      ## If you are a WORKER agent (executor):
      1. Load the skill specified in your task prompt IMMEDIATELY
      2. Follow the skill's instructions exactly
      3. Work ONLY on the task assigned to you — do not modify unrelated files
      4. Do not attempt architectural decisions — escalate if you encounter them
      5. Report using: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
YAML

  ok "Created: $AO_CONFIG"
fi

# ── Step 5: Generate .claude/settings.json ──────────────────────────────────
CLAUDE_DIR="$PROJECT_PATH/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

if [[ -f "$SETTINGS" ]]; then
  warn ".claude/settings.json already exists — checking permissions..."

  # Check if key permissions are already present
  EXISTING="$(cat "$SETTINGS")"
  MISSING_PERMS=()
  for perm in "Edit" "Write" "Bash(npm *)" "Bash(git *)" "Bash(ao *)"; do
    if ! echo "$EXISTING" | grep -q "\"$perm\""; then
      MISSING_PERMS+=("$perm")
    fi
  done

  if [[ ${#MISSING_PERMS[@]} -gt 0 ]]; then
    warn "Missing auto-approve permissions: ${MISSING_PERMS[*]}"
    warn "Add them manually to $SETTINGS"
  else
    ok "Required permissions already configured"
  fi
else
  info "Creating .claude/settings.json with auto-approve rules..."

  mkdir -p "$CLAUDE_DIR"
  cat > "$SETTINGS" <<'JSON'
{
  "permissions": {
    "allow": [
      "Edit",
      "Write",
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(node *)",
      "Bash(npx *)",
      "Bash(curl *)",
      "Bash(lsof *)",
      "Bash(ao *)",
      "Bash(mkdir *)",
      "Bash(cat *)",
      "Bash(echo *)",
      "Bash(cp *)",
      "Bash(ls *)",
      "Bash(diff *)",
      "Bash(tmux *)"
    ]
  }
}
JSON

  ok "Created: $SETTINGS"
fi

# ── Step 6: Check DEPLOY.md ─────────────────────────────────────────────────
DEPLOY_MD="$PROJECT_PATH/DEPLOY.md"

if [[ -f "$DEPLOY_MD" ]]; then
  ok "DEPLOY.md exists"
else
  warn "DEPLOY.md not found"
  warn "dev-loop DELIVERING phase requires DEPLOY.md for deployment instructions"
  info "Creating template DEPLOY.md..."

  cat > "$DEPLOY_MD" <<'MARKDOWN'
# Deploy Instructions

## Prerequisites
- Node.js >= 18
- npm

## Deploy Steps
1. Install dependencies: `npm install`
2. Run tests: `npm test`
3. Kill existing server (if any): `lsof -ti:$PORT | xargs kill -9 2>/dev/null; true`
4. Start server: `PORT=3000 npm start`
5. Verify: `curl http://localhost:3000/api/health`

## E2E Tests
After the server is running, run E2E tests (if configured):
```
npm run test:e2e
```
MARKDOWN

  ok "Created template: $DEPLOY_MD"
  warn "Edit DEPLOY.md with your project's actual deployment steps"
fi

# ── Step 7: Check CLAUDE.md ─────────────────────────────────────────────────
CLAUDE_MD="$PROJECT_PATH/CLAUDE.md"

if [[ -f "$CLAUDE_MD" ]]; then
  ok "CLAUDE.md exists"
else
  warn "CLAUDE.md not found — spawned sessions won't have project context"
  warn "Consider creating CLAUDE.md with project overview and conventions"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "dev-loop init complete for: $PROJECT_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Files created/checked:"
[[ -f "$AO_CONFIG" ]]  && echo "  ✓ $AO_CONFIG"
[[ -f "$SETTINGS" ]]   && echo "  ✓ $SETTINGS"
[[ -f "$DEPLOY_MD" ]]  && echo "  ✓ $DEPLOY_MD"
echo ""
echo "Next steps:"
echo "  1. Review and edit DEPLOY.md with actual deployment steps"
echo "  2. cd $PROJECT_PATH"
echo "  3. ao spawn ${PROJECT_NAME} --prompt \"dev-loop master"
echo ""
echo "     Execute autonomously. Do not ask for confirmation."
echo ""
echo "     实现需求：<your requirement here>"
echo "     \""
echo ""
echo "Docs: skills/dev-loop/SKILL.md"
echo "Worker template: skills/dev-loop/worker-prompt-template.md"
