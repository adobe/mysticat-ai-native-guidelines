# Token Efficiency Guide - Design Spec

**Status**: Draft
**Date**: 2026-04-01
**Author**: DJ (with Claude)
**Location**: `docs/04-configuration/token-efficiency.md`

## Purpose

Create a comprehensive token efficiency guide for the mysticat-ai-native-guidelines repo. The guide serves two audiences:

1. **Mysticat/SpaceCat team** - daily Claude Code users on enterprise billing who need practical levers to reduce spend
2. **Broader Adobe org** - teams evaluating or onboarding to Claude Code who need to understand cost structure

The guide fills a gap: existing docs cover context management conceptually (harness-engineering.md, aci-design.md) but nothing addresses the economics - cost awareness, model selection strategy, effort tuning, MCP overhead, or measurement.

## Document Structure

### Section 1: Understanding the Cost Model

**Goal**: Give readers a mental model of what actually costs tokens and money.

**Content**:

- How Claude Code billing works: input tokens reprocessed every message, output tokens, thinking tokens
- Pricing table for Opus/Sonnet/Haiku
- The "reprocessing tax" - every message re-sends the full context (system prompt + CLAUDE.md + tool definitions + conversation history)
- Cost anatomy diagram showing token composition of a typical message:

```
Message Cost Anatomy
====================

+----------------------------------------------------------+
|  SYSTEM PROMPT (fixed per session)                       |
|  - Base instructions, permissions, hooks                 |
+----------------------------------------------------------+
|  TOOL DEFINITIONS (fixed per session)                    |
|  - MCP server tools (deferred: names only)               |
|  - Built-in tools (Read, Edit, Bash, etc.)               |
|  - Fully loaded tools (after first use)                  |
+----------------------------------------------------------+
|  CLAUDE.md CHAIN (fixed per session)                     |
|  - Workspace CLAUDE.md + @imports                        |
|  - Project CLAUDE.md                                     |
|  - User CLAUDE.md                                        |
|  - Auto-memory (MEMORY.md)                               |
+----------------------------------------------------------+
|  CONVERSATION HISTORY (grows with each message)          |
|  - All prior user messages                               |
|  - All prior assistant messages                          |
|  - All prior tool calls + results                        |
|  - (Compacted to summary when limit approached)          |
+----------------------------------------------------------+
|  CURRENT MESSAGE (your prompt)                           |
+----------------------------------------------------------+

       ||
       \/ processed as INPUT TOKENS (billed per message)

+----------------------------------------------------------+
|  THINKING TOKENS (controlled by effort level)            |
|  - Extended thinking / chain-of-thought                  |
|  - Stripped from prior turns (not carried forward)        |
+----------------------------------------------------------+
|  RESPONSE + TOOL CALLS                                   |
|  - Assistant text                                        |
|  - Tool invocations + results feed back as input         |
+----------------------------------------------------------+

       ||
       \/ billed as OUTPUT TOKENS (more expensive than input)
```

- Prompt caching: Claude Code uses it automatically, 90% cache hit discount on re-sent context
- Baseline numbers from Anthropic: average $6/dev/day, p90 $12/day
- Key insight: the fixed overhead (system prompt + tools + CLAUDE.md) is reprocessed on every message but benefits from caching; conversation history grows and eventually triggers compaction

**External links**:

