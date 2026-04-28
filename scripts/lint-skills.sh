#!/usr/bin/env bash
# lint-skills.sh — Validate SKILL.md files against format and quality rules.
# Usage: ./scripts/lint-skills.sh [options] [skill-path ...]
#   No args  = check all skills under skills/
#   skill-path = check one or more specific skill directories

set -euo pipefail

# ── Options ──────────────────────────────────────────────────────────
VERBOSE=0
QUIET=0
ERRORS=0
WARNINGS=0

for arg in "$@"; do
  case "$arg" in
    -v|--verbose) VERBOSE=1; shift ;;
    -q|--quiet)   QUIET=1; shift ;;
  esac
done

# ── Helpers ──────────────────────────────────────────────────────────
error() {
  ((QUIET)) && return 0
  local loc="$1"; shift
  echo "  ERROR [$loc]: $*" >&2
  ((ERRORS++)) || true
}

warn() {
  ((QUIET)) && return 0
  local loc="$1"; shift
  echo "  WARN  [$loc]: $*" >&2
  ((WARNINGS++)) || true
}

info() {
  ((VERBOSE)) || return 0
  local loc="$1"; shift
  echo "  ok    [$loc]: $*" >&2
}

# ── Discover skills ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

TARGETS=()
for arg in "$@"; do
  [[ "$arg" == -v || "$arg" == -q || "$arg" == --verbose || "$arg" == --quiet ]] && continue
  TARGETS+=("$arg")
done

if ((${#TARGETS[@]} == 0)); then
  while IFS= read -r -d '' d; do
    [[ -f "$d/SKILL.md" ]] && TARGETS+=("$d")
  done < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -not -name 'ext-*' -print0 | sort -z)
fi

echo "Linting ${#TARGETS[@]} skill(s)..."

# ── Per-skill checks ────────────────────────────────────────────────
check_skill() {
  local skill_dir="$1"
  local skill_name
  skill_name="$(basename "$skill_dir")"
  local skill_file="$skill_dir/SKILL.md"

  ((QUIET)) || echo "Checking: $skill_name"

  # 1. SKILL.md exists
  if [[ ! -f "$skill_file" ]]; then
    error "$skill_name" "SKILL.md not found"
    return
  fi
  info "$skill_name" "SKILL.md exists"

  # 2. Parse frontmatter
  local fm
  fm=$(awk '/^---$/{if(start) exit; start=1; next} start{print}' "$skill_file")

  if [[ -z "$fm" ]]; then
    error "$skill_name" "No YAML frontmatter found"
    return
  fi

  # 3. Required fields: name, description
  local name desc
  name=$(echo "$fm" | grep -oP '^name:\s*\K.*' || true)
  desc=$(echo "$fm" | grep -oP '^description:\s*\K.*' || true)

  if [[ -z "$name" ]]; then
    error "$skill_name" "Missing required field: name"
  else
    info "$skill_name" "name = $name"
  fi

  if [[ -z "$desc" ]]; then
    error "$skill_name" "Missing required field: description"
  fi

  # 4. Directory name == name field
  if [[ -n "$name" && "$name" != "$skill_name" ]]; then
    error "$skill_name" "Directory name '$skill_name' != frontmatter name '$name'"
  else
    info "$skill_name" "Directory name matches frontmatter name"
  fi

  # 5. Name format: lowercase, digits, hyphens only
  if [[ -n "$name" && ! "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    error "$skill_name" "Name '$name' must be lowercase alphanumeric with hyphens"
  fi

  # 6. Description length ≤ 1024 chars
  if [[ -n "$desc" && ${#desc} -gt 1024 ]]; then
    error "$skill_name" "Description is ${#desc} chars (max 1024)"
  fi

  # 7. Description starts with "Use when" (recommended)
  if [[ -n "$desc" && ! "$desc" =~ ^Use\ when ]]; then
    warn "$skill_name" "Description should start with 'Use when ...'"
  else
    info "$skill_name" "Description starts with 'Use when'"
  fi

  # ── Link validation ───────────────────────────────────────────────
  # Extract markdown links: [text](path) where path is a relative file reference
  local body
  body=$(sed '1,/^---$/d' "$skill_file" | sed '1,/^---$/d')

  while IFS= read -r link; do
    [[ -z "$link" ]] && continue
    # Resolve relative paths from the skill directory
    # Handle ../  prefixes (cross-skill references)
    local target="$skill_dir/$link"
    # Normalize the path
    target=$(cd "$(dirname "$target")" 2>/dev/null && pwd)/$(basename "$target") 2>/dev/null || true

    if [[ ! -e "$target" ]]; then
      # Check if it's a URL (skip)
      if [[ ! "$link" =~ ^https?:// && ! "$link" =~ ^mailto: ]]; then
        warn "$skill_name" "Broken link: $link"
      fi
    fi
  done < <(echo "$body" | grep -oP '\[(?:[^\]]*)\]\(\K[^)#)]+' | grep -v '^https\?://' | grep -v '^mailto:')

  # ── Quality checks ────────────────────────────────────────────────
  local total_lines
  total_lines=$(wc -l < "$skill_file")

  # 1. SKILL.md should have a top-level heading (# Title)
  if ! grep -qP '^# ' "$skill_file"; then
    error "$skill_name" "No top-level heading (# Title) found"
  else
    info "$skill_name" "Has top-level heading"
  fi

  # 2. Warn if SKILL.md exceeds 300 lines (progressive disclosure threshold)
  if ((total_lines > 300)); then
    warn "$skill_name" "SKILL.md is $total_lines lines (consider splitting into reference files)"
  fi

  # 3. Warn if no "Use when" or trigger guidance anywhere in the file
  if ! grep -qi "use when\|trigger\|when to use" "$skill_file"; then
    warn "$skill_name" "No usage trigger guidance found"
  fi

  # 4. Check for common placeholder patterns
  local placeholders
  placeholders=$(grep -ciP 'TBD|TODO|FIXME|PLACEHOLDER|\[insert|<fill' "$skill_file" || true)
  if ((placeholders > 0)); then
    error "$skill_name" "Contains $placeholders placeholder(s): TBD/TODO/FIXME/PLACEHOLDER"
  fi

  # 5. Referenced local files should exist
  # Already covered by link validation above
}

for t in "${TARGETS[@]}"; do
  check_skill "$t"
done

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "Done. $ERRORS error(s), $WARNINGS warning(s)."
if ((ERRORS > 0)); then
  exit 1
fi
exit 0
