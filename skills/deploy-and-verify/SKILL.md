---
name: deploy-and-verify
description: Use when deploying an application and verifying the deployment works — reads DEPLOY.md, executes deployment, runs smoke tests or E2E tests, reports structured results. Triggers on "deploy", "deploy and verify", "上线", "验证", or after finishing a development branch.
---

# deploy-and-verify: Deploy and Verify

Deploy the application and verify the deployment works.

**Trigger:** User asks to deploy, deploy and verify, 上线, 验证. Or agent judges deployment is the natural next step after `finishing-a-development-branch`.

## Workflow

### 1. Read Deployment Config

Read `DEPLOY.md` from the project root. If it exists, extract:
- Deploy commands (the steps under "Deployment" section)
- Verification commands or URLs (health endpoints, E2E test commands)
- Environment info (ports, URLs)

If `DEPLOY.md` does not exist:
- Check if the `deploy` skill's template is appropriate — offer to create `DEPLOY.md` using that template
- If user declines, proceed with best-effort deployment (look for `package.json` scripts, `docker-compose.yml`, `Makefile` targets)

### 2. Execute Deployment

Run the deploy commands from DEPLOY.md (or discovered equivalents) using Bash tool directly.

**Pre-deploy cleanup:** If the deploy involves starting a server, kill any existing process on the target port first:
```bash
lsof -ti:$PORT | xargs kill -9 2>/dev/null; true
```

**Execute each deploy step sequentially.** If any step fails, stop and report.

### 3. Verify Deployment

After deployment succeeds, verify it works. Try in order — use the first that applies:

1. **DEPLOY.md has verification commands** → run them
2. **`package.json` has `test:e2e` script** → run `npm run test:e2e`
3. **Deployed a HTTP service** → `curl` the health/root endpoint
4. **None of the above** → report "SKIPPED: no verification configured"

### 4. Report Results

Report structured results:

```
## Deploy & Verify Results

- **Deploy:** SUCCESS | FAILED
- **Verify:** PASSED | FAILED | SKIPPED
- **URL:** <access URL if applicable>
- **Evidence:** <command output showing success or failure>
```

If FAILED at deploy or verify stage:
- Include the error output
- Suggest a likely cause (code bug / config issue / infrastructure)
- Do NOT automatically retry — let agent/human decide next step

## Principles

- **Linear steps.** No state machine, no loop counting.
- **Report, don't retry.** Failure is information, not a trigger for automatic action.
- **Works with Claude Code alone.** No Agent-Orchestrator dependency.
- **Reuses DEPLOY.md convention** from the `deploy` skill.

## Red Flags

| Thought | Reality |
|---------|---------|
| "Deploy probably worked" | Verify with evidence — curl output, test results |
| "I'll skip verification" | Verification is the whole point of this skill |
| "Let me retry automatically" | Report failure, let agent/human decide |
| "I need ao spawn for this" | Use Bash tool directly — this is a single-agent operation |

## Integration

**Works after:** `finishing-a-development-branch`
**Works before:** `value-proof` (optional)
**Uses convention from:** `deploy` skill (DEPLOY.md)
