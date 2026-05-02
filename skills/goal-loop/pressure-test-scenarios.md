# Goal-Loop Pressure Test Scenarios

These scenarios test the goal-loop skill's behavior across various edge cases and workflows. Each scenario specifies the situation, expected agent behavior, and verification points in the state file.

## Scenario 1: Happy path — goal achieved in 3 iterations

**Situation**: User runs goal-loop with a linting goal. The initial assessment finds 3 lint warnings. Each iteration fixes one warning, and the self-evaluation confirms progress. By iteration 3, all warnings are resolved and the self-evaluation passes all criteria.

**Expected behavior**:
1. Parse user goal: "Fix all linting warnings in the codebase"
2. Run initial assessment: find 3 lint warnings (unused imports, inconsistent naming, missing docs)
3. Create backlog with 3 items, prioritize and select 1 for iteration 1
4. Call SUMM skill (tdd) to fix first warning
5. Run self-evaluation: criterion 1 (lint warnings reduced) ✓, criterion 2 (tests pass) ✓, criterion 3 (no regressions) ✓
6. Update state: iteration_count=1, status=IN_PROGRESS, backlog now has 2 items
7. Select next backlog item for iteration 2
8. Call SUMM skill (tdd) to fix second warning
9. Run self-evaluation: all criteria ✓
10. Update state: iteration_count=2, backlog has 1 item
11. Select final backlog item for iteration 3
12. Call SUMM skill (tdd) to fix third warning
13. Run self-evaluation: all criteria ✓, no backlog items remain
14. Update state: iteration_count=3, status=COMPLETED, final_evaluation=PASSED
15. Output completion promise summarizing achievements and next steps

**Verify** in state file:
- `iteration_count` should be 3
- `status` should be "COMPLETED"
- `final_evaluation` should be "PASSED"
- `backlog` should be empty array
- `initial_assessment` should contain the 3 discovered issues
- `iteration_history` should have 3 entries with skill calls and evaluation results

---

## Scenario 2: Iteration limit reached

**Situation**: User provides a goal that's too large for the default 5-iteration limit. After 5 iterations, progress is made but the goal is not fully achieved. The loop should preserve progress and exit gracefully.

**Expected behavior**:
1. Parse user goal: "Refactor the entire authentication system"
2. Run initial assessment: discover 12 improvement areas (database queries, error handling, security fixes, performance, documentation, testing)
3. Create backlog with 12 items, prioritize and select top 5 for 5 iterations
4. Execute iterations 1-5, each calling appropriate SUMM skills
5. After iteration 5, run self-evaluation: criterion 1 (progress made) ✓, but criterion 2 (goal completed) ✗
6. Check iteration limit: 5/5 reached, cannot continue
7. Update state: status="ABORTED", iteration_count=5, abort_reason="iteration_limit_reached"
8. Output partial completion message:
   - What was achieved (5/12 items completed)
   - Remaining work summary
   - Guidance on how to continue (re-run goal-loop with refined goal, or manually execute remaining backlog items)
9. Preserve all state for potential continuation

**Verify** in state file:
- `iteration_count` should be 5
- `status` should be "ABORTED"
- `abort_reason` should be "iteration_limit_reached"
- `backlog` should have 7 remaining items (12 initial - 5 completed)
- `iteration_history` should have 5 entries
- `initial_assessment` should document the full scope (12 areas)
- All completed work should be preserved in `iteration_history`

---

## Scenario 3: Self-evaluation catches new problem

**Situation**: During iteration 2, a refactoring task breaks existing tests. The self-evaluation fails criterion 2 (tests passing), discovers the regression, and adds a fix item to the backlog.

**Expected behavior**:
1. Parse user goal: "Improve code quality in the payment module"
2. Run initial assessment: find 4 improvement areas
3. Create backlog, select item for iteration 1 (improve error handling)
4. Call SUMM skill (tdd), complete successfully
5. Run self-evaluation: all criteria ✓
6. Select item for iteration 2 (extract complex method)
7. Call SUMM skill (improve-architecture)
8. Run self-evaluation:
   - Criterion 1 (improvement made) ✓
   - Criterion 2 (tests pass) ✗ — 3 test failures detected
   - Criterion 3 (no regressions) ✗ — new failures indicate regression
9. Analyze test failures: identify that method extraction broke caller contracts
10. Add fix item to backlog with high priority: "Fix broken tests from method extraction"
11. Update state: status="IN_PROGRESS", backlog now has 4 items (3 remaining + 1 new)
12. Select high-priority fix item for iteration 3
13. Call SUMM skill (debugging) to fix the broken tests
14. Run self-evaluation: all criteria ✓
15. Continue with remaining backlog items

**Verify** in state file:
- `iteration_history[1]` should show evaluation with criterion_2="FAILED" and criterion_3="FAILED"
- `iteration_history[1].evaluation.notes` should describe the test failures
- `backlog` should show a new high-priority item added during iteration 2
- `iteration_history[2]` should show the fix was executed successfully
- The system demonstrates adaptive behavior: catching problems and self-correcting

