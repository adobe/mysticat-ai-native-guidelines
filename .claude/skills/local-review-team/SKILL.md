---
name: local-review-team
description: >-
  Code review a pull request locally using a dynamic expert team. Detects which
  topics a PR touches (infrastructure, backend, auth, security, etc.) and spawns
  one specialist agent per topic alongside the standard review checks. Outputs a
  combined issue table — no GitHub posting. Usage: /local-review-team [<pr-number>]
  If no PR number given, uses the current branch's open PR.
---

Perform a local code review for a pull request using a dynamically assembled expert team.
Output a table of issues with confidence scores and fix/skip recommendations.
**Do NOT post anything to GitHub.**

## Step 0: Resolve the PR

Parse `$ARGUMENTS` for an optional PR number.

- If a number is provided, use it directly.
- If no number is provided, detect the current branch and find its open PR:
  ```bash
  gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" --json number,title,url --limit 1
  ```
- If no open PR is found, inform the user and stop.

## Step 1: Eligibility check (Haiku agent)

Launch a **Haiku agent** to check whether the PR:
- (a) is closed or merged
- (b) is a draft
- (c) is trivially correct (automated PR, version bump only, etc.)

If any of the above, inform the user and stop.

## Step 2: Gather CLAUDE.md files (Haiku agent)

Launch a **Haiku agent** to collect file paths (not contents) of relevant CLAUDE.md files:
- The root CLAUDE.md file (if one exists)
- Any CLAUDE.md files inside directories that the PR modifies (check the diff file paths)

Return the list of paths to the orchestrator.

## Step 3: PR summary + diff (Haiku agent)

Launch a **Haiku agent** to:
1. Fetch the PR diff (all changed files + line diffs)
2. Return a short summary of the change (what it does, which areas it touches)
3. Return the full diff text so the orchestrator can pass it to downstream agents

## Step 4: Parallel review — wave 1 (Groups A + C + topic detection)

After Steps 2 and 3 complete, launch **all of the following in parallel**:

- **Group A** (5 Sonnet agents) — standard checks, needs only diff + CLAUDE.md paths
- **Group C** (1 Opus agent) — intent check, needs only diff
- **Topic detection** (1 Sonnet agent) — identifies which topic domains the PR touches

Groups A and C do not depend on topic detection, so they run concurrently with it.

### Topic detection (Sonnet agent)

Launch a **Sonnet agent** with the PR diff. Its job: identify every topic domain the PR touches.

**Topic catalog** — the agent must pick only from this list (return a JSON array of topic IDs):

| Topic ID | Triggers |
|---|---|
| `infrastructure` | Terraform, CloudFormation, AWS config, Docker, Kubernetes, serverless.yml, CDK |
| `ci-cd` | GitHub Actions workflows (`.github/`), CI config, deploy scripts, Makefiles |
| `observability` | Logging, metrics, tracing, alerting, Datadog/Coralogix/CloudWatch config |
| `backend-api` | HTTP handlers, REST/GraphQL endpoints, middleware, routing, controllers |
| `nodejs` | Node.js-specific: `package.json`, `node_modules`, async patterns, event loop, ESM/CJS |
| `database` | Schema changes, migrations, ORM models, raw queries, data pipelines |
| `authentication` | Auth flows, JWT, OAuth, session management, IMS, permissions, RBAC |
| `security` | Crypto, secrets handling, input validation, OWASP-class issues, CORS, CSP |
| `architecture` | System design patterns, module boundaries, abstractions, dependency injection |
| `testing` | Test files, test helpers, mocks, fixtures, coverage config |
| `documentation` | README, docs/, CLAUDE.md, inline JSDoc/docstrings, changelogs |
| `frontend` | UI components, CSS/SCSS, HTML, browser APIs, React/Vue/web components |
| `configuration` | `.env`, config files, feature flags, environment-specific settings, secrets injection |

Return **only** the JSON array, e.g.: `["backend-api", "nodejs", "security", "ci-cd"]`

A topic applies if the PR meaningfully changes code or config in that area — not just touching a file in passing. Aim for 2–6 topics for a typical PR.

### Group A — Standard checks (5 Sonnet agents, same as review-local)

