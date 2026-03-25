# Design: AI-Native Job Leveling Guides

**Date:** 2026-03-24
**Status:** Draft
**Author:** DJ
**Location:** `mysticat-ai-native-guidelines/docs/07-leadership/`

## Problem Statement

Our organization has Adobe job leveling guides that define the expected skills and behaviors for each role and level across categories like Technical Leadership, Design & Architecture, and Programming/Code. However, these guides predate AI-native engineering and do not address the skills required to work effectively with AI across the development lifecycle.

The Phase 1 white paper ("Becoming an AI-Native Org") establishes a maturity model, scorecard, and playbooks - but does not define what "good" looks like at each job level. Engineers, managers, and domain experts need a concrete, level-appropriate bar for AI-native skills - commensurate with the existing leveling guides - to support performance evaluation, self-assessment/mentoring, and hiring.

## Goals

1. Define AI-native skill expectations per job level for three role families: IC engineers, engineering managers, and domain experts
2. Use a format that is immediately recognizable alongside existing Adobe leveling guides (matrix table with levels as columns, categories as rows)
3. Enhance the matrix with prose vignettes per level that describe what someone at that level looks like in practice
4. Ground all categories and cell content in the Phase 1 white paper and the AI-native guidelines (not invented from scratch)
5. Describe observable behaviors, not abstract knowledge

## Non-Goals

- Replacing or modifying the existing Adobe leveling guides (ESDEP, ESDEM)
- Defining a new career ladder or compensation framework
- Covering AI/ML technical skills (model training, fine-tuning, etc.) - this is about AI-native engineering practices
- Reaching completeness - Phase 1 focuses on clarity and alignment

## Audience & Rollout

- **First readers:** Engineering leadership (directors, VPs) and frontier engineers - to validate and calibrate
- **Then:** Published org-wide in the AI-native guidelines repo for self-service
- **Use cases:** Performance evaluation, self-assessment and mentoring, hiring bar

## Inputs

| Input | What it contributes |
|-------|-------------------|
| Phase 1 white paper | Maturity model (L0-L4), scorecard (5 dimensions), playbooks, frontier engineer roles |
| AI-native guidelines (full repo) | Harness engineering, substrate model, spec-driven lifecycle, domain expert progression, guardrails, philosophy |
| ESDEP leveling guide (P10-P60) | IC level structure, category format, progressive skill descriptions |
| ESDEM leveling guide (M2-M6) | Manager level structure, category format, scope progression |

## Output: Three Documents

### Document 1: AI-Native Leveling - Individual Contributor (ESDEP)

**File:** `docs/07-leadership/ai-native-leveling-ic.md`
**Level mapping:** 1:1 with Adobe IC levels (P10, P20, P30, P40, P50, P55)
**Note on P60+:** Reference note only - Principal Scientists operate at a scope that transcends per-level AI-native prescriptions. The guide notes that P60+ are expected to define and evolve the AI-native bar itself.

#### Document Structure

1. **Header** - title, revision date, reference to ESDEP job code, relationship statement ("this guide complements, not replaces, the existing ESDEP leveling guide")
2. **How to Use This Guide** - three use cases (performance, self-assessment/mentoring, hiring), how to read alongside the standard guide, note that AI-native skills compound on existing role expectations
3. **Level Vignettes** - one prose paragraph per level (P10 through P55), ~3-5 sentences, describing what this person looks like in practice
4. **Matrix Table** - 6 columns (P10-P55), 5 category rows, each cell 2-4 bullet points of observable behaviors
5. **Glossary** - links to key concepts in the existing guidelines repo

#### IC Categories

**1. Harness Engineering**

Designing and maintaining the environment that makes AI effective - CLAUDE.md, AGENTS.md, MCP configuration, guardrails, hooks, feedback loops, skills, ignore files.

