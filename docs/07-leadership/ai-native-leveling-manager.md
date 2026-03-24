# AI-Native Leveling Guide - Engineering Manager

**Last reviewed**: 2026-03-24

**Job code reference:** ESDEM (M2-M6)

This guide defines AI-native skill expectations for engineering managers at each band from M2-M3 through M5-M6. It complements - not replaces - the existing ESDEM leveling guide. The standard guide defines the full role expectations; this guide adds the AI-native dimension.

**Contents:**

- [How to Use This Guide](#how-to-use-this-guide)
- [Band Vignettes](#band-vignettes)
- [AI-Native Skills Matrix](#ai-native-skills-matrix)
    - [1. AI Strategy and Maturity](#1-ai-strategy-and-maturity)
    - [2. Team Enablement and Adoption](#2-team-enablement-and-adoption)
    - [3. Operational Excellence for AI](#3-operational-excellence-for-ai)
    - [4. Domain Expert Integration](#4-domain-expert-integration)
- [Glossary](#glossary)
- [See Also](#see-also)

## How to Use This Guide

This guide supports three use cases:

1. **Performance evaluation.** Use the matrix alongside the standard ESDEM guide during review cycles. AI-native skills are one dimension of performance, not the whole picture. Evaluate whether someone demonstrates the behaviors described at their band.

2. **Self-assessment and mentoring.** Read the vignette for your current band and the one above. The vignette tells you what "good" looks like in practice. The matrix cells tell you what specific behaviors to develop. Use this with your manager or mentor to identify growth areas.

3. **Hiring.** Use the matrix to calibrate interview expectations. AI-native skills compound on existing role expectations - an M4 who is strong on team enablement but weak on operational excellence fundamentals is not ready for M5.

**How to read alongside the standard guide:** Each band in this guide maps to the ESDEM levels. The standard guide defines what an M4 does across all dimensions (people leadership, delivery, strategy, etc.). This guide defines what an M4 does specifically in the AI-native dimension. Both apply.

**AI-native skills compound.** Each band builds on the prior. The matrix cells describe what is new at each band, not the full set of expectations. An M5-M6 is expected to demonstrate M2-M4 behaviors as well.

## Band Vignettes

### M2-M3

An M2-M3 manager ensures their team is equipped and enabled for AI-native work. Every team member has a working harness, knows the spec-driven lifecycle, and has access to a frontier engineer for guidance. They participate in scorecard assessments and can explain where their systems sit on the maturity model. They create space for learning - the 5% allocation is real, not theoretical. They pair domain experts with engineering buddies and make sure AI-assisted contributions are reviewed fairly.

### M4

An M4 owns the AI-native operating rhythm across their systems. They run scorecard assessments on a regular cadence, have assigned ownership for every identified bottleneck, and track maturity trends over time. They've cultivated frontier engineers who pull teams forward and established adoption patterns that survive beyond initial enthusiasm. They balance the pressure to adopt AI faster with the discipline to maintain quality - they know the Phase 1 goal is visibility and alignment, not speed.

### M5-M6

An M5-M6 defines AI-native strategy for their org. They evolved the operating model from Phase 1's initial framework into something that fits their teams' reality. They connect maturity progress to business outcomes in ways leadership understands. They've shaped hiring to include domain experts and harness engineers as first-class roles. They ensure every new system starts at Level 4 and hold system owners accountable for documented blockers on existing systems. They grow the frontier engineer guild as the org's engine of continuous adoption.

## AI-Native Skills Matrix

Each category below is presented as a separate table with Band and Description columns. Cells describe observable behaviors - what someone at this band does, not what they know. Each band builds on the prior; cells focus on what is new at that band.

### 1. AI Strategy and Maturity

Using the Phase 1 framework - assessing systems on the maturity model, running scorecards, identifying dominant bottlenecks, prioritizing which scorecard dimensions to improve, setting targets.

| Band | Description |
|------|-------------|
| M2-M3 | Participates in scorecard assessments for own team's systems. Understands the maturity model and can explain where systems are and why. Identifies the dominant bottleneck in own team's systems and proposes a plan to address it. |
| M4 | Owns scorecard cadence across multiple systems. Drives bottleneck removal with clear ownership assignments. Reports on maturity trends and connects them to delivery outcomes. Exercises autonomy to adjust priorities based on scorecard findings. |
| M5-M6 | Defines the AI-native strategy for the org. Evolves the operating model (scorecard, cadence, participants) as the org matures. Connects maturity progress to business outcomes and uses it to inform investment decisions. Sets maturity targets and holds system owners accountable. |

### 2. Team Enablement and Adoption

Building AI-native capability in the team - onboarding, mentoring, frontier engineer cultivation, managing mutual mentorship (seniors teach judgment, juniors teach AI fluency), the 5% allocation.

| Band | Description |
|------|-------------|
| M2-M3 | Ensures every team member has a working AI harness and knows how to use it. Pairs frontier engineers with those ramping up. Allocates the 5% for proactive quality and learning. Creates psychological safety for domain experts and juniors shipping code. |
| M4 | Cultivates frontier engineers across managed teams. Establishes adoption patterns that work (not just tool rollout, but workflow change). Measures adoption meaningfully (not tool usage, but system-level impact). Manages the mutual mentorship dynamic between senior and junior engineers. |
| M5-M6 | Grows the frontier engineer guild as an org-level asset. Shapes the talent strategy for new role types (domain experts, harness engineers, AI orchestrators). Defines what AI-native looks like in hiring rubrics. Ensures adoption is sustainable, not a one-time push. |

### 3. Operational Excellence for AI

The operational side of the scorecard - validation speed, environment fidelity, deployment practices. Ensuring the team's systems support AI effectiveness.

| Band | Description |
|------|-------------|
| M2-M3 | Ensures team's systems have fast validation loops and production-like non-prod environments. Advocates for investment in environment fidelity. Tracks and reduces time-to-feedback for the development cycle. |
| M4 | Owns end-to-end validation and traceability across managed systems. Drives investment in non-production environments that behave like production. Establishes operational standards that make systems AI-debuggable. |
| M5-M6 | Sets org-wide standards for validation speed, traceability, and environment fidelity. Connects operational investment to AI leverage (quantifies the ROI). Ensures new systems meet Level 4 operational requirements from day one. |

### 4. Domain Expert Integration

Creating the conditions for domain experts to be productive - engineering buddy assignments, review practices, progression path support, bridging the substrate boundary.

| Band | Description |
|------|-------------|
| M2-M3 | Assigns engineering buddies for domain experts. Reviews domain expert PRs with appropriate expectations (not engineer-level code style, but correctness and safety). Creates sandbox environments where domain experts can experiment safely. |
| M4 | Establishes domain expert progression paths across teams. Calibrates review standards that are rigorous without being gatekeeping. Ensures harnesses and CI pipelines support non-engineer contributors. |
| M5-M6 | Defines the domain expert operating model for the org. Creates career paths and growth frameworks (D1-D4). Advocates for domain expert roles in headcount planning. Ensures domain expertise flows into product, not just into reports. |

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
- [AI-Native Leveling - Individual Contributor](ai-native-leveling-ic.md) - IC engineer leveling guide
- [AI-Native Leveling - Domain Expert](ai-native-leveling-domain-expert.md) - Domain expert leveling guide
- [AI Readiness Checklist](../06-adoption/ai-readiness-checklist.md) - Assess repo readiness for AI-first development
