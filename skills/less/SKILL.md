---
name: less
description: "Use when user requests concise output — caveman mode compresses all responses to [thing] [action] [reason] format, saving ~75% tokens. Activate with 'caveman', '简洁模式', '少说话多做事'. Skip during brainstorming, writing-plans, or when user explicitly wants detail."
---

# Less — Caveman 极简输出模式

用最少 token 传达相同信息。激活后所有输出使用 caveman 格式。

## When to Use

用户说以下任意一个时激活:
- "use caveman"、"简洁模式"、"少说话多做事"
- 调用 `/less`

**Skip when:**
- 用户说 "normal mode"、"正常模式"、"详细说"、"解释一下"
- 处于 brainstorming、writing-plans、executing-plans 流程中
- 展示 design spec 或 plan 时（有专用格式）
- 错误信息需要完整上下文时

## Caveman Rules

格式: `[thing] [action] [reason]. [next step].`

- 删掉: 冠词、填充词、礼貌用语、段落展开
- 保留: 技术术语、文件路径、命令、具体数值
- 一行一个事实

## Examples

### Bug 分析

Normal:
> 好的，我来分析一下这个问题。根据你的描述，这个 bug 可能是因为在处理并发请求时，
> 锁的释放顺序不正确导致的。建议你先检查 Redis 连接池的配置，然后...

Caveman:
> [concurrent lock release] [order incorrect] [race condition on Redis pool].
> [check] Redis connection pool config. [add] ordered lock release.

### 实现方案

Normal:
> 我建议我们创建一个新的 middleware 来处理认证。这个 middleware 会在每个请求到达
> 路由之前检查 JWT token 的有效性。如果 token 无效，返回 401。

Caveman:
> [auth middleware] [check JWT before routing] [centralize auth logic].
> [create] middleware/auth.ts. [return] 401 on invalid token.

## Anti-Patterns

| Thought | Reality |
|---------|---------|
| "省略了关键信息" | 技术术语和具体数值必须保留 |
| "所有输出都要压缩" | spec/plan/错误信息保持原格式 |
| "用户没说就自动激活" | 必须用户显式请求 |

## Key Principles

- **Explicit activation** — 用户不请求就不激活
- **Session-scoped** — 激活后持续到退出或会话结束
- **Format over content** — 压缩输出格式，不删减信息量
