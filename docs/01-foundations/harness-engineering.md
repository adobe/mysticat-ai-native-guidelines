# Harness Engineering

## What is a Harness?

A harness is the complete designed environment that surrounds an AI coding agent: the instructions it reads, the tools it can invoke, the feedback loops that correct it, the isolation boundaries that contain it, and the orchestration that sequences its work. It is the difference between "using an AI tool" and "engineering a system that reliably produces good outcomes through AI."

Most teams focus on model selection - which LLM to use, which version, which provider. This is the wrong lever. Research consistently shows that the harness matters more than the model. SWE-bench evaluations found that the same model's performance jumped from 12% to 76% when the harness was redesigned - same weights, same training, dramatically different outcomes. The model is important, but the harness is decisive.

Think of it this way: a skilled carpenter with poor tools in a chaotic workshop produces worse results than a competent one with sharp tools, organized materials, and a well-lit bench. AI coding agents work the same way. The environment you design around them determines the quality of what they produce.

## The Harness Stack

The harness is not a single layer - it is a stack of concerns. Each layer addresses a different aspect of agent effectiveness:

| Layer | What It Does | Examples in These Guidelines |
|-------|-------------|------------------------------|
| **Human Oversight** | Sets goals, reviews output, makes judgment calls | PR review, spec approval, architecture decisions |
| **Planning & Specs** | Defines what to build before building it | [Design & Spec](../02-lifecycle/01-design-spec.md), spec-driven development |
| **Lifecycle Platforms** | Manages tickets, PRs, CI/CD, and deployment | Jira, GitHub, CI pipelines |
| **Task Runners** | Orchestrates multi-step agent workflows | Multi-session patterns, initializer + worker agents |
| **Agent Orchestrators** | Coordinate multiple agents working in parallel | Git worktree isolation, feature-list tracking |
| **Harness Frameworks** | Provide the runtime: tool access, context, permissions | Claude Code, Cursor, Codex, [CLAUDE.md](../04-configuration/ai-tools/claude-code.md), [AGENTS.md](../04-configuration/cross-tool-setup.md) |
| **Coding Agents** | The LLM that reads, writes, and reasons about code | Claude, GPT, Gemini |

Most teams only think about the bottom layer - which coding agent to use. Effective teams engineer the entire stack. These guidelines exist to help you do that: [workspace setup](workspace-setup.md) and [configuration](../04-configuration/) address harness frameworks, [the development lifecycle](../02-lifecycle/overview.md) addresses planning and task orchestration, and [guardrails](../05-guardrails/must-rules.md) address oversight and enforcement.

### Where the Leverage Is

When an agent performs poorly, the instinct is to blame the model or switch to a different one. Resist that instinct. Most failures trace to harness problems:

- **Agent edits the wrong file** - The harness did not provide enough project context. Improve CLAUDE.md or add an ARCHITECTURE.md.
- **Agent loses track of the task** - The context window is cluttered with irrelevant information. Apply progressive disclosure (load only what is needed, when it is needed).
- **Agent introduces a bug** - The harness lacks immediate feedback. Add a linter hook or post-edit test runner.
- **Agent goes in circles** - There is no state persistence across sessions. Add a progress file or TODO.md that the agent reads on startup.

Before switching models, audit the harness. Fix the environment first.

## Context Management

The context window is the agent's working consciousness - not a storage buffer. Everything in the context window competes for attention. Irrelevant information does not just take up space; it actively degrades reasoning by forcing the model to distinguish signal from noise.

This has direct practical implications for how you design your harness.

### Principles

**Keep CLAUDE.md lean.** Your workspace CLAUDE.md is loaded into every session. Every line in it competes with the actual task for the agent's attention. Use `@import` to pull in reference docs, but be selective - import what the agent needs for most tasks, not everything it might ever need.

**Use progressive disclosure.** Structure information in layers:

1. **Always loaded** - Core rules, project structure, critical conventions (CLAUDE.md)
2. **Loaded on demand** - Reference docs, detailed procedures (@import files, docs/ directory)
3. **Discovered by search** - Implementation details, historical decisions (code, git history)

The [skills ecosystem](../04-configuration/skills/overview.md) implements this pattern well: skill names and descriptions load immediately (the map), but full skill content loads only when invoked (the territory).

