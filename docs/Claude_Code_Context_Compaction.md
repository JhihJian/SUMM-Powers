# Claude Code 上下文压缩机制

> 基于 Claude Code v2.1.123 (2026-04-28)，提取自 [Piebald-AI/claude-code-system-prompts](https://github.com/Piebald-AI/claude-code-system-prompts)

## 核心原理

Claude Code 的上下文压缩**没有外部算法**，完全依赖模型自身的总结能力。通过精心设计的结构化 prompt 引导模型生成有损摘要，替换原始对话历史。

## 触发时机

1. **自动触发** — 上下文窗口接近容量上限
2. **手动触发** — 用户调用 `/compact`

## 三种压缩策略

### 1. 完全压缩（Context Compaction Summary）

- **Prompt 文件**: `system-prompt-context-compaction-summary.md` (278 tokens)
- **触发场景**: SDK 层面，上下文窗口彻底耗尽
- **压缩方式**: 整个对话历史被替换为一条结构化摘要

**Prompt 全文:**

```
You have been working on the task described above but have not yet completed it. Write a continuation summary that will allow you (or another instance of yourself) to resume work efficiently in a future context window where the conversation history will be replaced with this summary. Your summary should be structured, concise, and actionable. Include:
1. Task Overview
The user's core request and success criteria
Any clarifications or constraints they specified
2. Current State
What has been completed so far
Files created, modified, or analyzed (with paths if relevant)
Key outputs or artifacts produced
3. Important Discoveries
Technical constraints or requirements uncovered
Decisions made and their rationale
Errors encountered and how they were resolved
What approaches were tried that didn't work (and why)
4. Next Steps
Specific actions needed to complete the task
Any blockers or open questions to resolve
Priority order if multiple steps remain
5. Context to Preserve
User preferences or style requirements
Domain-specific details that aren't obvious
Any promises made to the user
Be concise but complete—err on the side of including information that would prevent duplicate work or repeated mistakes. Write in a way that enables immediate resumption of the task.
Wrap your summary in tags.
```

**输出结构 (5段):**

| # | 段落 | 内容 |
|---|------|------|
| 1 | Task Overview | 用户核心请求、成功标准、约束条件 |
| 2 | Current State | 已完成事项、文件路径、产出物 |
| 3 | Important Discoveries | 技术约束、决策理由、错误及修复、失败的尝试 |
| 4 | Next Steps | 待执行动作、阻塞项、优先级 |
| 5 | Context to Preserve | 用户偏好、领域细节、承诺事项 |

**核心原则**: "err on the side of including information that would prevent duplicate work or repeated mistakes"

---

### 2. 完整对话摘要（Conversation Summarization）

- **Prompt 文件**: `agent-prompt-conversation-summarization.md` (1121 tokens)
- **触发场景**: Agent 级别的全量对话压缩
- **压缩方式**: 两阶段处理——先分析，再输出

**Prompt 全文:**

```
Your task is to create a detailed summary of the conversation so far, paying close attention to the user's explicit requests and your previous actions.

This summary should be thorough in capturing technical details, code patterns, and architectural decisions that would be essential for continuing development work without losing context.

Before providing your final summary, wrap your analysis in tags to organize your thoughts and ensure you've covered all necessary points. In your analysis process:
1. Chronologically analyze each message and section of the conversation. For each section thoroughly identify:
   - The user's explicit requests and intents
   - Your approach to addressing the user's requests
   - Key decisions, technical concepts and code patterns
   - Specific details like:
     - file names
     - full code snippets
     - function signatures
     - file edits
   - Errors that you ran into and how you fixed them
   - Pay special attention to specific user feedback that you received, especially if the user told you to do something differently.
2. Double-check for technical accuracy and completeness, addressing each required element thoroughly.

Your summary should include the following sections:

1. Primary Request and Intent: Capture all of the user's explicit requests and intents in detail
2. Key Technical Concepts: List all important technical concepts, technologies, and frameworks discussed.
3. Files and Code Sections: Enumerate specific files and code sections examined, modified, or created. Pay special attention to the most recent messages and include full code snippets where applicable and include a summary of why this file read or edit is important.
4. Errors and fixes: List all errors that you ran into, and how you fixed them. Pay special attention to specific user feedback that you received, especially if you told you to do something differently.
5. Problem Solving: Document problems solved and any ongoing troubleshooting efforts.
6. All user messages: List ALL user messages that are not tool results. These are critical for understanding the users' feedback and changing intent.
6. Pending Tasks: Outline any pending tasks that you have explicitly asked to work on.
7. Current Work: Describe in detail precisely what was being worked on immediately before this summary request, paying special attention to the most recent messages from both user and assistant. Include file names and code snippets where applicable.
8. Optional Next Step: List the next step that you will take that is related to the most recent work you were doing. IMPORTANT: ensure that this step is DIRECTLY in line with the user's most recent explicit requests, and the task you were working on immediately before this summary request. If your last task was concluded, then only list next steps if they are explicitly in line with the users request. Do not start on tangential requests or really old requests that were already completed without confirming with the user first. If there is a next step, include direct quotes from the most recent conversation showing exactly what task you were working on and where you left off. This should be verbatim to ensure there's no drift in task interpretation.

Here's an example of how your output should be structured:

[Your thought process, ensuring all points are covered thoroughly and accurately]

1. Primary Request and Intent:
[Detailed description]

2. Key Technical Concepts:
- [Concept 1]
- [Concept 2]
- [...]

3. Files and Code Sections:
- [File Name 1]
  - [Summary of why this file is important]
  - [Summary of the changes made to this file, if any]
  - [Important Code Snippet]
- [File Name 2]
  - [Important Code Snippet]
- [...]

4. Errors and fixes:
- [Detailed description of error 1]:
  - [How you fixed the error]
  - [User feedback on the error if any]
- [...]

5. Problem Solving:
[Description of solved problems and ongoing troubleshooting]

6. All user messages:
- [Detailed non tool use user message]
- [...]

7. Pending Tasks:
- [Task 1]
- [Task 2]
- [...]

8. Current Work:
[Precise description of current work]

9. Optional Next Step:
[Optional Next step to take]

Please provide your summary based on the conversation so far, following this structure and ensuring precision and thoroughness in your response.

There may be additional summarization instructions provided in the included context. If so, remember to follow these instructions when creating this summary.

Examples of instructions include:
## Compact Instructions
When summarizing the conversation focus on typescript code changes and also remember the mistakes you made and how you fixed them.

# Summary instructions
When you are using compact - please focus on test output and code changes. Include file reads verbatim.
```

**输出结构 (9段):**

| # | 段落 | 内容 |
|---|------|------|
| 1 | Primary Request and Intent | 所有用户请求和意图 |
| 2 | Key Technical Concepts | 技术概念、框架、模式 |
| 3 | Files and Code Sections | 文件路径 + 完整代码片段 + 重要性说明 |
| 4 | Errors and fixes | 错误详情 + 修复方式 + 用户反馈 |
| 5 | Problem Solving | 已解决问题 + 进行中的排查 |
| 6 | All user messages | 所有非工具调用的用户消息 |
| 7 | Pending Tasks | 待办任务 |
| 8 | Current Work | 最近工作内容（含代码片段） |
| 9 | Optional Next Step | 下一步（附原文引用防漂移） |

**关键特性:**
- **两阶段处理**: 先在 `tags` 中做时序分析，再输出正式摘要
- **完整代码保留**: 要求保留完整代码片段、函数签名、文件路径
- **自定义指令注入**: 支持通过 `## Compact Instructions` 或 `# Summary instructions` 覆盖默认关注点

---

### 3. 部分压缩（Recent Message Summarization）

- **Prompt 文件**: `agent-prompt-recent-message-summarization.md` (724 tokens)
- **触发场景**: 上下文接近满但不需要全部压缩
- **压缩方式**: 只压缩最近尾部消息，早期消息原封不动保留

**Prompt 全文:**

```
Your task is to create a detailed summary of the RECENT portion of the conversation — the messages that follow earlier retained context. The earlier messages are being kept intact and do NOT need to be summarized. Focus your summary on what was discussed, learned, and accomplished in the recent messages only.

${`Before providing your final summary, wrap your analysis in tags to organize your thoughts and ensure you've covered all necessary points. In your analysis process:
1. Analyze the recent messages chronologically. For each section thoroughly identify:
   - The user's explicit requests and intents
   - Your approach to addressing the user's requests
   - Key decisions, technical concepts and code patterns
   - Specific details like:
     - file names
     - full code snippets
     - function signatures
     - file edits
   - Errors that you ran into and how you fixed them
   - Pay special attention to specific user feedback that you received, especially if the user told you to do something differently.
2. Double-check for technical accuracy and completeness, addressing each required element thoroughly.`}

Your summary should include the following sections:

1. Primary Request and Intent: Capture the user's explicit requests and intents from the recent messages
2. Key Technical Concepts: List important technical concepts, technologies, and frameworks discussed recently.
3. Files and Code Sections: Enumerate specific files and code sections examined, modified, or created. Include full code snippets where applicable and include a summary of why this file read or edit is important.
4. Errors and fixes: List errors encountered and how they were fixed.
5. Problem Solving: Document problems solved and any ongoing troubleshooting efforts.
6. All user messages: List ALL user messages from the recent portion that are not tool results.
7. Pending Tasks: Outline any pending tasks from the recent messages.
8. Current Work: Describe precisely what was being worked on immediately before this summary request.
9. Optional Next Step: List the next step related to the most recent work. Include direct quotes from the most recent conversation.

Here's an example of how your output should be structured:

\[Your thought process, ensuring all points are covered thoroughly and accurately\]

1. Primary Request and Intent:
\[Detailed description\]

2. Key Technical Concepts:
- \[Concept 1\]
- \[Concept 2\]

3. Files and Code Sections:
- \[File Name 1\]
  - \[Summary of why this file is important\]
  - \[Important Code Snippet\]

4. Errors and fixes:
- \[Error description\]:
  - \[How you fixed it\]

5. Problem Solving:
\[Description\]

6. All user messages:
- \[Detailed non tool use user message\]

7. Pending Tasks:
- \[Task 1\]

8. Current Work:
\[Precise description of current work\]

9. Optional Next Step:
\[Optional Next step to take\]

Please provide your summary based on the RECENT messages only (after the retained earlier context), following this structure and ensuring precision and thoroughness in your response.
```

**与完整对话摘要的区别:**
- 摘要范围**只覆盖** "retained context 之后的消息"
- 早期消息完整保留，不参与压缩
- 最终上下文 = **早期原始消息 + 尾部摘要**
- 包含 `${...}` 模板注入点，支持自定义分析指令

---

## 策略对比

| 维度 | 完全压缩 | 完整对话摘要 | 部分压缩 |
|------|---------|------------|---------|
| Prompt 大小 | 278 tokens | 1121 tokens | 724 tokens |
| 压缩范围 | 全部替换 | 全部替换 | 只压缩尾部 |
| 输出段落数 | 5 段 | 9 段 | 9 段 |
| 分析阶段 | 无 | 有（tags 内） | 有（tags 内） |
| 信息保留度 | 中等 | 最高 | 早期100%+近期摘要 |
| 代码片段保留 | 不要求 | 要求完整保留 | 要求完整保留 |
| 自定义指令 | 不支持 | 支持 | 支持（模板注入） |
| 细节丢失风险 | 较高 | 最低 | 尾部可能丢失 |

## 设计哲学

1. **结构化优于自由文本** — 固定段落结构确保关键信息不遗漏
2. **宁可多保留** — "err on the side of including information"
3. **防重复** — 特别关注"失败的尝试"和"用户纠正"，避免重蹈覆辙
4. **时序分析** — 完整/部分压缩都要求先按时间顺序逐条分析
5. **代码优先** — 要求保留完整代码片段而非抽象描述
6. **可恢复性** — 目标是让新的模型实例能无缝接续工作
