# Agent-Computer Interface (ACI) Design

## Overview

The Agent-Computer Interface (ACI) is the designed surface between an AI agent and the tools, files, and feedback it interacts with. Just as HCI (Human-Computer Interface) design determines how effectively a person can use software, ACI design determines how effectively an agent can operate in your codebase.

The insight behind ACI is that agent performance depends less on which model you use and more on how you design the environment around it. SWE-agent demonstrated this directly: the same underlying model jumped from 1.7% to 12.5% task completion by redesigning the interface - capping search results, adding line numbers to file views, integrating linters at the edit step, and forcing search refinement. The model did not change. The interface did.

This document covers ACI design principles, practical patterns you can apply today, and an audit checklist for evaluating your own setup. For the broader concept of harness engineering - why the designed environment around an agent matters more than the model - see [Harness Engineering](../01-foundations/harness-engineering.md). For tool-specific configuration, see the individual tool docs ([Claude Code](ai-tools/claude-code.md), [Cursor](ai-tools/cursor.md), [Copilot](ai-tools/copilot.md)). For the skills loading model that implements progressive disclosure, see [Agent Skills Ecosystem](skills/overview.md).

## Why ACI Matters

Most teams think about AI tools in terms of model capabilities: which model is smartest, which has the largest context window, which scores highest on benchmarks. But in practice, the environment design has a larger effect on outcomes than the model choice.

Common symptoms of poor ACI design:

- The agent searches for a function, gets 200 results, and picks the wrong one
- The agent edits a file, introduces a syntax error, and does not notice until three steps later
- The agent loses track of what it was doing after reading a large file
- The agent asks questions that are already answered in project documentation
- The agent makes the same category of mistake repeatedly across sessions

Each of these is an interface failure, not a model failure. The fix is not a better model - it is a better interface.

## Design Principles

### 1. Constrain Search to Force Precision

Unbounded search results overwhelm agents the same way they overwhelm humans. When a search returns 200 matches, the agent must spend context tokens processing results, often picking a plausible-but-wrong match early in the list.

**Pattern: Cap results and require refinement**

Configure tools to return a bounded number of results (e.g., 50) and surface a clear message when results are truncated. This forces the agent to narrow its query rather than guess from a noisy list.

In practice:
- CLAUDE.md rules like "MUST use specific grep patterns - never search for single common words"
- MCP servers that paginate results and include total counts
- Custom wrapper scripts that cap output and append "N more results - refine your query"

```markdown
## Rules

### Search
- MUST include at least two qualifying terms in grep/search queries
- MUST NOT pipe search results through head/tail without checking total count first
- SHOULD use file-type filters (--type) to narrow searches before broadening
```

### 2. Add State to Navigation

Stateless file viewing - where the agent reads an entire file or an arbitrary slice - leads to disorientation. Agents lose track of where they are in a file, re-read sections they already saw, or miss the surrounding context of a function.

**Pattern: Windowed viewing with position awareness**

When agents view files, they should see:
- Line numbers on every line (enables precise edit references)
- A bounded window (e.g., 100-200 lines at a time) rather than the whole file
- Current position indicators ("lines 150-250 of 800")

Claude Code's Read tool already provides line numbers and supports offset/limit parameters. The ACI design task is to make your project documentation reference line ranges explicitly:

```markdown
## Architecture

The request pipeline is defined in src/api/middleware.ts (lines 45-120).
Auth validation happens in src/auth/validate.ts:validateToken (line 23).
```

Explicit line references give the agent a precise starting point rather than forcing a search-then-read cycle.

### 3. Integrate Feedback at the Point of Action

The fastest feedback loop is one that fires on every edit, not after a commit or CI run. When an agent makes a syntax error, the ideal ACI catches it within seconds - before the agent builds on the broken state.

**Pattern: Hooks as immediate feedback**

Claude Code hooks (PostToolUse, PreToolUse) let you run validation after every edit or before dangerous operations:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "./scripts/lint-changed.sh"
      }
    ]
  }
}
```

The hook script should:
- Run fast (under 5 seconds) - it blocks the agent
- Return structured output the agent can act on (file, line, message)
- Focus on the changed file, not the whole project

```bash
#!/bin/bash
# scripts/lint-changed.sh - lint only the file that was just edited
FILE=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // .filePath // empty')
if [ -n "$FILE" ] && [ -f "$FILE" ]; then
  npx eslint --format compact "$FILE" 2>&1 || true
fi
```

See [Claude Code hooks](ai-tools/claude-code.md#hooks) for configuration details and [Mechanical Enforcement](../05-guardrails/mechanical-enforcement.md) for a guardrails-focused treatment of hooks as enforcement points. The key ACI insight is framing hooks not as convenience automation but as a harness design pattern: the faster the feedback loop, the better the agent performs.

### 4. Write Error Messages for Agents

Human-readable error messages often rely on visual context, implicit knowledge, or suggestions that assume the reader will investigate manually. Agent-readable error messages need to be explicit, structured, and actionable.

**Pattern: Structured, specific, fixable**

Good agent-facing errors include:
- **File and line**: Exactly where the problem is
- **What is wrong**: Specific violation, not a category
- **How to fix it**: The expected pattern or value

```
# Bad (for agents)
Error: Invalid configuration

