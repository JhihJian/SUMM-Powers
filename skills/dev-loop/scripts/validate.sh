#!/usr/bin/env bash
set -uo pipefail

# Static validation for dev-loop skill files.
# Checks structural consistency across SKILL.md, master-prompt.md, worker-prompt-template.md.

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_MD="$SKILL_DIR/SKILL.md"
MASTER_MD="$SKILL_DIR/master-prompt.md"
WORKER_MD="$SKILL_DIR/worker-prompt-template.md"

PASS=0
FAIL=0

check() {
  local desc="$1" result="$2"
  if [ "$result" = "true" ]; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $desc"
  fi
}

sgrep() { grep "$@" || true; }

echo "=== dev-loop Skill Static Validation ==="
echo ""

# [1] Phase table vs transition rules consistency
echo "[1] Phase table vs transition rules consistency"

PHASE_TABLE_START=$(sgrep -n "Phase.*Sub-state" "$SKILL_MD" | head -1 | cut -d: -f1)
PHASE_TABLE_END=$(tail -n +"$PHASE_TABLE_START" "$SKILL_MD" | grep -n '```' | head -1 | cut -d: -f1)
PHASE_TABLE_END=$((PHASE_TABLE_START + PHASE_TABLE_END))

PHASES_FROM_TABLE=""
CURRENT_PHASE=""
while IFS= read -r line; do
  [[ "$line" =~ ^─ ]] && continue
  [[ "$line" =~ Phase.*Sub-state ]] && continue
  [[ -z "${line// /}" ]] && continue
  if [[ "$line" =~ ^[A-Z]{3,} ]]; then
    CURRENT_PHASE=$(echo "$line" | awk '{print $1}')
    SUB_STATE=$(echo "$line" | awk '{print $2}')
    if [ -n "$SUB_STATE" ] && [[ "$SUB_STATE" =~ ^[A-Z] ]]; then
      PHASES_FROM_TABLE="$PHASES_FROM_TABLE
$CURRENT_PHASE.$SUB_STATE"
    fi
  elif [[ "$line" =~ ^[[:space:]]+[A-Z] ]]; then
    SUB_STATE=$(echo "$line" | awk '{print $1}')
    if [ -n "$SUB_STATE" ] && [[ "$SUB_STATE" =~ ^[A-Z] ]]; then
      PHASES_FROM_TABLE="$PHASES_FROM_TABLE
$CURRENT_PHASE.$SUB_STATE"
    fi
  fi
done < <(sed -n "$((PHASE_TABLE_START+1)),$((PHASE_TABLE_END-1))p" "$SKILL_MD")
PHASES_FROM_TABLE=$(echo "$PHASES_FROM_TABLE" | sort -u | grep -v '^$')

PHASES_FROM_RULES=$(grep -oE '→ [A-Z]+\.[A-Z0-9_]+|→ ESCALATED|→ DONE' "$SKILL_MD" | awk '{print $2}' | sort -u)
PHASES_SOURCES=$(grep -oE '^[A-Z]+\.[A-Z_]+' "$SKILL_MD" | sort -u)
ALL_PHASES=$(echo -e "$PHASES_FROM_TABLE\n$PHASES_FROM_RULES\n$PHASES_SOURCES" | sort -u | grep -v '^$')

TERMINAL_STATES="ESCALATED DONE"
for phase in $ALL_PHASES; do
  if echo "$TERMINAL_STATES" | grep -qw "$phase"; then
    check "Phase '$phase' is a known terminal state" "true"
  elif echo "$PHASES_FROM_TABLE" | grep -qF "$phase"; then
    check "Phase '$phase' exists in phase table" "true"
  else
    check "Phase '$phase' exists in phase table" "false"
  fi
done

echo ""

# [2] No stale phase references
echo "[2] No stale phase references"

STALE_COUNT=$(sgrep -n "BRAINSTORMING" "$SKILL_MD" | sgrep -v "does not include brainstorming" | sgrep -v "produced by" | wc -l)
check "SKILL.md no stale BRAINSTORMING refs (except explanation)" "$([ "$STALE_COUNT" -eq 0 ] && echo true || echo false)"

STALE_MASTER=$(sgrep -c "BRAINSTORMING" "$MASTER_MD" | head -1)
check "master-prompt.md no BRAINSTORMING refs" "$([ "${STALE_MASTER:-0}" -eq 0 ] && echo true || echo false)"