| Level | Description |
|-------|-------------|
| P10 | Uses an existing harness effectively. Follows established CLAUDE.md patterns. Configures personal AI tools with guidance. |
| P20 | Extends and improves harness configuration for own projects. Adds project-specific rules, MCP servers, and ignore patterns. Identifies gaps in existing harness. |
| P30 | Designs harness configurations for new services. Writes effective guardrails (MUST/SHOULD rules). Creates feedback loops (hooks, linters) that catch AI mistakes before they ship. |
| P40 | Owns harness architecture for a service or service group. Designs cross-tool configurations (Claude Code, Cursor, Copilot). Creates reusable skills and patterns adopted by the team. |
| P50 | Defines harness engineering patterns across multiple teams. Builds shared tooling (skills, MCP servers, plugins) that raise the floor for the org. Evolves the harness as AI capabilities change. |
| P55 | Architects the harness strategy for the org. Defines standards that other teams adopt. Evaluates and integrates new AI platforms and capabilities. Sets the direction for how the org's AI environment evolves. |

**2. AI-Directed Development**

The spec-driven workflow - writing specs as AI input, planning mode, validating/refining plans, prompt craft, multi-session patterns, knowing when to delegate to AI vs do manually.

| Level | Description |
|-------|-------------|
| P10 | Follows the spec-driven lifecycle with guidance. Uses AI tools for module-level coding tasks. Learns prompt patterns by studying senior engineers' specs and plans. |
| P20 | Independently uses the spec-driven lifecycle for well-scoped tasks. Writes specs that AI can act on. Knows when a task is too ambiguous for AI and asks for clarification. |
| P30 | Drives the full lifecycle (spec, plan, implement, validate) for features of moderate complexity. Designs validation criteria before implementation. Uses multi-session patterns for larger work. |
| P40 | Orchestrates AI across complex, multi-service features. Writes specs that decompose naturally into parallelizable agent work. Validates AI plans against architectural constraints before execution. |
| P50 | Defines spec and planning patterns adopted by the team. Designs workflows where AI handles end-to-end implementation with human checkpoints at critical boundaries. Mentors others on AI-directed development. |
| P55 | Shapes how the org approaches AI-directed development. Identifies where the lifecycle breaks down and evolves it. Pushes the boundary of what can be effectively delegated to AI. |

**3. System Design for AI Effectiveness**

Designing systems where AI can reason, validate, and debug - maps to the Phase 1 scorecard dimensions (validation speed, environment fidelity, traceability, coupling). Moving systems up the maturity model.

| Level | Description |
|-------|-------------|
| P10 | Writes code that AI can understand and test at module scope. Uses clear naming, explicit types, and small functions. Writes tests that provide fast feedback. |
| P20 | Designs components with explicit contracts and boundaries. Writes integration tests that run without production dependencies. Keeps coupling low within own modules. |
| P30 | Designs services with AI debuggability in mind - structured logs, explicit error handling, clear API contracts. Contributes to environment fidelity (local dev matches production behavior). |
| P40 | Owns a service's position on the maturity model. Actively improves the weakest scorecard dimension. Designs validation pipelines that give realistic feedback without deployment. Ensures end-to-end traceability for owned services. |
| P50 | Designs systems at Level 3+ (AI-debuggable across service boundaries). Implements shared correlation IDs, unified logging, replayable workflows. Removes the dominant system-level bottleneck for AI effectiveness. |
| P55 | Architects systems that are Level 4 (AI-native) by design. AI effectiveness increases as the system grows. Defines the architectural patterns that make this possible and ensures new services adopt them. |

**4. Knowledge Encoding & Amplification**

Making tacit knowledge explicit and durable - encoding domain knowledge, architectural decisions, failure modes, and production judgment into artifacts AI and humans can consume.

| Level | Description |
|-------|-------------|
| P10 | Documents own work clearly so AI (and humans) can build on it. Writes meaningful commit messages and PR descriptions. Keeps README and inline docs current for code they touch. |
| P20 | Writes decision records for non-obvious choices. Documents failure modes and edge cases discovered during development. Contributes to team knowledge bases. |
| P30 | Encodes architectural knowledge into CLAUDE.md and AGENTS.md. Writes runbooks that AI can follow. Creates examples and reference implementations that accelerate others. |
| P40 | Designs knowledge structures that scale - not just docs, but contracts, schemas, and structured metadata that AI can reason about programmatically. Ensures knowledge survives team changes. |
| P50 | Builds knowledge systems (skills, reference architectures, pattern libraries) that make the org's AI more effective. Shares knowledge broadly via white papers, tech talks, or architectural documents. |
| P55 | Creates the knowledge architecture for the org. Defines how institutional knowledge is captured, maintained, and made accessible to AI. The org's AI is measurably better because of systems this person built. |

