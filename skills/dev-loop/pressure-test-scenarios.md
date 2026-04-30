---
name: dev-loop-pressure-tests
description: Pressure test scenarios for the dev-loop skill
type: reference
---

# dev-loop Pressure Test Scenarios

These scenarios verify the dev-loop skill handles all state transitions correctly. Each scenario describes a situation and the expected behavior.

## Scenario 1: Happy Path (Full Loop)

**Given:** A requirement "Add user registration API endpoint"
**Expected flow:**
1. Master agent loads `summ:brainstorming`, produces design
2. Master agent loads `summ:writing-plans`, produces plan with 3 tasks
3. Master dispatches 3 TDD workers via `ao spawn`
4. All 3 workers report DONE
5. Master runs code review on all PRs — all pass
6. Master dispatches deploy worker — deploy succeeds
7. Master dispatches E2E worker — tests pass
8. Master evaluates value proof — PASS
9. Master archives evidence and notifies human

**Verify:** State transitions: PLANNING → BUILDING → DELIVERING → VALIDATING → DONE. loopCount stays at 1.

## Scenario 2: Worker Returns BLOCKED

**Given:** A requirement with a task that depends on an external API
**Expected flow:**
1. Planning proceeds normally
2. Worker dispatched for the API-dependent task
3. Worker reports BLOCKED: "External API returns 403, need API key"
4. Master assesses: cannot resolve without human input
5. Master transitions to ESCALATED
6. Master notifies human with blocker details

**Verify:** State reaches ESCALATED, not DONE. Human receives actionable notification.

## Scenario 3: Code Review Finds Issues

**Given:** A requirement where TDD workers complete but code has quality issues
**Expected flow:**
1. Planning → dispatch workers → all report DONE
2. Code review finds: missing error handling, hardcoded values
3. Master transitions back to BUILDING.TDD_IMPLEMENTING
4. Master dispatches fix workers with specific review feedback
5. Fix workers report DONE
6. Code review passes on second attempt
7. Continue to DELIVERING

**Verify:** loopCount increments to 2. Re-dispatch targets only the problematic tasks.

## Scenario 4: Deploy Failure

**Given:** Workers complete and review passes, but deployment fails
**Expected flow:**
1. DELIVERING.DEPLOYING starts
2. Deploy worker reports failure: "Port already in use"
3. Master transitions back to BUILDING.TDD_IMPLEMENTING
4. Fix worker resolves the configuration issue
5. Re-review passes → re-deploy succeeds
6. Continue to E2E

**Verify:** Failure in DELIVERING routes back to BUILDING, not PLANNING.

## Scenario 5: E2E Test Failure

**Given:** Deployment succeeds but E2E tests fail
**Expected flow:**
1. DELIVERING.E2E_VERIFYING starts
2. E2E worker runs Playwright tests — 2 of 5 fail
3. Master transitions back to BUILDING.TDD_IMPLEMENTING
4. Fix workers address the failing test scenarios
5. Re-deploy → E2E passes on second attempt

**Verify:** E2E failure routes back to BUILDING.TDD_IMPLEMENTING, not DELIVERING.DEPLOYING.

## Scenario 6: Value Proof Fails — Requirement Misunderstood

**Given:** Implementation technically works but doesn't match the original requirement
**Expected flow:**
1. Full pipeline completes (TDD, review, deploy, E2E all pass)
2. Master evaluates value proof: "Requirement was 'user registration' but implementation is 'user invitation'"
3. Master identifies this as a requirement misunderstanding
4. Master transitions back to PLANNING.BRAINSTORMING
5. loopCount increments to 2
6. Re-planning with corrected understanding

**Verify:** Routes back to PLANNING (requirement gap), not BUILDING. loopCount = 2.

## Scenario 7: Value Proof Fails — Partial Implementation

**Given:** Some features are missing from the implementation
**Expected flow:**
1. Full pipeline completes
2. Value proof: "Requirement includes email verification but it's not implemented"
3. Master identifies as partial implementation
4. Master transitions back to BUILDING.TDD_IMPLEMENTING
5. Dispatches workers for missing features only

**Verify:** Routes back to BUILDING (missing features), not PLANNING. Only missing tasks dispatched.

## Scenario 8: Max Loop Count Exceeded

**Given:** The workflow has looped 3 times and still fails
**Expected flow:**
1. loopCount reaches 3 after a third loop-back
2. Master transitions to ESCALATED regardless of failure type
3. Master includes full history: all 3 attempts, what failed each time, what was tried
4. Human receives comprehensive escalation report

**Verify:** No 4th loop attempt. Escalation includes diagnostic history.

## Scenario 9: Multiple Independent Tasks with Mixed Results

**Given:** Plan has 4 tasks; 3 complete successfully, 1 fails
**Expected flow:**
1. 4 workers dispatched in parallel
2. 3 report DONE, 1 reports BLOCKED
3. Master assesses the BLOCKED task
4. If resolvable with more context → re-dispatch with additional context
5. If unresolvable → proceed with completed tasks, escalate the blocked one
6. Value proof evaluates only the completed scope

**Verify:** Successful tasks are not blocked by one failure. Partial delivery is possible.

## Scenario 10: Worker Prompt Contains Correct Skill Injection

**Given:** Master dispatches a TDD worker
**Expected:**
- Worker prompt includes "Load skill summ:test-driven-development"
- Worker prompt includes the full task text from the plan
- Worker prompt includes report format template
- Worker prompt constrains scope to assigned task only

**Verify:** Worker prompt template includes all 4 required elements.
