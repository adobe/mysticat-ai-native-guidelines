# Multi-Session and Multi-Agent Patterns

## Why This Matters

The standard [lifecycle](overview.md) assumes a single human-AI session: one conversation, one task, one branch. But as agent capabilities grow, teams increasingly run agents that work autonomously across multiple sessions - or run several agents in parallel on different parts of a feature.

Without deliberate patterns for state persistence, session handoff, and isolation, these workflows break down. Agents lose context between sessions, step on each other's work, or repeat tasks already completed. This document provides the patterns that prevent those failures.

## The Two-Agent Pattern

Complex features benefit from splitting the work between an **initializer agent** and one or more **coding agents**:

| Agent | Responsibility | Session Pattern |
|-------|---------------|-----------------|
| **Initializer** | Sets up the environment, creates scaffolding, writes the feature list, establishes the progress file | Runs once at the start of the feature |
| **Coding agent** | Implements features one at a time, updates progress, commits after each feature | Runs repeatedly until the feature list is complete |

The initializer agent creates the structure that makes subsequent coding sessions productive. Without it, each coding session wastes time re-discovering the codebase and re-deciding on architecture.

### When to Use This Pattern

**SHOULD use for:**
- Features that take more than one session to implement
- Work that will be distributed across multiple agents running in parallel
- Autonomous agent workflows where a human is not present for every session

**Skip for:**
- Single-session tasks (bug fixes, config changes, small features)
- Work where a human is actively pair-programming with the agent

## State Persistence

Agents have no memory between sessions. Every piece of state that matters must be written to a file that the next session can read.

### Feature Lists

Track what needs to be built in a machine-readable format. JSON works well because agents can parse it reliably:

```json
{
  "feature": "user-dashboard",
  "spec": "docs/specs/user-dashboard.md",
  "items": [
    { "id": "api-endpoints", "description": "REST endpoints for dashboard data", "status": "pass", "session": "2025-03-15-01" },
    { "id": "data-service", "description": "Service layer with caching", "status": "pass", "session": "2025-03-15-01" },
    { "id": "ui-components", "description": "React components for dashboard", "status": "in-progress", "session": "2025-03-15-02" },
    { "id": "e2e-tests", "description": "End-to-end browser tests", "status": "pending", "session": null },
    { "id": "monitoring", "description": "CloudWatch dashboard and alerts", "status": "pending", "session": null }
  ]
}
```

Rules for feature lists:
- **MUST** use explicit status values: `pending`, `in-progress`, `pass`, `fail`
- **SHOULD** record which session completed each item
- **SHOULD** include enough description that a new agent session can understand the task without reading the full spec
- **MUST NOT** mark an item as `pass` without running its verification (tests, linter, build)

### Progress Files

A progress file is a running log of what happened across sessions. Unlike a feature list (which tracks *what*), a progress file tracks *decisions, blockers, and context*:

```markdown
# Progress: User Dashboard

## Session 2025-03-15-01 (initializer)
- Created feature branch `feature/PROJ-456-user-dashboard`
- Scaffolded directory structure under `src/dashboard/`
- Wrote feature list: 5 items
- Ran init.sh - all dependencies installed, baseline tests pass
- Decision: using Redis for caching (memcached not available in staging)

## Session 2025-03-15-02 (coding)
- Completed: api-endpoints, data-service (both passing)
- Started: ui-components
- Blocker: design tokens not exported from shared package yet
- Workaround: hardcoded tokens with TODO, will update when shared package ships
- Next session should: finish ui-components, then start e2e-tests
```

Rules for progress files:
- **MUST** record decisions that future sessions need to understand
- **MUST** record blockers and workarounds
- **SHOULD** include explicit guidance for the next session
- **SHOULD NOT** duplicate information already in the feature list or commit history

### TODO.md as Machine-Readable Tracking

For simpler workflows, the existing [TODO.md template](../03-templates/TODO.md) works well. The key adaptation for multi-session use: treat TODO.md as the source of truth that every session reads at startup and updates before committing.

## Handoff Protocols

The boundary between sessions is a **git commit**. This is the handoff protocol:

### End-of-Session Protocol

Before ending a session, the agent MUST:

1. **Commit all work** - no uncommitted changes should remain
2. **Update the feature list** - mark completed items as `pass` or `fail`
3. **Update the progress file** - record decisions, blockers, and guidance for the next session
4. **Push to remote** - ensure the branch is up to date
5. **Run verification** - tests, linter, build must pass before ending

```bash
# End-of-session sequence
npm test                          # verify tests pass
npm run lint                      # verify no lint errors
git add -A
git commit -m "feat(dashboard): complete data service layer

Session: 2025-03-15-02
Features completed: api-endpoints, data-service
Next: ui-components"
git push origin feature/PROJ-456-user-dashboard
```

### Start-of-Session Protocol

When an agent begins a new session on an existing feature, it SHOULD follow this startup sequence:

1. **Orient** - `pwd`, verify correct repository and branch
2. **Read progress** - read the progress file for context and decisions
3. **Read feature list** - identify the next pending item
4. **Run init.sh** - ensure the environment is set up (dependencies, env vars)
5. **Run baseline tests** - verify the codebase is in a working state before making changes
6. **Begin work** - start on the next pending feature item

