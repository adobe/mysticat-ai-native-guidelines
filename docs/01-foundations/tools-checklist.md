# Tools Checklist

## Overview

AI-first development requires a set of CLI tools and proper authentication. This checklist ensures your environment is ready for productive AI-assisted work.

> **Note**: Installation commands below assume macOS with Homebrew. For Linux or Windows, see each tool's official documentation for platform-specific instructions.

## Required Tools

### Git

**Purpose**: Version control, branching, collaboration

```bash
# Verify installation
git --version

# Configure identity (if not already set)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

**Required**: Yes - foundational for all development

### GitHub CLI (gh)

**Purpose**: PR creation, issue management, repo operations

```bash
# Install
brew install gh  # macOS
# or see https://cli.github.com for other platforms

# Authenticate
gh auth login

# Verify
gh auth status
```

**Configuration for multiple hosts**:
```bash
# Authenticate to enterprise GitHub
gh auth login --hostname git.corp.example.com

# Check all authenticated hosts
gh auth status
```

**Required**: Yes - essential for PR workflows

### AI Assistant CLI

#### Claude Code

```bash
# Install
npm install -g @anthropic-ai/claude-code

# Verify
claude --version

# First run will prompt for API key or authentication
claude
```

#### Cursor

Download from [cursor.sh](https://cursor.sh) - IDE with built-in AI

#### GitHub Copilot

Install via VS Code or JetBrains extensions

**Required**: At least one AI assistant

### Skill Management

```bash
# Install and manage agent skills
npx skills add owner/repo     # Install skills from GitHub
npx skills list               # Show installed skills
npx skills find               # Discover skills interactively

# Alternative: direct skill installation
npx skills add https://github.com/adobe/skills --all
```

**Required**: No - optional but recommended for teams using reusable skills

## Language-Specific Tools

### Node.js / JavaScript

```bash
# Install Node.js (recommend using nvm)
nvm install 20
nvm use 20

# Package managers
npm --version
# or
pnpm --version
# or
yarn --version
```

### Python

```bash
# Python version manager (recommend pyenv)
pyenv install 3.11
pyenv local 3.11

# Virtual environment
python -m venv .venv
source .venv/bin/activate

# Package manager
pip --version
# or
poetry --version
# or
uv --version

# uv - fast Python package manager (used by many MCP servers)
# Install: brew install uv
```

### Go

```bash
go version
```

### Rust

```bash
rustc --version
cargo --version
```

## Infrastructure Tools

### Terraform

```bash
# Install
brew install terraform

# Verify
terraform --version
```

### AWS CLI

```bash
# Install
brew install awscli

# Configure
aws configure

# Verify
aws sts get-caller-identity
```

### Docker

```bash
# Verify
docker --version
docker compose version
```

## MCP Servers (Optional)

MCP (Model Context Protocol) servers extend AI capabilities with external tool access.

### What MCP Provides

- **Jira integration** - Create/update issues from AI sessions
- **Confluence access** - Search and update documentation
- **Database queries** - Query databases for context
- **Slack integration** - Post messages, read channels
- **Custom tools** - Build organization-specific integrations

### MCP Configuration

Create `.mcp.json` in your workspace root:

```json
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["--python=3.12", "mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://jira.example.com",
        "CONFLUENCE_URL": "https://wiki.example.com",
        "JIRA_PERSONAL_TOKEN": "${JIRA_PERSONAL_TOKEN}",
        "CONFLUENCE_PERSONAL_TOKEN": "${CONFLUENCE_PERSONAL_TOKEN}"
      }
    },
    "slack": {
      "command": "npx",
      "args": ["-y", "slack-mcp-server@latest", "--transport", "stdio"],
      "env": {
        "SLACK_MCP_XOXP_TOKEN": "${SLACK_MCP_XOXP_TOKEN}"
      }
    }
  }
}
```

### Common MCP Servers

| Server | Purpose | Command |
|--------|---------|---------|
| mcp-atlassian | Jira & Confluence | `uvx --python=3.12 mcp-atlassian` |
| slack | Slack messaging | `npx -y slack-mcp-server@latest` |
| github | GitHub (github.com) | HTTP MCP via `api.githubcopilot.com/mcp` |
| github-enterprise | GitHub Enterprise | Docker: `ghcr.io/github/github-mcp-server` |
| postgres | PostgreSQL queries | `npx -y @modelcontextprotocol/server-postgres` |
| coralogix | Observability | `npx -y coralogix-mcp@latest` |

See [MCP Servers Catalog](../04-configuration/mcp/servers.md) for full configuration details.

## Authentication Checklist

### GitHub

```bash
# Public GitHub
gh auth status

# Enterprise GitHub (if applicable)
gh auth status --hostname git.corp.example.com
```

### AWS

```bash
# Verify credentials
aws sts get-caller-identity

# If using SSO
aws sso login --profile your-profile
```

### Jira/Confluence (for MCP)

Authentication typically uses:
- API tokens (Atlassian Cloud)
- Personal Access Tokens (Server/Data Center)
- OAuth (depending on MCP server implementation)

Store credentials in environment variables or credential managers, never in code.

### Vault (if applicable)

```bash
# Verify Vault CLI
vault --version

# Login
vault login -method=oidc
```

## Verification Script

Run this script to verify your environment:

```bash
#!/bin/bash

echo "=== AI-First Development Environment Check ==="
echo ""

# Git
echo -n "Git: "
git --version 2>/dev/null || echo "NOT INSTALLED"

# GitHub CLI
echo -n "GitHub CLI: "
gh --version 2>/dev/null | head -1 || echo "NOT INSTALLED"

# GitHub Auth
echo -n "GitHub Auth: "
gh auth status 2>&1 | grep -q "Logged in" && echo "OK" || echo "NOT AUTHENTICATED"

# Node.js
echo -n "Node.js: "
node --version 2>/dev/null || echo "NOT INSTALLED"

# Python
echo -n "Python: "
python --version 2>/dev/null || python3 --version 2>/dev/null || echo "NOT INSTALLED"

# Terraform
echo -n "Terraform: "
terraform --version 2>/dev/null | head -1 || echo "NOT INSTALLED"

# AWS CLI
echo -n "AWS CLI: "
aws --version 2>/dev/null || echo "NOT INSTALLED"

# Docker
echo -n "Docker: "
docker --version 2>/dev/null || echo "NOT INSTALLED"

# Claude Code (if applicable)
echo -n "Claude Code: "
claude --version 2>/dev/null || echo "NOT INSTALLED"

# Skills
echo -n "Skills CLI: "
npx skills --version 2>/dev/null | head -1 || echo "NOT INSTALLED (optional)"

echo ""
echo "=== Check Complete ==="
```

## Troubleshooting

### GitHub CLI not authenticated

```bash
# Re-authenticate
gh auth login

# For enterprise, specify host
gh auth login --hostname git.corp.example.com
```

### AWS credentials expired

```bash
# For SSO profiles
aws sso login --profile your-profile

# For temporary credentials
# Re-run your credential helper or login command
```

### MCP server not connecting

1. Verify the MCP server is installed: `which mcp-servername`
2. Check `.mcp.json` syntax: valid JSON, correct paths
3. Verify environment variables are set
4. Check server logs if available

### Claude Code can't find tools

1. Verify tool is in PATH: `which toolname`
2. Restart Claude Code after installing new tools
3. Check CLAUDE.md doesn't have incorrect tool references

## Next Steps

- [Workspace Setup](workspace-setup.md) - Configure your workspace structure
- [Development Lifecycle](../02-lifecycle/overview.md) - Start building with AI
