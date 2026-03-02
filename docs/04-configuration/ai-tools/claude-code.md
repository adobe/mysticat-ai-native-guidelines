# Claude Code Configuration

## Overview

Claude Code is Anthropic's official CLI tool for AI-assisted development. It brings Claude's capabilities directly into your terminal, understanding your codebase and helping you work through natural language.

This document covers Claude Code setup and CLAUDE.md file patterns. For MCP server configuration, see [MCP Overview](../mcp/overview.md). For plugins like superpowers, see [Plugins](../plugins/README.md).

## Installation

**npm (recommended):**
```bash
npm install -g @anthropic-ai/claude-code
```

**macOS/Linux (shell script):**
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Verify installation:**
```bash
claude --version
```

See the [official installation guide](https://docs.anthropic.com/en/docs/claude-code/overview) for the latest instructions and platform-specific options.

## Getting Started

```bash
# Navigate to your project
cd my-project

# Start Claude Code
claude

# Or run a specific command
claude "explain this codebase"
```

## CLAUDE.md

### Purpose

CLAUDE.md provides context and rules that guide AI behavior when working in your codebase. Think of it as a readme specifically for AI assistants.

### Hierarchy

```
~/.claude/CLAUDE.md           # Global (user-level) defaults
    ↓ inherits
workspace/CLAUDE.md           # Workspace-wide rules
    ↓ inherits
workspace/project/CLAUDE.md   # Project-specific overrides
```

Each level inherits from parent and can:
- Add new rules
- Override specific settings
- Reference sibling projects

### Structure

A well-organized CLAUDE.md includes:

```markdown
# Project Name

Brief description of what this project is.

## Project Context

Information AI needs to understand the project:
- Technology stack
- Architecture overview
- Key patterns

## Rules

### MUST (Non-negotiable)

- MUST run tests before committing
- MUST NOT commit secrets
- MUST follow existing code patterns

### SHOULD (Strong recommendations)

- SHOULD use conventional commits
- SHOULD add tests for new features
- SHOULD NOT add dependencies without justification

## Available Tools

Tools AI can use in this project:
- npm/pnpm/yarn commands
- pytest
- terraform
- etc.

## Working Context

Defaults and commands that accelerate AI workflows:
- Default Jira project, GitHub repo, environments
- Quick reference for common commands
- Current focus areas

## Code Patterns

Preferred patterns and conventions:
- File naming
- Error handling
- Logging
```

### Effective Rules

**Good Rules** (specific, actionable):
```markdown
- MUST run `npm test` before committing JavaScript changes
- MUST NOT use `any` type in TypeScript without justification comment
- MUST add database indexes for columns used in WHERE clauses
```

**Poor Rules** (vague, unenforceable):
```markdown
- Write good code
- Be careful with security
- Follow best practices
```

### Context That Helps

**Project Structure**:
```markdown
## Project Structure

- `src/api/` - REST API endpoints (Express)
- `src/services/` - Business logic
- `src/models/` - Database models (Prisma)
- `tests/` - Test files mirror src/ structure
```

**External Systems**:
```markdown
## External Dependencies

- **Auth**: Auth0 for authentication
- **Database**: PostgreSQL on RDS
- **Queue**: SQS for async processing
- **Monitoring**: Datadog for metrics and logs
```

**Team Conventions**:
```markdown
## Conventions

- Branch naming: `type/JIRA-123-description`
- PR titles: `[JIRA-123] Brief description`
- Commit messages: Conventional Commits format
```

### Tool References

Document MCP servers and CLI tools available:

```markdown
## Available Tools

### MCP Servers
- **mcp-atlassian**: Jira and Confluence access
- **slack**: Slack workspace integration
- **postgres**: Database queries

### CLI Tools
- `gh` - GitHub CLI (authenticated)
- `vault` - HashiCorp Vault for secrets
- `aws` - AWS CLI
```

### Working Context

The Working Context section accelerates AI workflows by declaring defaults and frequently-used commands. This eliminates repetitive questions like "which Jira project?" or "which environment?"

```markdown
## Working Context

### Defaults

| System | Default | Override with |
|--------|---------|---------------|
| Jira | MYPROJ project | "in OTHERPROJ" |
| GitHub | myorg/main-repo | "-R myorg/other" |
| AWS | dev account | "in staging" or "in prod" |

### Quick Reference

| Task | Command |
|------|---------|
| Run tests | `npm test` |
| Deploy staging | `make deploy-staging` |

### Active Work

- Epic: MYPROJ-100 (Q1 migration)
- Branch: feature/new-auth
```

See [Configuration Evolution](../../02-lifecycle/06-config-evolution.md) for guidance on maintaining this section over time.

## Key Commands

| Command | Purpose |
|---------|---------|
| `claude` | Start interactive session |
| `claude "prompt"` | Run single command |
| `claude /help` | Show help |
| `claude /bug` | Report a bug |
| `claude /clear` | Clear conversation |

## Best Practices

### CLAUDE.md

1. **Keep it updated** - Stale rules cause confusion
2. **Be specific** - Vague rules are ignored
3. **Prioritize** - MUST rules should be truly critical
4. **Include examples** - Show, don't just tell
5. **Cross-reference** - Link to detailed docs when needed

### Workspace Organization

```
my-workspace/
├── CLAUDE.md          # Workspace-level rules
├── .mcp.json          # MCP servers for all projects
├── .gitignore         # Standard ignores (node_modules, etc.)
│
├── frontend/
│   └── CLAUDE.md      # Frontend-specific rules
│
├── backend/
│   └── CLAUDE.md      # Backend-specific rules
│
└── infrastructure/
    └── CLAUDE.md      # Infrastructure-specific rules
```

## IDE Integration

Claude Code works primarily as a CLI but integrates with:

- **VS Code**: Through terminal or extensions
- **Terminal multiplexers**: tmux, screen for persistent sessions
- **Git workflows**: Use in pre-commit hooks or CI

## See Also

- [Tool Permissions](permissions.md) - Allowlists, denylists, and MCP permission patterns
- [MCP Overview](../mcp/overview.md) - External tool integration
- [Superpowers Plugin](../plugins/superpowers.md) - Structured workflows
- [Environment & Secrets](../env-secrets.md) - Safe secrets handling
- [Example Workspace CLAUDE.md](../../examples/workspace-claude-md.md)
- [Example Project CLAUDE.md](../../examples/project-claude-md.md)