**5. Ownership & Judgment**

The human side - reviewing AI output critically, knowing when AI is wrong, production judgment, accountability for AI-generated code, the "invest in brakes" principle.

| Level | Description |
|-------|-------------|
| P10 | Reviews AI output with support from seniors. Knows to ask when AI suggests something they don't understand. Does not ship code they cannot explain. |
| P20 | Independently reviews AI-generated code for correctness, security, and maintainability. Catches common AI failure patterns (hallucinated APIs, incorrect error handling, missing edge cases). |
| P30 | Reviews AI output from peers and junior engineers. Distinguishes structural problems from aesthetic preferences. Applies the substrate boundary - knows which changes need extra scrutiny. |
| P40 | Sets review standards for AI-generated code in their service. Owns production quality for AI-assisted contributions from any source (engineers, domain experts, AI). Balances velocity with the quality bar. |
| P50 | Defines the accountability model for AI-assisted work across teams. Creates mechanical enforcement (automated gates, structural tests) that catch issues before review. Models the judgment others learn from. |
| P55 | Sets the quality and accountability bar for the org. Defines what "invest in brakes" means in practice. Ensures AI-native practices do not erode production judgment, security, or reliability. |

**6. Improvement Leverage (Capacity Reinvestment)**

The deliberate direction of AI-generated capacity toward improvements, quality, security, and learning - rather than absorbing it into feature velocity. Evolves the pre-AI "5% Rule" into a scalable framework.

| Level | Description |
|-------|-------------|
| P10 | Uses time saved by AI to learn deeper skills (debugging, architecture, production systems) rather than just shipping more features. Tracks what AI handles well and invests freed time in areas AI can't. |
| P20 | Identifies recurring manual work that AI could automate and proposes improvements. Uses AI-generated capacity to improve test coverage, documentation, and code quality in areas they touch. |
| P30 | Systematically uses AI to create capacity for system-level improvements - better validation pipelines, structured logging, environment fidelity. Maintains an improvement backlog alongside the feature backlog. |
| P40 | Designs workflows where AI-generated efficiency gains are visibly redirected to improvements. Quantifies the capacity AI creates and advocates for reinvesting it. Models this behavior for the team. |
| P50 | Builds tools and patterns that make improvement leverage structural - not dependent on individual discipline. Creates automated quality improvements that scale with AI usage across teams. |
| P55 | Defines the org's approach to improvement leverage. Designs systems where increased AI effectiveness automatically generates increased investment in quality, security, and learning. The org gets better as it gets faster. |

#### Sample Level Vignettes (IC)

**P10:**
A P10 works within an established AI harness. They follow the spec-driven lifecycle with guidance from seniors, use Claude Code or similar tools to write and test code at module scope, and review AI output with a checklist mindset. They're learning to write good prompts by studying how senior engineers structure their specs and CLAUDE.md files. When AI suggests something they don't understand, they ask rather than ship.

**P20:**
A P20 runs the spec-driven lifecycle independently for well-scoped tasks. They extend harness configurations for their projects, write specs AI can act on, and catch common AI mistakes in their own reviews. They're building intuition for when AI is the right tool and when manual work is faster. They document their decisions and failure modes so the next person (or AI) doesn't repeat them.

**P30:**
A P30 designs services with AI effectiveness in mind. Their APIs have explicit contracts, their logs are structured, and their tests run without production dependencies. They drive features through the full lifecycle and use multi-session patterns for larger work. They write guardrails that prevent AI mistakes and create reference implementations that accelerate the team. They review AI output from others and know the difference between a style preference and a structural defect.

**P40:**
A P40 owns their service's AI-native maturity. They actively improve the weakest scorecard dimension, whether that's validation speed, traceability, or environment fidelity. They mentor P20s and P30s on AI-directed development and contribute reusable harness patterns back to the team. When reviewing AI-generated code from any contributor - engineer, domain expert, or AI - they evaluate system-level impact, not just correctness. They're the person who makes the service AI-debuggable, not just AI-assisted.

**P50:**
A P50 operates across team boundaries to remove the system-level bottlenecks that cap AI effectiveness. They design shared infrastructure (correlation IDs, unified logging, replayable workflows) that makes entire service chains AI-debuggable. They build the skills, tools, and patterns that other teams adopt. They define how AI-directed development works at scale and mentor the next generation of frontier engineers. Their harness contributions are used by people who've never met them.

