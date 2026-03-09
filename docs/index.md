# AI-First Development Guidelines

Comprehensive guidelines for teams adopting AI-first development practices with Claude Code, Cursor, and Copilot.

## Quick Start

1. **New to AI-first development?** Start with [Philosophy](01-foundations/philosophy.md)
2. **Setting up your environment?** See [Workspace Setup](01-foundations/workspace-setup.md) and [Tools Checklist](01-foundations/tools-checklist.md)
3. **Ready to build?** Follow the [Development Lifecycle](02-lifecycle/overview.md)
4. **Need templates?** Check [Templates](03-templates/)
5. **Configuring your AI tools?** See [Configuration](04-configuration/)

## Navigation

### [01 - Foundations](01-foundations/)

Core concepts and environment setup:

| Document | Description |
|----------|-------------|
| [Philosophy](01-foundations/philosophy.md) | Why AI-first, core principles |
| [Substrate Model](01-foundations/substrate-model.md) | Durable vs fluid layers, hiring implications |
| [Workspace Setup](01-foundations/workspace-setup.md) | Directory structure, multi-repo layout |
| [Tools Checklist](01-foundations/tools-checklist.md) | CLI tools, authentication, MCP servers |

### [02 - Development Lifecycle](02-lifecycle/)

The 5-phase development cycle:

| Phase | Document | Description |
|-------|----------|-------------|
| Overview | [Lifecycle Overview](02-lifecycle/overview.md) | The complete cycle with diagram |
| 1 | [Design & Spec](02-lifecycle/01-design-spec.md) | Collaborative spec iteration |
| 2 | [Planning](02-lifecycle/02-planning.md) | Agent plan mode |
| 3 | [Implementation](02-lifecycle/03-implementation.md) | Branch/PR workflow |
| 4 | [Validation](02-lifecycle/04-validation.md) | Testing, CI/CD monitoring |
| 5 | [Closure](02-lifecycle/05-closure.md) | Docs, Jira, cleanup |
| + | [Config Evolution](02-lifecycle/06-config-evolution.md) | Maintaining AI configuration |

### [03 - Templates](03-templates/)

Ready-to-use templates:

| Template | Use Case |
|----------|----------|
| [Spec Proposal](03-templates/spec-proposal.md) | Design documents, feature proposals |
| [Contract](03-templates/contract.md) | Component-level Design by Contract specs |
| [Migration Plan](03-templates/migration.md) | System migrations, refactoring plans |
| [Decision Record](03-templates/decision-record.md) | Architecture Decision Records (ADRs) |
| [Pull Request](03-templates/pull-request-template.md) | PR template with AI usage disclosure |
| [TODO.md](03-templates/TODO.md) | Task tracking (Jira alternative) |

### [04 - Configuration](04-configuration/)

AI tool configuration, plugins, and MCP integration:

| Category | Documents |
|----------|-----------|
| **AI Tools** | [Claude Code](04-configuration/ai-tools/claude-code.md), [Cursor](04-configuration/ai-tools/cursor.md), [Copilot](04-configuration/ai-tools/copilot.md) |
| **Plugins** | [Overview](04-configuration/plugins/README.md), [Superpowers](04-configuration/plugins/superpowers.md) |
| **MCP** | [Overview](04-configuration/mcp/overview.md), [Servers](04-configuration/mcp/servers.md), [Workflows](04-configuration/mcp/workflows.md) |
| **Secrets** | [Environment & Secrets](04-configuration/env-secrets.md) |

### [05 - Guardrails](05-guardrails/)

Rules and anti-patterns:

| Document | Description |
|----------|-------------|
| [MUST Rules](05-guardrails/must-rules.md) | Non-negotiable requirements |
| [SHOULD Rules](05-guardrails/should-rules.md) | Strong recommendations |
| [AI Task Boundaries](05-guardrails/ai-task-boundaries.md) | What to delegate to AI vs own manually |
| [Anti-Patterns](05-guardrails/anti-patterns.md) | Common mistakes to avoid |

### [06 - Adoption](06-adoption/)

Team adoption guides and case studies:

| Document | Description |
|----------|-------------|
| [Onboarding Guide](06-adoption/onboarding-guide.md) | Getting started as a new engineer on an AI-first team |

### [07 - Leadership](07-leadership/)

Guidance for engineering leaders navigating AI-first:

| Document | Description |
|----------|-------------|
| [AI-First Leadership](07-leadership/ai-first-leadership.md) | What leaders get wrong, what to do instead |
| [For Junior Engineers](07-leadership/junior-engineers.md) | Building depth alongside AI fluency |
| [For Domain Experts](07-leadership/domain-experts.md) | Growing into production as a non-engineer |
| [For Experienced Engineers](07-leadership/experienced-engineers-guide.md) | When the tools changed - the identity shift |

### [Examples](examples/)

Concrete configuration examples:

| Example | Description |
|---------|-------------|
| [Workspace CLAUDE.md](examples/workspace-claude-md.md) | Workspace-level configuration |
| [Project CLAUDE.md](examples/project-claude-md.md) | Project-specific overrides |
| [.mcp.json](examples/mcp-json-example.json) | MCP server configuration |
| [CloudFormation IAM Alerts](examples/cloudformation-iam-alerts.md) | Production-ready infrastructure automation with real-time alerting |

### [Presentations](presentations/)

Slide decks for introducing AI-first development (Marp format):

| Presentation | Audience | Description |
|--------------|----------|-------------|
| [Intro](presentations/intro.md) | All technical staff | What AI-first is, why it matters, 5-phase workflow |
| [Getting Started](presentations/getting-started.md) | Engineers | Hands-on setup: tools, CLAUDE.md, MCP configuration |

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
