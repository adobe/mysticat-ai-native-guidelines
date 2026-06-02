# Token Efficiency

## Overview

Token efficiency is the practice of getting the most value from every token spent in AI-assisted development. It connects directly to [harness engineering](../01-foundations/harness-engineering.md) - a well-designed harness is inherently token-efficient because it loads the right context at the right time.

This guide covers three things: understanding what costs tokens (so you can reason about tradeoffs), design principles that make efficiency a natural byproduct of good practice, and a concrete playbook of actions ranked by impact.

**Who this is for:**

- **Teams already using Claude Code** who want to reduce spend without reducing output
- **Teams evaluating AI tools** who need to understand cost structure before they start

## Understanding the Cost Model

Every message in a Claude Code conversation reprocesses the full context. This is the single most important thing to understand about token costs: you are not paying per-message, you are paying per-message times the size of the accumulated context.

### What Gets Sent Per Message

```
+----------------------------------------------------------+
|  SYSTEM PROMPT (fixed per session)                       |
|  Base instructions, permissions, hooks config             |
+----------------------------------------------------------+
|  TOOL DEFINITIONS (fixed per session)                    |
|  MCP server tools (deferred: names only until used)       |
|  Built-in tools (Read, Edit, Bash, Grep, etc.)            |
|  Fully loaded tool schemas (after first use of a tool)    |
+----------------------------------------------------------+
|  CLAUDE.md CHAIN (fixed per session)                     |
|  Workspace CLAUDE.md + @imports                           |
|  Project CLAUDE.md                                        |
|  User CLAUDE.md                                           |
|  Auto-memory (MEMORY.md)                                  |
+----------------------------------------------------------+
|  CONVERSATION HISTORY (grows per message)                |
|  All prior messages, tool calls, and tool results         |
|  (Compacted to summary when limit is approached)          |
+----------------------------------------------------------+
|  YOUR MESSAGE                                            |
+----------------------------------------------------------+
          |
          v  INPUT TOKENS (billed per message)

+----------------------------------------------------------+
|  THINKING TOKENS (controlled by effort level)            |
|  Extended reasoning - stripped from prior turns            |
+----------------------------------------------------------+
|  RESPONSE + TOOL CALLS                                   |
|  Assistant text + tool results feed back as input         |
+----------------------------------------------------------+
          |
          v  OUTPUT TOKENS (more expensive than input)
```

The fixed overhead (system prompt, tools, CLAUDE.md) is reprocessed on every message but benefits from [prompt caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching): cache reads cost 10% of the base input price, while the first write of new content costs a premium of 1.25x (5-minute TTL, the default Claude Code uses) or 2x (1-hour TTL, for direct-API integrators). Caching is automatic in Claude Code. Conversation history grows and eventually triggers compaction, which summarizes older content to make room.

Caching cuts cost and latency but does **not** reduce the model's attention over cached tokens, so signal dilution is unaffected by how much is cached. Several mid-session changes also bust the cached prefix and force a full re-process on the next turn: editing CLAUDE.md or the system prompt, switching model, changing effort level, or changing output style. Prefer making those changes between sessions, and reach for a subagent rather than flipping the main session's model when you want a cheaper one-off sub-task.

### Model Pricing

