# 与 AI 协作的底层逻辑

写给你的——无论你用 Claude Code、Cursor、Copilot 还是其他任何 AI 编程工具。

---

## 一件你必须理解的事

所有的大语言模型，不管它叫什么名字、标了多少参数，本质上只做一件事：**根据当前的上下文，预测下一个最可能出现的词。**

没有记忆，没有理解，没有意图。就是预测下一个词。

这件事听起来很简单，但它有一个直接的推论，理解了这个推论，你就理解了与 AI 协作的一切：

**你给 AI 什么上下文，它就往什么方向走。上下文决定输出的一切。**

这意味着：
- 给它好的上下文，它能写出超出你预期的代码
- 给它差的上下文，它会自信地写出一堆没用的东西
- 给它模糊的上下文，它就用通用知识填补空白——而通用知识往往不是你想要的

所以，与 AI 协作的核心能力不是「怎么写 prompt」，而是**「怎么管理上下文」**。

---

## 上下文从哪里来

管理上下文，首先要理解它有两个方向，缺一不可：

**现状（它面前的世界）**：代码库的结构、已有的约定、技术约束、团队风格。AI 需要知道「现在的世界是什么样的」才能做出符合现状的决策。

**目标（你期望的世界）**：你希望 AI 实现什么。不是模糊的「做个登录功能」，而是精确的「在 `src/auth/` 下实现 JWT 认证，兼容现有的 `UserService` 接口，错误处理遵循 `src/errors/` 的模式」。

没有现状，AI 的输出跟项目格格不入。没有目标，AI 不知道该往哪走，就会自由发挥。

在工程实践中，高质量的上下文由四个部分组成。每解决一个部分，AI 的输出质量就会上一个台阶：

### 一、需求规格（SPEC）

**是什么**：对「要做什么」和「不做什么」的精确描述。

**为什么重要**：模糊的需求是 AI 过度工程和漂移的根源。当 AI 读到「优化一下登录体验」时，它可能重新设计整个认证系统。当它读到「在 `LoginForm.tsx` 中添加输入校验，规则见 `validators.ts`」时，它的输出就精确得多。

**怎么做好**：
- 明确范围：做什么、不做什么
- 明确约束：技术限制、兼容性要求、性能指标
- 明确成功标准：怎么判断「做完了」

**容易忽略的**：**不做什么**比做什么更重要。AI 的本能是生成更多内容，你需要用明确的边界来约束它。告诉它「不需要重构现有代码」「不需要添加新依赖」和告诉它「要做什么」一样重要。

### 二、领域知识

**是什么**：你的项目独有的概念、术语定义、业务规则、逻辑约束。这些东西**无法从公开资料获得**——它们是你的团队在长期工作中积累的独特认知。

**为什么重要**：AI 的训练数据里没有你的业务逻辑。当你说「用户状态是 frozen」时，AI 不知道这意味着「不能登录、不能发起交易、但可以查看历史记录」。它会按字面意思理解，可能把 frozen 用户当成「已删除」处理。

**怎么做好**：
- 建立术语表：每个领域概念都有明确定义
- 记录业务规则：「当 X 时必须 Y」、「Z 和 W 互斥」
- 标注隐含约束：那些「所有人都知道但没人写下来」的规则

**容易忽略的**：你以为「大家都知道」的东西，AI 完全不知道。最常见的上下文缺失不是复杂的技术问题，而是那些你觉得太简单不需要解释的业务常识。

### 三、团队经验

**是什么**：你的团队在实践中积累的「怎么用我们自己的工具」的知识。自开发组件的用法、自有接口的对接方式、踩过的坑和总结出的模式。

**为什么重要**：AI 知道怎么用 React、怎么写 SQL、怎么配置 Webpack——这些都是公开知识。但它不知道你们的 `ApiClient` 封装了重试逻辑，不知道你们的 `useAuth` hook 需要配合 `AuthProvider` 使用，不知道数据库迁移必须经过 `MigrationService` 而不是直接跑 SQL。

**怎么做好**：
- 记录自有组件的用法和注意事项
- 记录接口对接的约定和陷阱
- 记录「我们试过 X 方案但不行因为 Y」的决策历史

**容易忽略的**：这类知识最容易被低估，因为它在团队内部是「常识」。但 AI 不在你的团队里，它只拥有互联网上的公开知识。

### 四、工作流（Skills）

**是什么**：在持续工作中提炼出的、经过反复验证的最佳实践。它不是某个具体任务的知识，而是「遇到这类问题应该怎么做」的方法论。