**Cap search results.** When agents search the codebase, unbounded results flood the context with marginally relevant matches. Effective harness design constrains search to force refinement - returning the top results rather than all results, so the agent must sharpen its query if the first attempt does not find what it needs.

**Summarize, do not accumulate.** In long sessions, earlier observations become stale. Effective harness patterns summarize prior findings rather than preserving every raw result. When you notice an agent session getting long and unfocused, start a new session with a clear summary of what was accomplished and what remains.

For the cost implications of context management decisions - what tokens cost, how conversation history accumulates, and practical actions to reduce spend - see [Token Efficiency](../04-configuration/token-efficiency.md).

### Anti-Patterns

| Anti-Pattern | Why It Hurts | Fix |
|-------------|-------------|-----|
| Dumping full architecture into CLAUDE.md | Consumes context budget on every task, even simple ones | Use @import and keep CLAUDE.md under 200 lines of rules |
| Loading all reference docs by default | Agent processes irrelevant docs before starting work | Import selectively; put detailed docs in files the agent can search |
| Unbounded grep/search results | Floods context with low-relevance matches | Configure search to return limited results; let the agent refine |
| Keeping raw tool output from early in a long session | Stale context competes with current task focus | Start fresh sessions with a summary when context gets cluttered |

For detailed patterns on search constraints, file navigation, feedback hooks, and documentation structure, see [ACI Design](../04-configuration/aci-design.md).

## The Environment Audit Mindset

Every agent failure is a signal about what the harness needs. This is the most important mental shift in harness engineering: stop treating failures as agent limitations and start treating them as design feedback.

When an agent makes the same mistake twice, the right response is not "the model is bad at this" - it is "my harness does not prevent or correct this." Concretely:

| Failure Pattern | Harness Signal | Harness Response |
|----------------|---------------|------------------|
| Agent makes wrong edits that break the build | No immediate build feedback | Add a post-edit build hook or linter integration |
| Agent forgets project conventions | Conventions are not in CLAUDE.md | Add the convention to CLAUDE.md as a MUST rule |
| Agent creates files in wrong locations | Project structure is not documented | Add directory layout to CLAUDE.md or ARCHITECTURE.md |
| Agent repeats work across sessions | No state persistence between sessions | Add a progress file or TODO.md the agent reads on startup |
| Agent makes insecure changes | No security linting | Add security-focused linter as a pre-commit hook |
| Agent drifts from the spec | Spec is not loaded or too long | Shorten the spec's active section; load it explicitly at session start |

The [config evolution](../02-lifecycle/06-config-evolution.md) process captures one version of this mindset - the "three times" heuristic for adding rules to CLAUDE.md. But the audit mindset applies to the entire harness stack, not just configuration files. It applies to tool selection, feedback loop design, isolation boundaries, and orchestration patterns.

**SHOULD** review agent failures weekly and ask: "What harness change would have prevented this?" Track recurring failures and address them systematically rather than working around them session by session.

## Application Legibility

A harness can only be as effective as the application allows. If your application is hard for agents to understand and operate, no amount of harness engineering will compensate. Application legibility is the practice of designing your application to be understandable and operable by AI agents.

### What Makes an Application Legible

