---
name: value-proof
description: Use when verifying that a delivery matches its original requirement — compares requirement points against the actual code diff to produce a structured pass/partial/mismatch/scope-creep assessment. Triggers on "verify delivery", "value proof", "check completeness", "验收", or after deploy-and-verify.
---

# value-proof: Requirement vs Delivery Verification

Compare what was requested against what was delivered. Read the diff, check against the requirement, report gaps.

**Trigger:** User asks to verify delivery, check completeness, value proof, 验收. Or agent judges final acceptance is needed after `deploy-and-verify`.

## Workflow

### 1. Identify the Requirement

Find the original requirement. Try in order:

1. **Design spec** in `docs/superpowers/specs/` — look for the most recent spec matching the current work
2. **Implementation plan** in `docs/superpowers/plans/` — extract the goal and task list
3. **User's original message** — look back in conversation for the request that started this work
4. **Ask user** — if none of the above, ask "What was the original requirement?"

Extract discrete requirement points. If the requirement is a paragraph, break it into individual checkable points.

### 2. Read the Diff

Run these commands to understand what changed:

```bash
git diff <base>..<head> --stat
```

Then read the full diff for details:

```bash
git diff <base>..<head>
```

Determine `<base>` and `<head>`:
- If on a feature branch: base = `main`, head = current branch
- If working on main: base = last commit before work started, head = `HEAD`
- Ask user if unclear

### 3. Evaluate Per Requirement Point

For each requirement point, check: does the diff contain code evidence that this is implemented?

Mark each point:

| Status | Meaning |
|--------|---------|
| EVIDENCED | Code in the diff directly implements this point |
| PARTIAL | Some code exists but coverage is incomplete |
| NO_EVIDENCE | No code in the diff relates to this point |

**Be specific.** For each point, name the file(s) and function(s) that provide evidence. "Tests pass" is not evidence — code that implements the requirement is evidence.

### 4. Check Scope

Scan the diff for changes NOT related to any requirement point:
- Files changed that aren't explained by any requirement
- Features added that weren't requested
- Refactoring or cleanup mixed into the delivery

### 5. Report

```
## Value Proof Report

**Requirement:** <first 80 chars of requirement>
**Branch:** <branch> vs <base>
**Verdict:** PASS | PARTIAL | MISMATCH | SCOPE_CREEP

### Requirement Points

| # | Requirement | Status | Evidence |
|---|------------|--------|----------|
| 1 | <point> | EVIDENCED | <file:line or function> |
| 2 | <point> | NO_EVIDENCE | — |
| ... | ... | ... | ... |

### Scope Check

<If scope creep found: list the unrelated changes>
<If clean: "No unrelated changes detected">

### Recommended Next Action

<Based on verdict, suggest what to do>
```

### Verdict Definitions

- **PASS** — Every point EVIDENCED, no unrelated changes. Delivery satisfies the requirement.
- **PARTIAL** — Some points missing evidence. List the gaps so they can be addressed.
- **MISMATCH** — What was built doesn't match what was asked. The implementation direction is wrong.
- **SCOPE_CREEP** — Significant unrelated changes found alongside the requirement work.

## Principles

- **Report only.** No automatic re-plan or re-implement. The agent or human reads the report and decides.
- **Read actual code.** Don't trust reports from previous phases — read the diff yourself.
- **Be strict.** Every point must have evidence. "Close enough" is not PASS.
- **No loop counting.** This is a one-shot assessment.

## Red Flags

| Thought | Reality |
|---------|---------|
| "Tests pass, so it's done" | Tests prove correctness, not completeness |
| "The worker said it's done" | Verify against the requirement, not against reports |
| "Close enough" | Every point needs evidence |
| "I'll skip the scope check" | Scope creep is a real problem |

## Integration

**Works after:** `deploy-and-verify` (or directly after `finishing-a-development-branch` if no deployment needed)
**Uses:** `summ:verification-before-completion` mindset — evidence before claims

**After value-proof:** If PASS, the delivery is complete — notify the user with the verdict and summary. If PARTIAL/MISMATCH/SCOPE_CREEP, the report's "Recommended Next Action" tells the agent what to do (usually go back to implementation or re-plan). No further skill needed.
