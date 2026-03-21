---
marp: true
theme: adobe
paginate: true
header: 'AI-First Development'
footer: 'github.com/solaris007/ai-first-guidelines'
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _header: '' -->

# Getting Started

## AI-First Development in Practice

---

# Prerequisites

### You'll Need
- Terminal access (macOS/Linux/Windows)
- Git configured

### Choose Your Tool
- **Claude Code** (recommended) — CLI, full codebase understanding
- **Cursor** — IDE with built-in AI
- **GitHub Copilot** — VS Code extension

This guide focuses on Claude Code.

---

# Step 1: Install Claude Code

### macOS / Linux
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### Windows
```powershell
irm https://claude.ai/install.ps1 | iex
```

### Verify
```bash
claude --version
```

---

# Step 2: Workspace Setup

```
my-workspace/              # Workspace repository
├── init.sh                # Bootstrap script (idempotent)
├── mani.yaml              # Repo manifest - repos organized with tags
├── CLAUDE.md              # Workspace-wide AI rules (@import)
├── AGENTS.md              # Cross-tool agent conventions
├── .claude/agents/        # Role-based and service-specific agents
├── .mcp.json.template     # MCP config template (committed)
└── project-a/             # Cloned by init.sh
    └── CLAUDE.md          # Project-specific rules
```

- **Workspace repository** = single bootstrap for your entire team setup
- **init.sh** = automated clone, install, and configure
- **Agent definitions** = deep context for AI per role and service

---

# Step 3: Your First CLAUDE.md

<!-- _class: smaller -->

```markdown
# My Project

Brief description of what this project does.

## Project Context
- Language: Python 3.11
- Framework: FastAPI

## Rules
- MUST run tests before committing
- MUST NOT commit secrets or .env files
- SHOULD use conventional commits

## Working Context

| Task | Command |
|------|---------|
| Run tests | `pytest` |
| Start server | `uvicorn main:app --reload` |
| Run linter | `ruff check .` |
```

---

# CLAUDE.md Patterns

### Good Rules (Specific, Actionable)
```markdown
- MUST run `npm test` before committing
- MUST NOT use `any` type without justification
- SHOULD use React Query for data fetching
```

### Bad Rules (Vague, Unenforceable)
```markdown
- Write good code
- Be careful with security
```

**Be specific. AI follows what you write literally.**

---

# What is MCP?

**Model Context Protocol** — Connects AI to external tools

```
┌──────────────┐
│  Claude Code │
└──────┬───────┘
       │ MCP Protocol
       ▼
┌──────────┐   ┌──────────┐   ┌──────────┐
│   Jira   │   │  GitHub  │   │  Slack   │
└──────────┘   └──────────┘   └──────────┘
```

- **Without MCP**: Parse CLI output, fragile
- **With MCP**: Structured data, reliable, rich context

---

# Step 4: Configure MCP

### Location: `.mcp.json` in your workspace root

```json
{
  "mcpServers": {
    "server-name": {
      "command": "mcp-server-command",
      "env": {
        "API_KEY": "${ENV_VAR_NAME}"
      }
    }
  }
}
```

**Never hardcode secrets** — use `${ENV_VAR}` syntax

---

# Essential MCP Servers

| Server | Purpose | Package |
|--------|---------|---------|
| mcp-atlassian | Jira + Confluence | `uvx mcp-atlassian` |
| github | GitHub repos, PRs | HTTP endpoint or Docker |
| slack | Messages, channels | `npx slack-mcp-server` |
| postgres | Database queries | `npx @modelcontextprotocol/server-postgres` |

**See `04-configuration/mcp/servers.md` for full setup.**

---

# MCP Example: Jira + Confluence

<!-- _class: smaller -->

```json
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["--python=3.12", "mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://jira.example.com",
        "CONFLUENCE_URL": "https://wiki.example.com",
        "JIRA_PERSONAL_TOKEN": "${JIRA_PERSONAL_TOKEN}"
      }
    }
  }
}
```

Restart Claude Code after changes.

---

# Secrets with 1Password

<!-- _class: smaller -->

**Never commit secrets.** Use 1Password CLI with a wrapper script.

**`run-with-op.sh`:**
```bash
#!/bin/bash
export SPLUNK_API_URL="https://splunk-api.or1.adobe.net"
export SPLUNK_API_USER="$(op item get 'Splunk' --fields username)"
export SPLUNK_API_PASSWORD="$(op item get 'Splunk' --fields password --reveal)"
exec node /path/to/adobe-mcp-servers/src/splunk-mcp-server/dist/index.js
```

**`.mcp.json`:**
```json
{
  "mcpServers": {
    "splunk": {
      "command": "bash",
      "args": ["/path/to/run-with-op.sh"]
    }
  }
}
```

---

# Superpowers Plugin

Structured workflows on top of Claude Code

```bash
claude plugins:install obra/superpowers
```

| Skill | What It Does |
|-------|--------------|
| brainstorming | Explore requirements before coding |
| writing-plans | Detailed implementation plans |
| test-driven-development | RED-GREEN-REFACTOR cycles |
| verification-before-completion | Prove it works before done |

---

# Workflow: Feature Development

1. **Read Jira ticket** → `jira_get_issue("PROJ-123")`
2. **Create branch** → `create_branch("feature/...")`
3. **Implement with TDD** → superpowers skill
4. **Create PR** → `create_pull_request(...)`
5. **Link PR to Jira** → `jira_create_remote_issue_link(...)`
6. **Notify team** → `conversations_add_message(...)`
7. **On merge** → `jira_transition_issue(...)`

**Full traceability from ticket to deployment**

---

# Workflow: Incident Response

Real example: S3 backup generating $111K/year in costs

1. **Alert received** → Check Slack #alerts
2. **Query logs** → `splunk: search_splunk(...)`
3. **Investigate data** → `postgres: query(...)`
4. **Identify root cause** → AWS Backup scanning all versions
5. **Stop bleeding** → AWS CLI to stop job
6. **Create fix PR** → `create_pull_request(...)`
7. **Document** → `confluence_create_page(...)`

---

# Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Secrets in .mcp.json | Use `${ENV_VAR}` references |
| Vague CLAUDE.md rules | Be specific and actionable |
| Skipping verification | Use superpowers plugin |
| Not reading AI output | Review like a junior's code |
| Outdated CLAUDE.md | Review quarterly (see Config Evolution guide) |

---

# Guardrails Recap

### Non-Negotiable (MUST)
- Run tests before committing
- Never commit secrets
- Verify before claiming done
- Review AI-generated code

### Strong Recommendations (SHOULD)
- Use conventional commits
- Add tests for new features
- Document complex logic

---

# Resources

| Topic | Location |
|-------|----------|
| CLAUDE.md patterns | `04-configuration/ai-tools/claude-code.md` |
| MCP overview | `04-configuration/mcp/overview.md` |
| MCP servers | `04-configuration/mcp/servers.md` |
| Superpowers plugin | `04-configuration/plugins/superpowers.md` |
| MUST/SHOULD rules | `05-guardrails/` |

---

# Get Help

### Stuck?
- Check the docs in `04-configuration/`
- Open a GitHub Issue on the repo
- Reach out on Slack

### Want to Contribute?
- Fork the repo
- Submit a PR
- All contributions welcome

---

<!-- _class: lead -->
<!-- _paginate: false -->

# Start Now

```bash
# 1. Clone your team's workspace repo
git clone github.com/your-team/workspace

# 2. Run the bootstrap script
cd workspace && ./init.sh

# 3. Start working
claude
```

**You're ready to go.**