1. **CLAUDE.md compliance** — Audit changes against the collected CLAUDE.md files. Only flag violations explicitly called out. Note: CLAUDE.md is guidance for Claude as it writes code, so not all instructions apply during review.
2. **Bug scan** — Shallow scan of the diff for obvious bugs. Focus on changes only. Flag large bugs, skip nitpicks. Ignore likely false positives.
3. **Historical context** — Read `git blame` and history of modified files. Identify bugs in light of that history (e.g., reverting a fix, breaking an invariant).
4. **Prior PR comments** — Read previous PRs touching these files. Check for recurring review feedback that also applies here.
5. **Code comment compliance** — Read code comments in modified files. Verify changes respect any guidance in those comments.

Each Group A agent returns issues in this format:
```
- <description> | reason: <CLAUDE.md adherence | bug | historical context | prior PR feedback | code comment>
```

### Group C — Intent check (1 Opus agent, always runs)

Launch one **Opus** `domain-expert` agent alongside all other agents. It always runs regardless of detected topics.

**Purpose:** Check whether the implementation actually reflects correct domain understanding — catch engineering-centric solutions that miss the business intent, implicit business rule violations, and mismatches between what the PR claims to do and what the code actually does.

**Prompt:**

> You are a non-engineer domain expert reviewing a pull request from a product and business perspective.
> You are NOT checking for bugs, style, or technical correctness — other specialists handle that.
> Your job: evaluate whether the implementation makes sense from a domain and intent perspective.
>
> Ask yourself:
> - Does the code actually solve the stated problem, or does it solve a different (possibly simpler) problem?
> - Are there implicit business rules or domain constraints that this change violates or ignores?
> - Does the API design / data model / user-facing behavior reflect how users or the business actually thinks about this domain?
> - Is there a mismatch between the PR description/title and what the diff actually does?
> - Does this change introduce assumptions about the domain that are likely wrong or untested?
>
> Return issues in this format:
> `- <description> | reason: intent | file: <path:line or N/A>`
>
> Only flag issues a product manager or domain expert would genuinely care about.
> Skip technical nitpicks. If no domain-level concerns, return: `NONE`

## Step 5: Parallel review — wave 2 (Group B, after topic detection completes)

Once the topic detection agent from Step 4 returns, launch **Group B** agents.

### Group B — Topic-expert agents (one **Opus** agent per detected topic)

Expert agents use **Opus** — domain-specific analysis (architectural coupling, exploit chains,
migration safety) requires deeper reasoning than the standard mechanical checks.

For each topic ID returned by the topic detection agent, launch one agent using the mapping below.
Pass each agent: the full PR diff, the list of CLAUDE.md file paths, and its domain focus.

**Topic → Agent mapping:**

| Topic ID | Agent `subagent_type` | Model | Expert persona |
|---|---|---|---|
| `infrastructure` | `senior-sre` | opus | Infrastructure & SRE: IaC correctness, resource lifecycle, blast radius, rollback safety |
| `ci-cd` | `senior-sre` | opus | CI/CD: pipeline correctness, secret exposure, deploy ordering, rollback |
| `observability` | `senior-sre` | opus | Observability: missing log levels, metric cardinality, alert gaps, structured logging |
| `backend-api` | `senior-engineer` | opus | Backend API: HTTP semantics, error handling, idempotency, pagination, contract changes |
| `nodejs` | `senior-engineer` | opus | Node.js: async/await misuse, event loop blocking, package hygiene, ESM/CJS issues |
| `database` | `data-engineer` | opus | Data: schema evolution safety, N+1 queries, migration reversibility, index coverage |
| `authentication` | `senior-authn-authz-specialist` | opus | Auth/AuthZ: token lifecycle, privilege escalation, session fixation, scope leaks |
| `security` | `senior-security-researcher` | opus | Security: injection, SSRF, secret exposure, OWASP Top 10, supply chain risk (defensive) |
| `security` | `senior-penetration-tester` | opus | Security: attack chains, exploitability, real-world PoC paths (offensive) |
| `architecture` | `principal-engineer` | opus | Architecture: coupling, cohesion, abstraction leaks, cross-cutting concerns, scalability |
| `architecture` | `distinguished-engineer` | opus | Architecture: forward-looking design gaps, framework choices, cross-domain consistency |
| `testing` | `qa-engineer` | opus | QA: coverage gaps, untestable code, flaky patterns, edge cases, regression risk |
| `documentation` | `senior-technical-writer` | opus | Docs: accuracy, completeness, stale content, missing user-facing implications |
| `frontend` | `ux-designer` | opus | Frontend/UX: accessibility, interaction patterns, responsive behavior, design consistency |
| `configuration` | `senior-staff-engineer` | opus | Config: secrets architecture, env design, feature flag strategy, config drift at system scale |

