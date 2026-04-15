# Becoming an AI-Native Org - Phase 1: AI-Native Engineering

**Last reviewed**: 2026-03-23

This white paper explains what we mean by AI-Native engineering, the first phase in our transformation, and how we will execute it together. The goal of this document is to build clarity and alignment, not completeness.

**Contents:**

- [What Phase 1 Is and Is Not](#what-phase-1-is-and-is-not)
- [Executive Summary](#executive-summary)
- [The Framework](#the-framework-what-we-mean-by-ai-native-engineering)
- [Maturity Model](#the-framework-ai-native-engineering-maturity-model)
- [The Playbook](#the-playbook-turning-insights-into-action)
- [The Operating Model](#the-operating-model)
- [Frontier Engineers](#frontier-engineers-role-and-definition)
- [Expectations](#on-expectations)
- [Conclusion and Next Steps](#conclusion-and-next-steps)
- [Appendix](#appendix)

## What Phase 1 Is and Is Not

Phase 1 is:

- A shared understanding of where AI breaks down today
- Baseline maturity and scorecard assessments for major systems
- Explicit ownership of the most critical bottlenecks

Phase 1 is not:

- A tool rollout or a performance evaluation
- A mandate to rewrite systems
- An attempt to reach Level 4 (see the [maturity levels](#the-framework-ai-native-engineering-maturity-model) section)

Phase 1 succeeds when AI impact for generating functional code is no longer limited, and we have clarity and alignment.

## Executive Summary

Our organization is already AI-enabled. AI tools are widely used and deliver clear productivity gains. However, those gains do not compound beyond unit or module scope. Time-to-value is still dominated by deployment cycles, manual validation, and system-level debugging.

This is not a skills or adoption problem. It is a system, platform, and workflow design problem. Phase 1 focuses on making this problem visible, shared, and actionable.

There are three parts that form Phase 1: a framework (how we think), playbook (how we act), and operating model (how we're held accountable).

## The Framework: What We Mean by AI-Native Engineering

An AI-Native engineering organization is one where:

- Systems are designed so AI can reason beyond local code context (beyond module)
- Validation and debugging do not depend on production deployments
- Failures are observable and explainable end to end
- AI effectiveness increases as systems grow, instead of degrading

AI-Native is not about using more tools or writing prompts faster. It is about designing systems where AI can participate meaningfully across the development lifecycle.

### The Core Insight

AI works extremely well when:

- Context is local (AI has complete view of the system, not just the module)
- Behavior is deterministic
- Validation is fast and automated
- Feedback loops can be safely created

AI breaks down when:

- It's hard to debug its changes
- Systems are tightly coupled
- Environments differ from production
- Traceability is missing
- Validation requires deployment to production
- Feedback loops cannot be created

As systems scale, system properties - not individual skill - determine AI effectiveness.

## The Framework: AI-Native Engineering Maturity Model

See [appendix](#appendix) for detailed explanations.

The maturity model describes how effective the AI can operate in our code bases:

- **Level 0 - AI-Resistant Systems**: AI exists but is blocked by the system
- **Level 1 - AI-Assisted Units**: AI works at module/unit scope only
- **Level 2 - AI-Aware Services**: AI can reason about individual services
- **Level 3 - AI-Debuggable Systems**: AI can assist with end-to-end workflows
- **Level 4 - AI-Native Organization**: AI is a first-class participant by design

We believe that it is fair to say that most of our systems today are at Level 1, regardless of the engineers' knowledge.

## The Playbook: Turning Insights into Action

Based on the past year of deploying AI within our org, we see the following playbooks giving us the most lift to move up on the maturity levels.

### Playbook 1 - Frontier Engineers: Scale Impact

Frontier engineers are expected to:

- Surface patterns, not just ship faster
- Build shared assets and reference examples
- Help unblock systems, not bypass them

Their role is to pull the organization forward, not run ahead of it.

### Playbook 2 - New Services/Systems: AI-Native by Design

New services must be:

- Runnable and testable without production
- Observable by default
- Explicit in contracts and dependencies
- Debuggable by AI

This prevents adding new AI-hostile surface area.

### Playbook 3 - Existing Services/Systems: Remove the Dominant Bottleneck

For existing systems:

- Identify the single biggest blocker to fast validation or debugging
- Make one end-to-end workflow AI-debuggable
- Codify and reuse what works

Progress comes from focused constraint removal and not necessary from rewriting the whole system (although this could be a solution sometimes).

## The Operating Model

We will use a shared scorecard as the operating model for this phase. The purpose of the scorecard is not reporting or evaluation; it helps to:

- Make the system level constraints visible
- Guide prioritization and tradeoffs
- Create accountability without blame

There are three parts to the scorecard: dimensions we score each system on, scoring model, and scope and cadence.

### The Six Scorecard Dimensions

Each system that is currently worked on will be assessed across all six. See [appendix](#appendix) for detailed explanations.

1. **Validation Speed** - Can realistic feedback be obtained without deploying to production?
2. **Environment Fidelity** - Do non-production environments behave like production in the ways that matter?
3. **End-to-End Traceability** - Can humans and AI explain what happened across systems?
4. **System Coupling** - How predictable is system behavior from local context?
5. **Ownership & Mandate** - Is there clear ownership to remove system-level bottlenecks?
6. **Improvement Leverage** - Is AI-generated capacity being reinvested in improvements, or absorbed into more feature work?

### Scoring Model

Each dimension is scored on a simple 0-3 ordinal scale:

| Score | Label | Meaning |
|-------|-------|---------|
| 0 | Blocked | The system actively prevents progress |
| 1 | Fragile | Possible but slow, manual, or unreliable |
| 2 | Reliable | Works for common cases |
| 3 | Default | Works by default, without heroics |

### Scope and Cadence

- **Unit of assessment**: a system or major service (never a team)
- **Cadence**: monthly initially, quarterly later (we need to decide together)
- **Participants**: system owners (EM and engineers) and at least two frontier engineers

### How The Scorecard Is Used

For each system that is actively worked on and takes significant effort (each team can decide what the threshold is), we:

1. Establish a baseline (score the system)
2. Identify the main blocker/constraint
3. Assign clear ownership
4. Select one or two scorecard dimensions to actively improve on

### Concrete Example

Consider a system where:

- Unit tests are strong and AI is effective at module-level coding
- End-to-end validation requires deployment
- Failures are hard to diagnose across services

A Phase-1 scorecard might look like:

| Dimension | Score |
|-----------|-------|
| Validation Speed | 0-1 (blocked or fragile) |
| Environment Fidelity | 1 |
| End-to-End Traceability | 0 |
| System Coupling | 2 |
| Ownership & Mandate | 1 |
| Improvement Leverage | 1 |

The conclusion is: AI impact is capped at unit scope because validation and traceability are system-level bottlenecks. In Phase 1, this system would likely select Validation Speed and Traceability as its focus areas.

## Frontier Engineers: Role and Definition

Frontier engineers are the catalysts of AI-native engineering transformation. They stay at the cutting edge, operationalize AI-native practices within existing teams and codebases, and scale that knowledge across the organization. Formalizing this role accelerates adoption, de-risks the transition, and creates competitive advantage.

### Why It Matters

In early-stage AI-native organizations, frontier engineers are a small, high-leverage minority. In mature organizations (e.g., Anthropic), every engineer operates this way. The gap between these two states represents both risk and opportunity for any software company investing in engineering productivity.

### Core Responsibilities

1. **Track the state of the art** - monitor what leading AI-native organizations (Anthropic, StrongDM, OpenAI) are doing and how practices are evolving.
2. **Operationalize internally** - adapt AI-native development workflows, tooling, and architectural patterns to work within our codebase and processes.
3. **Scale knowledge across the org** - actively transfer both external best practices and internal learnings to enable every engineer.

### Two Specializations

Frontier engineers operate in two complementary modes (one person may do both):

| | Harness Engineer | AI Orchestrator |
|---|---|---|
| **Focus** | Build the environment where AI is a first-class citizen | Direct AI to produce high-quality work |
| **Scope** | CLIs, MCPs, architectural constraints, design patterns, feedback loops, linters, and code scanners that provide guardrails for AI | Writing specs as AI input, running planning mode, validating and refining plans, designing functional and non-functional tests |
| **Key Skill** | Deep software engineering - system design, operations, frontend frameworks | AI direction + deep business/customer understanding. Opens the door to non-engineers (PMs, designers, PMMs) |

## On Expectations

You might ask what the end-state and expectations are for the Sites engineering team at the end of Phase 1. We know that we succeeded if:

- The organization is able to continue the learning and the adoption to the day-to-day job of AI (this was not a one-time effort)
    - OKR: the frontier engineer guild is growing
- All new systems are Level 4 from the start (exceptions can exist, but better have a good reason)
    - OKR: 0 new systems below Level 4
- Existing systems are either moved to Level 4 or, if not possible, the blockers are clearly documented (and re-evaluated as the AI gets better)
    - OKR: for all critical existing systems not at Level 4, the critical blockers are documented

## Conclusion and Next Steps

Becoming an AI-Native engineering org is a system transformation. This paper proposes an approach for seeing the system clearly (shared understanding and aligned on what, how, and who) so we can change it deliberately (as opposed to hoping to happen organically).

As for the next steps, first we need to align on this paper. As a group let's work through questions like "what feels accurate?", "where does this resonate with my system?", "where does it feel uncomfortable and why?".

## Appendix

### AI-Native Maturity Levels

#### Level 1 - AI-Assisted Units

AI works at module scope only. Level 1 is about code quality.

Example:

- Crosswalk long-tail backlog
- 85%+ unit test coverage
- Strong mocks
- Throughput doubles

But:

- Deployment cycle still dominates time-to-value.

AI effective locally, blocked systemically.

#### Level 2 - AI-Aware Services

AI can reason about an entire service. Level 2 is about system design.

Example - a service has:

- Clear API contracts
- Production-like local environment
- Service-level integration tests
- Structured logs

AI can:

- Implement features
- Run realistic validation
- Diagnose most service-level failures

Still limited at cross-service boundaries.

#### Level 3 - AI-Debuggable Systems

AI can assist with end-to-end workflows across systems. Level 3 is about system design.

Example - AEMCS to EDS to SpaceCat request:

- Shared correlation ID
- Unified logs
- Traceable execution path
- Replayable workflows

AI can:

- Analyze full workflow
- Identify where failure occurred
- Suggest cross-system fixes

Human debugging speed dramatically increases.

#### Level 4 - AI-Native Organization

AI is designed into workflows by default. Level 4 is organizational design.

Example - every new service:

- Must support local-first validation
- Must emit structured trace events
- Must have explicit contracts
- Must be runnable in isolation

Scorecard used by default. Architectural decisions evaluated partly on "AI-debuggability." At this level: AI effectiveness increases as systems grow.

At Level 3 and Level 4, the harness is mature enough to support [director-mode operation](../01-foundations/operating-modes.md) for fluid-layer work. This does not mean humans stop reviewing - it means the nature of review shifts from line-by-line code inspection toward results verification and architectural judgment. The prerequisites (comprehensive tests, mechanical enforcement, staging gates, observability, rollback capability) are natural outputs of L3/L4 maturity investments.

### Scorecard Dimensions - Detailed

#### 1) Validation Speed

Can realistic feedback be obtained without deploying to production?

- **Good**: Mystique workflow can be executed locally with realistic data and dependencies
- **Bad**: Brand Presence improvements require full SpaceCat + Sharepoint integration and real deployment

#### 2) Environment Fidelity

Do non-production environments behave like production in the ways that matter?

- **Good**: Local cloud environment uses same auth, configs, contracts
- **Bad**: Local mocks don't reflect real EDS behavior - works locally, fails in prod

This is where "it worked on my machine" kills AI leverage.

#### 3) End-to-End Traceability

Can humans and AI explain what happened across systems?

- **Good** - AI can reason across logs:
    - Request ID flows from AEMCS to EDS to SpaceCat
    - Logs correlated
    - Structured events
- **Bad** - AI cannot debug across systems:
    - Separate log systems
    - No shared IDs
    - Manual correlation

#### 4) System Coupling

How predictable is system behavior from local context?

"Local context" means: if I look only at this service's code, tests, and documented contracts - can I predict how it will behave? If I must understand hidden behavior in 2-3 other systems to predict outcomes, then behavior is not predictable from local context.

**Low Coupling Example (Score 2-3)**

A service:

- Calls EDS via a versioned API
- Has a clear contract
- Handles errors explicitly
- Has mocks that simulate realistic EDS responses

An engineer (or AI) can read the service, run tests, and predict outcomes. Behavior is predictable locally.

**High Coupling Example (Score 0-1)**

A service:

- Relies on undocumented behavior in AEMCS
- Breaks if a downstream config flag changes
- Depends on environment-specific content structure
- Has no reliable mocks

Now: unit tests pass, production fails, root cause is outside the service. Behavior is not predictable from local context and AI collapses beyond unit scope.

#### 6) Improvement Leverage (Capacity Reinvestment)

Is AI-generated capacity being reinvested in improvements, or absorbed into more feature work?

In pre-AI orgs, proactive investment in quality, security, and learning was negotiated as the "5% Rule" - a hard-won floor of human capacity. In AI-native orgs, AI multiplies capacity. The question shifts from "can we protect 5% of human time?" to "are we structurally directing the capacity AI creates toward making our systems, quality, and people better?"

- **Good**: Team tracks AI-generated efficiency gains and has explicit mechanisms (improvement backlogs, frontier engineer time, sprint allocation) that direct freed capacity toward quality, security, learning, and system-level improvements. Investment scales with AI effectiveness.
- **Bad**: AI makes the team faster, but all gains are absorbed into shipping more features. No structural mechanism redirects capacity. The 5% floor erodes under delivery pressure, and AI amplifies the erosion.

This dimension is unique because it measures an organizational choice, not a technical property. A system can score 3 on every other dimension but 0 on Improvement Leverage if all AI-generated capacity goes to feature velocity.

## See Also

- [AI-First Leadership](ai-first-leadership.md) - What leaders get wrong, what to do instead
- [Philosophy](../01-foundations/philosophy.md) - Core AI-first principles
- [AI Readiness Checklist](../06-adoption/ai-readiness-checklist.md) - Assess repo readiness
