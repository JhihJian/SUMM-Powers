# dev-loop 端到端测试方案

## 测试环境

### 最小测试项目

在 `/tmp/dev-loop-test-project` 创建一个 Express.js 项目：

```
/tmp/dev-loop-test-project/
├── package.json              # Express + vitest
├── src/
│   └── index.js              # Express app，初始只有 GET /api/health
├── tests/
│   └── health.test.js        # 基础测试
│   └── e2e.test.js           # E2E 测试（Playwright 或 HTTP 请求）
├── DEPLOY.md                 # 本地部署指令：npm start → localhost:3000
├── CLAUDE.md                 # 告诉 Claude 这是 Express 项目
└── agent-orchestrator.yaml   # dev-loop 配置（含 agentRules）
```

**项目特点：**
- 足够简单：一个 endpoint，几行代码
- 足够完整：有测试、有 DEPLOY.md、能启动服务
- 每个 test case 从一个干净的 git state 开始

### AO 配置

```yaml
# agent-orchestrator.yaml
defaults:
  runtime: tmux
  agent: claude-code
  workspace: worktree

projects:
  dev-loop-test:
    path: /tmp/dev-loop-test-project
    defaultBranch: main
    agentRules: |
      You have SUMM. You MUST use the Skill tool to load skills before doing any work.
      If you are a MASTER agent: load summ:dev-loop immediately and follow its state machine.
      If you are a WORKER agent: load the skill specified in your task. Work ONLY on your assigned task.
```

## 测试方法

每个场景按以下流程执行：

1. **Reset** — `cd /tmp/dev-loop-test-project && git checkout main && git clean -fd`
2. **Spawn** — `ao spawn dev-loop-test --prompt "<requirement>"`
3. **Observe** — 用 `ao status` 轮询，记录状态变化
4. **Verify** — 检查 git log、文件变更、session 输出
5. **Cleanup** — `ao session kill` 所有 session

## 预估成本

| 场景 | 预计时长 | API 成本 | 说明 |
|------|----------|----------|------|
| 1. Happy path | 15-30 min | ~$2-5 | 全流程，最贵 |
| 2. Worker BLOCKED | 5-10 min | ~$0.5 | planning + 1 worker |
| 3. Code Review 失败 | 20-40 min | ~$3-6 | 需要 2 轮 TDD + review |
| 4. Deploy 失败 | 20-40 min | ~$3-6 | 需要 deploy → fix → re-deploy |
| 5. E2E 失败 | 25-45 min | ~$4-7 | 需要 E2E → fix → re-deploy → re-E2E |
| 6. Value Proof: 需求偏差 | 30-50 min | ~$5-8 | 全流程 + 重新 planning |
| 7. Value Proof: 部分缺失 | 25-45 min | ~$4-7 | 全流程 + 补实现 |
| 8. Max loops | 40-60 min | ~$6-10 | 3 轮循环 |
| 9. 混合结果 | 15-25 min | ~$2-4 | 多 worker，部分成功 |
| 10. Worker prompt | 5 min | ~$0.3 | 只检查 prompt 内容 |

**总计: ~$28-60, 约 3-5 小时**

---

## 场景 1: Happy Path (全流程)

**目标：** 验证 PLANNING → BUILDING → DELIVERING → VALIDATING → DONE 完整流程。

**前置条件：** 干净的测试项目，只有 `GET /api/health` endpoint。

**需求 prompt：**
```
实现需求：为应用添加一个 POST /api/echo endpoint，接受 JSON body { "message": "hello" }，
返回 { "echo": "hello" }。需要：
1. 参数验证（message 必须是字符串，非空，最大 200 字符）
2. 错误返回 400 + { "error": "描述" }
3. 成功返回 200 + { "echo": "..." }
4. 单元测试覆盖正常和异常情况
5. E2E 测试验证 HTTP 请求
```