**Prompt for each Group B agent:**

> You are a [expert persona] reviewing a pull request. Your job: find issues in your domain only.
> Focus exclusively on [topic area]. Ignore issues outside your domain — other specialists cover those.
> Review the PR diff below. Return only real issues — skip nitpicks a senior engineer would wave off.
>
> Return issues in this format:
> `- <description> | reason: [topic-id] | file: <path:line>`
>
> If no issues in your domain, return: `NONE`

## Step 6: Score each issue (parallel Haiku agents)

For **every** issue found across Groups A, B, and C, launch a parallel **Haiku agent** with the PR diff, the issue description, and the CLAUDE.md file list. The agent scores on a 0–100 confidence scale:

| Score | Meaning |
|---|---|
| 0 | False positive. Does not hold up, or is pre-existing. |
| 25 | Might be real, might be false positive. Could not verify. Stylistic issues not in CLAUDE.md. |
| 50 | Verified real but may be nitpick or low impact. Not important relative to the rest of the PR. |
| 75 | Highly confident. Double-checked, very likely real. Directly impacts functionality or is in CLAUDE.md. |
| 100 | Absolutely certain. Confirmed real, will happen frequently. Evidence directly confirms. |

For CLAUDE.md issues, the agent **must** re-verify CLAUDE.md actually calls it out.

### False positive guidance (give to every scoring agent)

Score 0–25 for:
- Pre-existing issues (not introduced by this PR)
- Something that looks like a bug but is not
- Pedantic nitpicks a senior engineer would not flag
- Issues a linter, typechecker, or CI would catch (imports, types, formatting)
- General code quality (test coverage, docs) unless explicitly required in CLAUDE.md
- CLAUDE.md issues explicitly silenced in code (e.g., lint ignore comments)
- Intentional functionality changes related to the broader change
- Real issues on lines the author did not modify

## Step 7: Compile and present the report

Collect all scored issues. Sort by score descending. Present:

```
## Local Code Review: PR #<number> — <title>

### Summary
<1-2 sentence summary from Step 3>

### Affected Topics
<comma-separated list of topic IDs detected, e.g.: `backend-api`, `nodejs`, `security`, `ci-cd`>
Experts engaged: Senior Engineer (backend-api, nodejs) · Security Researcher (security) · SRE (ci-cd)

### Issues

| # | Score | Action | Category | Expert | Description | File |
|---|-------|--------|----------|--------|-------------|------|
| 1 | 92 | FIX | bug | standard | <description> | `path/file.py:42` |
| 2 | 85 | FIX | security | senior-penetration-tester | <description> | `path/file.py:17` |
| 3 | 80 | FIX | intent | domain-expert | <description> | N/A |
| 4 | 75 | FIX | CLAUDE.md | standard | <description> (CLAUDE.md: "<quote>") | `path/file.py:99` |
| 5 | 60 | CONSIDER | backend-api | senior-engineer | <description> | `path/other.py:5` |
| 6 | 30 | SKIP | style | standard | <description> | `path/other.py:8` |
```

**Action column rules:**
- Score >= 75: **FIX** — address before merge
- Score 50–74: **CONSIDER** — worth looking at, not blocking
- Score < 50: **SKIP** — likely false positive or not worth fixing

If no issues were found at all:
```
## Local Code Review: PR #<number> — <title>

### Affected Topics
<topic list>

No issues found. Checked: bugs, CLAUDE.md compliance, historical context, prior PR feedback, code comment compliance, domain intent, and topic-expert reviews (<topics>).
```

**Important:** Do NOT post anything to GitHub. Do NOT use `gh pr comment`. Output is displayed inline only.