**P55:**
A P55 defines what AI-native means for the org. They architect systems where AI effectiveness increases as the system grows - Level 4 by design. They set the standards for harness engineering, knowledge encoding, and quality accountability that teams across the org adopt. They evolve the AI-native operating model as AI capabilities change. They balance pushing the frontier with ensuring the org doesn't outrun its ability to maintain quality and ownership.

---

### Document 2: AI-Native Leveling - Engineering Manager (ESDEM)

**File:** `docs/07-leadership/ai-native-leveling-manager.md`
**Level mapping:** Banded - M2-M3, M4, M5, M6

#### Document Structure

Same as IC: header, how-to-use, vignettes (one per band), matrix table (4 columns, 4 rows), glossary.

#### Manager Categories

**1. AI Strategy & Maturity**

Using the Phase 1 framework - assessing systems on the maturity model, running scorecards, identifying dominant bottlenecks, prioritizing which scorecard dimensions to improve, setting targets.

| Band | Description |
|------|-------------|
| M2-M3 | Participates in scorecard assessments for own team's systems. Understands the maturity model and can explain where systems are and why. Identifies the dominant bottleneck in own team's systems and proposes a plan to address it. |
| M4 | Owns scorecard cadence across multiple systems. Drives bottleneck removal with clear ownership assignments. Reports on maturity trends and connects them to delivery outcomes. Exercises autonomy to adjust priorities based on scorecard findings. |
| M5 | Defines the AI-native strategy for the org. Evolves the operating model (scorecard, cadence, participants) as the org matures. Connects maturity progress to business outcomes and uses it to inform investment decisions. Sets maturity targets and holds system owners accountable. |
| M6 | Shapes AI-native strategy across OneAEM or CXO level. Influences peer organizations' adoption of maturity models and scorecards. Connects AI-native maturity to enterprise-level business outcomes. Represents the org's AI-native transformation to senior leadership and cross-functional partners. |

**2. Team Enablement & Adoption**

Building AI-native capability in the team - onboarding, mentoring, frontier engineer cultivation, managing mutual mentorship (seniors teach judgment, juniors teach AI fluency). AI is an accelerator - the proactive allocation (5% floor) should rise as AI frees up capacity.

| Band | Description |
|------|-------------|
| M2-M3 | Ensures every team member has a working AI harness and knows how to use it. Pairs frontier engineers with those ramping up. Protects the 5% floor for proactive quality and learning, and uses AI efficiency gains to expand it. Creates psychological safety for domain experts and juniors shipping code. |
| M4 | Cultivates frontier engineers across managed teams. Establishes adoption patterns that work (not just tool rollout, but workflow change). Measures adoption meaningfully (not tool usage, but system-level impact). Manages the mutual mentorship dynamic between senior and junior engineers. Quantifies time reclaimed through AI and reinvests it in improvements. |
| M5 | Grows the frontier engineer guild as an org-level asset. Shapes the talent strategy for new role types (domain experts, harness engineers, AI orchestrators). Defines what AI-native looks like in hiring rubrics. Ensures adoption is sustainable, not a one-time push. |
| M6 | Drives AI-native talent strategy across OneAEM or CXO. Champions frontier engineer programs that span organizational boundaries. Influences industry hiring standards for AI-native roles. Builds partnerships with external organizations (Anthropic, OpenAI) to stay at the cutting edge of enablement. |

**3. Operational Excellence for AI**

The operational side of the scorecard - validation speed, environment fidelity, deployment practices. Ensuring the team's systems support AI effectiveness.

| Band | Description |
|------|-------------|
| M2-M3 | Ensures team's systems have fast validation loops and production-like non-prod environments. Advocates for investment in environment fidelity. Tracks and reduces time-to-feedback for the development cycle. |
| M4 | Owns end-to-end validation and traceability across managed systems. Drives investment in non-production environments that behave like production. Establishes operational standards that make systems AI-debuggable. |
| M5 | Sets org-wide standards for validation speed, traceability, and environment fidelity. Connects operational investment to AI leverage (quantifies the ROI). Ensures new systems meet Level 4 operational requirements from day one. |
| M6 | Drives operational excellence standards across OneAEM or CXO. Influences platform teams and shared infrastructure to support AI-native development patterns. Champions cross-org investment in shared validation and traceability infrastructure. |