**预期状态流转：**
```
PLANNING.BRAINSTORMING → PLAN_WRITING → BUILDING.TDD_IMPLEMENTING
→ CODE_REVIEWING → DELIVERING.DEPLOYING → E2E_VERIFYING
→ VALIDATING.VALUE_PROVING → COMPLETING → DONE
```

**验证点：**
- [ ] `ao status` 显示 master session 的 phase 经历了所有 4 个大阶段
- [ ] `git log` 有 worker 的实现提交
- [ ] `tests/echo.test.js` 存在且测试通过
- [ ] `src/index.js` 包含 POST /api/echo endpoint
- [ ] 部署后 `curl localhost:3000/api/echo -X POST -d '{"message":"hi"}'` 返回正确
- [ ] loopCount 保持为 1（无回退）
- [ ] master session 输出包含 value proof 通过的证据

---

## 场景 2: Worker BLOCKED

**目标：** 验证 worker 报告 BLOCKED 时 master 正确升级。

**前置条件：** 干净的测试项目。

**需求 prompt（制造不可解决的任务）：**
```
实现需求：集成第三方支付 API。
需要调用 POST https://nonexistent-api-12345.example.com/v1/payments，
使用 API key 从环境变量 PAYMENT_API_KEY 获取。
如果环境变量不存在或 API 不可达，报告 BLOCKED。
```

**预期：**
- Worker 尝试调用 API → 失败
- Worker 报告 BLOCKED（外部依赖不可用）
- Master 转入 ESCALATED
- Master 通知人工

**验证点：**
- [ ] `ao status` 最终状态为 exited/blocked（不是 done）
- [ ] master session 输出包含 "ESCALATED" 或 "escalat"
- [ ] 没有 PR 被创建

---

## 场景 3: Code Review 发现问题

**目标：** 验证 code review 失败时回退到 BUILDING。

**前置条件：** 干净的测试项目。

**需求 prompt（诱导过度实现）：**
```
实现需求：添加 GET /api/time endpoint，返回当前时间的 ISO 格式。
只需要这一个 endpoint，不要添加其他功能。
```

**注意：** 此场景依赖 worker 可能过度实现（比如添加时区转换等额外功能）。如果 worker 恰好完美实现，则 code review 通过，此场景转为 happy path 的一个变体。

**如果需要强制 code review 失败：** 在测试项目的 CLAUDE.md 中加入规则：
```
Code review 标准：所有 endpoint 必须有 JSDoc 注释和输入验证。
如果发现缺少注释或没有错误处理，标记为 review 失败。
```

**预期：**
- Worker 实现 endpoint
- Code review 发现缺少注释或错误处理
- 回退到 BUILDING.TDD_IMPLEMENTING
- loopCount 变为 2
- Worker 修复问题后 code review 通过

**验证点：**
- [ ] `ao status` 显示至少 2 个 BUILDING 阶段的 worker session
- [ ] loopCount >= 2
- [ ] 最终 DONE（不是 ESCALATED）

---

## 场景 4: Deploy 失败

**目标：** 验证部署失败时回退到 BUILDING。

**前置条件：** 在 DEPLOY.md 中加入会失败的部署步骤：
```markdown
## Deploy Steps
1. 检查端口 3000 是否空闲：`lsof -i :3000`
2. 如果端口被占用，部署失败，报告错误
3. 启动服务：`PORT=3000 npm start`
```

**同时：** 在部署前先占用端口 3000：
```bash
# 在另一个终端
node -e "require('http').createServer(()=>{}).listen(3000, ()=>console.log('blocking port 3000'))"
```

**预期：**
- Worker 实现完毕
- Code review 通过
- Deploy worker 尝试部署 → 端口被占用 → 失败
- 回退到 BUILDING.TDD_IMPLEMENTING
- Worker 修复部署配置（使用其他端口或杀掉占用进程）
- 重新部署成功

**验证点：**
- [ ] Deploy worker 报告失败
- [ ] loopCount 递增
- [ ] 最终部署成功（使用替代端口）
- [ ] 回退目标是 BUILDING 而非 PLANNING

