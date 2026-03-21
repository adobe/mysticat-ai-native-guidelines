# Configuration

This section covers configuration for AI-assisted development tools, plugins, and integrations.

## Structure

```
04-configuration/
├── aci-design.md       # Agent-Computer Interface design principles
├── ai-tools/           # AI coding assistant setup
│   ├── claude-code.md  # Claude Code + CLAUDE.md patterns
│   ├── cursor.md       # Cursor + .cursorrules
│   └── copilot.md      # GitHub Copilot
├── plugins/            # Extensions and plugins by tool
│   ├── README.md       # Plugin index
│   ├── superpowers.md  # Claude Code superpowers plugin
│   └── adobe-skills.md # Adobe Skills for AEM Edge Delivery
├── skills/             # Agent skills ecosystem
│   └── overview.md     # agentskills.io standard, SKILL.md format, package mgmt
├── mcp/                # Model Context Protocol (cross-tool)
│   ├── overview.md     # What MCP is, why it matters
│   ├── servers.md      # Recommended server catalog
│   └── workflows.md    # End-to-end workflow examples
├── cross-tool-setup.md # AGENTS.md, multi-tool config, thin adapters
└── env-secrets.md      # Environment variables and secrets management
```

## Quick Links

### AI Tools

| Tool | Config File | Documentation |
|------|-------------|---------------|
| [Claude Code](ai-tools/claude-code.md) | `CLAUDE.md` | Setup, CLAUDE.md patterns, CLI usage |
| [Tool Permissions](ai-tools/permissions.md) | `settings.json` | Allowlists, denylists, MCP permissions |
| [Cursor](ai-tools/cursor.md) | `.cursorrules` | Setup, rules file patterns |
| [GitHub Copilot](ai-tools/copilot.md) | VS Code settings | Setup, prompting strategies |

### Plugins

| Plugin | For Tool | Documentation |
|--------|----------|---------------|
| [Superpowers](plugins/superpowers.md) | Claude Code | Structured workflows, TDD, planning |
| [Adobe Skills](plugins/adobe-skills.md) | Claude Code | AEM Edge Delivery Services skills |

### Skills Ecosystem

| Document | Description |
|----------|-------------|
| [Skills Overview](skills/overview.md) | agentskills.io standard, SKILL.md format, progressive loading, package management |

### ACI Design

| Document | Description |
|----------|-------------|
| [ACI Design](aci-design.md) | Agent-Computer Interface principles, progressive disclosure, documentation patterns, audit checklist |

### Cross-Tool Configuration

| Document | Description |
|----------|-------------|
| [Cross-Tool Setup](cross-tool-setup.md) | AGENTS.md, thin adapters, multi-tool MCP sync, directory layout |

### MCP (Model Context Protocol)

| Document | Description |
|----------|-------------|
| [Overview](mcp/overview.md) | What MCP is, architecture, when to use it |
| [Servers](mcp/servers.md) | Catalog of recommended MCP servers |
| [Workflows](mcp/workflows.md) | End-to-end examples: development, deployment, incident response |

### Other

| Document | Description |
|----------|-------------|
| [Environment & Secrets](env-secrets.md) | Managing secrets safely with AI tools |

## Choosing Your Tools

### For Individual Developers

Start with one AI tool and add MCP servers as needed:

1. **Choose an AI tool**: Claude Code (CLI), Cursor (IDE), or Copilot (IDE plugin)
2. **Set up configuration**: CLAUDE.md, .cursorrules, or VS Code settings
3. **Add MCP servers**: Start with the ones for your daily tools (Jira, GitHub, Slack)
4. **Consider plugins**: Add superpowers for Claude Code if you want structured workflows

### For Teams

1. **Standardize AI tool configuration**: Commit CLAUDE.md or .cursorrules to repos
2. **Share MCP configuration**: Document required servers and setup steps
3. **Establish workflows**: Use the workflow examples as templates for your team

## See Also

- [ACI Design](aci-design.md) - Agent-Computer Interface design principles and audit checklist
- [Workspace Setup](../01-foundations/workspace-setup.md) - Initial workspace configuration
- [Tools Checklist](../01-foundations/tools-checklist.md) - Required tools and installation
- [MUST Rules](../05-guardrails/must-rules.md) - Security and quality rules