**4. Domain Expert Integration**

Creating the conditions for domain experts to be productive - engineering buddy assignments, review practices, progression path support, bridging the substrate boundary.

| Band | Description |
|------|-------------|
| M2-M3 | Assigns engineering buddies for domain experts. Reviews domain expert PRs with appropriate expectations (not engineer-level code style, but correctness and safety). Creates sandbox environments where domain experts can experiment safely. |
| M4 | Establishes domain expert progression paths across teams. Calibrates review standards that are rigorous without being gatekeeping. Ensures harnesses and CI pipelines support non-engineer contributors. |
| M5 | Defines the domain expert operating model for the org. Creates career paths and growth frameworks (D10-D55). Advocates for domain expert roles in headcount planning. Ensures domain expertise flows into product, not just into reports. |
| M6 | Champions the domain expert model across OneAEM or CXO. Influences how other organizations integrate non-engineer contributors. Advocates for domain expert career paths at the enterprise level. Shapes how domain expertise is valued in cross-org planning and strategy. |

**5. Improvement Leverage (Capacity Reinvestment)**

The deliberate direction of AI-generated capacity toward improvements, quality, security, and learning. Ensures freed capacity is structurally invested, not absorbed into feature velocity.

| Band | Description |
|------|-------------|
| M2-M3 | Tracks where AI-generated capacity goes on the team. Ensures freed time is visibly allocated to improvements, not silently absorbed into more feature work. Makes improvement investment a standing agenda item. |
| M4 | Establishes structural mechanisms (improvement sprints, dedicated backlog, frontier engineer allocation) that direct AI-generated capacity toward improvements across managed teams. Reports on improvement investment as a metric. |
| M5 | Defines org-level policies for improvement leverage. Sets expectations that AI efficiency gains are reinvested, not just harvested for velocity. Connects improvement investment to system maturity and team capability growth. |
| M6 | Champions improvement leverage across OneAEM or CXO. Influences enterprise-level expectations that AI adoption includes investment in quality and capability, not just speed. Shapes how the broader org measures the return on AI-native practices. |

#### Sample Level Vignettes (Manager)

**M2-M3:**
An M2-M3 manager ensures their team is equipped and enabled for AI-native work. Every team member has a working harness, knows the spec-driven lifecycle, and has access to a frontier engineer for guidance. They participate in scorecard assessments and can explain where their systems sit on the maturity model. They protect the 5% floor for proactive work and actively look for ways AI can help the team invest more in quality, security, and learning. They pair domain experts with engineering buddies and make sure AI-assisted contributions are reviewed fairly.

**M4:**
An M4 owns the AI-native operating rhythm across their systems. They run scorecard assessments on a regular cadence, have assigned ownership for every identified bottleneck, and track maturity trends over time. They've cultivated frontier engineers who pull teams forward and established adoption patterns that survive beyond initial enthusiasm. They quantify time reclaimed through AI and reinvest it in improvements rather than just shipping faster. They balance the pressure to adopt AI faster with the discipline to maintain quality.

**M5:**
An M5 defines AI-native strategy for their org. They evolved the operating model from Phase 1's initial framework into something that fits their teams' reality. They connect maturity progress to business outcomes in ways leadership understands. They've shaped hiring to include domain experts and harness engineers as first-class roles. They ensure every new system starts at Level 4 and hold system owners accountable for documented blockers on existing systems. They grow the frontier engineer guild as the org's engine of continuous adoption.

**M6:**
An M6 drives AI-native transformation beyond their org. They influence peer organizations across OneAEM or CXO to adopt maturity models, scorecards, and frontier engineer programs. They represent the org's AI-native journey to senior leadership and shape enterprise-level investment decisions. They champion domain expert integration and operational excellence standards that span organizational boundaries. They build external partnerships that keep the org at the cutting edge of AI-native practices.

---

### Document 3: AI-Native Leveling - Domain Expert

**File:** `docs/07-leadership/ai-native-leveling-domain-expert.md`
**Level mapping:** D10 through D55 (parallel to ESDEP numbering, own ladder)

