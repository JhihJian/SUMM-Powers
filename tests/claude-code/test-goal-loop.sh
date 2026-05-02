#!/usr/bin/env bash
# Test: goal-loop skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: goal-loop skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the goal-loop skill? Describe its purpose briefly." 30)

if assert_contains "$output" "goal-loop\|Goal Loop\|Goal loop" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "iterat\|循环\|循环" "Mentions iteration"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify default max-iterations
echo "Test 2: Default max-iterations..."

output=$(run_claude "In the goal-loop skill, what is the default maximum number of iterations if the user does not specify --max-iterations?" 30)

if assert_contains "$output" "10" "Default is 10"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify self-evaluation three questions
echo "Test 3: Self-evaluation criteria..."

output=$(run_claude "In the goal-loop skill, what are the three self-evaluation questions that determine if the goal is met? List all three." 30)

if assert_contains "$output" "goal.*met\|met.*goal\|目标.*达成\|达成.*目标" "Criterion 1: goal met"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "side.?effect\|副作用\|no.*new.*problem\|regression" "Criterion 2: no side effects"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "continu\|收益\|diminish\|worth.*continu\|worthwhile" "Criterion 3: worth continuing"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify skill mapping
echo "Test 4: Skill mapping for architecture items..."

output=$(run_claude "In the goal-loop skill, which SUMM skill should be loaded for an architecture or structure improvement item?" 30)

if assert_contains "$output" "improve-architecture" "Architecture maps to improve-architecture"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify one item per iteration constraint
echo "Test 5: One item per iteration..."

output=$(run_claude "In the goal-loop skill, how many improvement items should be executed per iteration? Is it one or multiple?" 30)

if assert_contains "$output" "one\b\|single\|1 item\|一个" "One item per iteration"; then
    : # pass
else
    exit 1
fi

if assert_not_contains "$output" "multiple.*item\|several.*item\|all.*item\|多个.*改进" "Not multiple items"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify state file path
echo "Test 6: State file path..."

output=$(run_claude "In the goal-loop skill, what is the exact file path of the state file that tracks iteration progress?" 30)

if assert_contains "$output" "\.claude/goal-loop-state\.md" "Correct state file path"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 7: Verify completion promise format
echo "Test 7: Completion promise format..."

output=$(run_claude "In the goal-loop skill, what XML tag format does the completion promise use when the goal is met?" 30)

if assert_contains "$output" "goal-loop-complete" "Completion promise tag"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 8: Verify iteration limit handling
echo "Test 8: Iteration limit handling (ABORTED)..."

output=$(run_claude "In the goal-loop skill, what happens when the maximum iteration limit is reached but the goal is not yet fully met? What is the status set to?" 30)

if assert_contains "$output" "ABORTED" "Status set to ABORTED"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "progress\|remaining\|backlog\|建议\|suggest" "Progress preserved with suggestions"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 9: Verify dev-loop conflict detection
echo "Test 9: Dev-loop conflict detection..."

output=$(run_claude "In the goal-loop skill, what does the pre-flight check look for before starting the loop? What potential conflict does it detect?" 30)

if assert_contains "$output" "dev-loop\|dev_loop" "Detects dev-loop"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "plan" "Mentions plans"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All goal-loop skill tests passed ==="
