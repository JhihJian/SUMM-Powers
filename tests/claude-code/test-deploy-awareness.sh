#!/usr/bin/env bash
set -euo pipefail

# Test for deploy-awareness skill
# Usage: ./run-skill-tests.sh --test test-deploy-awareness.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RESULTS=()
OVERALL=0

# ============================================================
# Setup: Create a temp project with DEPLOY.md
# ============================================================
setup_project() {
    local project_dir=$(create_test_project)

    # Create DEPLOY.md
    cat > "$project_dir/DEPLOY.md" <<'DEPLOY'
# DEPLOY.md

## Environments

| Name | URL | Purpose |
|------|-----|---------|
| dev | http://localhost:8080 | local development |
| staging | https://staging.myapp.io | pre-release |
| prod | https://myapp.io | production |

## Deployment

- **Method**: CI/CD
- **Command/Pipeline**: `make deploy ENV=staging`
- **Rollback**: `make rollback ENV=staging`

## Dependencies

| Service | Address | Credentials |
|---------|---------|-------------|
| PostgreSQL | db.internal:5432 | See `.env` |
| Redis | cache.internal:6379 | None |

## Configuration

- **Environment Variables**: `.env.example`
- **Config Files**: `config/app.yaml`

## Monitoring

- **Logs**: https://logs.myapp.io
- **Alerts**: PagerDuty #oncall channel
DEPLOY

    # Create docker-compose.yml (for update trigger tests)
    cat > "$project_dir/docker-compose.yml" <<'DOCKER'
version: '3.8'
services:
  web:
    build: .
    ports:
      - "8080:8080"
    depends_on:
      - db
      - redis
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
  redis:
    image: redis:7
DOCKER

    echo "$project_dir"
}

# ============================================================
# Test 1: Read trigger — user asks about staging environment
# ============================================================
test_read_trigger_env_question() {
    local project_dir="$1"
    local test_name="Read trigger: user asks about staging"

    local output=$(run_claude "In the project at $project_dir, I need to test against the staging environment. What's the staging URL and how do I deploy there?" 90 "Bash,Read" 2>&1 || true)

    if assert_contains "$output" "staging" "$test_name: mentions staging"; then
        RESULTS+=("PASS: $test_name")
    else
        RESULTS+=("FAIL: $test_name")
        OVERALL=1
    fi
}

# ============================================================
# Test 2: Read trigger — functional testing scenario
# ============================================================
test_read_trigger_functional_test() {
    local project_dir="$1"
    local test_name="Read trigger: functional testing needs environment"

    local output=$(run_claude "In the project at $project_dir, I just finished implementing the user registration feature. I need to do functional testing on a real environment. What environment should I use and how do I access it?" 90 "Bash,Read" 2>&1 || true)

    if assert_contains "$output" "staging\|environment\|deploy\|localhost" "$test_name: mentions environment info"; then
        RESULTS+=("PASS: $test_name")
    else
        RESULTS+=("FAIL: $test_name")
        OVERALL=1
    fi
}

# ============================================================
# Test 3: Update trigger — modifying docker-compose
# ============================================================
test_update_trigger_docker() {
    local project_dir="$1"
    local test_name="Update trigger: docker-compose modification"

    # Add a new service to docker-compose
    local output=$(run_claude "In the project at $project_dir, please add a RabbitMQ service to the docker-compose.yml file. Use image rabbitmq:3-management with port 5672." 120 "Bash,Read,Edit,Write" 2>&1 || true)

    if assert_contains "$output" "DEPLOY\|deploy\|Dependencies\|dependencies" "$test_name: mentions DEPLOY.md or dependencies"; then
        RESULTS+=("PASS: $test_name")
    else
        RESULTS+=("FAIL: $test_name")
        OVERALL=1
    fi
}

# ============================================================
# Test 4: No trigger — pure business logic change
# ============================================================
test_no_trigger_business_logic() {
    local project_dir="$1"
    local test_name="No trigger: business logic change should not mention DEPLOY"

    local output=$(run_claude "In the project at $project_dir, I have a file src/utils.js with a function called formatDate. Please change it so that it outputs dates in YYYY-MM-DD format instead of MM/DD/YYYY." 90 "Bash,Read,Edit,Write" 2>&1 || true)

    if assert_not_contains "$output" "DEPLOY\|deploy" "$test_name: does NOT mention DEPLOY"; then
        RESULTS+=("PASS: $test_name")
    else
        RESULTS+=("FAIL: $test_name")
        OVERALL=1
    fi
}

# ============================================================
# Test 5: Template — user asks to create DEPLOY.md
# ============================================================
test_template_creation() {
    local project_dir="$1"
    local test_name="Template: user asks to create DEPLOY.md"

    # Use a project WITHOUT DEPLOY.md
    local empty_project=$(create_test_project)
    mkdir -p "$empty_project/src"

    local output=$(run_claude "In the project at $empty_project, please help me create a DEPLOY.md file for my project. It's a Node.js app with PostgreSQL and Redis, deployed via GitHub Actions to AWS." 120 "Bash,Read,Edit,Write" 2>&1 || true)

    if assert_contains "$output" "Environment\|environment" "$test_name: includes Environments section"; then
        RESULTS+=("PASS: $test_name")
    else
        RESULTS+=("FAIL: $test_name")
        OVERALL=1
    fi

    if assert_contains "$output" "Dependen" "$test_name: includes Dependencies section"; then
        RESULTS+=("PASS: $test_name (dependencies)")
    else
        RESULTS+=("FAIL: $test_name (dependencies)")
        OVERALL=1
    fi

    cleanup_test_project "$empty_project"
}

# ============================================================
# Main
# ============================================================
echo "=== deploy-awareness skill tests ==="
echo ""

PROJECT_DIR=$(setup_project)
echo "Test project: $PROJECT_DIR"
echo ""

test_read_trigger_env_question "$PROJECT_DIR"
test_read_trigger_functional_test "$PROJECT_DIR"
test_update_trigger_docker "$PROJECT_DIR"
test_no_trigger_business_logic "$PROJECT_DIR"
test_template_creation "$PROJECT_DIR"

# Cleanup
cleanup_test_project "$PROJECT_DIR"

# Summary
echo ""
echo "=== Results ==="
for result in "${RESULTS[@]}"; do
    echo "  $result"
done
echo ""
if [ $OVERALL -eq 0 ]; then
    echo "All tests passed!"
else
    echo "Some tests failed."
fi

exit $OVERALL