**为什么重要**：没有工作流指导，AI 每次都从零开始决策「我该先做什么」。有了工作流，它就站在了你们团队经验的肩膀上——不用重新发明轮子，不用重复踩你们已经踩过的坑。

**怎么做好**：
- 把反复验证有效的做法写成流程
- 包含反模式：「不要做 X，因为会导致 Y」
- 持续更新：每次工作流的输出不符合预期时，回头改进工作流本身

**容易忽略的**：工作流不是一次写好就永远有效的。它需要在持续的工作中反复证明自己。如果一个工作流产生了不好的结果，问题可能不在 AI，而在工作流本身需要改进。

### 四者的关系

这四个部分不是独立的清单，而是一个互相支撑的体系：

```
SPEC（要做什么）  ←  领域知识（概念是什么）  ←  团队经验（怎么用我们的工具）  ←  工作流（怎么做这类事）
```

- 没有 SPEC，领域知识就没有应用场景
- 没有领域知识，AI 就用通用理解代替业务理解
- 没有团队经验，AI 就用公开模式代替你的内部模式
- 没有工作流，AI 就每次从零开始，无法积累团队智慧

四个部分都到位时，AI 的输出就会让你觉得「这像是我们团队的人写的」。缺少任何一个，AI 的输出就会「差那么一点」。

---

## 一个常见的误解

**「我在项目目录里启动了 Claude Code / Cursor / Copilot，它就自动理解了我的项目。」**

这是完全错误的。

你在项目目录里启动 AI 工具，它只是获得了读取文件的**能力**，而不是获得了项目的**上下文**。就像给一个人一把图书馆的钥匙——他能进去看书，但不代表他理解图书馆里每一本书的内容。

AI 不会主动知道：
- 你的项目架构为什么这样设计
- 哪些模块是核心、哪些是遗留代码
- 你们的团队约定和术语定义
- 当前任务跟其他模块的依赖关系

这些信息需要你主动提供，或者设计机制让 AI 自己去获取。

---

## 上下文不足时会怎样

当 AI 在上下文不完整的情况下做决策，你会看到七种典型的失败模式。理解这些模式的根因，你就知道在哪里补充上下文：

### 1. 跳步

AI 直接跳到写代码，跳过了设计和规划。

为什么：它缺少「为什么需要先设计」的上下文。对它来说，拿到需求就开始生成文本（代码）是最自然的路径。

### 2. 幻觉

AI 声称完成了，但实际没验证。

为什么：它用自己生成的输出来验证自己。在它的上下文里，自己写的代码就是「现实」——它缺少外部真实状态的校验。

### 3. 漂移

做着做着偏离了原始目标。

为什么：随着对话变长，上下文窗口里充满了相关信息，原始目标被新信息淹没。AI 没有一个持续的目标锚点。

### 4. 污染

多个任务的信息互相干扰。

为什么：不同任务的上下文被塞进同一个窗口，AI 无法区分「这个信息属于哪个任务」。

### 5. 过度工程

加了不需要的功能和抽象。

为什么：缺少「边界在哪里」的上下文。没有明确的「不做什么」，AI 倾向于多做——因为生成更多内容是它的本能。

### 6. 自我合理化

找到借口跳过流程或降低标准。

为什么：缺少「这些流程为什么存在」的上下文。AI 看到的是流程的摩擦，不是流程的价值。

### 7. 遗忘

忘了早先的约定和术语定义。

为什么：上下文窗口有物理限制。长对话中信息被压缩或丢弃，AI 缺少外部记忆的补充。

---

## 怎么管理上下文

上下文管理有两条路径：

**被动注入**：你预先提供信息——现状、目标、约定、约束。让 AI 在开始工作时就拥有足够的背景。

**主动挖掘**：你设计机制，让 AI 在遇到不确定时主动去获取信息——读取文件、搜索代码、跑命令、问你问题。这就是所谓的「推理引导」：告诉 AI「当你不确定的时候，先去查，不要猜」。

两条路径结合起来，就是与 AI 协作的核心方法论。

---

## 三个管理维度

### 维度一：结构——让 AI 在正确的时机获得正确的上下文

最强的上下文管理手段不是事后纠错，而是**从一开始就设计好信息流动的方式**。

| 做法 | 效果 |
|------|------|
| 把工作分成固定阶段，上一阶段完成才能进入下一阶段 | 每个阶段的上下文范围被限定，减少无关信息干扰 |
| 在会话开始时自动加载项目规则和约定 | AI 从一开始就有现状信息 |
| 不同任务用独立的上下文 | 避免信息互相污染 |
| 每 N 个任务暂停检查 | 定期校正目标方向 |

