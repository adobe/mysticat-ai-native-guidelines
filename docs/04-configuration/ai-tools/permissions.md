# Tool Permissions

## Overview

Claude Code prompts for approval before executing tools - reading files, running shell commands, editing code, calling MCP servers. This is safe by default, but the constant "yes/no" flow becomes a bottleneck. A developer approving 50+ tool calls per session loses focus and starts rubber-stamping - the opposite of safe.

The permission system in `settings.json` lets you declare allowlists and denylists so Claude auto-approves routine operations and blocks dangerous ones. The result: fewer interruptions, faster flow, and stronger guardrails than manual approval.

## Settings Hierarchy

Permissions are configured in `settings.json` files at three levels:

| Scope | Location | Who it affects | Shared? |
|-------|----------|----------------|---------|
| Global | `~/.claude/settings.json` | You, across all projects | No |
| Project | `.claude/settings.json` | All team members | Yes (committed to git) |
| Local | `.claude/settings.local.json` | You, this repo only | No (gitignored) |

Rules merge across levels. Use global settings for personal workflow preferences, project settings for team standards, and local settings for machine-specific overrides.

## Rule Format

Rules live in `permissions.allow`, `permissions.deny`, and `permissions.ask` arrays:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Bash(git status *)",
      "mcp__splunk__search_splunk"
    ],
    "deny": [
      "Bash(rm -rf *)"
    ]
  }
}
```

### Syntax

| Pattern | Matches |
|---------|---------|
| `Read` | All file reads (no specifier = match all uses) |
| `Bash(git status *)` | Any bash command starting with `git status ` |
| `Bash(git status)` | Bare `git status` with no arguments |
| `Bash(ls)` | Bare `ls` only |
| `Bash(ls *)` | `ls` with any arguments |
| `mcp__splunk` | All tools from the splunk MCP server |
| `mcp__splunk__search_splunk` | One specific MCP tool |

The `*` wildcard matches any characters after the preceding text. Note the space before `*` matters: `Bash(git *)` matches `git status`, `git log`, etc. `Bash(git*)` would also match `gitk` (no word boundary).

### Evaluation Order

Rules are evaluated: **deny > ask > allow**. The first matching rule wins.

This means you can use broad allow patterns with targeted deny overrides:

```json
{
  "permissions": {
    "allow": ["Bash(git *)"],
    "deny": ["Bash(git push --force *)"]
  }
}
```

Here `git push --force main` is blocked even though `Bash(git *)` would allow it - deny takes priority.

## Strategy: Categorize by Risk

The key insight is to categorize tools by risk, not by individual command. Most tool calls fall into predictable categories:

### Tier 1: Always Allow (Read/Explore)

Operations that only read state. No side effects, fully reversible (there's nothing to reverse).

```json
"allow": [
  "Read",
  "Glob",
  "Grep",
  "WebFetch",
  "WebSearch"
]
```

### Tier 2: Allow with Deny Guardrails (Write/Execute)

Operations that modify local state. Generally safe, but a few specific commands are dangerous. Allow the category broadly, deny the exceptions.

```json
"allow": [
  "Edit",
  "Write",
  "Bash(git *)",
  "Bash(npm *)",
  "Bash(terraform *)"
],
"deny": [
  "Bash(git push --force *)",
  "Bash(git push --force)",
  "Bash(git push --force-with-lease *)",
  "Bash(git push --force-with-lease)",
  "Bash(git push -f *)",
  "Bash(git push -f)",
  "Bash(git reset --hard *)",
  "Bash(git reset --hard)",
  "Bash(rm -rf *)",
  "Bash(rm -r *)"
]
```

### Tier 3: Allow Selectively (MCP Tools)

MCP servers mix read and write operations under one umbrella. A single `mcp__github` server contains both `list_issues` (harmless) and `create_pull_request` (consequential). Whitelist read operations individually; leave write operations to prompt.

```json
"allow": [
  "mcp__splunk",

  "mcp__github__get_file_contents",
  "mcp__github__list_pull_requests",
  "mcp__github__search_code",
  "mcp__github__pull_request_read",
  "mcp__github__issue_read"
]
```

### Tier 4: Always Prompt (Unallowlisted)

Anything not in `allow` still prompts. This is your safety net for:

- MCP write operations (creating issues, posting comments, merging PRs)
- Database queries (arbitrary SQL through postgres MCP tools)
- Unfamiliar CLI tools
- Operations against shared infrastructure

You don't need to list these anywhere - they prompt by default.

## MCP Permission Patterns

MCP tools need more thought than shell commands because they interact with shared external systems.

### All-Read Servers

Some MCP servers only expose read operations. Whitelist the entire server:

```json
"allow": [
  "mcp__splunk"
]
```

This covers `search_splunk`, `list_indexes`, `get_index_info`, `health_check`, and every other tool on that server.

### Mixed Servers

Most MCP servers have both read and write tools. Enumerate the read tools individually:

**GitHub** (applies to each GitHub MCP server you have configured):

```json
"allow": [
  "mcp__github__get_commit",
  "mcp__github__get_file_contents",
  "mcp__github__get_label",
  "mcp__github__get_latest_release",
  "mcp__github__get_me",
  "mcp__github__get_release_by_tag",
  "mcp__github__get_tag",
  "mcp__github__get_team_members",
  "mcp__github__get_teams",
  "mcp__github__issue_read",
  "mcp__github__list_branches",
  "mcp__github__list_commits",
  "mcp__github__list_issue_types",
  "mcp__github__list_issues",
  "mcp__github__list_pull_requests",
  "mcp__github__list_releases",
  "mcp__github__list_tags",
  "mcp__github__pull_request_read",
  "mcp__github__search_code",
  "mcp__github__search_issues",
  "mcp__github__search_pull_requests",
  "mcp__github__search_repositories",
  "mcp__github__search_users"
]
```

If you have multiple GitHub MCP servers (e.g., `github`, `github-enterprise`, an org-specific server), repeat the list with each server prefix.

**Atlassian (Jira + Confluence)**:

```json
"allow": [
  "mcp__mcp-atlassian__jira_get_issue",
  "mcp__mcp-atlassian__jira_search",
  "mcp__mcp-atlassian__jira_search_fields",
  "mcp__mcp-atlassian__jira_get_field_options",
  "mcp__mcp-atlassian__jira_get_project_issues",
  "mcp__mcp-atlassian__jira_get_transitions",
  "mcp__mcp-atlassian__jira_get_worklog",
  "mcp__mcp-atlassian__jira_get_agile_boards",
  "mcp__mcp-atlassian__jira_get_board_issues",
  "mcp__mcp-atlassian__jira_get_sprints_from_board",
  "mcp__mcp-atlassian__jira_get_sprint_issues",
  "mcp__mcp-atlassian__jira_get_all_projects",

  "mcp__mcp-atlassian__confluence_search",
  "mcp__mcp-atlassian__confluence_get_page",
  "mcp__mcp-atlassian__confluence_get_page_children",
  "mcp__mcp-atlassian__confluence_get_comments",
  "mcp__mcp-atlassian__confluence_get_labels",
  "mcp__mcp-atlassian__confluence_get_page_history"
]
```

### Dangerous MCP Tools

Some MCP tools warrant extra caution. Leave these out of allow lists (they'll prompt every time):

- **Database query tools** (`mcp__postgres__query`) - Accepts arbitrary SQL. A `SELECT` is fine; a `DROP TABLE` is not. The tool can't distinguish.
- **Deployment tools** (`mcp__flex__AddOrRemoveEnvironmentsInFlex`) - Modifies shared infrastructure.
- **Alert management** (`mcp__coralogix__create_alert`, `delete_alert`) - Changes team-wide monitoring.

## Deny Rules as Defense-in-Depth

Deny rules complement behavioral rules in CLAUDE.md. Your CLAUDE.md might say:

```markdown
- MUST NOT force-push to any branch
- MUST NOT commit directly to main/master
```

The AI follows these instructions, but deny rules add a hard block:

```json
"deny": [
  "Bash(git push --force *)",
  "Bash(git push --force)",
  "Bash(git push --force-with-lease *)",
  "Bash(git push --force-with-lease)",
  "Bash(git push -f *)",
  "Bash(git push -f)",
  "Bash(git reset --hard *)",
  "Bash(git reset --hard)",
  "Bash(git clean -f *)",
  "Bash(git clean -fd *)",
  "Bash(rm -rf *)",
  "Bash(rm -r *)"
]
```

Behavioral rules are advisory. Deny rules are enforced. Use both.

!!! note "Deny rules don't catch every permutation"
    A command like `git push origin main --force` has the flag at the end, not after `push`. Glob patterns match left-to-right, so `Bash(git push --force *)` won't catch this ordering. Deny rules are defense-in-depth, not a firewall. Behavioral rules in CLAUDE.md remain the primary control.

## Starter Configurations

### Conservative (Recommended Starting Point)

Read operations only. All writes and executions still prompt.

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "WebFetch",
      "WebSearch"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(rm -r *)"
    ]
  }
}
```

