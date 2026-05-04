#!/usr/bin/env bash
# Test: Retro Skill structural verification
# Verifies SKILL.md has valid frontmatter, all 5 analysis dimensions, report format,
# issue generation logic, and state schema consistency
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILLS_DIR="$(cd "$SCRIPT_DIR/../../skills" && pwd)"
SKILL_FILE="$SKILLS_DIR/retro/SKILL.md"
SCHEMA_FILE="$SKILLS_DIR/retro/state-schema.md"

echo "=== Test: Retro Skill ==="
echo ""

# ============================================================
# Layer 1: File existence and frontmatter
# ============================================================

echo "--- Layer 1: Files and frontmatter ---"
echo ""

# Test 1: SKILL.md exists
echo "Test 1: SKILL.md exists..."
if [ ! -f "$SKILL_FILE" ]; then
    echo "  [FAIL] skills/retro/SKILL.md does not exist"
    exit 1
fi
echo "  [PASS] SKILL.md exists"

# Test 2: Valid YAML frontmatter with name
echo "Test 2: frontmatter has 'name: retro'..."
name_line=$(head -5 "$SKILL_FILE" | grep "^name:" || true)
if [ -z "$name_line" ]; then
    echo "  [FAIL] Missing 'name:' in frontmatter"
    exit 1
fi
if ! echo "$name_line" | grep -q "retro"; then
    echo "  [FAIL] name is not 'retro'"
    exit 1
fi
echo "  [PASS] frontmatter name is retro"

# Test 3: frontmatter has description
echo "Test 3: frontmatter has description..."
if ! head -10 "$SKILL_FILE" | grep -q "^description:"; then
    echo "  [FAIL] Missing 'description:' in frontmatter"
    exit 1
fi
echo "  [PASS] frontmatter has description"

# Test 4: state-schema.md exists
echo "Test 4: state-schema.md exists..."
if [ ! -f "$SCHEMA_FILE" ]; then
    echo "  [FAIL] skills/retro/state-schema.md does not exist"
    exit 1
fi
echo "  [PASS] state-schema.md exists"

# ============================================================
# Layer 2: Five analysis dimensions
# ============================================================

echo ""
echo "--- Layer 2: Five analysis dimensions ---"
echo ""

dimensions=(
    "Plan Accuracy"
    "Skill Coverage"
    "Code Pattern"
    "Workflow Efficiency"
    "Skill Quality"
)

i=5
for dim in "${dimensions[@]}"; do
    echo "Test $i: Analysis dimension '$dim' exists..."
    if ! grep -qi "$dim" "$SKILL_FILE"; then
        echo "  [FAIL] Missing analysis dimension: $dim"
        exit 1
    fi
    echo "  [PASS] Dimension '$dim' found"
    i=$((i + 1))
done

# ============================================================
# Layer 3: Workflow steps
# ============================================================

echo ""
echo "--- Layer 3: Workflow steps ---"
echo ""

workflow_steps=(
    "Data Collection\|Collect Data\|数据采集\|Phase 1"
    "Analysis\|分析引擎\|Phase 2"
    "Pattern Recognition\|模式识别\|Pattern"
    "Report\|报告"
    "Issue\|Issue"
)

for step in "${workflow_steps[@]}"; do
    echo "Test $i: Workflow step matching '$step' exists..."
    if ! grep -qi "$step" "$SKILL_FILE"; then
        echo "  [FAIL] Missing workflow step: $step"
        exit 1
    fi
    echo "  [PASS] Workflow step found"
    i=$((i + 1))
done

# ============================================================
# Layer 4: Report format and issue generation
# ============================================================

echo ""
echo "--- Layer 4: Report and issues ---"
echo ""

# Test: Report format section
echo "Test $i: Report format section exists..."
if ! grep -qi "retro report\|报告格式" "$SKILL_FILE"; then
    echo "  [FAIL] Missing report format section"
    exit 1
fi
echo "  [PASS] Report format section found"
i=$((i + 1))

# Test: Four finding types
echo "Test $i: Four finding types (流程/技能缺陷/Bug/技能优化)..."
finding_types=("流程" "技能缺陷" "Bug" "技能优化")
for ftype in "${finding_types[@]}"; do
    if ! grep -q "$ftype" "$SKILL_FILE"; then
        echo "  [FAIL] Missing finding type: $ftype"
        exit 1
    fi
done
echo "  [PASS] All four finding types found"
i=$((i + 1))

# Test: gh issue create mentioned
echo "Test $i: Issue creation via gh CLI..."
if ! grep -qi "gh issue create\|gh issue" "$SKILL_FILE"; then
    echo "  [FAIL] Missing gh issue create instructions"
    exit 1
fi
echo "  [PASS] gh issue create instructions found"
i=$((i + 1))

# Test: Pattern Library in schema
echo "Test $i: Pattern Library in state schema..."
if ! grep -qi "pattern library" "$SCHEMA_FILE"; then
    echo "  [FAIL] Missing Pattern Library in state schema"
    exit 1
fi
echo "  [PASS] Pattern Library found in state schema"

echo ""
echo "=== All tests passed ==="
