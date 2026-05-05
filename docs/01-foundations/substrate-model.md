# Durable vs Fluid Substrate

## Overview

Not all code requires the same rigor. AI-first development works best when you explicitly separate your platform into two layers with different expectations.

This model is an architectural response to the [risks of AI-first development](philosophy.md#the-risks-of-ai-first-development). By containing the "move fast" energy in a well-bounded layer, you get speed without sacrificing reliability.

## The Two Layers

**Durable Substrate** - Core platform foundations
- Authentication, authorization, data storage, APIs, infrastructure
- Requires traditional engineering rigor: security reviews, performance testing, formal architecture
- Changes are infrequent but high-impact
- Failure cascades across the system
- Built by experienced engineers with full engineering discipline

**Fluid Substrate** - Features and integrations built on top
- User-facing features, experiments, integrations, workflows
- Moves fast, tolerates controlled failure
- Domain experts can ship without traditional engineering gatekeeping
- Failures are contained, not catastrophic
- Primary goal: **produce business value for customers quickly**

### Operating Modes by Layer

The substrate layer is one axis that determines how you work with AI. The [operating modes spectrum](operating-modes.md) maps the full picture - layer combined with [AI-native maturity](../07-leadership/ai-native-engineering-phase1.md) determines whether collaborator or director mode is appropriate.

In short: fluid-layer work with a strong harness can support director-mode operation - human defines intent via specs and tests, AI executes, human verifies results. Durable-layer work requires closer human collaboration regardless of maturity, because failures cascade across the system. Work that crosses the boundary (a fluid feature requiring a durable schema change) requires collaborator-mode rigor at the boundary.

## Domain Experts as Producers

The fluid layer enables a new producer role: **Domain Experts**. These are ICs with deep knowledge in non-engineering domains - SEO specialists, GEO analysts, paid traffic experts, content strategists.

With AI assistance and a solid durable substrate, domain experts can:
- Prototype and validate solutions within the fluid layer
- Validate hypotheses with real data
- Ship features that directly apply their expertise
- Iterate without waiting in engineering queues

This isn't about replacing engineers - it's about letting the right expertise drive the right work. A GEO expert building a market-specific feature knows their domain better than any engineer could. The durable substrate ensures they can't accidentally break core systems.

## Architecture Implications

Design your durable substrate to:
- Provide clear, stable APIs for the fluid layer
- Contain failures from fluid layer experiments
- Enable feature flags and gradual rollouts
- Support rollback without engineering intervention
- Make it easy to observe fluid layer behavior

The more robust your durable substrate, the more velocity your fluid layer achieves.

## Hiring Implications

AI-first development changes the engineering hiring profile. Instead of one type, you now need a spectrum:

**Domain Experts** - Deep expertise in business domains (SEO, analytics, content). With AI and a solid platform, they become producers, not just requesters. They understand customer needs better than pure engineers.

**Fluid Engineers** - Engineers comfortable with rapid iteration, AI tools, and shipping at speed. Strong product sense, good at prototyping, willing to move fast and break (contained) things.

**Durable Engineers** - Engineers focused on core platform reliability. Security-minded, performance-focused, architecturally rigorous. They build the foundation everything else depends on.

**Progression and overlap**: Durable engineers can and should participate in fluid work - it keeps them connected to customer value. Some fluid engineers mature into durable roles as they develop architectural judgment. Mentoring flows in both directions.

**The right mix matters.** Too many durable engineers and you move too slowly. Too many fluid engineers and your platform becomes unstable. No domain experts and your features miss customer reality. Actively manage this balance in hiring.

## See Also

- [Philosophy](philosophy.md) - Core AI-first principles
- [MUST Rules](../05-guardrails/must-rules.md) - Non-negotiable requirements (apply to durable substrate)
- [SHOULD Rules](../05-guardrails/should-rules.md) - Recommendations (more flexible in fluid substrate)