| Level | Name | Description |
|-------|------|-------------|
| D10 | Sandbox | Learning tools, isolated prototypes |
| D20 | Guided Contributor | First PRs with heavy engineering review |
| D30 | Independent Producer | Runs spec-driven lifecycle independently, produces reviewable PoCs |
| D40 | Autonomous Producer | PoC-to-production, owns quality gates, joins on-call |
| D50 | Domain Platform Builder | Architects harness patterns for other domain experts, mentors D10-D40 |
| D55 | Domain Strategy Leader | Shapes how domain expertise flows into product at org level |

#### Document Structure

Same as IC: header, how-to-use, levels overview table, vignettes (one per level), matrix table (6 columns, 4 rows), glossary.

#### Domain Expert Categories

**1. AI-Native Production** (renamed from AI-Assisted Production)

Using AI harnesses to go from domain insight to working artifact - prototypes, PoCs, production code. The progression from "uses AI to explore" to "uses AI to ship and scale."

| Level | Description |
|-------|-------------|
| D10 | Uses AI tools to create isolated prototypes that demonstrate domain insights. Works in sandbox environments. Output is exploratory - validates ideas, not production-ready. Learns basic AI tool usage (prompting, iteration). |
| D20 | Produces first working artifacts using the team's established harness. Follows the spec-driven lifecycle with engineering review at each stage. Understands quality gates (tests, CI) and works to meet them. Output is functional and reviewable. |
| D30 | Independently runs the spec-driven lifecycle for domain-scoped work. Produces PoCs that engineers can review without rewriting. Uses AI harnesses fluently for common domain tasks. Adapts prompts and workflows to domain-specific needs. |
| D40 | Produces PoCs that are productizable - code meets quality standards, tests exist, CI passes. Can shepherd work through the full pipeline. Understands when a PoC should become a product feature and how to propose it. Adapts harnesses to novel domain problems. |
| D50 | Architects harness patterns that enable other domain experts to be productive. Creates reusable templates and workflows for common domain-to-product paths. Shapes the tools and processes that make domain expert production scalable. |
| D55 | Defines the AI-native production model for domain experts across the org. Evaluates and integrates new AI capabilities into domain workflows. Sets the standard for what domain expert production looks like at scale. |

**2. Domain-to-System Translation**

Turning domain expertise into artifacts the system can use - specs, validation criteria, test cases, scoring rubrics, data models.

| Level | Description |
|-------|-------------|
| D10 | Articulates domain knowledge in conversations and informal docs. Can explain what "correct" looks like from a domain perspective. Provides input to specs written by engineers. |
| D20 | Writes specs that AI and engineers can act on. Defines acceptance criteria grounded in domain expertise. Creates test data from real-world scenarios. Reviews AI output for domain correctness. |
| D30 | Creates validation criteria and test cases rooted in domain expertise. Encodes domain knowledge into CLAUDE.md and reference docs that make AI more effective in the domain. Defines what "correct" means for domain-specific features. |
| D40 | Creates validation frameworks rooted in domain expertise (e.g., "this SEO audit is correct when X, Y, Z"). Defines domain models that engineers implement as system contracts. Shapes how domain concepts map to system architecture. |
| D50 | Designs domain models that become system contracts and product differentiators. Creates knowledge systems that persist beyond any individual - the domain's institutional memory is durable because of artifacts this person built. |
| D55 | Shapes product direction through encoded expertise. Defines the domain taxonomy and ontology that the org's systems are built on. The product's domain intelligence is architecturally grounded because of frameworks this person designed. |

**3. Production Awareness**

Understanding how code gets to production and stays healthy - deployment, observability, failure modes, the substrate boundary.

| Level | Description |
|-------|-------------|
| D10 | Understands that production differs from localhost. Asks before deploying. Knows who their engineering buddy is and when to escalate. Treats the substrate boundary as a hard stop. |
| D20 | Can read logs and understand CI pipeline output. Knows the deployment process for their team. Recognizes when something is a domain-level bug vs a platform issue. Escalates appropriately. |
| D30 | Navigates the deployment pipeline independently for domain-scoped changes. Can read structured logs to verify domain logic in non-production environments. Knows the substrate boundary and respects it without prompting. |
| D40 | Joins on-call rotation for domain-relevant alerts. Can diagnose domain-level failures in production. Understands the substrate boundary instinctively - knows which changes are safe to own and which need engineering review. Contributes to incident response for domain-related issues. |
| D50 | Contributes to observability design for domain-relevant metrics. Defines what "healthy" looks like from the domain perspective and ensures monitoring reflects it. Bridges the gap between domain insight and operational reality. |
| D55 | Shapes the org's approach to domain-aware observability. Defines SLIs and quality signals rooted in domain expertise. Ensures production systems reflect domain correctness, not just technical health. |