### Moderate

Adds file editing and safe shell commands. Good for solo developers or trusted environments.

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "Write",
      "Glob",
      "Grep",
      "WebFetch",
      "WebSearch",

      "Bash(git *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(node *)",

      "Bash(ls)",
      "Bash(ls *)",
      "Bash(pwd)",
      "Bash(which *)",
      "Bash(cat *)",
      "Bash(jq *)",
      "Bash(curl *)",
      "Bash(mkdir *)"
    ],
    "deny": [
      "Bash(git push --force *)",
      "Bash(git push --force)",
      "Bash(git push --force-with-lease *)",
      "Bash(git push --force-with-lease)",
      "Bash(git push -f *)",
      "Bash(git push -f)",
      "Bash(git reset --hard *)",
      "Bash(git reset --hard)",
      "Bash(rm -rf *)",
      "Bash(rm -r *)"
    ]
  }
}
```

### Permissive

Full local autonomy with MCP read access. For experienced users with multiple MCP servers who want minimal interruption.

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "Write",
      "NotebookEdit",
      "Glob",
      "Grep",
      "WebFetch",
      "WebSearch",

      "Bash(git *)",
      "Bash(gh *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(node *)",
      "Bash(terraform *)",

      "Bash(ls)",
      "Bash(ls *)",
      "Bash(pwd)",
      "Bash(which *)",
      "Bash(cat *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(wc *)",
      "Bash(sort *)",
      "Bash(jq *)",
      "Bash(echo *)",
      "Bash(curl *)",
      "Bash(mkdir *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(touch *)",
      "Bash(find *)",
      "Bash(diff *)",
      "Bash(sed *)",
      "Bash(awk *)",

      "mcp__splunk",

      "mcp__github__get_commit",
      "mcp__github__get_file_contents",
      "mcp__github__get_me",
      "mcp__github__issue_read",
      "mcp__github__list_branches",
      "mcp__github__list_commits",
      "mcp__github__list_issues",
      "mcp__github__list_pull_requests",
      "mcp__github__pull_request_read",
      "mcp__github__search_code",
      "mcp__github__search_issues",
      "mcp__github__search_pull_requests",

      "mcp__mcp-atlassian__jira_get_issue",
      "mcp__mcp-atlassian__jira_search",
      "mcp__mcp-atlassian__jira_get_project_issues",
      "mcp__mcp-atlassian__jira_get_all_projects",
      "mcp__mcp-atlassian__confluence_search",
      "mcp__mcp-atlassian__confluence_get_page"
    ],
    "deny": [
      "Bash(git push --force *)",
      "Bash(git push --force)",
      "Bash(git push --force-with-lease *)",
      "Bash(git push --force-with-lease)",
      "Bash(git push -f *)",
      "Bash(git push -f)",
      "Bash(git reset --hard *)",
      "Bash(git reset --hard)",
      "Bash(git clean -f *)",
      "Bash(git clean -fd *)",
      "Bash(rm -rf *)",
      "Bash(rm -r *)"
    ]
  }
}
```

