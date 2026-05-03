#!/usr/bin/env bash
# Test: Smart Execution Router changes
# Verifies writing-plans auto-routes to Subagent-Driven,
# executing-plans is internal fallback, subagent-driven references auto-routing
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILLS_DIR="$(cd "$SCRIPT_DIR/../../skills" && pwd)"

echo "=== Test: Smart Execution Router ==="
echo ""

# ============================================================
# Layer 1: Structural verification (grep-based, instant)
# ============================================================

echo "--- Layer 1: Structural verification ---"
echo ""

# Test 1: writing-plans Execution Handoff — no user choice prompt
echo "Test 1: writing-plans does NOT ask user to choose..."
handoff_section=$(sed -n '/^## Execution Handoff/,/^## /{ /^## Execution Handoff/p; /^## /!p }' "$SKILLS_DIR/writing-plans/SKILL.md" | head -20)
if echo "$handoff_section" | grep -q "Which approach"; then
    echo "  [FAIL] writing-plans still contains 'Which approach?'"
    exit 1
fi
echo "  [PASS] No 'Which approach?' in Execution Handoff"

# Test 2: writing-plans auto-starts execution
if ! echo "$handoff_section" | grep -q "automatically start execution"; then
    echo "  [FAIL] Missing 'automatically start execution'"
    exit 1
fi
echo "  [PASS] Contains 'automatically start execution'"

# Test 3: writing-plans defaults to Subagent-Driven
if ! echo "$handoff_section" | grep -q "Subagent-Driven"; then
    echo "  [FAIL] Missing 'Subagent-Driven' in Execution Handoff"
    exit 1
fi
echo "  [PASS] Defaults to Subagent-Driven"

# Test 4: writing-plans explicitly says don't ask
if ! echo "$handoff_section" | grep -qi "do not ask.*choose\|don't ask.*choose"; then
    echo "  [FAIL] Missing 'Do not ask the user to choose'"
    exit 1
fi
echo "  [PASS] Says 'Do not ask the user to choose'"

# Test 5: executing-plans description is internal fallback
exec_desc=$(head -5 "$SKILLS_DIR/executing-plans/SKILL.md")
if ! echo "$exec_desc" | grep -q "Internal fallback"; then
    echo "  [FAIL] executing-plans description missing 'Internal fallback'"
    exit 1
fi
echo "  [PASS] executing-plans description contains 'Internal fallback'"

# Test 6: executing-plans does NOT have old user-facing note
if grep -q "Tell your human partner" "$SKILLS_DIR/executing-plans/SKILL.md"; then
    echo "  [FAIL] executing-plans still has 'Tell your human partner' note"
    exit 1
fi
echo "  [PASS] executing-plans removed 'Tell your human partner'"

# Test 7: executing-plans mentions automatic invocation
if ! grep -q "invoked automatically by the execution router" "$SKILLS_DIR/executing-plans/SKILL.md"; then
    echo "  [FAIL] executing-plans missing 'invoked automatically by the execution router'"
    exit 1
fi
echo "  [PASS] executing-plans mentions automatic invocation"

# Test 8: subagent-driven does NOT have old decision tree
if grep -q "digraph when_to_use" "$SKILLS_DIR/subagent-driven-development/SKILL.md"; then
    echo "  [FAIL] subagent-driven still has old decision tree dot graph"
    exit 1
fi
echo "  [PASS] subagent-driven removed old decision tree"

# Test 9: subagent-driven does NOT have vs. Executing Plans
if grep -q "vs\. Executing Plans" "$SKILLS_DIR/subagent-driven-development/SKILL.md"; then
    echo "  [FAIL] subagent-driven still has 'vs. Executing Plans'"
    exit 1
fi
echo "  [PASS] subagent-driven removed 'vs. Executing Plans'"

# Test 10: subagent-driven mentions auto-invokes
when_section=$(sed -n '/^## When to Use/,/^## /{ /^## When to Use/p; /^## /!p }' "$SKILLS_DIR/subagent-driven-development/SKILL.md" | head -20)
if ! echo "$when_section" | grep -q "auto-invokes"; then
    echo "  [FAIL] subagent-driven When to Use missing 'auto-invokes'"
    exit 1
fi
echo "  [PASS] subagent-driven mentions 'auto-invokes'"

echo ""

# ============================================================
# Layer 2: Behavioral verification (claude -p, ~2-3 min)
# ============================================================

echo "--- Layer 2: Behavioral verification ---"
echo ""

# Test 11: Claude knows writing-plans auto-routes
echo "Test 11: Claude recognizes auto-routing in writing-plans..."
output=$(run_claude "Read the writing-plans skill. After the plan is saved, does it ask the user to choose an execution strategy or does it auto-select? Quote the relevant section." 60)

if echo "$output" | grep -qi "auto\|automatically\|not ask\|doesn't ask\|no choice"; then
    echo "  [PASS] Claude recognizes auto-routing"
else
    echo "  [FAIL] Claude doesn't recognize auto-routing"
    echo "  Output: $(echo "$output" | head -5)"
    exit 1
fi

echo ""

# Test 12: Claude knows executing-plans is internal fallback
echo "Test 12: Claude recognizes executing-plans as internal fallback..."
output=$(run_claude "Read the executing-plans skill. Is this a skill users should select directly, or is it an internal fallback? Explain based on the skill content." 60)

if echo "$output" | grep -qi "internal\|fallback\|not.*direct\|not.*user\|automatic"; then
    echo "  [PASS] Claude recognizes executing-plans as internal fallback"
else
    echo "  [FAIL] Claude doesn't recognize executing-plans as fallback"
    echo "  Output: $(echo "$output" | head -5)"
    exit 1
fi

echo ""

# Test 13: Claude knows subagent-driven is auto-selected
echo "Test 13: Claude recognizes subagent-driven is auto-selected..."
output=$(run_claude "Read the subagent-driven-development skill. How is this skill activated — does the user choose it manually, or is it auto-selected by writing-plans? Quote the When to Use section." 60)

if echo "$output" | grep -qi "auto.*select\|automatically\|auto-invokes\|no user choice"; then
    echo "  [PASS] Claude recognizes auto-selection"
else
    echo "  [FAIL] Claude doesn't recognize auto-selection"
    echo "  Output: $(echo "$output" | head -5)"
    exit 1
fi

echo ""
echo "=== All Smart Execution Router tests passed ==="
