# Workspace Setup

## Overview

AI-first development works best with a well-organized workspace. A **workspace** is a parent directory containing one or more related repositories, with shared AI configuration that provides context across all contained projects.

This guide covers two approaches:

- **Simple workspace** - A manually created directory with cloned repos and hand-written configuration files. Good for small teams, solo projects, or getting started quickly.
- **Workspace repository** - A dedicated Git repo that automates the entire developer environment setup through a bootstrap script. The mature pattern for teams with many repos, complex tooling, or frequent onboarding.

Both approaches produce the same result - a directory where AI assistants have shared context across projects. The workspace repository just automates what you would otherwise do by hand.

## Directory Structure

### Simple Workspace

A manually assembled workspace with repos cloned side by side:

```
~/projects/my-workspace/          # Workspace root
├── CLAUDE.md                     # Workspace-level AI configuration
├── .mcp.json                     # MCP server configuration
├── .cursorrules                  # Cursor rules (if using Cursor)
│
├── frontend/                     # Repository 1
│   ├── CLAUDE.md                 # Project-specific overrides
│   ├── package.json
│   └── src/
│
├── backend/                      # Repository 2
│   ├── CLAUDE.md                 # Project-specific overrides
│   ├── pyproject.toml
│   └── src/
│
├── infrastructure/               # Repository 3
│   ├── CLAUDE.md                 # Project-specific overrides
│   └── terraform/
│
└── docs/                         # Documentation repository
    ├── specs/                    # Design specifications
    ├── decisions/                # Architecture Decision Records
    └── runbooks/                 # Operational procedures
```

### Workspace Repository

A Git repo that contains automation, configuration, and reference docs - plus the cloned sub-repos:

```
~/projects/my-workspace/          # Workspace repo root
├── init.sh                       # Bootstrap script (idempotent)
├── mani.yaml                     # Repo manifest with tags
├── CLAUDE.md                     # Workspace AI config (@imports sub-repo configs)
├── AGENTS.md                     # Cross-tool agent conventions
├── .mcp.json                     # Generated MCP config (gitignored)
├── .mcp.json.template            # MCP config with secret placeholders
├── skills.yaml                   # Skills manifest
│
├── .claude/
│   ├── settings.json             # Shared tool permissions
│   └── agents/                   # Agent definitions
│       ├── senior-engineer.md    # Role-based agent
│       ├── qa.md                 # Role-based agent
│       └── sre.md                # Role-based agent
│
├── docs/                         # Reference docs (@imported into CLAUDE.md)
│   ├── reference-tools.md        # Tool routing tables
│   ├── reference-observability.md
│   └── reference-deploy.md
│
├── frontend/                     # Cloned by init.sh
│   └── CLAUDE.md
├── backend/                      # Cloned by init.sh
│   └── CLAUDE.md
└── infrastructure/               # Cloned by init.sh
    └── CLAUDE.md
```

### Why This Structure?

1. **Shared configuration** - Workspace CLAUDE.md applies to all projects
2. **Cross-repo awareness** - AI can reference other repos when helpful
3. **Centralized docs** - Specs and decisions in one searchable location
4. **Clear boundaries** - Each repo remains independently deployable
5. **Reproducible setup** - New team members run one script instead of following a wiki page

## Configuration Hierarchy

AI configuration follows a hierarchy with inheritance:

```
~/.claude/CLAUDE.md                   # Global (user-level) defaults
    ↓
workspace/CLAUDE.md                   # Workspace-wide rules
    ↓  (can @import reference docs and sub-repo CLAUDE.md files)
workspace/project/CLAUDE.md           # Project-specific overrides
```

Lower levels can:
- **Add** new rules and context
- **Override** specific settings from parent levels
- **Reference** other projects in the workspace

### The @import Pattern

Workspace repositories use `@import` directives to pull reference docs and sub-repo configurations into the workspace CLAUDE.md:

```markdown
# My Workspace

@import docs/reference-tools.md
@import docs/reference-observability.md
@import frontend/CLAUDE.md
@import backend/CLAUDE.md
```

This keeps each concern in its own file while giving the AI assistant a unified view. Reference docs can be detailed (tool routing tables, query patterns, auth flows) without cluttering the main CLAUDE.md.

### Agent Definitions

The `.claude/agents/` directory contains role-based and service-specific agent definitions. These let team members invoke specialized agent behaviors:

```markdown
# .claude/agents/sre.md
You are an SRE investigating a production issue.
Focus on observability, logs, and metrics.
MUST check dashboards before suggesting code changes.
```

Agent definitions complement `AGENTS.md` (the cross-tool universal entry point) by providing Claude Code-specific agent roles that encode team workflows.

## Multi-Repo Coordination

### Workspace CLAUDE.md Pattern

```markdown
# My Workspace

## Projects

- **frontend/** - React application (Node 20, pnpm)
- **backend/** - Python API (3.11, FastAPI)
- **infrastructure/** - Terraform (AWS)

## Cross-Project Rules

- API changes require updating both frontend and backend
- Infrastructure changes require approval before apply
- All PRs need passing CI before merge

## Shared Conventions

- Branch naming: `feature/JIRA-123-description`
- Commit messages: Conventional Commits format
- PR titles: `[PROJECT] Brief description`
```

