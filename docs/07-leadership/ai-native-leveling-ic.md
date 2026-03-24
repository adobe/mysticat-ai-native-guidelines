# AI-Native Leveling Guide - Individual Contributor

**Last reviewed**: 2026-03-24

**Job code reference:** ESDEP (P10-P55)

This guide defines AI-native skill expectations for individual contributor engineers at each level from P10 through P55. It complements - not replaces - the existing ESDEP leveling guide. The standard guide defines the full role expectations; this guide adds the AI-native dimension.

**Note on P60+:** Principal Scientists operate at a scope that transcends per-level AI-native prescriptions. P60+ are expected to define and evolve the AI-native bar itself.

**Contents:**

- [How to Use This Guide](#how-to-use-this-guide)
- [Level Vignettes](#level-vignettes)
- [AI-Native Skills Matrix](#ai-native-skills-matrix)
    - [1. Harness Engineering](#1-harness-engineering)
    - [2. AI-Directed Development](#2-ai-directed-development)
    - [3. System Design for AI Effectiveness](#3-system-design-for-ai-effectiveness)
    - [4. Knowledge Encoding and Amplification](#4-knowledge-encoding-and-amplification)
    - [5. Ownership and Judgment](#5-ownership-and-judgment)
- [Glossary](#glossary)
- [See Also](#see-also)

## How to Use This Guide

This guide supports three use cases:

1. **Performance evaluation.** Use the matrix alongside the standard ESDEP guide during review cycles. AI-native skills are one dimension of performance, not the whole picture. Evaluate whether someone demonstrates the behaviors described at their level.

2. **Self-assessment and mentoring.** Read the vignette for your current level and the one above. The vignette tells you what "good" looks like in practice. The matrix cells tell you what specific behaviors to develop. Use this with your manager or mentor to identify growth areas.

3. **Hiring.** Use the matrix to calibrate interview expectations. AI-native skills compound on existing role expectations - a P30 who is strong on AI-directed development but weak on system design fundamentals is not ready for P40.

**How to read alongside the standard guide:** Each level in this guide maps 1:1 to the ESDEP levels. The standard guide defines what a P30 does across all dimensions (technical leadership, architecture, communication, etc.). This guide defines what a P30 does specifically in the AI-native dimension. Both apply.

**AI-native skills compound.** Each level builds on the prior. The matrix cells describe what is new at each level, not the full set of expectations. A P40 is expected to demonstrate P10-P30 behaviors as well.

## Level Vignettes

### P10

A P10 works within an established AI harness. They follow the spec-driven lifecycle with guidance from seniors, use Claude Code or similar tools to write and test code at module scope, and review AI output with a checklist mindset. They're learning to write good prompts by studying how senior engineers structure their specs and CLAUDE.md files. When AI suggests something they don't understand, they ask rather than ship.

### P20

A P20 runs the spec-driven lifecycle independently for well-scoped tasks. They extend harness configurations for their projects, write specs AI can act on, and catch common AI mistakes in their own reviews. They're building intuition for when AI is the right tool and when manual work is faster. They document their decisions and failure modes so the next person (or AI) doesn't repeat them.

### P30

A P30 designs services with AI effectiveness in mind. Their APIs have explicit contracts, their logs are structured, and their tests run without production dependencies. They drive features through the full lifecycle and use multi-session patterns for larger work. They write guardrails that prevent AI mistakes and create reference implementations that accelerate the team. They review AI output from others and know the difference between a style preference and a structural defect.

### P40

A P40 owns their service's AI-native maturity. They actively improve the weakest scorecard dimension, whether that's validation speed, traceability, or environment fidelity. They mentor P20s and P30s on AI-directed development and contribute reusable harness patterns back to the team. When reviewing AI-generated code from any contributor - engineer, domain expert, or AI - they evaluate system-level impact, not just correctness. They're the person who makes the service AI-debuggable, not just AI-assisted.

### P50

A P50 operates across team boundaries to remove the system-level bottlenecks that cap AI effectiveness. They design shared infrastructure (correlation IDs, unified logging, replayable workflows) that makes entire service chains AI-debuggable. They build the skills, tools, and patterns that other teams adopt. They define how AI-directed development works at scale and mentor the next generation of frontier engineers. Their harness contributions are used by people who've never met them.

### P55

A P55 defines what AI-native means for the org. They architect systems where AI effectiveness increases as the system grows - Level 4 by design. They set the standards for harness engineering, knowledge encoding, and quality accountability that teams across the org adopt. They evolve the AI-native operating model as AI capabilities change. They balance pushing the frontier with ensuring the org doesn't outrun its ability to maintain quality and ownership.

## AI-Native Skills Matrix

Each category below is presented as a separate table with Level and Description columns. Cells describe observable behaviors - what someone at this level does, not what they know. Each level builds on the prior; cells focus on what is new at that level.

### 1. Harness Engineering

Designing and maintaining the environment that makes AI effective - CLAUDE.md, AGENTS.md, MCP configuration, guardrails, hooks, feedback loops, skills, ignore files.

| Level | Description |
|-------|-------------|
| P10 | Uses an existing harness effectively. Follows established CLAUDE.md patterns. Configures personal AI tools with guidance. |
| P20 | Extends and improves harness configuration for own projects. Adds project-specific rules, MCP servers, and ignore patterns. Identifies gaps in existing harness. |
| P30 | Designs harness configurations for new services. Writes effective guardrails (MUST/SHOULD rules). Creates feedback loops (hooks, linters) that catch AI mistakes before they ship. |
| P40 | Owns harness architecture for a service or service group. Designs cross-tool configurations (Claude Code, Cursor, Copilot). Creates reusable skills and patterns adopted by the team. |
| P50 | Defines harness engineering patterns across multiple teams. Builds shared tooling (skills, MCP servers, plugins) that raise the floor for the org. Evolves the harness as AI capabilities change. |
| P55 | Architects the harness strategy for the org. Defines standards that other teams adopt. Evaluates and integrates new AI platforms and capabilities. Sets the direction for how the org's AI environment evolves. |

### 2. AI-Directed Development

The spec-driven workflow - writing specs as AI input, planning mode, validating and refining plans, prompt craft, multi-session patterns, knowing when to delegate to AI vs do manually.

| Level | Description |
|-------|-------------|
| P10 | Follows the spec-driven lifecycle with guidance. Uses AI tools for module-level coding tasks. Learns prompt patterns by studying senior engineers' specs and plans. |
| P20 | Independently uses the spec-driven lifecycle for well-scoped tasks. Writes specs that AI can act on. Knows when a task is too ambiguous for AI and asks for clarification. |
| P30 | Drives the full lifecycle (spec, plan, implement, validate) for features of moderate complexity. Designs validation criteria before implementation. Uses multi-session patterns for larger work. |
| P40 | Orchestrates AI across complex, multi-service features. Writes specs that decompose naturally into parallelizable agent work. Validates AI plans against architectural constraints before execution. |
| P50 | Defines spec and planning patterns adopted by the team. Designs workflows where AI handles end-to-end implementation with human checkpoints at critical boundaries. Mentors others on AI-directed development. |
| P55 | Shapes how the org approaches AI-directed development. Identifies where the lifecycle breaks down and evolves it. Pushes the boundary of what can be effectively delegated to AI. |

### 3. System Design for AI Effectiveness

Designing systems where AI can reason, validate, and debug - maps to the Phase 1 scorecard dimensions (validation speed, environment fidelity, traceability, coupling). Moving systems up the maturity model.

| Level | Description |
|-------|-------------|
| P10 | Writes code that AI can understand and test at module scope. Uses clear naming, explicit types, and small functions. Writes tests that provide fast feedback. |
| P20 | Designs components with explicit contracts and boundaries. Writes integration tests that run without production dependencies. Keeps coupling low within own modules. |
| P30 | Designs services with AI debuggability in mind - structured logs, explicit error handling, clear API contracts. Contributes to environment fidelity (local dev matches production behavior). |
| P40 | Owns a service's position on the maturity model. Actively improves the weakest scorecard dimension. Designs validation pipelines that give realistic feedback without deployment. Ensures end-to-end traceability for owned services. |
| P50 | Designs systems at Level 3+ (AI-debuggable across service boundaries). Implements shared correlation IDs, unified logging, replayable workflows. Removes the dominant system-level bottleneck for AI effectiveness. |
| P55 | Architects systems that are Level 4 (AI-native) by design. AI effectiveness increases as the system grows. Defines the architectural patterns that make this possible and ensures new services adopt them. |

### 4. Knowledge Encoding and Amplification

Making tacit knowledge explicit and durable - encoding domain knowledge, architectural decisions, failure modes, and production judgment into artifacts AI and humans can consume.

| Level | Description |
|-------|-------------|
| P10 | Documents own work clearly so AI (and humans) can build on it. Writes meaningful commit messages and PR descriptions. Keeps README and inline docs current for code they touch. |
| P20 | Writes decision records for non-obvious choices. Documents failure modes and edge cases discovered during development. Contributes to team knowledge bases. |
| P30 | Encodes architectural knowledge into CLAUDE.md and AGENTS.md. Writes runbooks that AI can follow. Creates examples and reference implementations that accelerate others. |
| P40 | Designs knowledge structures that scale - not just docs, but contracts, schemas, and structured metadata that AI can reason about programmatically. Ensures knowledge survives team changes. |
| P50 | Builds knowledge systems (skills, reference architectures, pattern libraries) that make the org's AI more effective. Shares knowledge broadly via white papers, tech talks, or architectural documents. |
| P55 | Creates the knowledge architecture for the org. Defines how institutional knowledge is captured, maintained, and made accessible to AI. The org's AI is measurably better because of systems this person built. |

### 5. Ownership and Judgment

The human side - reviewing AI output critically, knowing when AI is wrong, production judgment, accountability for AI-generated code, the "invest in brakes" principle.

| Level | Description |
|-------|-------------|
| P10 | Reviews AI output with support from seniors. Knows to ask when AI suggests something they don't understand. Does not ship code they cannot explain. |
| P20 | Independently reviews AI-generated code for correctness, security, and maintainability. Catches common AI failure patterns (hallucinated APIs, incorrect error handling, missing edge cases). |
| P30 | Reviews AI output from peers and junior engineers. Distinguishes structural problems from aesthetic preferences. Applies the substrate boundary - knows which changes need extra scrutiny. |
| P40 | Sets review standards for AI-generated code in their service. Owns production quality for AI-assisted contributions from any source (engineers, domain experts, AI). Balances velocity with the quality bar. |
| P50 | Defines the accountability model for AI-assisted work across teams. Creates mechanical enforcement (automated gates, structural tests) that catch issues before review. Models the judgment others learn from. |
| P55 | Sets the quality and accountability bar for the org. Defines what "invest in brakes" means in practice. Ensures AI-native practices do not erode production judgment, security, or reliability. |

## Glossary

Key terms used in this guide, linked to their definitions in the AI-native guidelines.

| Term | Definition | Source |
|------|-----------|--------|
| Harness Engineering | The complete designed environment (instructions, tools, feedback loops, isolation) that determines AI agent effectiveness | [Harness Engineering](../01-foundations/harness-engineering.md) |
| Substrate Model | Durable (load-bearing infrastructure) vs Fluid (features/experiments) layer distinction | [Substrate Model](../01-foundations/substrate-model.md) |
| Spec-Driven Lifecycle | Design doc before code, 5-phase development cycle | [Lifecycle Overview](../02-lifecycle/overview.md) |
| Maturity Model | L0-L4 scale of how effectively AI can operate in a codebase | [Phase 1 White Paper](ai-native-engineering-phase1.md) |
| Scorecard | 5-dimension assessment (validation speed, environment fidelity, traceability, coupling, ownership) scored 0-3 | [Phase 1 White Paper](ai-native-engineering-phase1.md) |
| Frontier Engineer | Catalysts of AI-native transformation - Harness Engineer and/or AI Orchestrator specializations | [Phase 1 White Paper](ai-native-engineering-phase1.md) |
| The 5% Rule | Baseline allocation to proactive engineering work (quality, security, learning) | [AI-First Leadership](ai-first-leadership.md) |
| Engineering Buddy | Assigned engineering mentor for domain experts | [Domain Experts](domain-experts.md) |
| Substrate Boundary | The line between fluid (safe for domain experts to own) and durable (requires engineering rigor) changes | [Substrate Model](../01-foundations/substrate-model.md) |

## See Also

- [AI-First Leadership](ai-first-leadership.md) - What leaders get wrong, what to do instead
- [Becoming an AI-Native Org - Phase 1](ai-native-engineering-phase1.md) - Maturity model, scorecard, playbooks
- [Harness Engineering](../01-foundations/harness-engineering.md) - The designed environment for AI effectiveness
- [Substrate Model](../01-foundations/substrate-model.md) - Durable vs fluid layer distinction
- [AI Readiness Checklist](../06-adoption/ai-readiness-checklist.md) - Assess repo readiness for AI-first development
- [For Domain Experts: Growing Into Production](domain-experts.md) - Domain expert progression path
