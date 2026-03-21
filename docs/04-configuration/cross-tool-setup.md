# Cross-Tool Configuration

## Overview

Teams using multiple AI coding agents - Claude Code, Cursor, Codex, Gemini CLI, Copilot - face a configuration challenge: each tool has its own instructions file, MCP config format, and skills directory. Without a strategy, you end up maintaining parallel configs that drift apart.

This page covers the emerging standards for cross-tool configuration: AGENTS.md as the universal entry point, the thin adapter pattern for tool-specific files, MCP config synchronization, and a recommended directory layout for multi-tool repos.

For the skills ecosystem that enables portable agent capabilities, see [Agent Skills Ecosystem](skills/overview.md).

## AGENTS.md - The Universal Agent Entry Point

`AGENTS.md` is a standard for providing project context and conventions to any AI coding agent. It lives at the repository root and serves the same purpose as `CLAUDE.md` - but is recognized by a growing list of tools including Codex, Cursor, Gemini CLI, Goose, and others.

### What Goes in AGENTS.md

The content mirrors what you would put in a good `CLAUDE.md`:

- Project description and architecture
- Technology stack
- Code conventions and patterns
- MUST/SHOULD rules
- Build, test, and deploy commands
- Directory structure
- Links to detailed documentation

### Relationship to CLAUDE.md

| File | Scope | Recognized By |
|------|-------|---------------|
| `AGENTS.md` | Universal - any AI agent | Codex, Cursor, Gemini CLI, Goose, and others |
| `CLAUDE.md` | Claude-specific | Claude Code |

These files are not mutually exclusive. The recommended pattern is:

- **AGENTS.md** as the canonical source of truth for project context
- **CLAUDE.md** as a thin adapter that references AGENTS.md and adds Claude-specific configuration

This keeps one source of truth while letting each tool pick up its native format.

## The Thin Adapter Pattern

Rather than duplicating project context across multiple config files, use a single canonical source (AGENTS.md) and create lightweight adapters for each tool.

### Claude Code Adapter

`.claude/CLAUDE.md` or root `CLAUDE.md`:

```markdown
# Claude Code Configuration

Read and follow all instructions in ../AGENTS.md (or ./AGENTS.md if at root).

## Claude-Specific Additions

- Use the /compact command when context gets large
- Prefer MCP tools over CLI for Jira and GitHub operations
- See .mcp.json for available MCP servers
```

### Cursor Adapter

`.cursor/rules/follow-agents-md.mdc`:

```markdown
---
description: Load universal agent instructions from AGENTS.md
globs:
alwaysApply: true
---

Read and follow all instructions in the repository root AGENTS.md file.

Additional Cursor-specific rules:
- Use the Composer for multi-file changes
- Reference .cursor/mcp.json for MCP server availability
```

### Codex Adapter

Codex reads `AGENTS.md` natively - no adapter file is needed for instructions. MCP configuration goes in `.codex/config.toml` (see MCP section below).

### Benefits

- **Single source of truth** - update AGENTS.md once, all tools see the change
- **No drift** - tool-specific files contain only tool-specific additions
- **Easy onboarding** - new tools that support AGENTS.md work immediately
- **Reviewable** - PRs to AGENTS.md are visible to the whole team

## Multi-Tool Config File Map

| Tool | Instructions File | MCP Config | Skills Directory |
|------|-------------------|------------|------------------|
| Claude Code | `CLAUDE.md` | `.mcp.json` | `.claude/skills/` or `.agents/skills/` |
| Cursor | `.cursor/rules/*.mdc` | `.cursor/mcp.json` | `.agents/skills/` |
| Codex | `AGENTS.md` | `.codex/config.toml` | `.agents/skills/` |
| Gemini CLI | `AGENTS.md` | (built-in) | `.agents/skills/` |
| Copilot | `.github/copilot-instructions.md` | VS Code MCP settings | N/A |

## Keeping MCP Configs in Sync

Most teams need at least two MCP config files (`.mcp.json` for Claude Code, `.cursor/mcp.json` for Cursor), and potentially a third (`.codex/config.toml` for Codex). These files configure the same servers in different formats.

### Rules for MCP Config Management

- **MUST NOT** commit secrets - use environment variable references in all formats
- **MUST** keep the same server set across all config files - a server available in Claude Code SHOULD also be available in Cursor
- **SHOULD** update all config files in the same commit when adding or removing a server
- **SHOULD** document required environment variables in AGENTS.md or a setup guide

### Example: Same Server in Three Formats

Here is the same Atlassian (Jira/Confluence) MCP server configured for each tool.

**Claude Code (`.mcp.json`):**

```json
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["--python=3.12", "mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://jira.example.com",
        "JIRA_PERSONAL_TOKEN": "${JIRA_PERSONAL_TOKEN}",
        "CONFLUENCE_URL": "https://wiki.example.com",
        "CONFLUENCE_PERSONAL_TOKEN": "${CONFLUENCE_PERSONAL_TOKEN}"
      }
    }
  }
}
```

**Cursor (`.cursor/mcp.json`):**

