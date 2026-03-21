# What's New

Recent changes to the AI-First Development Guidelines, newest first. For the full history, see `git log`.

---

## 2026-03-21 - Harness Engineering and ACI Design

Added 4 new docs covering harness engineering concepts from the "Harness Is Everything" analysis (SWE-agent ACI research, Anthropic Claude Code harness, OpenAI Codex zero-manual-code experiment).

| Doc | Section | What it covers |
|-----|---------|----------------|
| [Harness Engineering](01-foundations/harness-engineering.md) | Foundations | Harness definition, 7-layer taxonomy, context management, environment audit mindset |
| [Multi-Session Patterns](02-lifecycle/multi-session-patterns.md) | Lifecycle | Two-agent pattern, state persistence, handoff protocols, git worktree isolation |
| [ACI Design](04-configuration/aci-design.md) | Configuration | Agent-Computer Interface principles, progressive disclosure, docs for agents, audit checklist |
| [Mechanical Enforcement](05-guardrails/mechanical-enforcement.md) | Guardrails | Automated gates over human review, agent-friendly errors, structural tests, throughput-aware merge |

Updated 12 existing docs with cross-references and navigation.

---

## 2026-03-21 - Workspace Repository Pattern

Rewrote [Workspace Setup](01-foundations/workspace-setup.md) to reflect the workspace repository pattern - dedicated Git repos that automate developer environment setup via bootstrap scripts, repo manifests, and shared AI configuration. Two tiers: simple workspace (manual) and workspace repository (automated). Reference implementation: `adobe/mysticat-workspace`.

Updated: [example CLAUDE.md](examples/workspace-claude-md.md) (modern patterns: @import, repo tags, MCP routing), [getting-started presentation](presentations/getting-started.md), [onboarding guide](06-adoption/onboarding-guide.md).

---

## 2026-03-11 - Cross-Tool Skills Ecosystem

Added [Skills Ecosystem](04-configuration/skills/overview.md) covering the agentskills.io standard, SKILL.md format, three-tier progressive disclosure, and package management. Added [Cross-Tool Setup](04-configuration/cross-tool-setup.md) with AGENTS.md as universal entry point and thin adapter pattern.

---

## 2026-03-02 - Tool Permissions Guide

Added Claude Code [settings.json permissions guide](04-configuration/ai-tools/claude-code.md) covering allowlist/denylist patterns, MCP tool permissions, and hook configuration.

---

## 2026-02-20 - Codex MCP Configuration

Clarified MCP configuration for Codex environments. Fixed `@latest` references in npx MCP server package commands.

---

## 2026-02-16 - AI-First Patterns from ASO UI Team

Incorporated battle-tested patterns from the ASO UI team's PR #1560, covering real-world AI-first development workflows.

---

## 2026-02-11 - Initial Release

Initial commit of AI-first development guidelines: philosophy, 5-phase lifecycle, templates, configuration guides, guardrails, adoption guides, and leadership docs.
