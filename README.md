# AI-First Development Guidelines

Comprehensive guidelines for teams adopting AI-first development practices with Claude Code, Cursor, and Copilot.

**[What's New](docs/LATEST.md)** - recent changes and additions

## Quick Start

1. **New to AI-first development?** Start with [Philosophy](docs/01-foundations/philosophy.md)
2. **Setting up your environment?** See [Workspace Setup](docs/01-foundations/workspace-setup.md) and [Tools Checklist](docs/01-foundations/tools-checklist.md)
3. **Ready to build?** Follow the [Development Lifecycle](docs/02-lifecycle/overview.md)
4. **Need templates?** Check [Templates](docs/03-templates/)
5. **Configuring your AI tools?** See [Configuration](docs/04-configuration/)

## Navigation

### [01 - Foundations](docs/01-foundations/)

Core concepts and environment setup:

| Document | Description |
|----------|-------------|
| [Philosophy](docs/01-foundations/philosophy.md) | Why AI-first, core principles |
| [Harness Engineering](docs/01-foundations/harness-engineering.md) | The designed environment: harness stack, context management, environment audit |
| [Substrate Model](docs/01-foundations/substrate-model.md) | Durable vs fluid layers, hiring implications |
| [Workspace Setup](docs/01-foundations/workspace-setup.md) | Directory structure, multi-repo layout |
| [Tools Checklist](docs/01-foundations/tools-checklist.md) | CLI tools, authentication, MCP servers |

### [02 - Development Lifecycle](docs/02-lifecycle/)

The 5-phase development cycle:

| Phase | Document | Description |
|-------|----------|-------------|
| Overview | [Lifecycle Overview](docs/02-lifecycle/overview.md) | The complete cycle with diagram |
| 1 | [Design & Spec](docs/02-lifecycle/01-design-spec.md) | Collaborative spec iteration |
| 2 | [Planning](docs/02-lifecycle/02-planning.md) | Agent plan mode |
| 3 | [Implementation](docs/02-lifecycle/03-implementation.md) | Branch/PR workflow |
| 4 | [Validation](docs/02-lifecycle/04-validation.md) | Testing, CI/CD monitoring |
| 5 | [Closure](docs/02-lifecycle/05-closure.md) | Docs, Jira, cleanup |
| + | [Multi-Session Patterns](docs/02-lifecycle/multi-session-patterns.md) | State persistence, handoff, parallel agents |
| + | [Config Evolution](docs/02-lifecycle/06-config-evolution.md) | Maintaining AI configuration |

### [03 - Templates](docs/03-templates/)

Ready-to-use templates:

| Template | Use Case |
|----------|----------|
| [Spec Proposal](docs/03-templates/spec-proposal.md) | Design documents, feature proposals |
| [Contract](docs/03-templates/contract.md) | Component-level Design by Contract specs |
| [Migration Plan](docs/03-templates/migration.md) | System migrations, refactoring plans |
| [Decision Record](docs/03-templates/decision-record.md) | Architecture Decision Records (ADRs) |
| [Pull Request](docs/03-templates/pull-request-template.md) | PR template with AI usage disclosure |
| [TODO.md](docs/03-templates/TODO.md) | Task tracking (Jira alternative) |

### [04 - Configuration](docs/04-configuration/)

AI tool configuration, plugins, and MCP integration:

| Category | Documents |
|----------|-----------|
| **ACI Design** | [Agent-Computer Interface](docs/04-configuration/aci-design.md) - design principles, progressive disclosure, documentation patterns, audit checklist |
| **Token Efficiency** | [Token Efficiency](docs/04-configuration/token-efficiency.md) - cost model, optimization playbook, anti-patterns, measurement |
| **AI Tools** | [Claude Code](docs/04-configuration/ai-tools/claude-code.md), [Cursor](docs/04-configuration/ai-tools/cursor.md), [Copilot](docs/04-configuration/ai-tools/copilot.md) |
| **Plugins** | [Overview](docs/04-configuration/plugins/README.md), [Superpowers](docs/04-configuration/plugins/superpowers.md), [Adobe Skills](docs/04-configuration/plugins/adobe-skills.md) |
| **Skills** | [Skills Ecosystem](docs/04-configuration/skills/overview.md) - agentskills.io standard, SKILL.md format, package management |
| **Cross-Tool** | [Cross-Tool Setup](docs/04-configuration/cross-tool-setup.md) - AGENTS.md, thin adapters, multi-tool config |
| **MCP** | [Overview](docs/04-configuration/mcp/overview.md), [Servers](docs/04-configuration/mcp/servers.md), [Workflows](docs/04-configuration/mcp/workflows.md) |
| **Secrets** | [Environment & Secrets](docs/04-configuration/env-secrets.md) |

### [05 - Guardrails](docs/05-guardrails/)

Rules and anti-patterns:

| Document | Description |
|----------|-------------|
| [MUST Rules](docs/05-guardrails/must-rules.md) | Non-negotiable requirements |
| [SHOULD Rules](docs/05-guardrails/should-rules.md) | Strong recommendations |
| [AI Task Boundaries](docs/05-guardrails/ai-task-boundaries.md) | What to delegate to AI vs own manually |
| [Mechanical Enforcement](docs/05-guardrails/mechanical-enforcement.md) | Automated gates, agent-friendly errors, structural tests |
| [Anti-Patterns](docs/05-guardrails/anti-patterns.md) | Common mistakes to avoid |

### [06 - Adoption](docs/06-adoption/)

Team adoption guides and case studies:

| Document | Description |
|----------|-------------|
| [Onboarding Guide](docs/06-adoption/onboarding-guide.md) | Getting started as a new engineer on an AI-first team |
| [AI Readiness Checklist](docs/06-adoption/ai-readiness-checklist.md) | Assess how prepared a repo is for AI-first development |

### [07 - Leadership](docs/07-leadership/)

Guidance for engineering leaders navigating AI-first:

| Document | Description |
|----------|-------------|
| [AI-First Leadership](docs/07-leadership/ai-first-leadership.md) | What leaders get wrong, what to do instead |
| [For Junior Engineers](docs/07-leadership/junior-engineers.md) | Building depth alongside AI fluency |
| [For Domain Experts](docs/07-leadership/domain-experts.md) | Growing into production as a non-engineer |
| [For Experienced Engineers](docs/07-leadership/experienced-engineers-guide.md) | When the tools changed - the identity shift |
| [AI-Native Phase 1](docs/07-leadership/ai-native-engineering-phase1.md) | Framework, maturity model, scorecard, and playbook for Phase 1 |
| [AI-Native Leveling (IC)](docs/07-leadership/ai-native-leveling-ic.md) | AI-native skill expectations per IC level (P10-P55) |
| [AI-Native Leveling (Manager)](docs/07-leadership/ai-native-leveling-manager.md) | AI-native skill expectations per manager band (M2-M6) |
| [AI-Native Leveling (Domain Expert)](docs/07-leadership/ai-native-leveling-domain-expert.md) | AI-native skill expectations per domain expert level (D10-D55) |

### [Examples](docs/examples/)

Concrete configuration examples:

| Example | Description |
|---------|-------------|
| [Workspace CLAUDE.md](docs/examples/workspace-claude-md.md) | Workspace-level configuration |
| [Project CLAUDE.md](docs/examples/project-claude-md.md) | Project-specific overrides |
| [.mcp.json](docs/examples/mcp-json-example.json) | MCP server configuration |

### [Presentations](docs/presentations/)

Slide decks for introducing AI-first development (Marp format):

| Presentation | Audience | Description |
|--------------|----------|-------------|
| [Intro](docs/presentations/intro.md) | All technical staff | What AI-first is, why it matters, 5-phase workflow |
| [Getting Started](docs/presentations/getting-started.md) | Engineers | Hands-on setup: tools, CLAUDE.md, MCP configuration |

## Audience

These guidelines are designed for:

- **Immediate team members** - Daily reference for AI-assisted development
- **Broader organization** - Standardizing AI practices across teams
- **New hires** - Onboarding to AI-first workflows

## Contributing

This documentation is itself maintained using AI-first practices. See [CLAUDE.md](CLAUDE.md) for guidelines on contributing with AI assistance.

## Key Principles

1. **Spec-driven development** - Design in markdown before coding
2. **AI as collaborator** - Not just autocomplete, but design partner
3. **Guardrails over guidelines** - Clear MUST/MUST NOT rules for critical paths
4. **Documentation as code** - Docs live in git, evolve with the project
5. **Multi-agent support** - Consistent experience across Claude Code, Cursor, Copilot
