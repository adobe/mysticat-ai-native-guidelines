# AI-Native Leveling Guide - Domain Expert

**Last reviewed**: 2026-03-24

**Level mapping:** D1 through D4

This guide defines AI-native skill expectations for domain experts at each level from D1 through D4. It complements - not replaces - the existing domain expert progression path. The progression path defines the full role expectations; this guide adds the AI-native dimension.

**Contents:**

- [How to Use This Guide](#how-to-use-this-guide)
- [Levels Overview](#levels-overview)
- [Level Vignettes](#level-vignettes)
- [AI-Native Skills Matrix](#ai-native-skills-matrix)
    - [1. AI-Assisted Production](#1-ai-assisted-production)
    - [2. Domain-to-System Translation](#2-domain-to-system-translation)
    - [3. Production Awareness](#3-production-awareness)
- [Glossary](#glossary)
- [See Also](#see-also)

## How to Use This Guide

This guide supports three use cases:

1. **Performance evaluation.** Use the matrix alongside the domain expert progression path during review cycles. AI-native skills are one dimension of performance, not the whole picture. Evaluate whether someone demonstrates the behaviors described at their level.

2. **Self-assessment and mentoring.** Read the vignette for your current level and the one above. The vignette tells you what "good" looks like in practice. The matrix cells tell you what specific behaviors to develop. Use this with your manager or engineering buddy to identify growth areas.

3. **Hiring.** Use the matrix to calibrate interview expectations. AI-native skills compound on existing role expectations - a D3 who is strong on AI-assisted production but weak on domain-to-system translation is not ready for D4.

**How to read alongside the progression path:** Each level in this guide maps to the domain expert progression levels (D1-D4). The progression path defines what a domain expert does across all dimensions. This guide defines what a domain expert does specifically in the AI-native dimension. Both apply.

**AI-native skills compound.** Each level builds on the prior. The matrix cells describe what is new at each level, not the full set of expectations. A D3 is expected to demonstrate D1-D2 behaviors as well.

## Levels Overview

| Level | Name | Description |
|-------|------|-------------|
| D1 | Sandbox | Isolated prototypes, learning the tools |
| D2 | Guided Producer | Fluid layer with engineering review |
| D3 | Autonomous Producer | Fluid layer with ownership, PoC-to-production |
| D4 | Platform-Aware Leader | Durable-aware, shapes how domain expertise flows into product |

## Level Vignettes

### D1

A D1 is an SEO specialist, product manager, or other domain expert who has started using AI tools to explore ideas. They create prototypes in sandbox environments - a quick analysis, a proof-of-concept dashboard, a draft audit rule. Their output demonstrates domain insight but isn't production-ready, and that's fine. They're learning the tools, building confidence, and discovering what's possible. They have an engineering buddy who reviews their experiments and explains what production would require.

### D2

A D2 produces working PoCs that engineers can review and build on. They write specs grounded in domain expertise, follow the team's established harness patterns, and submit PRs that pass CI. An engineer reviews their work and provides feedback - not rewrites. They're learning to think about edge cases, test coverage, and what happens when their domain logic meets real-world data at scale. Their domain expertise makes the specs better than what an engineer alone would write.

### D3

A D3 takes a domain insight - say, a new GEO ranking signal - from observation to working PoC independently. They write a spec, use the team's AI harness to implement it, validate it against real-world data, and shepherd it through CI. Engineers review their PRs but rarely need to rewrite them. They've joined on-call for domain-relevant alerts and can diagnose whether a failure is in the domain logic or the platform. They're starting to see patterns across their PoCs that could become product features.

### D4

A D4 shapes how domain expertise flows into the product. They've built harness patterns and templates that other domain experts use to go from insight to PoC. They design domain models that become system contracts - the scoring rubrics, audit rules, and validation frameworks that define what "correct" means. They bridge domain and engineering fluently, mentoring D1-D3 domain experts while contributing to architectural decisions that affect the domain. The product is measurably better because domain expertise is encoded into it, not locked in someone's head.

## AI-Native Skills Matrix

Each category below is presented as a separate table with Level and Description columns. Cells describe observable behaviors - what someone at this level does, not what they know. Each level builds on the prior; cells focus on what is new at that level.

### 1. AI-Assisted Production

Using AI harnesses to go from domain insight to working artifact - prototypes, PoCs, production code. The progression from "uses AI to explore" to "uses AI to ship."

| Level | Description |
|-------|-------------|
| D1 | Uses AI tools to create isolated prototypes that demonstrate domain insights. Works in sandbox environments. Output is exploratory - validates ideas, not production-ready. Learns basic AI tool usage (prompting, iteration). |
| D2 | Produces working PoCs using the team's established harness. Follows the spec-driven lifecycle with engineering review at each stage. Understands quality gates (tests, CI) and works to meet them. Output is functional and reviewable. |
| D3 | Independently produces PoCs that are productizable - code meets quality standards, tests exist, CI passes. Can shepherd work through the full pipeline. Understands when a PoC should become a product feature and how to propose it. Uses AI harnesses fluently, adapts them to domain-specific needs. |
| D4 | Architects harness patterns that enable other domain experts to be productive. Creates reusable templates and workflows for common domain-to-product paths. Mentors D1-D3 domain experts. Shapes the tools and processes that make domain expert production scalable. |

### 2. Domain-to-System Translation

Turning domain expertise into artifacts the system can use - specs, validation criteria, test cases, scoring rubrics, data models.

| Level | Description |
|-------|-------------|
| D1 | Articulates domain knowledge in conversations and informal docs. Can explain what "correct" looks like from a domain perspective. Provides input to specs written by engineers. |
| D2 | Writes specs that AI and engineers can act on. Defines acceptance criteria grounded in domain expertise. Creates test data from real-world scenarios. Reviews AI output for domain correctness. |
| D3 | Creates validation frameworks rooted in domain expertise (e.g., "this SEO audit is correct when X, Y, Z"). Defines domain models that engineers implement as system contracts. Encodes domain knowledge into CLAUDE.md and reference docs that make AI more effective in the domain. |
| D4 | Designs domain models that become system contracts and product differentiators. Shapes product direction through encoded expertise. Creates knowledge systems that persist beyond any individual - the domain's institutional memory is durable because of artifacts this person built. |

### 3. Production Awareness

Understanding how code gets to production and stays healthy - deployment, observability, failure modes, the substrate boundary.

| Level | Description |
|-------|-------------|
| D1 | Understands that production differs from localhost. Asks before deploying. Knows who their engineering buddy is and when to escalate. Treats the substrate boundary as a hard stop. |
| D2 | Can read logs and understand CI pipeline output. Knows the deployment process for their team. Recognizes when something is a domain-level bug vs a platform issue. Escalates appropriately. |
| D3 | Joins on-call rotation for domain-relevant alerts. Can diagnose domain-level failures in production. Understands the substrate boundary instinctively - knows which changes are safe to own and which need engineering review. Contributes to incident response for domain-related issues. |
| D4 | Contributes to observability design for domain-relevant metrics. Defines what "healthy" looks like from the domain perspective and ensures monitoring reflects it. Mentors other domain experts on production judgment. Bridges the gap between domain insight and operational reality. |

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

- [For Domain Experts: Growing Into Production](domain-experts.md) - Domain expert progression path
- [Becoming an AI-Native Org - Phase 1](ai-native-engineering-phase1.md) - Maturity model, scorecard, playbooks
- [AI-Native Leveling Guide - Individual Contributor](ai-native-leveling-ic.md) - IC engineer leveling guide
- [AI-Native Leveling Guide - Engineering Manager](ai-native-leveling-manager.md) - Manager leveling guide
- [Substrate Model](../01-foundations/substrate-model.md) - Durable vs fluid layer distinction