Token costs vary significantly by model. Opus 4.8/4.7/4.6 and Sonnet 4.6 support a 1M-token context window at standard pricing - there is no long-context surcharge. Haiku 4.5 and the 4.5-generation models (Opus 4.5, Sonnet 4.5) are 200k ([context windows docs](https://docs.anthropic.com/en/docs/build-with-claude/context-windows)).

| Model | Input (per MTok) | Cache Hit (per MTok) | Output (per MTok) | Relative Cost |
|-------|-------------------|----------------------|--------------------|---------------|
| Opus 4.8 | $5.00 | $0.50 | $25.00 | 1x (baseline) |
| Sonnet 4.6 | $3.00 | $0.30 | $15.00 | ~0.6x |
| Haiku 4.5 | $1.00 | $0.10 | $5.00 | ~0.2x |

Source: [Anthropic pricing](https://docs.anthropic.com/en/docs/about-claude/pricing)

> **Tokenizer note:** Opus 4.7 and later use a new tokenizer that can use up to ~35% more tokens for the same text than earlier models. The common "~4 characters per token" rule of thumb is approximate and not directly comparable across model generations.

### Baseline Numbers

Anthropic reports that average Claude Code usage costs **$6 per developer per day**, with the 90th percentile **below $12/day**. This translates to roughly $100-200/month for a typical developer using Sonnet. Opus-heavy usage, many MCP servers, or frequent agent spawning can push this significantly higher.

Source: [Claude Code cost management](https://docs.anthropic.com/en/docs/claude-code/costs)

A minimal "hello" message in Claude Code consumes approximately 53k tokens before any conversation begins, due to system prompt, tool definitions, and configuration loading ([GitHub #19105](https://github.com/anthropics/claude-code/issues/19105)). This baseline cost is largely cached after the first message, but it illustrates how much overhead exists before you even start working.

### What Makes Things Expensive

The cost formula is roughly: `(fixed overhead + conversation history + your message) x number of messages`. The levers you can pull:

1. **Reduce fixed overhead** - fewer MCP servers, leaner CLAUDE.md
2. **Reduce conversation history growth** - delegate data-heavy work to subagents, use `/compact`
3. **Reduce per-token cost** - use cheaper models for routine work
4. **Reduce thinking tokens** - lower effort level for simple tasks
5. **Reduce messages** - be specific so the agent needs fewer exploratory steps

Token-efficient tool use is built into all Claude 4+ models, reducing output token consumption by up to 70% for tool calls compared to earlier models ([token-saving updates](https://www.anthropic.com/news/token-saving-updates)).

## The Output Side

Most of this guide is about input - the context you re-send every turn. But output tokens are the most expensive part of a turn (several times the input rate) and are never cached, so they get their own levers. Largest first:

1. **Thinking effort.** Reasoning tokens are billed as output even when hidden, and are usually the biggest swing. Control them with the session [effort level](#3-effort-appropriate-reasoning); add `ultrathink` for a one-off deeper think. High effort on a trivial task is waste; low effort on a hard one causes wrong turns you then pay to fix.
2. **Edit style.** A surgical edit emits only the changed lines; a full-file rewrite emits the whole file - on a 1,000-line file that is the difference between tens and thousands of output tokens. Claude Code defaults to diff-style edits; reinforce it when needed ("make minimal edits, don't reprint the file").
3. **Narration.** Recent models already scale response length to task difficulty, but you can dial prose down further with a standing instruction ("be concise, skip non-essential context, keep examples minimal") in CLAUDE.md or per prompt.
4. **Scope of output.** "The whole module with tests and docs" is inherently large; "just the core function" is small. Scope the ask to what you need now.
5. **Output style.** The active [output style](https://docs.anthropic.com/en/docs/claude-code/output-styles) shapes verbosity at the system-prompt level - the built-in Explanatory and Learning styles are longer by design, Default is the lean baseline. Encode a recurring preference once as a custom style (via `/config`) rather than re-prompting every turn. Because the style is part of the system prompt, changing it mid-session busts the cached prefix. And since the system prompt is assembled at session start, the change only fully takes effect after `/clear` or a new session.

## Design Principles

These principles connect token efficiency to the broader [harness engineering](../01-foundations/harness-engineering.md) philosophy. A well-designed harness naturally saves tokens.

### 1. Main Context as Command Center

The main conversation context should be thin on raw data and rich in decisions. Heavy lifting - file reads, codebase searches, test runs, log analysis - belongs in subagents that return concise summaries to the main context.

Anthropic's [context engineering guide](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) calls this the "smallest set of high-signal tokens" principle. Every token in context should earn its place by informing the agent's next action. Raw grep output from an earlier step that you no longer need is dead weight that gets reprocessed on every subsequent message.

This connects to the existing [harness engineering](../01-foundations/harness-engineering.md#context-management) guidance: "Summarize, do not accumulate."

### 2. Right Model for the Right Job

Not every task needs the most capable model. Model selection is a per-task decision, not a session-wide commitment.

| Task Type | Recommended Model | Why |
|-----------|-------------------|-----|
| Architecture, complex debugging, multi-step reasoning | Opus | Reasoning quality justifies cost |
| Routine coding, file edits, test writing, PR descriptions | Sonnet | Handles 80%+ of coding tasks well |
| Simple subagent tasks: searches, classification, formatting | Haiku | 5x cheaper than Opus, sufficient for mechanical work |

Switch models mid-session with `/model sonnet` or `/model opus`. The harness engineering insight applies here: the model matters less than the harness. But the cost difference is real - Opus is roughly 5x the cost of Haiku - so defaulting to the most expensive model for everything is wasteful. One caveat: switching model mid-session busts the cached prefix (the cache is per-model), so a quick detour to a cheaper model for a single question can cost more in cache rebuild than it saves - for a one-off cheaper sub-task, reach for a subagent instead of flipping the main session's model.

### 3. Effort-Appropriate Reasoning

The [effort parameter](https://docs.anthropic.com/en/docs/build-with-claude/effort) controls how many tokens Claude spends on thinking before responding. It affects text responses, tool call decisions, and extended thinking depth. Reasoning tokens are billed as output, so effort is usually the biggest single lever on output cost.

| Level | Use Case | Token Impact |
|-------|----------|--------------|
| `low` | Short, scoped, latency-sensitive work that is not intelligence-sensitive | Minimal thinking |
| `medium` | Cost-sensitive work that can trade off some intelligence | Reduced thinking |
| `high` | Balances token usage and intelligence; default on Opus 4.8, Opus 4.6, Sonnet 4.6 | Full thinking |
| `xhigh` | Deeper reasoning at higher spend; default on Opus 4.7 | More thinking |
| `max` | Demanding tasks; can show diminishing returns and overthinking - test before adopting broadly | Maximum thinking |
| `ultracode` | Not a pure level: sets extra-high effort and has Claude orchestrate dynamic multi-agent workflows for substantive tasks | Highest, plus orchestration |

> `ultracode` is the odd one out: it is not just a thinking-depth setting but also switches Claude into orchestrating dynamic multi-agent workflows. Reach for it when the task warrants fan-out and verification, not merely deeper thinking.

Available levels depend on the model. Match effort to the task's difficulty *and the cost of being wrong* - bias toward the choice that minimizes rework, not per-token price. A cheaper, lower-effort setting that produces subtly wrong output you then have to catch and fix can burn far more than it saved.

Set effort per session with `/effort <level>`, bare `/effort` for a slider, or `/effort auto` to reset to the model default. Raise it only for the hard phases. For a one-off deeper think on a single turn, add `ultrathink` to your prompt.

### 4. Progressive Disclosure is Token Efficiency

The [ACI design](aci-design.md#progressive-disclosure-as-a-general-pattern) principle of progressive disclosure - loading information in tiers from summary to detail - is a direct cost optimization, not just a usability pattern.

Every line in CLAUDE.md is reprocessed on every message. Skills that load on-demand cost tokens only when invoked. The difference:

| Loading Pattern | Token Cost | When |
|----------------|------------|------|
| CLAUDE.md content | Every message | Always |
| @import'd files | Every message (loaded at session start) | Always |
| Skills | Only when invoked | On demand |
| docs/ files | Only when agent reads them | On demand |

Moving specialized workflows from CLAUDE.md into [skills](skills/overview.md) is the most direct way to reduce per-message overhead. The CLAUDE.md keeps a one-line description (the map), and the skill loads the full instructions only when needed (the territory).

**Caveat - the skill *description* budget.** Skill bodies are deferred, but each skill's name and one-line description load up front so the model knows the skill exists. Those descriptions share a budget that defaults to roughly 1% of the context window (`skillListingBudgetFraction`, raisable in `settings.json`). Once you install enough skills to overflow it, the least-used descriptions get shortened or dropped - and a skill with a truncated description can silently stop firing, with no error to tell you why. So the reason to curate skills is reliability, not context cost: keep descriptions tight, prune genuinely unused skills, and use `/doctor` or `/skills` to check whether you are overflowing the budget.

**SHOULD** keep CLAUDE.md stable and high-signal - roughly 100-200 lines of conventions that prevent rework, not the lowest line count you can manage. A right-sized CLAUDE.md is cached after the first turn and *saves* tokens by stopping rediscovery; its real costs are noise (which dilutes signal) and editing it mid-session (which busts the cached prefix behind it). Prune dead or contradictory content, and edit between sessions rather than during. If it grows past ~200 lines, audit for content that belongs in skills or @import'd docs.

### 5. Minimize Idle Tool Overhead

MCP servers add tool definitions to the system prompt. Claude Code uses [deferred loading](https://docs.anthropic.com/en/docs/claude-code/costs) - only tool names are sent initially, with full schemas loaded on first use. This is much better than loading everything upfront, but the name list still adds overhead that scales with server count.

Enterprise-injected servers you never use are pure waste. CLI tools like `gh`, `aws`, and `terraform` add zero per-message overhead because they are invoked through the Bash tool, which is already in context.

Known issues with MCP overhead:

- [GitHub #24677](https://github.com/anthropics/claude-code/issues/24677): Compaction death spiral - 6 MCP servers consumed 86.5% of context, causing 6 compactions in 3.5 minutes
- [GitHub #28984](https://github.com/anthropics/claude-code/issues/28984): With ~150 tools, 22% of context was consumed by tool definitions
- [GitHub #3406](https://github.com/anthropics/claude-code/issues/3406): Before deferred loading, MCP descriptions caused 10-20k token overhead on the first message

**SHOULD** audit MCP servers quarterly. Disable servers not used weekly. Prefer CLI equivalents when they exist.

## Practical Playbook

Concrete actions ranked by impact. Each links to the principle it implements and a corroborating source.

### Tier 1: High Impact

These changes have the largest effect on token spend. Implement them first.

**Default to Sonnet for routine work.** Use `/model sonnet` for everyday coding - file edits, test writing, PR descriptions, debugging. Reserve Opus for architecture decisions, complex multi-step reasoning, and deep debugging where Sonnet's output quality is noticeably lower. This single change can reduce token costs by 40-60% on routine tasks. See [Anthropic pricing](https://docs.anthropic.com/en/docs/about-claude/pricing).

**Set effort to medium.** For Sonnet-based agentic work, `/effort medium` is the recommended default. It provides meaningful thinking token reduction while maintaining quality for most coding tasks. Escalate to `high` for complex reasoning, drop to `low` for simple subagent tasks. See [effort parameter docs](https://docs.anthropic.com/en/docs/build-with-claude/effort).

**Disable unused MCP servers.** Audit your `.mcp.json` and remove servers you don't use weekly. For enterprise-injected servers from Claude.ai that you don't need, set `ENABLE_CLAUDEAI_MCP_SERVERS=false` in your Claude Code settings. Run `/context` to see what's consuming your context budget. See [Claude Code cost management](https://docs.anthropic.com/en/docs/claude-code/costs).

**Delegate data-heavy work to subagents.** File searches across repos, bulk file reads, test runs, log analysis - these produce large outputs that sit in your main context and get reprocessed on every subsequent message. Delegate them to subagents that return concise summaries. The main context stays clean and focused on decisions. See [context engineering blog](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents).

### Tier 2: Medium Impact

Refine your workflow with these practices.

**Use `/compact` with focus instructions.** When your context is growing large, proactively compact with a focus directive: `/compact Focus on architecture decisions, API contracts, and test results`. This tells the compaction what to preserve and what to drop, producing a better summary than automatic compaction. See [Claude Code best practices](https://docs.anthropic.com/en/docs/claude-code/best-practices).

**Use `/btw` for side questions.** The `/btw` command answers your question in a dismissible overlay that never enters conversation history. Use it for tangential lookups ("btw what's the syntax for X?") that would otherwise add tokens to every future message. Zero context growth.

**Keep CLAUDE.md high-signal (~100-200 lines).** Move specialized workflows (PR review checklists, database migration procedures, deployment runbooks) into [skills](skills/overview.md) that load on demand. The CLAUDE.md should be a map of pointers, not a dump of procedures - optimize for signal, not the lowest line count. See [ACI design - progressive disclosure](aci-design.md#progressive-disclosure-as-a-general-pattern).

**Write specific prompts.** "Add input validation to the login handler in `src/routes/auth.ts`" is cheaper than "make the auth system more secure." Specific prompts require fewer exploratory tool calls (file reads, searches) and produce less context accumulation. Name files, state outcomes, define scope. See [Claude Code best practices](https://docs.anthropic.com/en/docs/claude-code/best-practices).

**Specify cheaper models for subagents.** When spawning subagents for mechanical tasks (searches, formatting, simple edits), specify `model: "haiku"` or `model: "sonnet"` in the agent configuration. Each subagent creates a fresh context - the model choice directly affects the cost of that context.

**Trim what you paste in.** A 5,000-line build log, a giant JSON blob, or a full-resolution screenshot pasted into chat becomes context you carry and re-read for the rest of the session. Paste the relevant slice - the same principle as targeted file reads.

### Tier 3: Refinements

Further optimizations for teams that have addressed Tiers 1 and 2.

**Use preprocessing hooks to filter tool output.** Claude Code [hooks](ai-tools/claude-code.md) can preprocess data before it enters context. Instead of Claude reading a 10,000-line test output, a `PostToolUse` hook greps for failures first:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Bash",
      "command": "python3 scripts/filter-test-output.py"
    }]
  }
}
```

This reduces context from thousands of tokens to the handful that matter. See [ACI design - feedback loops](aci-design.md#3-integrate-feedback-at-the-point-of-action).

**Cap search results.** Configure tools to return bounded results and force query refinement rather than dumping hundreds of matches into context. See [ACI design - constrain search](aci-design.md#1-constrain-search-to-force-precision).

**Use `/clear` between unrelated tasks.** When switching topics within a session, `/clear` resets the context. Rename the session with `/rename` first so you can resume later. This eliminates stale context from the previous task being reprocessed on every message of the new task.

**Undo a wrong turn with `/rewind`, not `/clear`.** To roll back a single bad turn, `/rewind` truncates the conversation to an earlier point while keeping the warm cache intact - much cheaper than `/clear` (which drops the whole session and discards the cache) when all you need is to undo one step.

**Monitor with `/cost` or `/stats`.** Check token spend at natural breakpoints - after completing a feature, before spawning multiple agents, before starting a new task. Awareness drives behavior change. See [Measurement and Monitoring](#measurement-and-monitoring) below.

**Use agent teams deliberately.** Agent teams consume roughly 7x more tokens than single-agent sessions because each teammate maintains its own context window. Use teams when genuine parallelism justifies the cost - not for tasks a single agent can handle sequentially. See [Claude Code cost management](https://docs.anthropic.com/en/docs/claude-code/costs).

## Anti-Patterns

Token-specific anti-patterns. For general AI anti-patterns, see [Anti-Patterns](../05-guardrails/anti-patterns.md).

### The Opus Everywhere Pattern

**Pattern**: Running Opus on high effort for every task - simple file renames, git operations, single-line fixes.

**Why it's bad**: Opus costs ~5x more than Haiku per input token and ~1.7x more than Sonnet. Most routine coding tasks show no quality difference between Opus and Sonnet.

**Better approach**: Default to Sonnet with medium effort. Switch to Opus with `/model opus` when you need deep reasoning - architecture decisions, complex debugging, multi-step planning. Switch back when you're done.

### The MCP Hoarder

**Pattern**: Loading 20+ MCP servers "just in case," including enterprise-injected servers you've never used.

**Why it's bad**: Each server adds tool definitions to the system prompt. [GitHub #24677](https://github.com/anthropics/claude-code/issues/24677) documents a compaction death spiral where 6 MCP servers consumed 86.5% of context, causing 6 compactions in 3.5 minutes. With ~150 tools loaded, [22% of context](https://github.com/anthropics/claude-code/issues/28984) can be consumed by tool definitions alone.

**Better approach**: Audit quarterly. Disable servers not used weekly. Set `ENABLE_CLAUDEAI_MCP_SERVERS=false` for enterprise-injected servers you don't need. Prefer CLI tools (`gh`, `aws`, `terraform`) that add zero per-message overhead.

### The Context Landfill

**Pattern**: Reading entire large files into context when you need 5 lines. Running unbounded searches that return hundreds of results. Each raw result sits in context and gets reprocessed on every subsequent message.

**Why it's bad**: A 500-line file read that you needed once costs you tokens on every message after. Context grows with data you've already processed, and the reprocessing tax compounds.

**Better approach**: Use offset/limit on file reads. Delegate broad searches to subagents that return summaries. Cap grep results. If you need to read many files, do it in a subagent and bring back only the relevant findings.

### The Review Army

**Pattern**: Spawning 5+ parallel review agents for a 3-line PR. Each agent creates a full fresh context (system prompt + tools + CLAUDE.md + the diff). Token cost scales linearly with agent count.

**Why it's bad**: A 5-agent parallel review costs roughly 5x a single-agent review. For a small PR, the overhead vastly exceeds the value.

**Better approach**: Scale review depth to PR size. A small fix needs one reviewer, not a panel. Reserve multi-agent reviews for large, complex PRs where multiple perspectives genuinely add value.

### The Infinite Session

**Pattern**: Never using `/clear` or starting fresh. Context grows until compaction triggers repeatedly, each compaction losing nuance and detail.

**Why it's bad**: [GitHub #9579](https://github.com/anthropics/claude-code/issues/9579) documents a bug where a compaction loop consumed 108.8M tokens ($64+) in a single day. Even without bugs, late-session messages in a bloated context are expensive and the model's reasoning quality degrades as it sifts through more noise ([context rot](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)).

**Better approach**: Use `/clear` between unrelated tasks. Use `/compact` with focus instructions proactively before hitting limits. For long-running work on a single topic, keep the session - the accumulated context is valuable. But don't let unrelated work pile up.

### The Vague Prompt

**Pattern**: "Improve the codebase" or "look into the auth system" triggers broad exploratory scanning - reading dozens of files, running many searches. Each exploration step adds to context.

**Why it's bad**: Vague prompts cause 5-10x more tool calls than specific ones, and every tool result enters context permanently.

**Better approach**: Be specific. Name files, state outcomes, define scope. "Add rate limiting to `POST /api/login` in `src/routes/auth.ts` using express-rate-limit" is cheaper than "make auth more secure." See [Claude Code best practices](https://docs.anthropic.com/en/docs/claude-code/best-practices).

## Measurement and Monitoring

You can't optimize what you don't measure.

### Built-in Commands

| Command | What it shows | When to use |
|---------|--------------|-------------|
| `/cost` | Current session token usage and cost | API key users - check during long sessions |
| `/stats` | Session usage statistics | Pro/Max subscribers |
| `/context` | What's consuming context space | When context feels bloated or compaction triggers early |

### Status Line

Configure the [status line](https://docs.anthropic.com/en/docs/claude-code/best-practices) to show context usage continuously. This is the equivalent of a fuel gauge - you notice runaway consumption before it becomes expensive.

### Team-Level Tracking

| Billing Model | Tracking Method |
|--------------|-----------------|
| API key (Anthropic Console) | Workspace spend limits, usage dashboards |
| AWS Bedrock / Google Vertex | Native cloud billing dashboards |
| Per-developer granularity | [LiteLLM proxy](https://docs.litellm.ai/docs/proxy/virtual_keys#tracking-spend) with spend-by-key |
| Enterprise (Pro/Max) | Admin console usage reports |

### Warning Signs

Patterns that indicate a session is burning tokens unnecessarily:

| Signal | What's happening | Action |
|--------|-----------------|--------|
| Compaction triggering repeatedly | Context filled with stale data or MCP overhead | `/compact` with focus, or `/clear` and start fresh |
| Many subagents spawned in sequence | Each rebuilds full context independently | Batch related work into fewer, focused agents |
| Session cost exceeding $10 | Long session with accumulated context | Consider starting a new session |
| Same file read multiple times | Agent lost track of earlier reads (context rot) | `/compact` to refresh, or delegate to subagent |

### The Budget Habit

**SHOULD** check `/cost` or `/stats` at natural breakpoints: after completing a feature, before spawning multiple agents, before starting a new task. Think of it like checking the rearview mirror - not constant, but regular.

## See Also

- [Harness Engineering](../01-foundations/harness-engineering.md) - Why the harness matters more than the model, context management principles
- [ACI Design](aci-design.md) - Agent-computer interface design, progressive disclosure, search constraints, token budgets
- [Anti-Patterns](../05-guardrails/anti-patterns.md) - General AI anti-patterns including prompt stuffing
- [Multi-Session Patterns](../02-lifecycle/multi-session-patterns.md) - State persistence and agent isolation
- [Claude Code Configuration](ai-tools/claude-code.md) - Hooks, permissions, CLAUDE.md patterns
- [Skills Ecosystem](skills/overview.md) - On-demand loading via skills
- [MCP Configuration](mcp/overview.md) - MCP server setup and management