### Repo Manifest with mani

Workspace repositories use a **repo manifest** (`mani.yaml`) to declare all repos and organize them with tags:

```yaml
projects:
  frontend:
    url: git@github.com:org/frontend.git
    tags: [core, nodejs]

  backend:
    url: git@github.com:org/backend.git
    tags: [core, python]

  infrastructure:
    url: git@github.com:org/infrastructure.git
    tags: [infra]

  data-pipeline:
    url: git@github.com:org/data-pipeline.git
    tags: [extra, python]
```

[mani](https://manicli.com) enables cross-repo commands using tags:

```bash
# Check outdated dependencies across all Node.js repos
mani exec --tags nodejs 'npm outdated'

# Run tests across all core repos
mani exec --tags core 'npm test'

# Pull latest changes across everything
mani exec 'git pull'
```

Tags also serve as documentation - they tell AI assistants which repos belong together and what role each plays.

### Working Across Repos

When AI needs to coordinate changes across repositories:

1. **Plan first** - Use plan mode to outline changes in each repo
2. **Order matters** - Typically: API contract -> Backend -> Frontend -> Infra
3. **Link PRs** - Reference related PRs in each PR description
4. **Test integration** - Verify components work together before merge

## The Workspace Repository Pattern

A workspace repository is a Git repo dedicated to automating developer environment setup. Instead of a wiki page with manual steps, the workspace repo encodes the entire setup as code.

### Components

A mature workspace repository contains up to seven components:

#### 1. Bootstrap Script

The `init.sh` script is the single entry point for setting up a development environment. It MUST be **idempotent** - running it twice produces the same result as running it once.

Typical phases:
1. Install prerequisites (git, gh, mise, mani)
2. Configure SSH for multi-org GitHub access
3. Pin runtimes (Node.js, Python) via mise
4. Clone repos by group using mani
5. Install dependencies across repos
6. Resolve secrets from 1Password/Vault/.env into `.mcp.json`
7. Install AI skills
8. Generate IDE workspace file
9. Verify setup with health checks

Each phase SHOULD print its status and skip work that is already done.

#### 2. Repo Manifest

The `mani.yaml` file is the declarative inventory of all repos the team works with. Tags group repos by function (core, infra, ui, deploy) and technology (nodejs, python). See [Repo Manifest with mani](#repo-manifest-with-mani) above.

#### 3. AI Configuration

Three layers of AI configuration:

| File | Purpose | Recognized By |
|------|---------|---------------|
| `CLAUDE.md` | Claude-specific rules, `@import` directives | Claude Code |
| `AGENTS.md` | Universal agent conventions | Codex, Cursor, Gemini CLI, Goose, and others |
| `.claude/agents/*.md` | Role-based agent definitions | Claude Code |

See [Cross-Tool Configuration](../04-configuration/cross-tool-setup.md) for details on the AGENTS.md standard.

#### 4. MCP Configuration

MCP server configuration follows a template pattern:

- `.mcp.json.template` - Checked into Git, contains secret placeholders like `${JIRA_TOKEN}`
- `.mcp.json` - Generated by the bootstrap script, contains resolved secrets, gitignored

This lets teams share MCP server configuration without committing secrets. The bootstrap script resolves placeholders from 1Password, Vault, or local `.env` files.

See [MCP Overview](../04-configuration/mcp/overview.md) for server configuration details.

#### 5. Skills Ecosystem

A `skills.yaml` manifest pulls skills from multiple sources:

```yaml
skills:
  - source: github:adobe/experience-success-skills
    path: skills/
  - source: github:org/internal-skills
    path: skills/
  - source: local:./skills
```

Skills are portable instruction packages that work across AI tools. See [Agent Skills Ecosystem](../04-configuration/skills/overview.md) for the SKILL.md format and package management.

#### 6. Reference Docs

The `docs/` directory contains operational reference files that get `@import`ed into CLAUDE.md:

- Tool routing tables (which MCP server handles which GitHub org)
- Observability query patterns (Coralogix DataPrime, Splunk SPL)
- Deployment procedures
- Auth flows and SSO configuration
- Cloud provider notes

These files are detailed and specific. Keeping them separate from CLAUDE.md prevents the main config from becoming unwieldy while still making the information available to AI assistants.

#### 7. IDE Integration

The bootstrap script generates a VS Code workspace file (`.code-workspace`) covering all cloned repos. This gives developers a single "Open Workspace" action that loads every project with correct settings.

## Reference Implementation

> **Concrete example:** The Mysticat team maintains `adobe/mysticat-workspace` as a workspace repository implementing all seven components described above. Teams can study it as a reference or fork it as a starting point for their own workspace repo.

## Shareable Workspace Documentation

Beyond CLAUDE.md, effective workspaces include structured documentation that gives AI assistants deep project understanding. These files live at the workspace root alongside CLAUDE.md.

### Recommended Workspace Documents

| File | Purpose | When to create |
|------|---------|---------------|
| CLAUDE.md | Rules, conventions, defaults | Always |
| AGENTS.md | Universal agent entry point (cross-tool) | When team uses multiple AI tools |
| ARCHITECTURE.md | System topology, dependencies, data flow | Multi-service systems |
| TESTING.md | Test frameworks, patterns, per-repo testing guide | When test approaches vary across repos |
| USE_CASES.md | Step-by-step cross-repo workflows | When common tasks span multiple repos |

### ARCHITECTURE.md Pattern

An architecture document gives AI assistants the structural awareness needed for cross-repo work:

- **System topology** - which services talk to which
- **Dependency graph** - which repos depend on which
- **Persistence layer** - databases, queues, caches
- **API contracts** between services
- **ASCII or Mermaid diagrams** for visual topology

### TESTING.md Pattern

A testing document eliminates guesswork about how to validate changes:

- **Per-repo testing frameworks and commands** (e.g., Jest in frontend, pytest in backend)
- **Test patterns** - unit, integration, e2e, and when to use each
- **What to test for new features** - a checklist AI can follow

### USE_CASES.md Pattern

A use-cases document captures the cross-repo workflows that are hardest to discover:

- Common cross-repo workflows as step-by-step guides
- Example: "Adding a new API endpoint" - which repos to touch, in what order
- Example: "Adding a new data pipeline" - configuration, worker, reporting changes

### Example

```markdown
# Architecture

## System Topology

Frontend (React) --> API Gateway (Express)
                        |
                  +-----+-----+
                  |           |
              Auth Service  Worker Service
                  |           |
              PostgreSQL    SQS --> S3
```

### Maintenance

- **Update when architecture changes** - stale diagrams cause incorrect assumptions
- **Review quarterly** for accuracy
- AI assistants reference these files automatically when planning cross-repo work

## Initial Setup Checklist

### Option A: Workspace Repository (Recommended)

If your team has a workspace repository:

```bash
# 1. Clone the workspace repo
git clone git@github.com:org/my-workspace.git
cd my-workspace

# 2. Run the bootstrap script
./init.sh

# 3. Verify setup
# The bootstrap script runs health checks automatically.
# You should see status output for each phase.
```

That is it. The bootstrap script handles cloning repos, installing dependencies, configuring MCP servers, resolving secrets, and generating IDE workspace files.

### Option B: Manual Setup

For teams without a workspace repository:

#### 1. Create Workspace Directory

```bash
mkdir -p ~/projects/my-workspace
cd ~/projects/my-workspace
```

#### 2. Clone Repositories

```bash
git clone git@github.com:org/frontend.git
git clone git@github.com:org/backend.git
git clone git@github.com:org/infrastructure.git
```

#### 3. Create Workspace Configuration

```bash
# Create workspace CLAUDE.md
cat > CLAUDE.md << 'EOF'
# My Workspace

## Projects
- frontend/ - React application
- backend/ - Python API
- infrastructure/ - Terraform

## Rules
- Never commit secrets
- Always run tests before committing
EOF
```

#### 4. Create MCP Configuration (if using MCP servers)

```bash
# Create .mcp.json for external tool access
cat > .mcp.json << 'EOF'
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["--python=3.12", "mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://jira.example.com",
        "JIRA_PERSONAL_TOKEN": "${JIRA_PERSONAL_TOKEN}"
      }
    }
  }
}
EOF
```

#### 5. Initialize Docs Repository (optional)

```bash
mkdir -p docs/{specs,decisions,runbooks}
# Add templates from 03-templates/
```

## Workspace Maintenance

### Regular Tasks

- **Update CLAUDE.md** when conventions change
- **Archive old specs** by moving to `specs/archive/`
- **Review decisions** periodically for relevance
- **Sync configurations** when adding new projects

### Adding a New Project

For workspace repositories:
1. Add the repo to `mani.yaml` with appropriate tags
2. Re-run `./init.sh` (idempotent - only clones new repos)
3. Add `@import` to workspace CLAUDE.md if the repo has its own CLAUDE.md

For manual workspaces:
1. Clone into workspace directory
2. Create project-level CLAUDE.md if needed
3. Update workspace CLAUDE.md project list
4. Verify AI can access and understand the new project

## See Also

- [Tools Checklist](tools-checklist.md) - Required CLI tools and authentication
- [Claude Code Configuration](../04-configuration/ai-tools/claude-code.md) - Detailed CLAUDE.md patterns
- [Cross-Tool Configuration](../04-configuration/cross-tool-setup.md) - AGENTS.md, thin adapters, multi-tool config
- [Agent Skills Ecosystem](../04-configuration/skills/overview.md) - SKILL.md format, package management
- [MCP Overview](../04-configuration/mcp/overview.md) - MCP server configuration
- [Environment & Secrets](../04-configuration/env-secrets.md) - Secret resolution patterns
- [Example Workspace CLAUDE.md](../examples/workspace-claude-md.md) - Complete example
