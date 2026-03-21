# Example: Workspace CLAUDE.md

This is an example of a workspace-level CLAUDE.md that provides shared context and rules across multiple projects. It demonstrates the workspace repository pattern - a dedicated repo that acts as the control plane for your AI-assisted development environment.

Copy the content below (everything after the horizontal rule) and adapt it for your team.

---

# Acme Platform Workspace

AI-native workspace for the Acme Platform team.

@import docs/reference/api-conventions.md
@import docs/reference/database-patterns.md
@import docs/reference/observability.md
@import api-gateway/CLAUDE.md
@import user-service/CLAUDE.md
@import order-service/CLAUDE.md

## Repo Tags

Repos are organized with tags via [mani](https://manicli.com/) in `mani.yaml`. Use tags to target operations across related repos (e.g., `mani run test --tags core`).

- **core:** api-gateway, user-service, order-service, product-service, shared-types
- **ui:** web-app, admin-dashboard
- **infra:** infrastructure, deploy-configs
- **docs:** platform-docs (specs, ADRs, runbooks)
- **tools:** cli-tools, sdk-generator

## Workspace Rules

### MUST

- MUST work via Pull Requests for all code and infrastructure changes
- MUST create feature branches for all work - do not reuse branches
- MUST use `.mcp.json` in the workspace root for MCP server configuration - do not look outside the repo root
- MUST NOT commit `.mcp.json` directly - commit `.mcp.json.template` instead and let `init.sh` resolve secrets into `.mcp.json` (which is gitignored)
- MUST NOT commit secrets to any repository
- MUST run tests before committing
- MUST update API specs when endpoints change
- MUST NOT force-push to any shared branch

### SHOULD

- SHOULD follow conventional commits format
- SHOULD keep PRs under 400 lines changed
- SHOULD include ticket reference in branch name (e.g., `feature/ACME-123-add-payments`)
- SHOULD monitor CI/CD pipeline after pushing to a branch with a PR
- SHOULD prefer merge commits over rebasing when updating a pushed feature branch

## MCP Routing

| GitHub Org | MCP Server | Notes |
|------------|------------|-------|
| `github.com` personal/open-source (e.g. `acme/platform-*`) | `mcp__github__*` | Default for personal repos |
| `github.com` AcmeCorp EMU org | `mcp__acme-github__*` | Managed org, requires EMU token |
| `git.corp.acme.com` | `mcp__github-enterprise__*` | On-prem GitHub Enterprise |

### gh CLI Notes

- `gh` CLI is authenticated as personal account - cannot access AcmeCorp org repos directly
- For AcmeCorp operations MCP doesn't support, extract token from `.mcp.json` headers and pass as `GH_TOKEN`
- Prefer MCP servers over `gh` CLI for all GitHub operations
- Reserve `gh` CLI for operations MCP doesn't support (run rerun/watch, release create)

## Common Tasks

### Jira

- Default project: ACME
- Current epic: ACME-500 (Payment system overhaul)
- Default issue type: Task
- Default components: Platform, Payments
- Link issue to epic: `jira_update_issue` with `additional_fields={"customfield_11800": "EPIC-KEY"}`
- Link PR to issue: `jira_create_remote_issue_link` + clickable wiki markup `[PR #123|https://url]`

### API Base URLs

- Dev (CI): `https://api.acme-dev.example.com/ci/`
- Dev (main): `https://api.acme-dev.example.com/v1/`
- Staging: `https://api.acme-staging.example.com/v1/`
- Admin API key: `$ACME_API_KEY` env var, passed as `x-api-key` header

### Auth Patterns

- IMS tokens: `acme-cli auth token --ims` (requires `acme-cli login` first)
- AWS login: `klam login`
- Vault login requires MFA push notification

### Database Migrations

1. Create migration in the owning service
2. Test migration on staging database
3. Have DBA review production migrations
4. Schedule deployment during low-traffic window

## Working Context

Defaults so the AI does not ask every time.

| System | Default | Override with |
|--------|---------|---------------|
| Jira | ACME project | "in PLATFORM" |
| GitHub | acme/platform | "-R acme/infrastructure" |
| AWS | staging profile | "in prod" |
| Database | staging environment | "query prod" |
| Slack | #platform-dev channel | "in #platform-alerts" |
| Monitoring | staging dashboard | "check prod" |

## Environment Setup

### Bootstrap

The bootstrap script is idempotent - safe to re-run at any time:

```bash
./init.sh    # clones repos, installs dependencies, resolves secrets into .mcp.json
```

### Runtime Pinning

This workspace uses [mise](https://mise.jdx.dev/) for runtime version management:

```bash
mise install   # installs pinned versions from .mise.toml
```

Required runtimes (pinned in `.mise.toml`):
- Node.js 20
- Python 3.12
- Go 1.22
- Terraform 1.7

### Local Development

```bash
# Start all services locally
docker-compose up -d

# Or start specific services
docker-compose up -d postgres redis
cd user-service && make run
cd web-app && pnpm dev
```

## Agents and Skills

Agent definitions live in `.claude/agents/`. Skills are declared in `skills.yaml` at the workspace root. See `AGENTS.md` for the cross-tool agent entry point.

### Agents

- **deploy-checker** (`.claude/agents/deploy-checker.md`) - Verifies deployment health after releases
- **spec-reviewer** (`.claude/agents/spec-reviewer.md`) - Reviews design specs against architecture standards
- **migration-validator** (`.claude/agents/migration-validator.md`) - Validates database migrations before merge

### Skills

Registered in `skills.yaml`:

- `/deploy-staging` - Deploy current branch to staging environment
- `/run-integration` - Run cross-service integration tests
- `/create-migration` - Scaffold a new database migration with proper naming

## Cross-Project Coordination

### API Changes

When modifying APIs:
1. Update the spec in `platform-docs/specs/api/`
2. Modify the producing service
3. Update the API Gateway if needed
4. Update all consuming services
5. Update client SDKs if applicable

### Shared Types

TypeScript types shared between services:
- Location: `shared-types/`
- Update version when making changes
- All services must update to same version

## Monitoring

### Dashboards

- [Production Dashboard](https://monitoring.acme.example.com/prod)
- [Staging Dashboard](https://monitoring.acme.example.com/staging)
- [CI/CD Pipeline](https://github.com/acme/platform/actions)

### Alerts

Critical alerts go to #platform-alerts Slack channel.
- P1: Page on-call immediately
- P2: Respond within 1 hour
- P3: Address next business day

---

*This CLAUDE.md lives in a workspace repository - a dedicated Git repo that acts as the parent directory for all related project repos. The workspace repository contains `init.sh` (bootstrap), `mani.yaml` (repo manifest with tags), `CLAUDE.md` (AI config with `@import`), `AGENTS.md` (cross-tool agent entry point), `.mcp.json.template` (MCP config), `skills.yaml` (skills manifest), and reference docs. Each sub-repo has its own CLAUDE.md for project-specific rules. See [Workspace Setup](../01-foundations/workspace-setup.md) for the full pattern.*