```json
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["--python=3.12", "mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://jira.example.com",
        "JIRA_PERSONAL_TOKEN": "${JIRA_PERSONAL_TOKEN}",
        "CONFLUENCE_URL": "https://wiki.example.com",
        "CONFLUENCE_PERSONAL_TOKEN": "${CONFLUENCE_PERSONAL_TOKEN}"
      }
    }
  }
}
```

The Claude Code and Cursor formats are identical JSON - you can symlink `.cursor/mcp.json` to `.mcp.json` if your server set is the same for both tools.

**Codex (`.codex/config.toml`):**

```toml
[mcp_servers.mcp-atlassian]
command = "uvx"
args = ["--python=3.12", "mcp-atlassian"]

[mcp_servers.mcp-atlassian.env]
JIRA_URL = "https://jira.example.com"
JIRA_PERSONAL_TOKEN = "${JIRA_PERSONAL_TOKEN}"
CONFLUENCE_URL = "https://wiki.example.com"
CONFLUENCE_PERSONAL_TOKEN = "${CONFLUENCE_PERSONAL_TOKEN}"
```

### Tip: Symlinks for Identical Configs

If Claude Code and Cursor use the same MCP servers, you can avoid duplication:

```bash
# Make Cursor use the same config as Claude Code
ln -s ../.mcp.json .cursor/mcp.json
```

This works because both tools use the same JSON format. Codex uses TOML, so it always needs its own file.

## Ignore Files

Both Claude Code and Cursor support ignore files that exclude paths from AI context. These SHOULD list the same paths to ensure consistent behavior regardless of which tool a team member uses.

### .claudeignore

```
# Build output
dist/
build/
node_modules/

# Generated files
*.min.js
*.map
coverage/

# Internal docs not for AI context
dev-docs/
.git/
```

### .cursorignore

```
# Build output
dist/
build/
node_modules/

# Generated files
*.min.js
*.map
coverage/

# Internal docs not for AI context
dev-docs/
.git/
```

**SHOULD** keep these files in sync. When you add a path to one, add it to the other.

## Recommended Directory Layout

A multi-tool repository that follows the patterns in this guide looks like this:

```
my-project/
  AGENTS.md                        # Universal agent entry point
  CLAUDE.md                        # Claude-specific overrides (thin adapter)
  .mcp.json                        # Claude Code MCP config
  .claudeignore                    # Claude Code ignore rules
  .cursorignore                    # Cursor ignore rules
  .agents/
    skills/                        # Cross-agent skills (agentskills.io standard)
      code-review/
        SKILL.md
      tdd/
        SKILL.md
  .claude/
    CLAUDE.md                      # Optional - can redirect to root CLAUDE.md
    skills/                        # Claude-only skills (or symlink to .agents/skills/)
  .cursor/
    rules/
      follow-agents-md.mdc        # Thin adapter to AGENTS.md
      api-design.mdc              # Cursor-specific glob-activated rules
    mcp.json                       # Cursor MCP config (or symlink to .mcp.json)
  .codex/
    config.toml                    # Codex MCP config (TOML format)
  .github/
    copilot-instructions.md        # Copilot instructions
```

### What to Commit to Version Control

| File/Directory | Commit? | Notes |
|----------------|---------|-------|
| `AGENTS.md` | Yes | Universal project context |
| `CLAUDE.md` | Yes | Team-shared Claude rules |
| `.mcp.json` | Yes | No secrets - env var references only |
| `.cursor/rules/*.mdc` | Yes | Team-shared Cursor rules |
| `.cursor/mcp.json` | Yes | No secrets - env var references only |
| `.agents/skills/` | Yes | Shared skills for the whole team |
| `.claudeignore` / `.cursorignore` | Yes | Consistent ignore rules |
| `.codex/config.toml` | Depends | Commit if project-level; skip if user-level (`~/.codex/`) |
| `.github/copilot-instructions.md` | Yes | Team-shared Copilot instructions |
| `.claude/CLAUDE.md` | Optional | Only if it adds value beyond root CLAUDE.md |

## Adobe Exemplars

### Adobe-Firefly/aip-agentic-context

A full multi-tool setup with AGENTS.md as the universal entry point, plus tool-specific adapters for Claude Code and Cursor. Demonstrates the thin adapter pattern at scale with a real production codebase.

### Adobe-AEM-Sites/aso-ai-toolkit

Uses a cross-tool bridge via `.cursor/rules/follow-claude-md.mdc` to point Cursor at the project's existing CLAUDE.md configuration. A pragmatic approach when CLAUDE.md is already the established source of truth and AGENTS.md has not been adopted yet.

## See Also

- [ACI Design](aci-design.md) - Agent-Computer Interface design principles, progressive disclosure as a general pattern, and documentation patterns for agents
- [Agent Skills Ecosystem](skills/overview.md) - The SKILL.md standard, progressive disclosure, and package management
- [Claude Code Configuration](ai-tools/claude-code.md) - CLAUDE.md patterns and hierarchy
- [Cursor Configuration](ai-tools/cursor.md) - .cursor/rules/ patterns and MCP setup
- [MCP Overview](mcp/overview.md) - MCP architecture, server types, and configuration
- [Environment & Secrets](env-secrets.md) - Managing secrets safely across tools
- [Plugins Overview](plugins/README.md) - Plugin ecosystem and available extensions