---

## Scenario 4: Backlog evolves — new items discovered

**Situation**: During the assessment phase of iteration 3, the agent discovers new improvement areas that weren't visible in the initial assessment. These are added to the backlog dynamically.

**Expected behavior**:
1. Parse user goal: "Optimize the user profile API"
2. Run initial assessment: find 3 improvement areas (database indexing, response caching, query optimization)
3. Create backlog with 3 items, execute iterations 1-2 successfully
4. Before iteration 3, run updated assessment:
   - Re-run tools (linter, complexity analysis, performance profiler)
   - Discover 2 new issues: N+1 query problem, unnecessary data fetching
5. Add 2 new items to backlog: "Fix N+1 query problem", "Remove unnecessary data fetching"
6. Re-prioritize backlog (new items get high priority due to performance impact)
7. Select new high-priority item for iteration 3
8. Call SUMM skill (improve-architecture) to fix N+1 query
9. Run self-evaluation: all criteria ✓
10. Continue with remaining items

**Verify** in state file:
- `backlog` should show 5 total items (3 initial + 2 discovered)
- `iteration_history[2].assessment` should document the new findings
- `iteration_history[2].assessment.new_discoveries` should list the 2 new issues
- The backlog should be re-prioritized with new items marked as high priority
- The system demonstrates adaptive discovery: finding hidden issues as work progresses

---

## Scenario 5: Goal already met at start

**Situation**: User provides a goal that's already satisfied. The initial assessment finds no issues to address, so the loop completes immediately.

**Expected behavior**:
1. Parse user goal: "Ensure all code follows style guidelines"
2. Run initial assessment:
   - Run linter: 0 warnings
   - Check complexity: all functions within limits
   - Review test coverage: 95% (above threshold)
3. Assessment result: no improvements needed
4. Create empty backlog
5. Check iteration loop condition: backlog is empty, cannot iterate
6. Update state: iteration_count=0, status="COMPLETED", final_evaluation="GOAL_ALREADY_MET"
7. Output message: "Goal already satisfied. No improvements needed."
8. Provide summary of current state (all metrics passing)

**Verify** in state file:
- `iteration_count` should be 0
- `status` should be "COMPLETED"
- `final_evaluation` should be "GOAL_ALREADY_MET"
- `backlog` should be empty array
- `initial_assessment` should document all passing metrics
- `iteration_history` should be empty
- The system efficiently handles the edge case of completed work

---

## Scenario 6: Multiple goals in one statement

**Situation**: User provides a compound goal statement covering multiple areas (e.g., "Fix linting, improve performance, and add tests"). The system treats this as a single goal with a backlog spanning multiple domains.

**Expected behavior**:
1. Parse user goal: "Fix linting, improve performance, and add tests"
2. Run initial assessment across all three domains:
   - Linting: 5 warnings found
   - Performance: 3 bottlenecks identified
   - Tests: 4 missing test cases
3. Create backlog with 12 items total (5 lint + 3 performance + 4 tests)
4. Prioritize backlog by impact (performance issues first, then critical tests, then style warnings)
5. Execute iterations 1-5:
   - Iteration 1: Fix performance bottleneck (improve-architecture)
   - Iteration 2: Fix performance bottleneck (improve-architecture)
   - Iteration 3: Fix performance bottleneck (improve-architecture)
   - Iteration 4: Add critical test case (tdd)
   - Iteration 5: Fix linting warning (to-do-it)
6. After 5 iterations, check self-evaluation: progress made but goal not complete
7. Output partial completion: 5/12 items completed
8. Preserve state with 7 remaining backlog items

**Verify** in state file:
- `goal` should capture the full compound statement
- `backlog` should have 12 items across 3 domains
- `iteration_history` should show different SUMM skills called based on item type
  - improve-architecture for performance items
  - tdd for test items
  - to-do-it for linting items
- The system treats the compound goal as a single cohesive goal with a unified backlog

---

## Scenario 7: Skill correctly selects appropriate SUMM skill

**Situation**: The backlog contains items of different types (architecture, TDD, debugging, to-do-it). The system must map each item type to the correct SUMM skill.

**Expected behavior**:
1. Parse user goal: "Improve overall code quality"
2. Run initial assessment: discover items of various types:
   - Architectural issues: tight coupling, violation of SRP, missing abstractions
   - Test gaps: untested critical paths, edge cases
   - Bug reports: known issues in issue tracker
   - Minor tasks: documentation, comments, naming consistency
3. Create backlog with categorized items:
   - Item 1: "Extract payment processing into separate service" (type: architecture)
   - Item 2: "Add test for error handling in checkout" (type: test)
   - Item 3: "Fix timeout issue in API client" (type: bug)
   - Item 4: "Improve variable names in utils module" (type: minor)
   - Item 5: "Introduce payment gateway interface" (type: architecture)
