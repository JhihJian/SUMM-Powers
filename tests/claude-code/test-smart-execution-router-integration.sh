#!/usr/bin/env bash
# Integration Test: Smart Execution Router
# Simulates the writing-plans → Execution Handoff flow end-to-end
# Verifies that writing-plans auto-routes to Subagent-Driven without asking user to choose
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "========================================"
echo " Integration Test: Smart Execution Router"
echo "========================================"
echo ""
echo "This test simulates the writing-plans → execution handoff flow and verifies:"
echo "  1. writing-plans does NOT ask 'Which approach?'"
echo "  2. writing-plans auto-selects Subagent-Driven"
echo "  3. writing-plans announces execution strategy without waiting"
echo ""
echo "WARNING: This test may take 5-10 minutes."
echo ""

# Create a minimal test spec and plan to trigger the execution handoff
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"
trap "cleanup_test_project $TEST_PROJECT" EXIT

cd "$TEST_PROJECT"

# Set up minimal project structure
mkdir -p docs/superpowers/specs docs/superpowers/plans src

# Create a minimal spec
cat > docs/superpowers/specs/test-spec-design.md <<'SPEC'
# Test Feature

## Problem
Need a simple add function.

## Solution
Create an add(a, b) function in src/math.js.

## Files Changed
- Create: src/math.js

## What Doesn't Change
- Everything else
SPEC

# Create a minimal plan (simulating what writing-plans would produce)
cat > docs/superpowers/plans/test-feature.md <<'PLAN'
# Test Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summ:subagent-driven-development (recommended) or summ:executing-plans to implement this plan task-by-task.

**Goal:** Create an add function

**Architecture:** Simple function in a single file

**Tech Stack:** JavaScript

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| src/math.js | Create | add function |

## Task Index

| # | Task | Files | Complexity | Notes |
|---|------|-------|------------|-------|
| 1 | Create add function | src/math.js | S | Simple function |

---

### Task 1: Create add function

**Files:**
- Create: src/math.js

- [ ] **Step 1:** Create src/math.js with add(a, b) function
- [ ] **Step 2:** Verify it works
PLAN

echo "Plan created at docs/superpowers/plans/test-feature.md"
echo ""

# Test: Give Claude the writing-plans skill context and ask it to complete the plan
# Then verify the execution handoff behavior
echo "Test 1: Simulating writing-plans completion → execution handoff..."
echo ""

# We ask Claude to act as if it just finished writing the plan,
# and observe what it does at the Execution Handoff stage
output=$(run_claude "You are in the SUMM-Powers project at $(pwd). You just finished writing an implementation plan saved to docs/superpowers/plans/test-feature.md. Based on the writing-plans skill's Execution Handoff section, what do you do next? Do NOT actually execute anything. Just describe what you would do at the Execution Handoff step, quoting the relevant parts of the skill." 120)

echo "Claude's response:"
echo "$output" | sed 's/^/  /'
echo ""

# Verify: should NOT ask user to choose
if echo "$output" | grep -qi "Which approach\|which approach\|choose.*execution\|select.*approach\|pick.*option"; then
    echo "  [FAIL] Claude still asks user to choose execution strategy"
    echo "  Found question about choosing in output"
    exit 1
fi
echo "  [PASS] Does NOT ask user to choose execution strategy"

# Verify: should auto-select Subagent-Driven
if echo "$output" | grep -qi "subagent.driven\|subagent-driven\|Subagent-Driven"; then
    echo "  [PASS] Auto-selects Subagent-Driven"
else
    echo "  [FAIL] Does not mention Subagent-Driven as the default"
    exit 1
fi

# Verify: should mention auto-start / no question
if echo "$output" | grep -qi "automatically\|auto.*start\|immediately\|not ask\|without asking\|no choice"; then
    echo "  [PASS] Mentions automatic execution / no user choice needed"
else
    echo "  [FAIL] Does not mention automatic behavior"
    exit 1
fi

echo ""

# Test 2: Verify executing-plans is recognized as fallback only
echo "Test 2: Verify executing-plans is only a fallback..."
output=$(run_claude "In the SUMM-Powers project at $(pwd), if I ask you to execute a plan, would you use the executing-plans skill? Under what circumstances would that skill be used? Read the skill file to answer." 60)

if echo "$output" | grep -qi "internal\|fallback\|not available\|no subagent\|platform.*without\|automatically.*invoked"; then
    echo "  [PASS] executing-plans described as internal/fallback"
else
    echo "  [FAIL] executing-plans not recognized as internal fallback"
    echo "  Output: $(echo "$output" | head -5)"
    exit 1
fi

# Should NOT be described as a user-selectable option
# Use negative lookahead: match "select" only when NOT preceded by "not" or "NOT"
if echo "$output" | grep -qi "you can choose\|you should choose\|option.*pick\|pick one\|select.*executing-plans\|choose.*executing-plans"; then
    echo "  [FAIL] executing-plans still described as user-selectable"
    exit 1
fi
echo "  [PASS] executing-plans NOT described as user-selectable"

echo ""
echo "========================================"
echo " All Smart Execution Router integration tests passed"
echo "========================================"
