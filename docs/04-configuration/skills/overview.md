# Agent Skills Ecosystem

## Overview

Skills are portable, version-controlled packages of instructions for AI coding agents. Rather than locking teams into a single tool's extension format, the skills ecosystem provides a standard that works across 30+ agent products - including Claude Code, Cursor, Copilot, Codex, Gemini CLI, Goose, and Roo Code.

A skill is a directory containing a `SKILL.md` file with YAML frontmatter and markdown instructions. The format is defined by [agentskills.io](https://agentskills.io), an open standard maintained by the community with adoption across the major agent platforms.

This page covers the standard itself, where skills live, how they load efficiently, package management, and Adobe's skills in the ecosystem. For configuring multiple AI tools to share skills and other configuration, see [Cross-Tool Configuration](../cross-tool-setup.md).

## The SKILL.md Format

Every skill is a directory containing a `SKILL.md` file. The file has two parts: YAML frontmatter for metadata and a markdown body for instructions.

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier, max 64 chars, lowercase with hyphens (e.g., `test-driven-development`) |
| `description` | Yes | What the skill does and when to use it, max 1024 chars |
| `license` | No | SPDX license identifier (e.g., `MIT`, `Apache-2.0`) |
| `compatibility` | No | List of compatible agent products |
| `metadata` | No | Arbitrary key-value pairs for categorization |
| `allowed-tools` | No | List of tools the skill may invoke |

### Example SKILL.md

```markdown
---
name: code-review
description: >
  Performs structured code review with security, performance,
  and maintainability checks. Activate when reviewing PRs
  or before committing changes.
license: MIT
compatibility:
  - claude-code
  - cursor
  - codex
---

## Process

1. Read all changed files
2. Check for security issues (injection, secrets, auth)
3. Check for performance regressions
4. Verify error handling is comprehensive
5. Summarize findings with severity levels

## Output Format

Use a table with columns: File, Line, Severity, Finding.

## References

See references/review-checklist.md for the full checklist.
```

### Optional Subdirectories

A skill directory can include supporting files beyond `SKILL.md`:

```
my-skill/
  SKILL.md              # Required - frontmatter + instructions
  scripts/              # Executable scripts the skill can invoke
  references/           # Supporting documentation, checklists, examples
  assets/               # Static files (templates, schemas, configs)
  evals/                # Test cases for validating skill behavior
```

These subdirectories follow a convention, not a strict schema. Agents load them on demand (see Progressive Disclosure below).

## Directory Conventions

Skills can live at two scopes (project and user) and in two path families (cross-agent and agent-specific). Project-level paths take precedence over user-level paths, and agent-specific paths take precedence over cross-agent paths.

### Scope and Path Matrix

| Scope | Cross-Agent Path | Agent-Specific Path |
|-------|-------------------|---------------------|
| Project | `.agents/skills/` | `.<agent>/skills/` (e.g., `.claude/skills/`) |
| User | `~/.agents/skills/` | `~/.<agent>/skills/` (e.g., `~/.claude/skills/`) |

### Precedence Order (highest to lowest)

1. Project `.<agent>/skills/` - agent-specific, project-level
2. Project `.agents/skills/` - cross-agent, project-level
3. User `~/.<agent>/skills/` - agent-specific, user-level
4. User `~/.agents/skills/` - cross-agent, user-level

### Recommendations

- **SHOULD** use `.agents/skills/` for skills that work across all tools
- **SHOULD** use `.<agent>/skills/` only for skills with agent-specific features (e.g., Claude-only tool references)
- **SHOULD** commit project-level skills to version control so the whole team benefits
- **MUST NOT** store secrets in skill files - use environment variable references instead

## Progressive Disclosure (Three-Tier Loading)

Skills use a three-tier loading model to keep context windows small. Installing 20 skills does not cost 20x the tokens upfront.

### Tier 1: Catalog (Session Start)

At session start, the agent loads only the `name` and `description` from each installed skill's frontmatter. This costs roughly 50-100 tokens per skill, so even a large collection stays lightweight.

```
Loaded at session start:
  code-review: "Performs structured code review..."
  tdd: "Test-driven development with RED-GREEN-REFACTOR..."
  db-migration: "Safe database migration workflow..."
```

### Tier 2: Instructions (On Activation)

When a skill is activated - either by the agent matching a request to a skill description, or by the user invoking it explicitly - the full `SKILL.md` body is loaded into context. The agentskills.io standard recommends keeping the body under 5,000 tokens.

```
User: "Review this PR before I merge"

Agent loads: code-review/SKILL.md body (~2,000 tokens)
Agent follows: the review process defined in the skill
```

### Tier 3: Resources (On Reference)

Scripts, reference docs, and assets are loaded only when the skill's instructions reference them. A skill that says "See references/checklist.md" triggers loading of that file only when the agent reaches that instruction.

```
Skill instruction: "Use the checklist in references/review-checklist.md"

Agent loads: code-review/references/review-checklist.md (on demand)
```

### Why This Matters

| Tier | When Loaded | Token Cost | Example |
|------|-------------|------------|---------|
| Catalog | Session start | ~50-100/skill | Name + description |
| Instructions | On activation | <5,000/skill (recommended) | Full SKILL.md body |
| Resources | On reference | Varies | Scripts, checklists, templates |

A project with 20 installed skills costs roughly 1,000-2,000 tokens at session start (Tier 1 only). Without progressive disclosure, the same 20 skills would consume 100,000+ tokens upfront.

## Package Management with `npx skills`

The `skills` CLI (by Vercel Labs) provides package management for the agentskills.io ecosystem. It handles installing, listing, discovering, and initializing skills.

### Key Commands

| Command | Description |
|---------|-------------|
| `npx skills add <source>` | Install a skill from GitHub, URL, or local path |
| `npx skills list` | List installed skills |
| `npx skills find <query>` | Search for skills in the marketplace |
| `npx skills init` | Create a new skill from a template |

### Installation Sources

The `add` command accepts multiple source formats:

```bash
# GitHub shorthand (owner/repo)
npx skills add obra/superpowers

# GitHub URL with path to specific skill
npx skills add https://github.com/adobe/skills/tree/main/skills/aem/edge-delivery-services

# Specific skills from a collection
npx skills add adobe/skills -s content-driven-development building-blocks

# All skills from a collection
npx skills add adobe/skills --all

# Local path
npx skills add ./my-local-skills/code-review
```

### Scope

By default, `npx skills add` installs to the project-level directory (`./<agent>/skills/`). Use the `-g` flag for user-level installation:

```bash
# Project scope (default) - goes into ./<agent>/skills/
npx skills add obra/superpowers

# Global scope - goes into ~/.<agent>/skills/
npx skills add -g obra/superpowers
```

### Marketplace

The skills marketplace at [skills.sh](https://skills.sh) provides a browsable catalog of community-published skills. Use `npx skills find` to search from the command line:

```bash
# Search by keyword
npx skills find "code review"
npx skills find "testing"
npx skills find "database migration"
```

## Adobe Skills in the Ecosystem

Two Adobe skill collections follow the SKILL.md standard:

### Superpowers (obra/superpowers)

A complete development workflow built on composable skills - brainstorming, planning, TDD, debugging, and verification. Originally created for Claude Code, now portable via the agentskills.io standard.

Key skills: `brainstorming`, `writing-plans`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`

See [Superpowers Plugin](../plugins/superpowers.md) for full documentation.

### Adobe Skills (adobe/skills)

AI agent skills for AEM Edge Delivery Services - block development, content modeling, migration, and discovery. Provides 17 specialized skills organized into core development, discovery, and migration categories.

Key skills: `content-driven-development`, `building-blocks`, `page-import`, `block-inventory`

See [Adobe Skills](../plugins/adobe-skills.md) for full documentation.

### Installation

Both collections support multiple install methods:

```bash
# Superpowers via npx skills
npx skills add obra/superpowers

# Adobe Skills via npx skills
npx skills add adobe/skills -s content-driven-development building-blocks

# Adobe Skills via Claude Code plugins
/plugin marketplace add adobe/skills

# Adobe Skills via GitHub CLI extension
gh extension install trieloff/gh-upskill
gh upskill adobe/skills
```

## Best Practices

### Authoring Skills

- **SHOULD** keep `SKILL.md` under 500 lines - put detailed reference material in `references/`
- **SHOULD** use relative paths for file references within the skill directory
- **SHOULD** write a clear, specific `description` in frontmatter - this is what agents use to decide when to activate the skill
- **MUST** make scripts non-interactive - they run in agent contexts without user prompts
- **SHOULD** have scripts support `--help` and use structured output (JSON or tables)
- **SHOULD** include an `evals/` directory with test cases for non-trivial skills

### Organizing Skills

- **SHOULD** prefer `.agents/skills/` over `.<agent>/skills/` for cross-tool portability
- **SHOULD** commit project-level skills to version control
- **SHOULD** use `npx skills` for managing third-party skills rather than manual `git clone`
- **MUST NOT** duplicate skills across `.agents/skills/` and `.<agent>/skills/` - pick one location

### Performance

- **SHOULD** keep the Tier 2 body under 5,000 tokens to avoid bloating context on activation
- **SHOULD** move large reference material (checklists, schemas, examples) to `references/` so it loads only when needed (Tier 3)
- **SHOULD** use specific `description` text so agents activate the right skill without trial and error

## See Also

- [ACI Design](../aci-design.md) - Progressive disclosure as a general harness pattern (beyond skills)
- [Cross-Tool Configuration](../cross-tool-setup.md) - Setting up AGENTS.md, multi-tool configs, and shared skills directories
- [Superpowers Plugin](../plugins/superpowers.md) - Development workflow skills
- [Adobe Skills](../plugins/adobe-skills.md) - AEM Edge Delivery Services skills
- [Plugins Overview](../plugins/README.md) - Plugin vs skill vs MCP comparison
- [agentskills.io](https://agentskills.io) - The open standard specification
- [skills.sh](https://skills.sh) - Skills marketplace