4. Execute iterations with correct skill mapping:
   - Iteration 1: Call `improve-architecture` skill for Item 1
   - Iteration 2: Call `tdd` skill for Item 2
   - Iteration 3: Call `debugging` skill for Item 3
   - Iteration 4: Call `to-do-it` skill for Item 4
   - Iteration 5: Call `improve-architecture` skill for Item 5
5. Verify each iteration's self-evaluation passes

**Verify** in state file:
- `backlog` items should have `type` field categorizing each item
- `iteration_history` entries should show:
  - `iteration_history[0].skill_called` = "improve-architecture"
  - `iteration_history[1].skill_called` = "tdd"
  - `iteration_history[2].skill_called` = "debugging"
  - `iteration_history[3].skill_called` = "to-do-it"
  - `iteration_history[4].skill_called` = "improve-architecture"
- The skill mapping logic should be demonstrably correct across all item types

---

## Scenario 8: State file persists across context compaction

**Situation**: The goal loop runs for many iterations, causing context to grow large and trigger compaction. The state file ensures continuity after compaction.

**Expected behavior**:
1. Parse user goal: "Comprehensive refactoring of entire codebase"
2. Run initial assessment: discover 30 improvement areas
3. Create backlog with 30 items
4. Execute iterations 1-8:
   - Each iteration calls SUMM skill, runs self-evaluation, updates state
   - Context grows with each iteration's output
5. After iteration 8, context approaches size limit (~200K tokens)
6. Context compaction occurs: older context dropped, but state file preserved
7. Continue with iteration 9:
   - Read state file to recover current status
   - Determine remaining backlog (22 items)
   - Check iteration count (8)
   - Execute iteration 9 normally
8. Continue iterations 10-15 similarly
9. Complete goal by iteration 15

**Verify** in state file:
- State file should be updated after every iteration
- State file should contain all essential data:
  - `iteration_count` (15)
  - `status` ("COMPLETED")
  - `backlog` (empty at end)
  - `iteration_history` (15 entries)
  - `initial_assessment`
  - `final_evaluation`
- After context compaction, the agent should read the state file and resume seamlessly
- The state file should be the single source of truth for loop continuity

---

## Scenario 9: User provides no --max-iterations

**Situation**: User runs goal-loop without specifying --max-iterations. The system should default to 10 iterations.

**Expected behavior**:
1. Parse user goal: "Improve code quality"
2. Check command-line arguments: no --max-iterations provided
3. Apply default: max_iterations = 10
4. Run initial assessment: discover 15 improvement areas
5. Create backlog with 15 items, select top 10 for iterations
6. Execute iterations 1-10 successfully
7. After iteration 10, check iteration limit: 10/10 reached
8. Run final self-evaluation: criterion 1 (progress made) ✓, criterion 2 (goal completed) ✗
9. Update state: status="ABORTED", abort_reason="iteration_limit_reached"
10. Output partial completion: 10/15 items completed, 5 remaining
11. Suggest re-running with refined goal or higher --max-iterations

**Verify** in state file:
- `max_iterations` should be 10 (default)
- `iteration_count` should be 10
- `status` should be "ABORTED"
- `backlog` should have 5 remaining items
- The default behavior should be clearly documented in the state
- The user should receive guidance on how to complete remaining work

---

## Scenario 10: Conflict with active dev-loop plan

**Situation**: User runs goal-loop while an active dev-loop plan exists in the workspace. The system detects the conflict and warns the user.

**Expected behavior**:
1. Parse user goal: "Improve API performance"
2. Check for active dev-loop plan:
   - Look for `.claude/dev-loop/plan.md` or similar state file
   - Found active plan with status "IN_PROGRESS"
3. Detect conflict: dev-loop and goal-loop both manage iterative development
4. Warn user with clear message:
   - "Active dev-loop plan detected in workspace"
   - "Running goal-loop simultaneously may cause conflicts"
   - "Options: (a) Stop dev-loop and proceed, (b) Cancel goal-loop"
5. Present user choice (if interactive) or stop and require explicit flag:
   - If --ignore-dev-loop flag provided, proceed
   - Else, stop with error code and guidance
6. If user chooses to proceed:
   - Update state: dev_loop_conflict="acknowledged"
   - Continue with goal-loop execution
7. If user cancels:
   - Update state: status="CANCELLED", cancel_reason="dev_loop_conflict"
   - Exit gracefully

**Verify** in state file:
- `dev_loop_conflict` should be set to "acknowledged" (if proceeded) or "detected" (if stopped)
- `status` should reflect user's choice ("IN_PROGRESS" or "CANCELLED")
- `cancel_reason` should be "dev_loop_conflict" if cancelled
- The system should demonstrate conflict detection and user guidance
- The workflow should prevent conflicting iterative systems from running simultaneously