# Good (for agents)
Error in src/config/database.ts:42 - Pool size must be between 1 and 100.
Current value: 0. Set `pool.size` to a positive integer.
```

When writing custom linters, validators, or hook scripts, format output for agent consumption:

```bash
# Output format agents can parse and act on
echo "ERROR src/api/routes.ts:15 - Missing error handler on async route. Wrap handler body in try/catch or use asyncHandler() wrapper."
```

### 5. Make the Repository Self-Describing

An agent should be able to understand your project by reading what is in the repository - not by asking a human, checking Slack, or reading a wiki. Everything the agent needs to make correct decisions MUST be in-repo.

**Pattern: Repository as system of record**

| What | Where | Why |
|------|-------|-----|
| Architecture decisions | `docs/decisions/` or ADRs | Agent understands why, not just what |
| API contracts | OpenAPI specs, protobuf files | Agent validates against contracts |
| Environment setup | `init.sh`, `docker-compose.yml` | Agent can bootstrap without asking |
| Code conventions | AGENTS.md / CLAUDE.md | Agent follows team patterns |
| Test patterns | Example tests in `tests/` | Agent mimics existing style |

The anti-pattern is a codebase where critical context lives in Confluence, Slack threads, or team members' heads. An agent working in that codebase will make decisions based on incomplete information, and no amount of model capability compensates for missing context.

See [Workspace Setup](../01-foundations/workspace-setup.md) for directory structure patterns that support this.

## Progressive Disclosure as a General Pattern

Progressive disclosure - loading information in tiers from summary to detail - is not just a skills optimization. It is a general ACI design principle that applies to every layer of project configuration.

### The Problem

Dumping all project context into a single file (a 2,000-line CLAUDE.md, a monolithic AGENTS.md) wastes context tokens and buries critical rules in noise. The agent reads everything at session start, retains a fraction, and misses the rule that mattered.

### The Pattern

Structure information in layers, from lightweight summaries to full detail:

| Layer | What loads | When | Token cost |
|-------|-----------|------|------------|
| **Map** | AGENTS.md / CLAUDE.md | Session start | 500-2,000 |
| **Module** | @import'd docs, activated skills | On reference or need | 1,000-5,000 each |
| **Detail** | Reference material, schemas, examples | On explicit request | Varies |

### Applying It

**AGENTS.md / CLAUDE.md as a map, not a dump**

Keep root instruction files short - under 200 lines. They should contain:
- Project identity (what this is, tech stack)
- Critical rules (MUST/MUST NOT - the ones that cause incidents if missed)
- Pointers to detail (links to deeper docs, @import directives)

```markdown
# My Project

Node.js API service on Express + PostgreSQL.

## Critical Rules

- MUST NOT commit to main directly
- MUST run `npm test` before committing
- MUST use parameterized queries for all database access

## Architecture

@import docs/architecture.md

## API Reference

@import docs/api-reference.md

## Deployment

See docs/deployment.md for environment-specific instructions.
```

**@import as progressive disclosure**

Claude Code's `@import` directive loads referenced files into context only when the CLAUDE.md is processed. This is a form of progressive disclosure - the main file stays small and readable, while detail is available on demand.

Structure imports by domain, not by file type:

```markdown
# Good - domain-oriented imports
@import docs/auth/overview.md
@import docs/database/conventions.md
@import docs/api/contracts.md

# Avoid - grab-bag imports that load everything
@import docs/all-the-things.md
```

**docs/ directory as navigable structure**

A well-organized docs directory acts as a third tier. The agent reads the map (CLAUDE.md), loads a module (@import), and can then navigate to reference material within docs/ when needed:

```
docs/
  architecture.md          # Loaded via @import - medium detail
  api-reference.md         # Loaded via @import - medium detail
  database/
    conventions.md         # Loaded via @import
    migration-guide.md     # Read on demand - full detail
    schema-reference.md    # Read on demand - full detail
```

**Skills three-tier model**

The [Agent Skills Ecosystem](skills/overview.md) implements progressive disclosure most explicitly with its three-tier loading: catalog at session start (name + description), instructions on activation (full SKILL.md), and resources on reference (scripts, checklists). This same layering principle applies to all project documentation.

### Anti-Patterns

| Anti-pattern | Problem | Fix |
|-------------|---------|-----|
| 2,000-line CLAUDE.md | Buries critical rules in noise | Split into map + @imports |
| Every doc in @import | Loads too much at session start | Import only essential modules |
| No docs/ structure | Agent cannot find detail when needed | Organize by domain with consistent naming |
| Architecture in Confluence | Agent cannot access it | Move to in-repo docs/ |

## Writing Documentation for Agents

Documentation meant for agent consumption follows different conventions than documentation meant for humans.

### Structure for Parseability

Agents navigate documents by headings, tables, and code blocks - not by reading prose linearly. Design for that:

- **Use tables over prose** for reference information (API parameters, configuration options, command flags)
- **Use consistent heading hierarchy** - agents match section names, so use predictable names across docs
- **Include code blocks with file paths** - agents can locate and verify referenced code
- **Use explicit cross-references** with relative paths rather than assuming the agent will search

```markdown
## Good: Table Format (agent-parseable)

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| pool.size | int | Yes | 10 | Database connection pool size (1-100) |
| pool.timeout | int | No | 30000 | Connection timeout in ms |

