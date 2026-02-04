# Todo Skill Test Scenarios

## Scenario 1: Simple Task (Typo Fix)

**Setup:** A small codebase with a typo in a variable name

**Prompt to agent:** "Fix the typo in the getUserData function"

**Expected without skill:**
- Agent might:
  - Directly read the file and fix (good)
  - Or over-engineer with extensive analysis/planning (bad)
  - Or use brainstorming skill unnecessarily (bad)

**Expected WITH skill:**
- Quick analysis (read file, identify typo)
- Confirm: "I found 'usreData' should be 'userData'. Fix it?"
- Execute directly with TodoWrite tracking
- Verify (maybe run lint or build)
- Complete

---

## Scenario 2: Task Requiring Clarification

**Setup:** Ambiguous task request

**Prompt to agent:** "Add error handling to the API"

**Expected without skill:**
- Agent might:
  - Guess what error handling is needed
  - Or add too much error handling
  - Or skip asking questions

**Expected WITH skill:**
- Ask clarifying questions (but keep it light)
- "What kind of errors? Network failures? Invalid responses? Something else?"
- Once understood, present 3-5 step plan
- Confirm and execute

---

## Scenario 3: Medium Complexity Task

**Setup:** Add loading state to a React component

**Prompt to agent:** "Add loading state to UserProfile component"

**Expected without skill:**
- Agent might:
  - Jump straight to coding (could be OK)
  - Or use brainstorming/writing-plans (overkill)

**Expected WITH skill:**
- Read UserProfile component
- Plan: add isLoading state, show spinner while loading, etc.
- Present plan, confirm
- Execute with TodoWrite

---

## Scenario 4: Too Complex for Todo Skill

**Setup:** Major feature affecting multiple files

**Prompt to agent:** "Refactor the authentication system to use JWT"

**Expected without skill:**
- Agent might attempt directly (risky)

**Expected WITH skill:**
- Analyze, recognize complexity
- Suggest: "This task is complex. Should I use /summ:writing-plans for a structured approach?"
- Wait for user decision

---

## Scenario 5: Installation Task

**Setup:** New project setup

**Prompt to agent:** "Install and start the project"

**Expected without skill:**
- Agent might run package install and start

**Expected WITH skill:**
- Detect package.json, dependencies
- Plan: install deps, configure if needed, start dev server
- Present plan, confirm
- Execute with TodoWrite and TaskWarrior tracking

---

## Testing Methodology

For each scenario:
1. Run with subagent WITHOUT the skill - document baseline behavior
2. Run with subagent WITH the skill - verify compliance
3. Document rationalizations and add counters to skill