---

## 场景 5: E2E 测试失败

**目标：** 验证 E2E 测试失败时回退到 BUILDING。

**前置条件：** 在 E2E 测试中加入会失败的条件：
```javascript
// tests/e2e.test.js
test('response includes timestamp', async () => {
  const res = await fetch('http://localhost:3000/api/echo', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: 'test' })
  });
  const data = await res.json();
  // 这个断言会失败 — echo endpoint 不返回 timestamp
  expect(data.timestamp).toBeDefined();
});
```

**需求 prompt：**
```
实现需求：添加 POST /api/echo endpoint（返回 { echo: message }）。
确保通过所有已有的测试，包括 tests/e2e.test.js。
```

**预期：**
- Worker 实现 endpoint
- Deploy 成功
- E2E 测试失败（缺少 timestamp 字段）
- 回退到 BUILDING
- Worker 添加 timestamp 字段
- 重新部署 → E2E 通过

**验证点：**
- [ ] E2E worker 报告测试失败
- [ ] 回退目标是 BUILDING.TDD_IMPLEMENTING
- [ ] loopCount 递增
- [ ] 最终 E2E 通过

---

## 场景 6: Value Proof — 需求理解偏差

**目标：** 验证 value proof 识别需求偏差时回退到 PLANNING。

**需求 prompt（含歧义）：**
```
实现需求：添加用户注册功能。
```

**关键：** 需求故意模糊。"用户注册"可以理解为：
- 简单的 API endpoint
- 包含邮箱验证的完整流程
- 包含密码重置功能

**预期：**
- Worker 可能实现了一个简单版本
- Value proof 评估时，master agent 发现实现与原始意图不匹配（因为没有明确说需要邮箱验证等）
- Master 回退到 PLANNING.BRAINSTORMING
- 重新明确需求

**注意：** 此场景最难控制，因为 AI 的行为不可预测。如果 master agent 接受了简单实现，则场景可能变成 happy path。可以通过在 CLAUDE.md 中加入严格的 value proof 标准来增加触发概率。

**验证点：**
- [ ] 回退目标是 PLANNING（不是 BUILDING）
- [ ] loopCount >= 2

---

## 场景 7: Value Proof — 部分功能缺失

**目标：** 验证 value proof 识别功能缺失时回退到 BUILDING。

**需求 prompt（多要求）：**
```
实现需求：添加 POST /api/echo endpoint，需要满足以下所有条件：
1. 接受 JSON body { "message": "hello" }
2. 返回 { "echo": "hello", "length": 5 }
3. 返回 { "timestamp": "<ISO时间>" }
4. 参数验证：message 必须是字符串、非空、最大 200 字符
5. 错误返回 400 + { "error": "描述" }
全部 5 个条件都必须满足。
```

**制造缺失：** 在 CLAUDE.md 中加入干扰：
```
开发偏好：优先实现核心功能，非核心功能可以省略。
timestamp 和 length 字段是辅助信息，不是核心功能。
```

**预期：**
- Worker 可能只实现 echo + 验证（核心），省略 length 和 timestamp
- Value proof 发现条件 2 和 3 未满足
- 回退到 BUILDING（不是 PLANNING）
- 只补充缺失的功能

**验证点：**
- [ ] 回退目标是 BUILDING（不是 PLANNING）
- [ ] 补充实现后 value proof 通过

---

## 场景 8: Max Loops

**目标：** 验证 loopCount >= 3 时强制 ESCALATED。

**前置条件：** 在 DEPLOY.md 中写一个永远不会成功的部署步骤：
```markdown
## Deploy Steps
1. 运行 `exit 1`（模拟永久性部署失败）
2. 如果上一步失败，报告部署失败
```

**需求 prompt：**
```
实现需求：添加 GET /api/version endpoint，返回 { "version": "1.0.0" }。
```