```markdown
## Startup Sequence (include in CLAUDE.md or agent instructions)

When resuming work on this feature:
1. Read `progress.md` for context and prior decisions
2. Read `features.json` and find the first `pending` item
3. Run `./init.sh` to set up the environment
4. Run `npm test` to verify baseline - if tests fail, fix before proceeding
5. Implement the next pending feature
6. After each feature: run tests, update features.json, update progress.md, commit
```

## Git Worktree Isolation

When running multiple agents in parallel, each agent MUST work in its own git worktree. Without isolation, agents overwrite each other's changes, create merge conflicts, and produce corrupted state.

### Why Worktrees

Git worktrees let you check out the same repository into multiple directories, each on a different branch. Each worktree has its own working tree and index, so agents can make changes simultaneously without interference.

```
project/                          # main worktree (human)
project-wt-api/                   # worktree for API agent
project-wt-ui/                    # worktree for UI agent
project-wt-tests/                 # worktree for test agent
```

### Setting Up Worktrees

```bash
# Create a worktree for each agent's work
git worktree add ../project-wt-api feature/PROJ-456-api
git worktree add ../project-wt-ui feature/PROJ-456-ui

# Each agent works in its own directory
# Agent 1: cd ../project-wt-api && <do work>
# Agent 2: cd ../project-wt-ui && <do work>

# Clean up when done
git worktree remove ../project-wt-api
git worktree remove ../project-wt-ui
```

### Rules for Parallel Agent Work

- **MUST** use one worktree per agent - never share a working directory
- **MUST** use separate branches per worktree
- **SHOULD** coordinate branches through a shared feature list or orchestrator
- **SHOULD** merge individual agent branches into a shared integration branch regularly
- **MUST NOT** have two agents working on the same file in parallel - split work at the file boundary

### Integration Pattern

When multiple agents work on different parts of a feature:

1. Create a shared integration branch: `feature/PROJ-456-dashboard`
2. Each agent works on a sub-branch: `feature/PROJ-456-dashboard-api`, `feature/PROJ-456-dashboard-ui`
3. Merge sub-branches into the integration branch as each completes
4. The integration branch gets the PR and human review

## Designing Work for Multi-Session Success

Not all tasks decompose naturally into multi-session workflows. The key design decision is **granularity**: each feature list item should be completable in a single session and independently verifiable.

### Good Decomposition

```json
[
  { "id": "data-model", "description": "Create TypeScript types and Zod schemas for dashboard data", "status": "pending" },
  { "id": "api-client", "description": "API client with caching, following existing pattern in src/api/", "status": "pending" },
  { "id": "summary-card", "description": "SummaryCard component with unit tests", "status": "pending" },
  { "id": "chart-widget", "description": "ChartWidget component with unit tests", "status": "pending" },
  { "id": "dashboard-page", "description": "Dashboard page composing SummaryCard + ChartWidget", "status": "pending" }
]
```

Each item is independently testable, references existing patterns, and has a clear scope.

### Bad Decomposition

```json
[
  { "id": "backend", "description": "Build the backend", "status": "pending" },
  { "id": "frontend", "description": "Build the frontend", "status": "pending" },
  { "id": "testing", "description": "Add tests", "status": "pending" }
]
```

Items are too broad for a single session, not independently verifiable, and "testing" as a separate item invites skipping tests during implementation.

### Rules of Thumb

- Each item SHOULD be completable in one agent session (roughly 15-30 minutes of agent work)
- Each item MUST have a verification step (test, lint, build, or visual check)
- Items SHOULD NOT have hidden dependencies on each other - if they do, make the dependency explicit in the feature list
- Items SHOULD reference existing patterns or files so the agent knows where to look

## Anti-Patterns

### The Amnesia Loop

**Pattern**: Each session starts from scratch because no state is persisted.

**Why it's bad**: The agent re-discovers the codebase, re-makes decisions, and may make different (contradictory) decisions each time. Work gets duplicated or undone.

**Better approach**: Use feature lists and progress files. The startup sequence reads state before doing anything.

### The Optimistic Checkmark

**Pattern**: An agent marks a feature as `pass` without actually running verification.

**Why it's bad**: Subsequent sessions assume the feature works and build on top of a broken foundation. The bug compounds across sessions until it is expensive to untangle.

**Better approach**: Enforce verification in CLAUDE.md rules: "MUST NOT mark a feature as pass without running `npm test` and confirming the relevant tests pass."

### The Shared Worktree

**Pattern**: Multiple agents work in the same directory, relying on "careful coordination."

**Why it's bad**: Race conditions on file writes, corrupted git index, merge conflicts inside uncommitted work. Debugging this state is harder than preventing it.

**Better approach**: One worktree per agent, always.

## See Also

- [Implementation Phase](03-implementation.md) - Single-session implementation workflow
- [Validation Phase](04-validation.md) - Verification patterns
- [TODO Template](../03-templates/TODO.md) - Simple task tracking
- [Harness Engineering](../01-foundations/harness-engineering.md) - The harness stack and environment audit mindset
- [Mechanical Enforcement](../05-guardrails/mechanical-enforcement.md) - Automated gates for agent workflows