## Avoid: Prose Format (requires inference)

The pool size controls how many database connections are maintained.
It defaults to 10 but you might want to increase it for high-traffic
services. The timeout is 30 seconds by default.
```

### Token Budgets

Keep individual documents within reasonable token budgets so they do not crowd out working context when loaded:

| Document type | Target size | Rationale |
|---------------|-------------|-----------|
| AGENTS.md / CLAUDE.md | Under 200 lines | Loaded every session |
| @import'd module | Under 500 lines | Loaded when referenced |
| Reference doc | Under 1,000 lines | Loaded on demand |
| Skills (SKILL.md body) | Under 5,000 tokens | Loaded on activation |

If a document exceeds its budget, split it. A 1,500-line architecture doc should become a 200-line overview that links to domain-specific detail docs.

For a comprehensive treatment of token cost optimization beyond document sizing - model selection, effort tuning, MCP overhead, and measurement - see [Token Efficiency](token-efficiency.md).

### Machine-Readable Sections

For sections that agents will act on programmatically (not just read for context), use formats that are unambiguous:

```markdown
## Build Commands

| Action | Command | Expected exit code |
|--------|---------|-------------------|
| Install dependencies | `npm ci` | 0 |
| Run tests | `npm test` | 0 |
| Build for production | `npm run build` | 0 |
| Lint | `npm run lint` | 0 |
```

This is more reliable than:

```markdown
## Building

First install dependencies with npm ci. Then you can run tests
with npm test. To build for production use npm run build.
```

## ACI Audit Checklist

Use this checklist to evaluate how well your project's interface serves agents. Each item maps to a design principle above.

### Search and Navigation

- [ ] Search results are bounded or paginated (not unbounded dumps)
- [ ] File references in documentation include line numbers or function names
- [ ] Directory structure is documented in AGENTS.md or CLAUDE.md
- [ ] Key architecture decisions are findable without searching Slack or wikis

### Feedback Loops

- [ ] Linter runs on every edit (via hooks or equivalent)
- [ ] Type checker runs on save or edit (for typed languages)
- [ ] Test suite can run incrementally (single file/module, not only full suite)
- [ ] Error output includes file, line, and actionable fix suggestion

### Context Management

- [ ] AGENTS.md / CLAUDE.md is under 200 lines
- [ ] Detail docs are loaded via @import or on-demand, not inlined
- [ ] Skills use the three-tier loading model (catalog, instructions, resources)
- [ ] Large files have internal navigation aids (section headings, tables of contents)

### Repository Completeness

- [ ] Project can be bootstrapped from a script (`init.sh`, `docker-compose up`)
- [ ] Architecture overview is in-repo, not in external wikis
- [ ] API contracts are machine-readable (OpenAPI, protobuf, JSON Schema)
- [ ] Code conventions are documented, not just "follow existing patterns"
- [ ] Environment variables are documented with types, defaults, and examples

### Error Design

- [ ] Custom validators produce structured output (file:line - message)
- [ ] Error messages include "how to fix," not just "what is wrong"
- [ ] CI failure output is concise enough to fit in agent context
- [ ] Build output does not include extraneous warnings that obscure real errors

## See Also

- [Harness Engineering](../01-foundations/harness-engineering.md) - Why the harness matters more than the model, the 7-layer harness stack, and the environment audit mindset
- [Application Legibility](../01-foundations/harness-engineering.md#application-legibility) - The application-side complement to ACI: designing your app to be operable by agents
- [Mechanical Enforcement](../05-guardrails/mechanical-enforcement.md) - Hooks as enforcement points, agent-friendly errors, structural tests, throughput-aware merge philosophy
- [Multi-Session Patterns](../02-lifecycle/multi-session-patterns.md) - State persistence, handoff protocols, and worktree isolation for parallel agents
- [Claude Code Configuration](ai-tools/claude-code.md) - CLAUDE.md patterns, hooks, and tool setup
- [Cross-Tool Configuration](cross-tool-setup.md) - AGENTS.md, thin adapters, multi-tool sync
- [Agent Skills Ecosystem](skills/overview.md) - Progressive disclosure in practice (three-tier loading)
- [Workspace Setup](../01-foundations/workspace-setup.md) - Directory structure and bootstrap patterns
- [Environment & Secrets](env-secrets.md) - Secrets management across tools
- [Configuration Evolution](../02-lifecycle/06-config-evolution.md) - How to evolve your configuration over time