**预期：**
- Worker 实现 endpoint（成功）
- Code review 通过
- Deploy 失败（DEPLOY.md 会永远失败）
- Loop 1: 回退 BUILDING → re-deploy → 又失败
- Loop 2: 回退 BUILDING → re-deploy → 又失败
- Loop 3: loopCount = 3 → ESCALATED
- Master 通知人工

**验证点：**
- [ ] loopCount 最终 >= 3
- [ ] 最终状态是 ESCALATED（不是 DONE）
- [ ] master 输出包含 3 次失败的诊断历史
- [ ] 没有第 4 次循环

---

## 场景 9: 多任务混合结果

**目标：** 验证部分成功 + 部分失败时的处理。

**需求 prompt（多任务）：**
```
实现需求：添加以下 3 个 endpoint：
1. GET /api/version — 返回 { "version": "1.0.0" }
2. POST /api/echo — 接受 { "message": "x" }，返回 { "echo": "x" }
3. POST /api/pay — 调用 https://nonexistent-api.example.com/charge 并返回结果
```

**预期：**
- Task 1, 2: Worker 成功实现
- Task 3: Worker BLOCKED（外部 API 不存在）
- Master 推进 Task 1, 2，对 Task 3 做升级处理
- Value proof 评估已完成的 2 个 task

**验证点：**
- [ ] Task 1 和 2 的 worker 报告 DONE
- [ ] Task 3 的 worker 报告 BLOCKED
- [ ] 流程继续（不因 Task 3 停滞）
- [ ] 最终 value proof 覆盖的是已完成的范围

---

## 场景 10: Worker Prompt 内容验证

**目标：** 验证 worker prompt 包含正确的 skill 注入。

**方法：** 不需要实际 spawn。检查 `agentRules` 配置和 `worker-prompt-template.md` 的内容。

**验证点：**
- [ ] agentRules 包含 "You have SUMM"
- [ ] agentRules 包含 "load the skill specified in your task"
- [ ] worker-prompt-template.md 包含 `[SKILL_NAME]` 占位符
- [ ] worker-prompt-template.md 包含报告格式（DONE/BLOCKED/NEEDS_CONTEXT）
- [ ] worker-prompt-template.md 包含 "do NOT read from file"（全文粘贴）

---

## 执行策略

### 分批执行

不建议一次性跑全部 10 个场景。建议按风险分组：

**Phase A（低成本验证）：**
- 场景 10（静态检查，无成本）
- 场景 2（Worker BLOCKED，5 min）

**Phase B（核心流程）：**
- 场景 1（Happy path，最重要）

**Phase C（失败回退）：**
- 场景 5（E2E 失败）— 最容易控制
- 场景 4（Deploy 失败）— 需要端口占用
- 场景 3（Code Review 失败）— 需要 CLAUDE.md 规则

**Phase D（高级场景）：**
- 场景 7（Value Proof 部分缺失）
- 场景 8（Max loops）
- 场景 9（混合结果）
- 场景 6（需求偏差）— 最不可控

### 每个场景的自动化脚本

每个场景应该有一个 shell 脚本：
```bash
# tests/e2e/test-scenario-1.sh
#!/usr/bin/env bash
set -euo pipefail
source ./tests/e2e/test-helpers.sh

setup_test_project
echo "Running Scenario 1: Happy Path"

REQUIREMENT="实现需求：为应用添加一个 POST /api/echo endpoint..."
SESSION=$(ao spawn dev-loop-test --prompt "$REQUIREMENT" 2>&1 | grep -oP 'session:\s*\K\S+')

wait_for_done "$SESSION" 1800  # 30 min timeout

# Verify
assert_file_exists "src/routes/echo.js"
assert_test_passes "npm test"
assert_endpoint_works "POST /api/echo" '{"message":"hello"}' '{"echo":"hello"}'

cleanup
echo "Scenario 1: PASSED"
```

### 观察工具

```bash
# 实时监控 master session 状态
watch -n 10 'ao status'

# 查看所有 worker sessions
ao session ls

# 查看 session 输出
ao open <session-id>
```
