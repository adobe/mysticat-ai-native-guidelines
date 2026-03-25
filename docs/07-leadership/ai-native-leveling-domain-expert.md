# AI-Native Leveling Guide - Domain Expert

**Last reviewed**: 2026-03-24

**Level mapping:** D10 through D55 (parallel to ESDEP numbering, own ladder)

This guide defines AI-native skill expectations for domain experts at each level from D10 through D55. It complements - not replaces - the existing domain expert progression path. The progression path defines the full role expectations; this guide adds the AI-native dimension.

**Contents:**

- [How to Use This Guide](#how-to-use-this-guide)
- [Levels Overview](#levels-overview)
- [Level Vignettes](#level-vignettes)
- [AI-Native Skills Matrix](#ai-native-skills-matrix)
    - [1. AI-Native Production](#1-ai-native-production)
    - [2. Domain-to-System Translation](#2-domain-to-system-translation)
    - [3. Production Awareness](#3-production-awareness)
    - [4. Domain Leadership and Mentoring](#4-domain-leadership-and-mentoring)
    - [5. Improvement Leverage (Capacity Reinvestment)](#5-improvement-leverage-capacity-reinvestment)
- [Glossary](#glossary)
- [See Also](#see-also)

## How to Use This Guide

This guide supports three use cases:

1. **Performance evaluation.** Use the matrix alongside the domain expert progression path during review cycles. AI-native skills are one dimension of performance, not the whole picture. Evaluate whether someone demonstrates the behaviors described at their level.

2. **Self-assessment and mentoring.** Read the vignette for your current level and the one above. The vignette tells you what "good" looks like in practice. The matrix cells tell you what specific behaviors to develop. Use this with your manager or engineering buddy to identify growth areas.

3. **Hiring.** Use the matrix to calibrate interview expectations. AI-native skills compound on existing role expectations - a D30 who is strong on AI-native production but weak on domain-to-system translation is not ready for D40.

**How to read alongside the progression path:** Each level in this guide maps to the domain expert progression levels (D10-D55). The progression path defines what a domain expert does across all dimensions. This guide defines what a domain expert does specifically in the AI-native dimension. Both apply.

**AI-native skills compound.** Each level builds on the prior. The matrix cells describe what is new at each level, not the full set of expectations. A D40 is expected to demonstrate D10-D30 behaviors as well.

## Levels Overview

| Level | Name | Description |
|-------|------|-------------|
| D10 | Sandbox | Learning tools, isolated prototypes |
| D20 | Guided Contributor | First PRs with heavy engineering review |
| D30 | Independent Producer | Runs spec-driven lifecycle independently, produces reviewable PoCs |
| D40 | Autonomous Producer | PoC-to-production, owns quality gates, joins on-call |
| D50 | Domain Platform Builder | Architects harness patterns for other domain experts, mentors D10-D40 |
| D55 | Domain Strategy Leader | Shapes how domain expertise flows into product at org level |

## Level Vignettes

### D10

A D10 is an SEO specialist, product manager, or other domain expert who has started using AI tools to explore ideas. They create prototypes in sandbox environments - a quick analysis, a proof-of-concept dashboard, a draft audit rule. Their output demonstrates domain insight but isn't production-ready, and that's fine. They're learning the tools, building confidence, and discovering what's possible. They have an engineering buddy who reviews their experiments and explains what production would require.

### D20

A D20 submits their first PRs. They write specs grounded in domain expertise, follow the team's established harness patterns, and produce artifacts that pass basic quality gates. An engineer reviews their work closely and provides substantial feedback - not rewrites, but real guidance on edge cases, test coverage, and production concerns. They're learning to think like a producer, not just a domain expert. Their domain knowledge already makes the specs better than what an engineer alone would write.

### D30

A D30 runs the spec-driven lifecycle independently for domain-scoped work. They write a spec, use the team's AI harness to implement it, and produce PoCs that engineers can review without needing to rewrite. They've internalized the substrate boundary and know what's safe to own. They mentor newer domain experts on tooling and workflow, and they create reusable templates that help others get started faster.

### D40

A D40 takes a domain insight - say, a new GEO ranking signal - from observation to production-ready code. They write a spec, implement it, validate it against real-world data, and shepherd it through CI. Engineers review their PRs but rarely need changes. They've joined on-call for domain-relevant alerts and can diagnose whether a failure is in the domain logic or the platform. They serve as engineering buddy for junior domain experts and lead domain-relevant knowledge-sharing sessions.

### D50

A D50 builds the infrastructure that makes other domain experts productive. They've created harness patterns, templates, and onboarding paths that D10-D40 domain experts use daily. They design domain models that become system contracts - the scoring rubrics, audit rules, and validation frameworks that define what "correct" means. They organize the domain expert guild, shape hiring criteria, and define what progression looks like at each level. The domain expert community exists as a functioning group because of this person's work.

### D55

A D55 defines how domain expertise flows into the product at org level. They've built the frameworks that other teams adopt for integrating domain experts. They advocate for domain expert roles at leadership level and shape the talent strategy. They design domain taxonomies and ontologies that the org's systems are built on. The product is measurably better because domain expertise is architecturally encoded, not locked in someone's head. They bridge domain and engineering at the highest level, influencing product direction through deep domain authority.

## AI-Native Skills Matrix

Each category below is presented as a separate table with Level and Description columns. Cells describe observable behaviors - what someone at this level does, not what they know. Each level builds on the prior; cells focus on what is new at that level.

### 1. AI-Native Production

Using AI harnesses to go from domain insight to working artifact - prototypes, PoCs, production code. The progression from "uses AI to explore" to "uses AI to ship and scale."

| Level | Description |
|-------|-------------|
| D10 | Uses AI tools to create isolated prototypes that demonstrate domain insights. Works in sandbox environments. Output is exploratory - validates ideas, not production-ready. Learns basic AI tool usage (prompting, iteration). |
| D20 | Produces first working artifacts using the team's established harness. Follows the spec-driven lifecycle with engineering review at each stage. Understands quality gates (tests, CI) and works to meet them. Output is functional and reviewable. |
| D30 | Independently runs the spec-driven lifecycle for domain-scoped work. Produces PoCs that engineers can review without rewriting. Uses AI harnesses fluently for common domain tasks. Adapts prompts and workflows to domain-specific needs. |
| D40 | Produces PoCs that are productizable - code meets quality standards, tests exist, CI passes. Can shepherd work through the full pipeline. Understands when a PoC should become a product feature and how to propose it. Adapts harnesses to novel domain problems. |
| D50 | Architects harness patterns that enable other domain experts to be productive. Creates reusable templates and workflows for common domain-to-product paths. Shapes the tools and processes that make domain expert production scalable. |
| D55 | Defines the AI-native production model for domain experts across the org. Evaluates and integrates new AI capabilities into domain workflows. Sets the standard for what domain expert production looks like at scale. |

### 2. Domain-to-System Translation

Turning domain expertise into artifacts the system can use - specs, validation criteria, test cases, scoring rubrics, data models.

| Level | Description |
|-------|-------------|
| D10 | Articulates domain knowledge in conversations and informal docs. Can explain what "correct" looks like from a domain perspective. Provides input to specs written by engineers. |
| D20 | Writes specs that AI and engineers can act on. Defines acceptance criteria grounded in domain expertise. Creates test data from real-world scenarios. Reviews AI output for domain correctness. |
| D30 | Creates validation criteria and test cases rooted in domain expertise. Encodes domain knowledge into CLAUDE.md and reference docs that make AI more effective in the domain. Defines what "correct" means for domain-specific features. |
| D40 | Creates validation frameworks rooted in domain expertise (e.g., "this SEO audit is correct when X, Y, Z"). Defines domain models that engineers implement as system contracts. Shapes how domain concepts map to system architecture. |
| D50 | Designs domain models that become system contracts and product differentiators. Creates knowledge systems that persist beyond any individual - the domain's institutional memory is durable because of artifacts this person built. |
| D55 | Shapes product direction through encoded expertise. Defines the domain taxonomy and ontology that the org's systems are built on. The product's domain intelligence is architecturally grounded because of frameworks this person designed. |

### 3. Production Awareness

Understanding how code gets to production and stays healthy - deployment, observability, failure modes, the substrate boundary.

| Level | Description |
|-------|-------------|
| D10 | Understands that production differs from localhost. Asks before deploying. Knows who their engineering buddy is and when to escalate. Treats the substrate boundary as a hard stop. |
| D20 | Can read logs and understand CI pipeline output. Knows the deployment process for their team. Recognizes when something is a domain-level bug vs a platform issue. Escalates appropriately. |
| D30 | Navigates the deployment pipeline independently for domain-scoped changes. Can read structured logs to verify domain logic in non-production environments. Knows the substrate boundary and respects it without prompting. |
| D40 | Joins on-call rotation for domain-relevant alerts. Can diagnose domain-level failures in production. Understands the substrate boundary instinctively - knows which changes are safe to own and which need engineering review. Contributes to incident response for domain-related issues. |
| D50 | Contributes to observability design for domain-relevant metrics. Defines what "healthy" looks like from the domain perspective and ensures monitoring reflects it. Bridges the gap between domain insight and operational reality. |
| D55 | Shapes the org's approach to domain-aware observability. Defines SLIs and quality signals rooted in domain expertise. Ensures production systems reflect domain correctness, not just technical health. |

### 4. Domain Leadership and Mentoring

Scaling domain impact beyond individual production - mentoring other domain experts, building the domain expert community, contributing to hiring and progression frameworks, bridging domain and engineering cultures.

| Level | Description |
|-------|-------------|
| D10 | Shares domain knowledge informally with the team. Asks questions that help engineers understand the domain better. Participates in domain-relevant discussions. |
| D20 | Documents domain patterns and gotchas for the team. Helps new domain experts get oriented. Provides domain-specific input during planning and review. |
| D30 | Mentors D10-D20 domain experts on tooling and workflow. Creates reusable domain-specific examples and templates. Bridges communication between domain and engineering perspectives. |
| D40 | Serves as engineering buddy for junior domain experts. Contributes to domain expert progression criteria. Leads domain-relevant retrospectives and knowledge-sharing sessions. |
| D50 | Builds the domain expert community - organizes guild meetings, creates onboarding paths, defines what "good" looks like at each level. Shapes hiring criteria for domain expert roles. |
| D55 | Defines how domain expertise scales in the org. Advocates for domain expert roles at leadership level. Creates frameworks that other teams adopt for integrating domain experts. The domain expert program is stronger because of this person's leadership. |

### 5. Improvement Leverage (Capacity Reinvestment)

The deliberate direction of AI-generated capacity toward domain quality improvements - rather than absorbing it into producing more PoCs or features.

| Level | Description |
|-------|-------------|
| D10 | Uses time saved by AI to deepen domain knowledge and learn production skills, not just produce more prototypes. Invests in understanding why things work, not just what works. |
| D20 | Identifies domain-specific quality improvements that AI makes possible - better validation data, more thorough acceptance criteria, improved domain documentation. |
| D30 | Uses AI-generated capacity to invest in domain knowledge encoding - creating reusable validation frameworks, domain-specific test suites, and reference implementations that raise quality for everyone. |
| D40 | Systematically directs AI-generated efficiency toward domain quality improvements - better audit rules, more comprehensive scoring rubrics, improved domain models. Maintains a domain improvement backlog. |
| D50 | Builds domain-specific improvement patterns that other domain experts adopt. Creates tools and templates that make domain quality investment structural, not dependent on individual initiative. |
| D55 | Defines how domain expertise investment scales with AI across the org. Ensures AI-generated capacity in domain work flows toward deeper domain intelligence, not just higher output volume. |

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
| Improvement Leverage | The deliberate direction of AI-generated capacity toward improvements, quality, security, and learning - rather than absorbing it into feature velocity | [Phase 1 White Paper](ai-native-engineering-phase1.md) |
| The 5% Rule (historical) | Pre-AI baseline allocation of human capacity to proactive engineering work. In AI-native orgs, this concept evolves into Improvement Leverage. | [AI-First Leadership](ai-first-leadership.md) |
| Engineering Buddy | Assigned engineering mentor for domain experts | [Domain Experts](domain-experts.md) |
| Substrate Boundary | The line between fluid (safe for domain experts to own) and durable (requires engineering rigor) changes | [Substrate Model](../01-foundations/substrate-model.md) |

## See Also

- [For Domain Experts: Growing Into Production](domain-experts.md) - Domain expert progression path
- [Becoming an AI-Native Org - Phase 1](ai-native-engineering-phase1.md) - Maturity model, scorecard, playbooks
- [AI-Native Leveling Guide - Individual Contributor](ai-native-leveling-ic.md) - IC engineer leveling guide
- [AI-Native Leveling Guide - Engineering Manager](ai-native-leveling-manager.md) - Manager leveling guide
- [Substrate Model](../01-foundations/substrate-model.md) - Durable vs fluid layer distinction