- [Anthropic pricing](https://docs.anthropic.com/en/docs/about-claude/pricing)
- [Claude Code cost management](https://docs.anthropic.com/en/docs/claude-code/costs)
- [Prompt caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
- [Context windows](https://docs.anthropic.com/en/docs/build-with-claude/context-windows)
- [Token-saving API updates (blog)](https://www.anthropic.com/news/token-saving-updates)
- [GitHub #19105 - baseline 53k tokens on "hi"](https://github.com/anthropics/claude-code/issues/19105)

### Section 2: Design Principles

**Goal**: Connect token efficiency to the repo's existing harness engineering philosophy. These are the "why" behind the tactical advice.

**Principle 1: Main Context as Command Center**

The main conversation context should be thin on raw data, rich in decisions. Heavy lifting (file reads, searches, test runs) belongs in subagents that return summaries. Anthropic's context engineering blog calls this the "smallest set of high-signal tokens" principle. Cross-link to harness-engineering.md's "summarize, do not accumulate."

**Principle 2: Right Model for the Right Job**

Not every task needs Opus. Model selection is a per-task decision, not a session-wide setting. Sonnet for ~80% of work, Opus for complex reasoning, Haiku for simple subagent tasks. The harness matters more than the model - but the cost difference is 5x, so model choice still matters for budget.

**Principle 3: Effort-Appropriate Reasoning**

The effort parameter controls thinking token spend. Most agentic work performs well at medium effort. High/max is for deep architectural reasoning. Low is for classification, simple lookups, subagent tasks.

**Principle 4: Progressive Disclosure is Token Efficiency**

The existing ACI design principle (CLAUDE.md as map, @import as modules, docs/ as detail) isn't just a UX pattern - it's a direct cost optimization. Every line in CLAUDE.md is reprocessed on every message. Skills that load on-demand vs. instructions that load always. Cross-link to aci-design.md's progressive disclosure section.

**Principle 5: Minimize Idle Tool Overhead**

MCP servers, even with deferred loading, add tool name lists to the system prompt. Enterprise-injected servers you never use are pure waste. CLI tools (gh, aws, terraform) add zero per-message overhead.

**External links**:

- [Context engineering blog](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Effort parameter docs](https://docs.anthropic.com/en/docs/build-with-claude/effort)
- [Claude Code best practices](https://docs.anthropic.com/en/docs/claude-code/best-practices)
- [GitHub #3406 - MCP overhead](https://github.com/anthropics/claude-code/issues/3406)
- [GitHub #28984 - 22% context from tool definitions](https://github.com/anthropics/claude-code/issues/28984)
- [GitHub #24677 - compaction death spiral](https://github.com/anthropics/claude-code/issues/24677)

### Section 3: Practical Playbook

**Goal**: Ranked list of concrete actions, highest to lowest impact. Each action: what to do, why it helps, expected impact, corroborating link.

**Tier 1 - High Impact**

| Action | What | Expected Impact |
|--------|------|-----------------|
| Default to Sonnet | `/model sonnet` for routine work, Opus for architecture/debugging | ~40-60% cost reduction on routine tasks |
| Set effort to medium | `/effort medium` as default, high only for complex reasoning | Significant thinking token reduction |
| Disable unused MCP servers | `ENABLE_CLAUDEAI_MCP_SERVERS=false`, audit `.mcp.json` | Reduces per-message system prompt overhead |
| Delegate data-heavy work to subagents | File searches, bulk reads, test runs in subagents | Keeps main context clean, avoids reprocessing raw output |

**Tier 2 - Medium Impact**

| Action | What | Expected Impact |
|--------|------|-----------------|
| `/compact` with focus instructions | `/compact Focus on architecture decisions and API contracts` | Preserves signal, drops noise during compaction |
| `/btw` for side questions | Side question answered in overlay, never enters history | Zero context growth for tangential questions |
| Keep CLAUDE.md under 200 lines | Move specialized workflows to skills (on-demand loading) | Reduces per-message base cost |
| Write specific prompts | "Add validation to login in auth.ts" not "improve the codebase" | Fewer exploratory tool calls |
| Specify cheaper models for subagents | `model: "haiku"` or `model: "sonnet"` in agent spawn config | Subagent cost reduction for simple tasks |

**Tier 3 - Refinements**

| Action | What | Expected Impact |
|--------|------|-----------------|
| Preprocessing hooks | Filter test output to failures, grep logs before Claude reads them | Reduces tool output tokens entering context |
| Cap search results | Configure tools to return bounded results | Less noise in context |
| `/clear` between unrelated tasks | Reset context when switching topics (not mid-task) | Eliminates stale context reprocessing |
| Monitor with `/cost` or `/stats` | Check spend at natural breakpoints | Awareness drives behavior change |
| Use agent teams deliberately | Teams use ~7x tokens - only when parallelism justifies it | Avoids accidental multiplier |

Each action gets a short paragraph expanding on the table entry, with external link.

**External links**:

- [Cost management docs](https://docs.anthropic.com/en/docs/claude-code/costs)
- [Effort parameter docs](https://docs.anthropic.com/en/docs/build-with-claude/effort)
- [Skills docs](https://docs.anthropic.com/en/docs/claude-code/skills)
- [Context engineering blog](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Best practices docs](https://docs.anthropic.com/en/docs/claude-code/best-practices)

### Section 4: Anti-Patterns

**Goal**: Token-specific anti-patterns in the repo's established style (Pattern / Why It's Bad / Better Approach).

**The Opus Everywhere Pattern**
Running Opus on high effort for every task. Opus costs 5x Sonnet per token. Most routine coding tasks show no quality difference.
Better: Switch models mid-session with `/model`. Default to Sonnet, escalate to Opus when reasoning quality matters.

**The MCP Hoarder**
Loading 20+ MCP servers "just in case." Each server adds tool definitions. GitHub #24677 documents a compaction death spiral from MCP overhead consuming 86.5% of context.
Better: Audit quarterly. Disable what you don't use. Prefer CLI tools when equivalent.

**The Context Landfill**
Reading entire large files when you need 5 lines. Running unbounded searches. Each raw result gets reprocessed on every subsequent message.
Better: Use offset/limit on file reads. Delegate broad searches to subagents. Cap grep results.

**The Review Army**
Spawning 5+ parallel review agents for a 3-line PR. Each agent creates a full fresh context. Token cost scales linearly with agent count.
Better: Scale review depth to PR size.

**The Infinite Session**
Never using `/clear` or starting fresh. Context grows until compaction triggers repeatedly, each compaction losing nuance.
Better: `/clear` between unrelated tasks. `/compact` with focus instructions proactively.

**The Vague Prompt**
"Improve the codebase" triggers broad scanning - reading dozens of files, many searches. Each step adds to context.
Better: Name files, state outcomes, define scope.

Cross-link to existing anti-patterns.md (prompt stuffing) rather than duplicating.

**External links**:

- [GitHub #24677 - compaction death spiral](https://github.com/anthropics/claude-code/issues/24677)
- [GitHub #9579 - autocompacting loop, $64+/day](https://github.com/anthropics/claude-code/issues/9579)
- [GitHub #19105 - baseline token cost](https://github.com/anthropics/claude-code/issues/19105)
- [Best practices - specific prompts](https://docs.anthropic.com/en/docs/claude-code/best-practices)

### Section 5: Measurement and Monitoring

**Goal**: Close the loop - you can't optimize what you don't measure.

**Built-in Commands**

| Command | What it shows | When to use |
|---------|--------------|-------------|
| `/cost` | Current session token usage and cost | API key users - check during long sessions |
| `/stats` | Session usage statistics | Pro/Max subscribers |
| `/context` | What's consuming context space | When context feels bloated or compaction triggers early |

**Status Line Configuration**
Configure status line to show context usage continuously - the fuel gauge.

**Team-Level Tracking**
- API key users: Anthropic Console workspace spend limits
- Bedrock/Vertex: native cloud billing
- Per-developer: LiteLLM proxy with spend-by-key
- Enterprise: Admin console usage reports

**Warning Signs Table**

| Signal | What's happening | Action |
|--------|-----------------|--------|
| Compaction triggering repeatedly | Context filled with stale data or MCP overhead | `/compact` with focus, or `/clear` |
| Agent spawning many subagents in sequence | Each rebuilds full context | Batch into fewer, focused agents |
| Session cost exceeding $10 | Long session with accumulated context | Consider new session |
| Same file read multiple times | Context rot | `/compact` or delegate to subagent |

**The Budget Habit**
SHOULD check `/cost` or `/stats` at natural breakpoints.

**External links**:

- [Cost management - tracking](https://docs.anthropic.com/en/docs/claude-code/costs)
- [LiteLLM spend tracking](https://docs.litellm.ai/docs/proxy/virtual_keys#tracking-spend)

## Placement and Cross-Links

**File**: `docs/04-configuration/token-efficiency.md`

**mkdocs.yml**: Under Configuration section, after aci-design.md

**Cross-links to add in existing docs**:

| Document | Where | What |
|----------|-------|------|
| `harness-engineering.md` | Context Management section | Link to token efficiency guide for cost implications |
| `aci-design.md` | Progressive Disclosure, Token Budgets | Link to full treatment of token cost optimization |
| `should-rules.md` | AI Collaboration section | Add 2-3 SHOULD rules for model selection, effort tuning, MCP audit |
| `anti-patterns.md` | AI-Specific section | Link to token-specific anti-patterns |
| `AGENTS.md` | Configuration section | Add entry for agent discoverability |

## Complete External Links Inventory

| Source | Topic | Section |
|--------|-------|---------|
| [Anthropic pricing](https://docs.anthropic.com/en/docs/about-claude/pricing) | Model costs | 1 |
| [Claude Code cost management](https://docs.anthropic.com/en/docs/claude-code/costs) | Baselines, /cost, tracking | 1, 3, 5 |
| [Prompt caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching) | Cache hit discount | 1 |
| [Context windows](https://docs.anthropic.com/en/docs/build-with-claude/context-windows) | 1M window, no surcharge | 1 |
| [Token-saving API updates](https://www.anthropic.com/news/token-saving-updates) | Token-efficient tool use | 1 |
| [Context engineering blog](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Subagent architecture | 2, 3 |
| [Effort parameter](https://docs.anthropic.com/en/docs/build-with-claude/effort) | Effort levels | 2, 3 |
| [Best practices](https://docs.anthropic.com/en/docs/claude-code/best-practices) | /compact, /btw, /clear | 3, 4 |
| [Skills docs](https://docs.anthropic.com/en/docs/claude-code/skills) | On-demand loading | 2, 3 |
| [GitHub #24677](https://github.com/anthropics/claude-code/issues/24677) | Compaction death spiral | 2, 4 |
| [GitHub #9579](https://github.com/anthropics/claude-code/issues/9579) | Autocompacting loop | 4 |
| [GitHub #19105](https://github.com/anthropics/claude-code/issues/19105) | Baseline 53k tokens | 1 |
| [GitHub #28984](https://github.com/anthropics/claude-code/issues/28984) | 22% context from tools | 2 |
| [GitHub #3406](https://github.com/anthropics/claude-code/issues/3406) | MCP overhead pre-deferred | 2 |
| [LiteLLM spend tracking](https://docs.litellm.ai/docs/proxy/virtual_keys#tracking-spend) | Per-developer tracking | 5 |

## Out of Scope

- API-level optimizations (batch processing, explicit cache breakpoints) - this guide is for Claude Code users, not API developers
- Pricing negotiation or enterprise contract details
- Model benchmarking or quality comparisons - only cost implications of model choice
- Rewriting existing harness-engineering.md or aci-design.md content - cross-link, don't duplicate