STALE_WORKER=$(sgrep -c "BRAINSTORMING" "$WORKER_MD" | head -1)
check "worker-prompt-template.md no BRAINSTORMING refs" "$([ "${STALE_WORKER:-0}" -eq 0 ] && echo true || echo false)"

echo ""

# [3] Cross-file references
echo "[3] Cross-file references"

MASTER_PLAN=$(sgrep -c "PLAN_WRITING\|writing-plans" "$MASTER_MD" | head -1)
check "master-prompt.md references planning" "$([ "${MASTER_PLAN:-0}" -gt 0 ] && echo true || echo false)"

MASTER_REVIEW=$(sgrep -c "code.review\|requesting-code-review" "$MASTER_MD" | head -1)
check "master-prompt.md references code review" "$([ "${MASTER_REVIEW:-0}" -gt 0 ] && echo true || echo false)"

MASTER_VALUE=$(sgrep -c "value proof\|VALUE_PROVING" "$MASTER_MD" | head -1)
check "master-prompt.md references value proof" "$([ "${MASTER_VALUE:-0}" -gt 0 ] && echo true || echo false)"

WORKER_SKILLS=$(sgrep -oE 'summ:[a-z-]+' "$WORKER_MD" | sort -u)
for skill in $WORKER_SKILLS; do
  if [ "$skill" = "summ:systematic-debugging" ]; then
    check "Worker template skill '$skill' is available" "true"
    continue
  fi
  FOUND=$(sgrep -c "$skill" "$SKILL_MD" | head -1)
  check "Worker template skill '$skill' in SKILL.md" "$([ "${FOUND:-0}" -gt 0 ] && echo true || echo false)"
done

echo ""

# [4] Required sections
echo "[4] Required sections in SKILL.md"

REQUIRED_SECTIONS=("Phase Instructions" "PLANNING.PLAN_WRITING" "BUILDING.TDD_IMPLEMENTING" "BUILDING.CODE_REVIEWING" "DELIVERING.DEPLOYING" "DELIVERING.E2E_VERIFYING" "VALIDATING.VALUE_PROVING" "VALIDATING.COMPLETING" "ESCALATION" "ao spawn")
for section in "${REQUIRED_SECTIONS[@]}"; do
  FOUND=$(sgrep -c "$section" "$SKILL_MD" | head -1)
  check "SKILL.md has '$section' section or reference" "$([ "${FOUND:-0}" -gt 0 ] && echo true || echo false)"
done

echo ""

# [5] Positive step coverage — each phase has "Do these steps" or numbered steps
echo "[5] Phase instructions have concrete steps"

PHASES_WITH_STEPS=("PLAN_WRITING" "TDD_IMPLEMENTING" "CODE_REVIEWING" "DEPLOYING" "E2E_VERIFYING" "VALUE_PROVING" "COMPLETING")
for phase in "${PHASES_WITH_STEPS[@]}"; do
  # Check that the phase section has numbered steps (e.g., "1.", "2.")
  FOUND=$(sgrep -A 20 "$phase" "$SKILL_MD" | sgrep -cE '^[0-9]+\.' | head -1)
  check "'$phase' has numbered steps" "$([ "${FOUND:-0}" -gt 0 ] && echo true || echo false)"
done

echo ""

# [6] Worker dispatch in action phases
echo "[6] Worker dispatch in execution phases"

for phase in "TDD_IMPLEMENTING" "DEPLOYING" "E2E_VERIFYING"; do
  SECTION=$(sgrep -A 30 "$phase" "$SKILL_MD")
  HAS_DISPATCH=$(echo "$SECTION" | sgrep -ci "dispatch" | head -1)
  check "'$phase' instructions include worker dispatch" "$([ "${HAS_DISPATCH:-0}" -gt 0 ] && echo true || echo false)"
done

echo ""

# Summary
echo "=== Summary ==="
TOTAL=$((PASS + FAIL))
echo "  Passed: $PASS / $TOTAL"
echo "  Failed: $FAIL / $TOTAL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "  FAIL: Validation FAILED"
  exit 1
else
  echo ""
  echo "  PASS: All checks passed"
  exit 0
fi