判断标准：如果你发现自己反复跟 AI 说「不要做 X」，问题不在于 AI 不听话，而在于你需要在那个时刻给它更好的上下文，使 X 自然不会发生。

### 维度二：引导——教 AI 识别「我的上下文可能不够」

结构规定了流程，但在流程中的每一步，AI 仍然需要判断「我现在的信息够不够做这个决策」。你需要教它做这个判断。

**元认知提示**是一种有效的做法——不告诉 AI 做什么，而是告诉它「当你在想这些话时，说明你的上下文可能不够」：

| AI 可能对自己说的 | 实际情况 | 应该做什么 |
|------------------|---------|-----------|
| "这个太简单了" | 简单的任务有最多未检视的假设 | 先确认需求 |
| "直接写吧" | 跳过了了解现状这一步 | 先读相关代码 |
| "我记得之前怎么做的" | 上下文可能已经变了 | 重新读取当前状态 |
| "这个特殊情况可以跳过" | "特殊"往往意味着信息不完整 | 先补充信息 |

核心原则：**AI 不知道自己不知道什么。你的任务是告诉它「什么时候该停下来去获取更多信息」。**

### 维度三：人类判断——在 AI 的上下文空白的时刻介入

有些信息 AI 无法自己获取——业务意图、用户偏好、架构决策的理由。这些只能从你那里获得。

关键原则：**少而精**。不是每一步都需要你介入，只在方向性决策时设卡。频繁介入会导致你审查疲劳（开始随便批准），或流程太慢（失去 AI 的速度优势）。

| 决策类型 | AI 的信息够吗？ | 需要你介入吗？ |
|---------|---------------|--------------|
| "做哪个方向？" | 不够，缺乏业务意图 | 是 |
| "这个设计合理吗？" | 不够，缺乏用户偏好 | 是 |
| "代码风格对不对？" | 够，linter 可以检查 | 否 |
| "测试覆盖率够吗？" | 够，工具可以测量 | 否 |

---

## 一套完整的工作流

把三个维度串起来，就是一个实际可用的开发流程：

### 思考阶段：建立上下文

**做什么**：让 AI 理解现状和目标。

**怎么做的**：
- AI 先读项目代码了解现状（被动注入现状）
- AI 通过提问补充缺失的目标信息（主动挖掘目标）
- 把理解写成文档，你审批后成为后续所有步骤的锚点

**为什么不能跳过**：跳过这个阶段，AI 就在没有上下文的情况下做决策。越「简单」的任务，未检视的假设造成的浪费越大。

### 规划阶段：细化上下文

**做什么**：把目标拆成具体步骤，每一步都有明确的输入和输出。

**为什么重要**：模糊的计划意味着模糊的上下文。当 AI 读到「修改相关文件」这种指令时，它需要猜测「相关」是什么意思。精确的计划消除了猜测。

### 执行阶段：上下文驱动

**做什么**：按计划执行，每一步都先验证上下文是否足够。

**关键机制**：
- 分批执行，每批暂停检查——定期校正目标上下文
- 先写测试再写实现——测试是「目标」的形式化表达
- 不同任务用独立上下文——避免信息污染

### 验证阶段：上下文闭环

**做什么**：用外部证据确认 AI 的输出是否正确。

**核心原则**：AI 自己说「完成了」不算数。它需要提供证据——测试通过、命令输出、实际运行结果。这些外部证据是校正 AI 内部上下文的最终手段。

---

## 案例