**4. Domain Leadership & Mentoring** (new)

Scaling domain impact beyond individual production - mentoring other domain experts, building the domain expert community, contributing to hiring and progression frameworks, bridging domain and engineering cultures.

| Level | Description |
|-------|-------------|
| D10 | Shares domain knowledge informally with the team. Asks questions that help engineers understand the domain better. Participates in domain-relevant discussions. |
| D20 | Documents domain patterns and gotchas for the team. Helps new domain experts get oriented. Provides domain-specific input during planning and review. |
| D30 | Mentors D10-D20 domain experts on tooling and workflow. Creates reusable domain-specific examples and templates. Bridges communication between domain and engineering perspectives. |
| D40 | Serves as engineering buddy for junior domain experts. Contributes to domain expert progression criteria. Leads domain-relevant retrospectives and knowledge-sharing sessions. |
| D50 | Builds the domain expert community - organizes guild meetings, creates onboarding paths, defines what "good" looks like at each level. Shapes hiring criteria for domain expert roles. |
| D55 | Defines how domain expertise scales in the org. Advocates for domain expert roles at leadership level. Creates frameworks that other teams adopt for integrating domain experts. The domain expert program is stronger because of this person's leadership. |

**5. Improvement Leverage (Capacity Reinvestment)**

The deliberate direction of AI-generated capacity toward domain quality improvements - rather than absorbing it into producing more PoCs or features.

| Level | Description |
|-------|-------------|
| D10 | Uses time saved by AI to deepen domain knowledge and learn production skills, not just produce more prototypes. Invests in understanding why things work, not just what works. |
| D20 | Identifies domain-specific quality improvements that AI makes possible - better validation data, more thorough acceptance criteria, improved domain documentation. |
| D30 | Uses AI-generated capacity to invest in domain knowledge encoding - creating reusable validation frameworks, domain-specific test suites, and reference implementations that raise quality for everyone. |
| D40 | Systematically directs AI-generated efficiency toward domain quality improvements - better audit rules, more comprehensive scoring rubrics, improved domain models. Maintains a domain improvement backlog. |
| D50 | Builds domain-specific improvement patterns that other domain experts adopt. Creates tools and templates that make domain quality investment structural, not dependent on individual initiative. |
| D55 | Defines how domain expertise investment scales with AI across the org. Ensures AI-generated capacity in domain work flows toward deeper domain intelligence, not just higher output volume. |

#### Sample Level Vignettes (Domain Expert)

**D10:**
A D10 is an SEO specialist, product manager, or other domain expert who has started using AI tools to explore ideas. They create prototypes in sandbox environments - a quick analysis, a proof-of-concept dashboard, a draft audit rule. Their output demonstrates domain insight but isn't production-ready, and that's fine. They're learning the tools, building confidence, and discovering what's possible. They have an engineering buddy who reviews their experiments and explains what production would require.

**D20:**
A D20 submits their first PRs. They write specs grounded in domain expertise, follow the team's established harness patterns, and produce artifacts that pass basic quality gates. An engineer reviews their work closely and provides substantial feedback - not rewrites, but real guidance on edge cases, test coverage, and production concerns. They're learning to think like a producer, not just a domain expert. Their domain knowledge already makes the specs better than what an engineer alone would write.

**D30:**
A D30 runs the spec-driven lifecycle independently for domain-scoped work. They write a spec, use the team's AI harness to implement it, and produce PoCs that engineers can review without needing to rewrite. They've internalized the substrate boundary and know what's safe to own. They mentor newer domain experts on tooling and workflow, and they create reusable templates that help others get started faster.

**D40:**
A D40 takes a domain insight - say, a new GEO ranking signal - from observation to production-ready code. They write a spec, implement it, validate it against real-world data, and shepherd it through CI. Engineers review their PRs but rarely need changes. They've joined on-call for domain-relevant alerts and can diagnose whether a failure is in the domain logic or the platform. They serve as engineering buddy for junior domain experts and lead domain-relevant knowledge-sharing sessions.

