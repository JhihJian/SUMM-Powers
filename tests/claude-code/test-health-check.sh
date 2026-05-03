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