以下三个场景展示了这些原则在实践中的运作。[SUMM-Powers](https://github.com/JhihJian/SUMM-Powers) 是一套实现了上述方法论的开源技能系统。每个场景展示了具体的命令、它构建的提示词、以及这些提示词怎么解决上下文问题。

### 场景一：一个新功能从想法到实现

你说："加一个代码审查功能"。

#### 第一步：`/brainstorm` — 补充 SPEC 和领域知识

**问题**：七个字的描述，AI 完全不知道你想要什么。

**命令做了什么**：brainstorming 技能强制 AI 执行一个 10 步清单，在写任何代码之前，先建立完整的上下文：

- **步骤 1「Explore project context」**：AI 先去读项目文件、文档、最近提交——被动注入**团队经验**上下文，了解现有代码是怎么组织的。
- **步骤 2「Domain language check」**：如果项目有 `CONTEXT.md`，AI 立刻读取并激活领域感知模式——注入**领域知识**上下文，确保它理解你们的术语。如果讨论中出现新的术语歧义，它还会当场更新这个文件。
- **步骤 4「Ask clarifying questions」**：AI 一次只问一个问题，用选择题优先——主动挖掘**SPEC**上下文：「审查是自动的还是人工的？」「审查范围是什么？」「结果怎么呈现？」

**关键提示词**——一个硬门禁阻止 AI 跳步：

> Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.

还有一个反模式提示词，专门封堵「这个太简单了不需要设计」的借口：

> Every project goes through this process. "Simple" projects are where unexamined assumptions cause the most wasted work.

**补充的上下文维度**：SPEC（通过提问）、领域知识（通过 CONTEXT.md）、团队经验（通过读取项目文件）。

#### 第二步：`/write-plan` — 把 SPEC 细化为精确指令

**问题**：设计文档里的目标还是偏高层，AI 执行时需要精确到文件路径和命令。

**命令做了什么**：writing-plans 技能要求计划必须满足一系列硬约束：

- **精确文件路径**：每个步骤必须写明要创建/修改哪个文件。AI 不能写「修改相关文件」——它必须写出 `src/review/reviewer.ts` 这样的具体路径。
- **完整命令**：每个步骤的验证命令必须完整写出，包括预期输出。
- **禁止占位符**：不允许出现「TBD」「以后补充」「类似步骤 N」。

**关键提示词**：

> No placeholders: No "TBD", "implement later", "similar to Task N"

这些约束的本质是：**消除计划中所有需要 AI 去猜测的地方**。猜测 = 上下文缺失。精确的指令 = 完整的上下文。

**补充的上下文维度**：SPEC（细化到可执行粒度）。

#### 第三步：`/execute-plan` — 分批执行，持续校正上下文

**问题**：一口气跑完所有任务，方向偏了发现太晚。

**命令做了什么**：executing-plans 技能把执行分成批次（默认每 3 个任务一批），每批完成后暂停等你检查：

> Report for review between batches. Show what was implemented, verification output, say "Ready for feedback".

每个批次执行时，还有一个隐含的上下文管理——**上下文隔离原则**：当 dispatch 子任务时，只提供该任务需要的上下文，不把整个对话历史都传进去。

**补充的上下文维度**：工作流（通过 batch review 持续校正目标上下文）。

#### 第四步：验证——`summ:verification-before-completion`

**问题**：AI 自己说「完成了」不算数。

**命令做了什么**：这个技能强制执行一个五步验证流程——IDENTIFY（识别验证方法）→ RUN（跑验证命令）→ READ（读结果）→ VERIFY（确认通过）→ ONLY THEN claim（才能声称完成）。

**关键提示词**：

> NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE

它还要求 AI 从三个视角自我检查：测试工程师视角（边界条件）、QA 视角（功能交互）、用户视角（实际需求）。

**补充的上下文维度**：用外部证据校正 AI 的内部上下文——防止 AI 用「我写的代码」当作「实际状态」。

---

### 场景二：调试一个 bug

用户报告"登录偶尔失败"。

#### `summ:systematic-debugging` — 用证据代替猜测

**问题**：AI 的本能是看两眼代码就猜原因，然后直接改。它用猜测填补了缺失的现状上下文。

**命令做了什么**：systematic-debugging 技能强制执行一个四阶段调查流程，每个阶段都在补充上下文：

**阶段 1：根因调查**——补充现状上下文

> NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST

AI 不能直接修 bug，必须先：读错误信息 → 复现问题 → 检查最近改动 → 在多层系统中逐层添加诊断日志 → 反向追踪调用栈 → 建立反馈循环（跑测试、看日志输出）。

这些步骤的本质是：**让 AI 通过工具主动获取真实的状态信息，而不是用自己的想象填补空白。**

**阶段 2：模式分析**——补充团队经验

AI 被要求去找系统中正常工作的类似代码，完整地读，对比差异，理解依赖关系。这本质上是在挖掘团队过去的经验：别人是怎么解决类似问题的。

**阶段 3：假设与验证**——用证据构建上下文

AI 必须提出可证伪的假设，一次只改一个变量，验证后才能继续。每个被排除的假设本身就是有价值的上下文（「不是 X」也是一种信息）。

**阶段 4：实现**——在完整上下文下动手

只有经过前三阶段的上下文积累，AI 才被允许写修复代码。而且要求先写一个能复现 bug 的失败测试，确认测试失败，再写修复，确认测试通过。

**一个兜底提示词**——当方向完全错误时：

> If 3+ fixes failed: STOP and question architecture

**补充的上下文维度**：SPEC（bug 的精确表现）、团队经验（正常代码的模式）、工作流（证据驱动的调查流程）。

---

### 场景三：跨模块的复杂任务

需要同时修改前端、后端和数据库 schema。

#### `summ:domain-language` — 先对齐术语

**问题**：三个模块可能有不同的术语体系。「用户」在前端是组件 props，在后端是数据库记录，在数据库是表的一行。

**命令做了什么**：domain-language 技能要求 AI 检查并维护项目的 `CONTEXT.md`——一个术语定义文件。讨论中每出现新的术语歧义，立刻更新，不批量处理：

> When a term is clarified or confirmed, update CONTEXT.md immediately — don't batch updates for later

如果 AI 发现你用了一个跟 `CONTEXT.md` 定义不同的含义，它会主动指出：「CONTEXT.md 定义 [术语] 为 [X]，但你正在用它表示 [Y]。我们需要更新定义吗？」

**补充的上下文维度**：领域知识（术语定义、概念边界）。

#### `summ:subagent-driven-development` — 上下文隔离

**问题**：一个对话里塞三个领域的知识，互相干扰。

**命令做了什么**：subagent-driven-development 技能为每个任务 dispatch 一个全新的子任务，每个子任务只接收它需要的上下文：

> Fresh subagent per task + two-stage review = high quality, fast iteration

每个子任务完成后，经过**两轮审查**：第一轮检查是否符合 SPEC（规格合规），第二轮检查代码质量。两轮审查的提示词分别定义在 `spec-reviewer-prompt.md` 和 `code-quality-reviewer-prompt.md` 中。

子任务之间通过精确定义的接口文档传递信息——接口文档成为子任务间信息传递的唯一通道，避免领域术语的混淆。

**补充的上下文维度**：SPEC（精确的接口定义）、领域知识（各模块独立）、团队经验（各模块的经验隔离注入）、工作流（两轮审查保证质量）。

---

## 总结

**一件事**：大模型是下一个词的预测器，上下文决定输出的一切。

**两个方向**：管理上下文就是同时补充现状（现在是什么样的）和目标（你想让它变成什么样）。

**四个实践维度**：
1. **SPEC** — 需求规格要精确，「不做什么」比「做什么」更重要
2. **领域知识** — 团队独有的术语、规则和约束，公开资料里没有的东西
3. **团队经验** — 自有工具的用法、内部接口的对接方式、踩过的坑
4. **工作流** — 反复验证过的最佳实践，需要在持续工作中不断改进

**一个判断方法**：当 AI 产生了你不想要的输出，问自己一个问题——「它在做这个决策时，上下文够吗？四个维度里缺了哪个？」补充上下文而不是责怪 AI。

---

## 一个具体的实践建议：监控你的上下文

整篇文章都在说「上下文决定一切」。但有一个前提问题：**你怎么知道自己的上下文还够不够？**

如果你用的是 Claude Code，运行 `/statusline` 命令，让它在底部状态栏显示上下文使用百分比。具体配置方法见 [Claude Code 文档](https://code.claude.com/docs/en/statusline)。

### 为什么这很重要

回到基本原理：大模型是下一个词预测器，上下文决定输出质量。上下文窗口被压缩时，信息会丢失——AI 会忘记之前的约定、术语定义、设计决策。压缩后的上下文质量必然下降，输出质量也会跟着下降。

这意味着：

**上下文使用率应该始终保持在 80% 以下。**

当上下文接近满载时，系统会自动压缩以腾出空间。**你应该把自动压缩视为一个危险信号，而不是一个正常的系统行为。** 触发自动压缩意味着：

- 对话中积累了太多信息，AI 开始遗忘
- 任务可能拆得不够细，一个对话里塞了太多工作
- 工作开始失控——AI 在上下文不完整的情况下继续执行

### 怎么做

1. **开启 statusline**：运行 `/statusline`，让它显示上下文使用率
2. **盯着那个数字**：当它接近 70% 时，开始收尾当前工作
3. **主动拆分任务**：不要在一个对话里做太多事。完成一个阶段后，把关键结论写到文件里（设计文档、计划文档），开一个新对话继续
4. **文件是持久化的上下文**：写在文件里的信息不会丢失。对话中的信息会随着压缩而退化。把重要的上下文写到文件里，而不是依赖对话记忆

这个建议不是 Claude Code 特有的——无论你用什么 AI 工具，都应该关注上下文的使用情况，在上下文退化之前主动管理它。

---

# 附录：Claude Code 上下文压缩机制

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

There may be additional summarization instructions provided in the included context. If so, remember to follow these instructions when creating your summary.

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