**D50:**
A D50 builds the infrastructure that makes other domain experts productive. They've created harness patterns, templates, and onboarding paths that D10-D40 domain experts use daily. They design domain models that become system contracts - the scoring rubrics, audit rules, and validation frameworks that define what "correct" means. They organize the domain expert guild, shape hiring criteria, and define what progression looks like at each level. The domain expert community exists as a functioning group because of this person's work.

**D55:**
A D55 defines how domain expertise flows into the product at org level. They've built the frameworks that other teams adopt for integrating domain experts. They advocate for domain expert roles at leadership level and shape the talent strategy. They design domain taxonomies and ontologies that the org's systems are built on. The product is measurably better because domain expertise is architecturally encoded, not locked in someone's head. They bridge domain and engineering at the highest level, influencing product direction through deep domain authority.

---

## Conventions Across All Three Documents

1. **Cumulative progression** - each level builds on the prior. The prose vignettes convey this narratively; the matrix cells focus on what is new or distinct at each level rather than restating lower-level content.
2. **Observable behaviors** - cells describe what someone does, not what they know. "Designs services with structured logs" not "understands observability."
3. **No overlap with existing guides** - these documents cover only the AI-native dimension. They complement, not replace, the existing ESDEP/ESDEM leveling content.
4. **Grounded in existing frameworks** - every category and cell traces back to concepts in the Phase 1 white paper or the AI-native guidelines repo. No invented terminology.
5. **Living documents** - revision date in header, expectation of quarterly review as AI capabilities and org maturity evolve.

## Glossary Terms (linked to existing docs)

| Term | Definition | Source |
|------|-----------|--------|
| Harness Engineering | The complete designed environment (instructions, tools, feedback loops, isolation) that determines AI agent effectiveness | `01-foundations/harness-engineering.md` |
| Substrate Model | Durable (load-bearing infrastructure) vs Fluid (features/experiments) layer distinction | `01-foundations/substrate-model.md` |
| Spec-Driven Lifecycle | Design doc before code, 5-phase development cycle | `02-lifecycle/overview.md` |
| Maturity Model | L0-L4 scale of how effectively AI can operate in a codebase | `07-leadership/ai-native-engineering-phase1.md` |
| Scorecard | 5-dimension assessment (validation speed, environment fidelity, traceability, coupling, ownership) scored 0-3 | `07-leadership/ai-native-engineering-phase1.md` |
| Frontier Engineer | Catalysts of AI-native transformation - Harness Engineer and/or AI Orchestrator specializations | `07-leadership/ai-native-engineering-phase1.md` |
| Improvement Leverage | The deliberate direction of AI-generated capacity toward improvements, quality, security, and learning - rather than absorbing it into feature velocity. Replaces the pre-AI "5% Rule" as the active framework. | `07-leadership/ai-native-engineering-phase1.md` |
| The 5% Rule (historical) | Pre-AI baseline allocation of human capacity to proactive engineering work. In AI-native orgs, this concept evolves into Improvement Leverage. | `07-leadership/ai-first-leadership.md` |
| Engineering Buddy | Assigned engineering mentor for domain experts | `07-leadership/domain-experts.md` |
| Substrate Boundary | The line between fluid (safe for domain experts to own) and durable (requires engineering rigor) changes | `01-foundations/substrate-model.md` |

## File Locations

All three documents will be placed in `docs/07-leadership/` in the `mysticat-ai-native-guidelines` repo:

- `docs/07-leadership/ai-native-leveling-ic.md`
- `docs/07-leadership/ai-native-leveling-manager.md`
- `docs/07-leadership/ai-native-leveling-domain-expert.md`

Navigation entries will be added to `mkdocs.yml`, `README.md`, and `AGENTS.md`.

## Validation Gates

1. Every matrix cell contains observable behaviors (not knowledge statements)
2. Every category traces to a concept in the Phase 1 white paper or AI-native guidelines
3. No cell duplicates content from the existing ESDEP/ESDEM leveling guides
4. Vignettes are concrete and distinguishable between adjacent levels
5. The three documents are internally consistent (same terms, same progression logic)
6. Glossary links resolve to existing documents in the repo