## Team Deployment

### Project-Level Permissions

Commit a `.claude/settings.json` to your repo for team-wide rules. Keep it conservative - individual developers can add permissive rules in their global settings or `.claude/settings.local.json`.

```json
{
  "permissions": {
    "deny": [
      "Bash(git push --force *)",
      "Bash(git push --force)",
      "Bash(git push --force-with-lease *)",
      "Bash(git push --force-with-lease)",
      "Bash(git push -f *)",
      "Bash(git push -f)",
      "Bash(git reset --hard *)",
      "Bash(git reset --hard)",
      "Bash(rm -rf *)",
      "Bash(rm -r *)"
    ]
  }
}
```

This enforces guardrails across the team without dictating individual workflow preferences. Each developer adds their own allow rules at global or local scope.

### Evolving Your Allowlist

Start conservative and expand based on friction:

1. **Week 1**: Start with the conservative config (reads only)
2. **Week 2**: Note which prompts you always approve - add those to allow
3. **Week 3**: Add MCP read tools for servers you use daily
4. **Ongoing**: When you find yourself rubber-stamping, add the pattern

The goal is to eliminate prompts you always approve while keeping prompts that make you pause and think.

## See Also

- [Claude Code Configuration](claude-code.md) - CLAUDE.md patterns and CLI usage
- [MUST Rules](../../05-guardrails/must-rules.md) - Rules that deny patterns can enforce
- [MCP Servers](../mcp/servers.md) - Catalog of MCP servers and their tools
- [Environment & Secrets](../env-secrets.md) - Safe secrets management