**Deterministic boot.** The application starts the same way every time, with a single command. No manual steps, no environment-specific workarounds, no "you also need to run X first." The [workspace repository pattern](workspace-setup.md#the-workspace-repository-pattern) with its idempotent `init.sh` is a legibility investment.

**Structured output.** When tests fail, they produce structured error messages with file paths, line numbers, and clear descriptions. When builds fail, the output identifies exactly what went wrong. Agents parse structured output far more reliably than they parse ambiguous human-readable messages.

**Local observability.** Agents can run the application locally and observe its behavior - through test suites, local dev servers, log output, or browser automation. If verifying a change requires deploying to a staging environment and manually checking, the feedback loop is too slow for effective agent work.

**Consistent project structure.** Files live where agents expect them based on conventions. Source code in `src/`, tests next to or mirroring source, configuration at the root. Unusual project layouts require extra documentation to compensate.

**Explicit dependencies.** Lock files, pinned versions, and declared dependencies - not implicit system requirements or "it works if you have X installed." Agents cannot infer undocumented dependencies.

### Legibility Checklist

Use this to assess how agent-friendly your application is:

- [ ] Can the application be set up from a clean checkout with a single command?
- [ ] Do test failures include file paths and clear error descriptions?
- [ ] Is there a single command to run the full test suite?
- [ ] Are project conventions documented in CLAUDE.md or ARCHITECTURE.md?
- [ ] Does the project follow standard directory conventions for its ecosystem?
- [ ] Are all dependencies declared in lock files or manifests?
- [ ] Can changes be verified locally without deploying to a remote environment?

Low scores on this checklist indicate that harness engineering will hit diminishing returns until the underlying application is made more legible. Start there.

## AI-Effective Technology Selection

When evaluating technologies, AI agent effectiveness is now a weighted input alongside traditional criteria - team expertise, performance characteristics, ecosystem maturity, hiring availability. It is not the deciding factor, but it is a factor.

**What makes a technology AI-effective:**

- **Large training corpus.** AI has seen millions of examples in popular languages and frameworks. It produces better code in Node.js or Python than in niche languages with smaller open-source footprints.
- **Strong type systems or conventions.** Languages and frameworks with explicit types, interfaces, or enforced conventions give AI more signal to work with. Fewer ambiguous decisions means fewer mistakes.
- **Standard project structures.** Frameworks with opinionated directory layouts (Next.js, Rails, FastAPI) are more legible to agents than bespoke structures requiring extensive documentation.
- **Rich, well-documented ecosystems.** Libraries with good docs, type definitions, and widespread usage appear in training data. Internal or poorly-documented libraries require more harness compensation (CLAUDE.md rules, reference docs, custom skills).
- **Good error messages.** Languages and tools that produce clear, structured error output enable AI to self-correct. Cryptic errors break feedback loops.

**Practical considerations:**

- When choosing between Node.js and Python for a new service, both are AI-effective - but consider which your team's harness (CLAUDE.md, skills, MCP servers) is already tuned for. Switching languages means rebuilding harness context.
- Well-known frameworks (Express, FastAPI, Spring Boot) over bespoke abstractions. AI has training signal for the former. Custom frameworks require extensive documentation to compensate.
- Standard idioms over clever idioms. A technique that is technically superior but rarely seen in open-source code will produce more AI errors than the conventional approach. One practitioner chose C++ over C specifically because AI could not handle C's manual memory management idioms (arena allocation, counted strings) despite understanding them theoretically.

**Caveat:** This criterion ages. What AI struggles with today it may handle next quarter as models improve. Weight it as one input among many, and revisit when you upgrade models or switch tools. Never choose a worse technology solely because AI is currently better at it - the harness can compensate through better CLAUDE.md rules, custom skills, and reference documentation.

This topic has been discussed at the AEM Architecture Council (e.g., Node.js vs Python for new services) and is an active consideration for technology decisions across the organization.

## Relationship to Existing Guidelines

This document introduces the conceptual framework - the "why" of harness engineering. The rest of these guidelines provide the "how":

- **[Philosophy](philosophy.md)** - The principles (spec-driven development, guardrails over guidelines) that inform harness design
- **[Workspace Setup](workspace-setup.md)** - The physical structure of the harness (directory layout, configuration hierarchy, bootstrap)
- **[Development Lifecycle](../02-lifecycle/overview.md)** - The workflow the harness supports (design, plan, implement, validate, close)
- **[Multi-Session Patterns](../02-lifecycle/multi-session-patterns.md)** - Orchestrating agents across sessions: state persistence, handoff protocols, worktree isolation
- **[ACI Design](../04-configuration/aci-design.md)** - The agent-computer interface: how to design tools, search, navigation, and error messages for agent usability
- **[Configuration](../04-configuration/)** - The tools and settings that compose the harness (CLAUDE.md, AGENTS.md, hooks, MCP, permissions)
- **[Mechanical Enforcement](../05-guardrails/mechanical-enforcement.md)** - Automated gates at the point of action: hooks, structural tests, agent-friendly errors
- **[Guardrails](../05-guardrails/must-rules.md)** - The constraints the harness enforces (MUST rules, anti-patterns, task boundaries)

Harness engineering is not a separate discipline from what these guidelines already cover. It is the lens through which all of it becomes intentional rather than accidental.
