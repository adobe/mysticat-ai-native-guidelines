# Mysticat PR Skill + PR-Routing Hook + pr-review Grounding Gate

| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Author** | Rainer Friederich |
| **Created** | 2026-06-17 |
| **Updated** | 2026-06-17 |
| **Decided** | N/A |
| **Approvers** | N/A |

> Spec only — no implementation in this document. Cross-repo references use repo-relative paths anchored at each repo root (e.g. `mysticat-workspace/hooks/...`, `experience-success-skills/skills/...`).

## Summary

Proposes three coordinated changes so that pull requests are created and reviewed against one consistent, team-owned standard:

1. A Claude Code **`create-pr` skill** (in `experience-success-skills`) that opens a GitHub PR from a single skill-bundled template — eight narrative sections the skill fills from the current session.
2. A **PreToolUse hook** (in `mysticat-workspace`) that routes the three ways PRs get opened — `gh pr create`, the **direct GitHub API** (`gh api`, `curl`, `gh api graphql`), and the GitHub MCP create-PR tools — through that skill, falling back to the normal path with a warning when the skill is unavailable.
3. A **`pr-review` grounding gate** (in `experience-success-skills` / `review-kit`) that gathers a PR's grounding from all available sources and emits a **"degraded review"** notice when no spec document can be found, so reviewers know the change could not be validated against an agreed design.

Together: the template *captures* the spec/plan links, the hook *ensures the template is used*, and pr-review *enforces* that grounding exists.

## Problem Statement

### Current State
PRs are opened three different ways with no shared structure:
- `gh pr create` in a Bash call.
- The **direct GitHub API** from a shell: `gh api .../pulls` (POST), `gh api graphql` with a `createPullRequest` mutation, or `curl` against `api.github.com` / a GitHub Enterprise host.
- The GitHub MCP create-PR tools (`mcp__github__create_pull_request` plus the enterprise variant).

Per-repo `pull_request_template.md` files are inconsistent (detailed checklist, minimal, or none). This repo also has a generic AI-disclosure PR template (`docs/03-templates/pull-request-template.md`) not wired to any automation. `pr-review` (review-kit) runs a strong multi-agent review but does not check whether a PR is grounded in a spec, so a change with no agreed design is reviewed with the same apparent confidence as one that has one.

### Desired State
- One team-owned PR template travels with a skill and is filled automatically from session context.
- PR creation is routed through the skill regardless of which of the three surfaces the agent reaches for, and degrades gracefully when the skill is absent.
- `pr-review` flags PRs with no discoverable spec as degraded reviews, closing the loop between "PR template asks for a spec link" and "review checks it is there".

### Gap Analysis
- No single source of truth for PR body structure.
- No automation encouraging or enforcing a consistent body.
- Three distinct creation surfaces (gh CLI, direct API, MCP) to cover.
- Must not break PR creation where the skill is not installed.
- Review confidence is not adjusted for absence of a spec.

## Goals and Non-Goals

### Goals
- A single `create-pr` skill that creates a GitHub PR using a template bundled with the skill, not pulled from the target repo.
- The template has static sections and session-derived sections the skill fills automatically.
- A workspace hook that intercepts all three shell-visible PR-creation surfaces and routes them through the skill.
- Graceful fallback: if the skill is unavailable, the hook lets the normal call proceed and emits a warning (does not block).
- A `pr-review` enhancement that detects missing spec grounding and surfaces a "degraded review" notice in the consolidated review.
- Follow existing `experience-success-skills` plugin/skill conventions and existing `mysticat-workspace` hook conventions.

### Non-Goals
- Replacing or deleting per-repo `pull_request_template.md` files (the skill template supersedes them at create time; the files stay).
- Auto-merging, review-requesting, or PR lifecycle management beyond creation.
- Changing how branches/commits are produced. The skill assumes the branch is pushed (or pushes as part of its flow).
- Forcing the skill on. The hook is a router with a fallback, not a hard gate (see the bypass in §A).
- Making the degraded-review notice a hard block. It annotates and reduces stated confidence; it does not fail the review.
- Intercepting PR creation outside the Claude Code agent. The hook sees only the agent's `Bash` and MCP tool calls; other clients (scripts, IDEs, the web UI, non-Claude-Code tooling) are intentionally out of scope (see §B).

## Proposed Solution

### Overview

Three artifacts working together:

```
┌─────────────────────────────────────────────────────────────────────┐
│ mysticat-workspace                                                    │
│  .claude/settings.json  ──registers──▶  hooks/pr-route-to-skill.sh    │
│        PreToolUse: Bash (gh pr create | gh api | curl) + MCP create-PR│
└───────────────────────────────┬──────────────────────────────────────┘
                                 │ intercepts the 3 PR-creation surfaces
                                 ▼
                  ┌──────────────────────────────┐
                  │  Is the create-pr skill there?│
                  └───────────┬───────────┬───────┘
                         yes  │           │  no
                              ▼           ▼
                 deny + instruct      exit 0 + stderr warning
                 "use the skill"      (original call proceeds)
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│ experience-success-skills                                            │
│  skills/review-kit/skills/create-pr/                                  │
│        SKILL.md                  ← gather session context            │
│        assets/pr_template.md     ← the bundled 8-section template     │
│                                                                       │
│  skills/review-kit/skills/pr-review/  (grounding gate)               │
│        Phase 1: discover grounding (all sources) → has-spec flag     │
│        Phase 3: prepend "degraded review" banner when no spec        │
└─────────────────────────────────────────────────────────────────────┘
```

**Routing mechanism (researched, confirmed).** A Claude Code hook cannot directly invoke a skill — hooks are shell commands run by the harness; skills are invoked by the model. The hook therefore *blocks* the PR-creation tool call and *injects an instruction* telling the model to call the skill. The model then chooses to invoke it. This is a reliable block plus a strong nudge (not a hard guarantee — see Risks).

### Technical Design

#### A. Control surface: the body marker and the bypass (read first)

**Threat model.** This routing is a **convenience guard** to keep PR bodies consistent, **not a security boundary**. Both controls below (the in-body marker and the bypass env var) are trivially settable by any user or agent — intentionally, because the skill must never be a hard gate (see non-goals). Substring matching is therefore acceptable; tightening it would add fragility without adding a real control. Nothing here prevents a determined caller from opening a raw PR; the goal is to make the *templated* path the default and the *raw* path a conscious choice.

Two markers, with distinct roles:

1. **Body marker `<!-- mysticat-pr-skill -->` — the skill's own-output recognizer (recursion guard).** A skill is just instructions; it has no special PR API. When the model runs `create-pr`, the skill ultimately submits the PR through whatever transport is available — `gh pr create`, a direct-API `gh api`/`curl` POST, or the GitHub MCP `create_pull_request` tool — each of which is itself an intercepted tool call, so the hook fires again and would block the skill's own PR creation: an infinite loop. The skill avoids this **transport-agnostically**: the rendered template body carries a sanctioned, invisible HTML-comment marker `<!-- mysticat-pr-skill -->` (it renders invisibly on GitHub and is the one comment the skill does NOT strip — see §D). The hook resolves the PR body for whichever surface it sees and **allows any PR-create whose resolved body contains the marker** — that body is the skill's own templated output, regardless of transport. Implementers should match on the marker *key* (`mysticat-pr-skill`), not the exact literal string: §H proposes extending this same marker with structured creation-time state (`base`/`head`/`commits`/`files`) for post-push drift detection, so the recursion guard must keep matching when those fields are present.

   *Why a body marker and not an inline `gh`-only env prefix.* An inline `MYSTICAT_PR_SKILL=1 gh pr create ...` sentinel lives only on the `gh` command string, so it cannot guard the MCP tool call (no command string at all) or a `curl`/`gh api` POST, and it hardcodes `gh` into the skill (§C). A marker that travels *in the body* is visible to the hook on every surface, freeing the skill to pick any transport. (The generic `🤖 Generated with Claude Code` footer is NOT the marker — it is a team-wide convention on many Claude PRs and so cannot distinguish the skill's output.)

   *How the hook resolves the body per surface* (so the marker is findable): `gh pr create --body/-b "<text>"` → the inline text; `gh pr create --body-file/-F <path>` → the hook reads that file (the skill renders it in step 3, before the step-4 create call, so it exists when the hook fires); `gh api .../pulls -f body=<text|@file>` / `--input <file>` and `curl -d/--data <text|@file>` → the body field or the referenced file; MCP `create_pull_request` → `tool_input.body`. The skill MUST submit through one of these resolvable forms (it does — see §C); an unresolvable exotic form degrades to the raw-call path (deny when the skill is present), which the skill simply does not use.

2. **`MYSTICAT_PR_SKILL_BYPASS=1` — the human/operator override (escape hatch).** Read by the hook from **its own process environment**. When set, the hook no-ops (allows) on every surface — Bash, direct API, and MCP — optionally emitting a one-line stderr note. This is the documented override for "I deliberately want a raw (non-templated) PR", and the answer to "what if the skill has a bug or I want to bypass it": set the env var (or disable the skill). It is now cleanly orthogonal to the recursion guard above: the **marker** says "this *is* the templated body, allow"; the **bypass** says "I want a raw body, allow anyway". This is what keeps the hook a router, not a gate.

#### B. Hook (mysticat-workspace)

- Script: `mysticat-workspace/hooks/pr-route-to-skill.sh` (executable). Mirrors the existing hook style (`pre-push-main-check.sh`, `lint-staged.sh`): read JSON from stdin, inspect `tool_input`, emit a JSON decision or nothing.
- Registration: in the **committed workspace `mysticat-workspace/.claude/settings.json`** (shared across all sessions, not per-user) under `PreToolUse`, using the repo's directory-walk command pattern. One matcher entry covers all surfaces — the direct-API calls (`gh api`, `curl`) are themselves Bash commands, so the `Bash` matcher already routes them to the script, which then pattern-matches the command:

```jsonc
{
  "matcher": "Bash|mcp__github__create_pull_request|mcp__github-enterprise__create_pull_request",
  "hooks": [
    { "type": "command",
      "command": "bash -c 'd=$PWD; while [ \"$d\" != / ] && [ ! -x \"$d/hooks/pr-route-to-skill.sh\" ]; do d=$(dirname \"$d\"); done; [ \"$d\" != / ] && exec \"$d/hooks/pr-route-to-skill.sh\"'"
    }
  ]
}
```

**Matcher names track `.mcp.json`.** The `mcp__github__create_pull_request` / `mcp__github-enterprise__create_pull_request` entries are the *configured MCP server names* from the workspace `.mcp.json` (server name + tool name). Treat the matcher as a living list: if the GitHub MCP server is renamed, removed, or a new GitHub MCP server is added, the matcher must be kept in sync. The `Bash` arm is stable; only the MCP arm is config-coupled. To make drift loud rather than silent, the hook PR (Phase 2) adds a **CI/startup assertion** that every `mcp__*__create_pull_request` name in the matcher still resolves to a server declared in the workspace `.mcp.json` (and, conversely, that every GitHub-MCP server declared there is covered by the matcher); a mismatch fails the check with the offending name, instead of the matcher quietly missing a renamed server.

**Scope — PR creation only.** The hook routes *PR creation* and nothing else. It must NOT match commands that merely interact with existing PRs (posting comments or reviews, listing, editing, merging). Concretely, a Bash command is treated as a PR-create attempt only when it matches one of:
- `gh pr create` (the primary path) — but not `gh pr create --web` (that opens a browser for the human to fill the body; allowed through).
- `gh api` AND a POST that *creates* a PR: the `pulls` collection endpoint with create fields (e.g. `gh api repos/{owner}/{repo}/pulls -f title=... -f head=... -f base=...`, or `-X POST`/`--method POST`). It must NOT match sub-resources such as `.../pulls/{n}`, `.../pulls/{n}/comments`, `.../pulls/{n}/reviews`, nor GET *lists* of `pulls`.
- `gh api graphql` AND `createPullRequest`.
- `curl` AND a GitHub API host (`api.github.com` or the enterprise host) AND a POST to the `/pulls` collection (again, not `/pulls/{n}/...` sub-resources).

This is advisory routing, not enforcement: a false positive degrades to "use the skill" and a false negative degrades to a raw PR — both acceptable.

**Known limitation — dynamically constructed commands.** Commands assembled at runtime (`eval "$cmd"`, heredocs, a variable holding the command string, base64-decoded payloads) can evade the substring heuristics. This is accepted: a miss degrades to a raw PR, consistent with the convenience-guard framing in §A. It is not worth trying to defeat, since it is not a security control.

**Repeated non-compliance.** A `deny` is idempotent — there is no counter or escalation. If the model retries the raw call after a deny, the hook simply denies again; if it keeps retrying, resolution is user intervention (invoke the skill, or set `MYSTICAT_PR_SKILL_BYPASS=1`). The hook never blocks the session, only the specific PR-create call.

**Decision table** (the `MYSTICAT_PR_SKILL_BYPASS=1` env override short-circuits to no-op/allow on every row):

| Tool | Condition | Action |
|---|---|---|
| any | `MYSTICAT_PR_SKILL_BYPASS=1` in hook env | exit 0, no output (override — allow) |
| any | resolved PR body contains the `<!-- mysticat-pr-skill -->` marker | exit 0, no output (allow — skill's own templated body, any transport) |
| `Bash` | not a PR-create pattern (no `gh pr create` / direct-API create match) | exit 0, no output (no-op) |
| `Bash` | `gh pr create --web` | exit 0, no output (allow — human fills body in browser) |
| `Bash` | `gh pr create`, no marker, skill present | deny + instruct model to use the skill |
| `Bash` | `gh pr create`, no marker, skill absent | exit 0 + stderr warning (allow fallback) |
| `Bash` | direct-API PR-create (gh api / graphql / curl), no marker, skill present | deny + instruct model to use the skill |
| `Bash` | direct-API PR-create, no marker, skill absent | exit 0 + stderr warning (allow fallback) |
| `mcp__github*__create_pull_request` | no marker, skill present | deny + instruct model to use the skill |
| `mcp__github*__create_pull_request` | no marker, skill absent | exit 0 + stderr warning (allow fallback) |

**Output format** — use the repo's proven legacy shape (as in `pre-push-main-check.sh`): block with stdout `{"decision":"deny","message":"<imperative reason naming the skill>"}`; for the fallback warning, exit 0 and write the warning to stderr. Avoid the newer `hookSpecificOutput.permissionDecision` fields and speculative values (`"defer"`, `updatedInput`, per-hook `if:`) — unverified in research.

**Skill-presence detection.** The `create-pr` skill is distributed in the **`experience-success-skills`** repo as part of the **`review-kit` plugin** (adobe-experience-success marketplace), alongside `pr-review`, and installed like the team's other plugins. The hook detects its presence by globbing for the skill's `SKILL.md` across the Claude Code skill roots: the plugin install root (the marketplace-installed `review-kit` plugin), the project skill dir (`<repo>/.claude/skills/create-pr/SKILL.md`), and the personal skill dir (`~/.claude/skills/create-pr/SKILL.md`). Any match → present. (The implementation reads the live plugin install location from the Claude Code plugin layout rather than assuming a fixed string, so presence detection does not hard-depend on the plugin name.)

**Scope — Claude Code agent only.** By design the hook covers only the Claude Code agent's tool calls (`Bash` and the named MCP tools). PRs opened from anywhere else — an opaque script (`python create_pr.py` using PyGithub/requests, a Node script using octokit), an IDE button, the GitHub web UI, or any non-Claude-Code tooling — are out of scope and are not intercepted. This is deliberate: the hook is a guard *for the agent*, where consistency most needs help, not an org-wide enforcement layer. Broader coverage, if ever wanted, belongs in a server-side control (e.g. a GitHub Action), not this hook.

#### C. Skill (experience-success-skills)

- Placement: the existing `review-kit` plugin (alongside `pr-review`), skill `create-pr` inside it. Layout `skills/review-kit/skills/create-pr/{SKILL.md, assets/pr_template.md, scripts/}`. No `marketplace.json` / `plugin.json` change needed: skills auto-discover from the plugin's `skills/` dir (the manifest lists plugins, not skills). Co-located with `pr-review` because the two are a coordinated PR lifecycle (the template captures the spec link the §E gate then checks) and Part 3's grounding gate already modifies `review-kit`.
- SKILL.md frontmatter follows repo convention (`name`, `description`, `user-invocable`, `argument-hint`; no em-dashes in body). The description must be strong enough that the model reliably selects the skill when the hook nudges it.
- Workflow: (1) pre-flight (a PR-creation transport is available and authenticated — the GitHub MCP `create_pull_request` tool is connected, or `gh` is authenticated; not on the default branch; branch pushed); (2) gather session context (branch, `git log` since base, diff summary, Jira keys, what was verified); (3) render the body from `assets/pr_template.md` to a temp file — the rendered body carries the sanctioned `<!-- mysticat-pr-skill -->` marker (§A/§D); (4) create the PR through **whatever transport is available — no `gh` hardcode**: prefer the GitHub MCP `create_pull_request` tool when it is connected (pass the rendered body as `body`), else `gh pr create --base <base> --title "<title>" --body-file <tmp-body> [--draft]`, else a direct-API `gh api`/`curl` POST — always submitting through a hook-resolvable body form (§A) so the in-body marker, not an inline env prefix, guards against recursion on every surface; (5) report the PR URL.
- Scripts: existing plugins are Python 3 stdlib. Default to no scripts; a small stdlib `render_body.py` is justified only if deterministic rendering / Jira-key extraction proves fiddly.

#### D. The bundled PR template

The template is a **dedicated standalone file** — `assets/pr_template.md` in the skill — never inlined in code or `SKILL.md`; the skill reads it from disk at render time. Its canonical source ships as a **separate file alongside this spec**, [`2026-06-17-mysticat-pr-skill-template.md`](2026-06-17-mysticat-pr-skill-template.md). The template proper is the content **between the `---` markers** of that companion file (the H1, introduction, and example outside the markers are documentation, per this repo's doc rules, and are NOT part of the PR body); at implementation that between-markers content is copied **verbatim** into the skill's `assets/pr_template.md`. The companion file holds the full eight-section template; it is intentionally not reproduced inline here, to keep a single source of truth.

Properties of the template (full text in the companion file):
- It is the single source of truth and **replaces** whatever `pull_request_template.md` lives in the target repo.
- Eight sections; sections 5, 6, and 8 are conditional (the skill drops the whole section when not applicable).
- Each section carries an `<!-- AGENT: ... -->` instruction comment (stripped after filling) and a `{{TOKEN}}` placeholder (replaced). The skill MUST replace every token, strip every comment, and fill-or-remove each conditional section; a leftover `{{TOKEN}}` is a bug and the skill should fail rather than open a PR with raw placeholders. **The sole comment the skill does NOT strip is the sanctioned recursion-guard marker `<!-- mysticat-pr-skill -->` (§A)** — it is intentionally retained in every rendered body, renders invisibly on GitHub, and is what the routing hook keys on to recognise the skill's own output across all transports.
- A fixed `🤖 Generated with Claude Code` footer is appended at the end of every body (lightweight AI-usage disclosure — see "AI disclosure" below). This footer is distinct from the recursion-guard marker above and is NOT used for recursion detection (it is a team-wide convention on many Claude PRs, so it cannot identify the skill's output).

**Rendering contract for empty values.** This is the contract an implementer (or the optional `render_body.py`) MUST follow, stated here so it does not live only in a stripped instruction comment: when a placeholder — or a section-4 bullet's value — resolves to **empty/null**, the skill removes the **entire line or bullet**, not just the `{{TOKEN}}`, so no dangling `- Spec:` remains. The "leftover token is a bug → fail" rule applies only to a token the skill *cannot resolve at all*, which is distinct from a deliberately-empty optional that is removed cleanly.

**Fill-guide (placeholder → content → data source):**

| Placeholder | What the skill writes | Primary source |
|---|---|---|
| `{{ABSTRACT}}` | 1-2 sentence what-is-this | branch name, PR title, Jira summary, diff summary |
| `{{REASONING}}` | the why / trigger | Jira/issue description, commit messages, session context |
| `{{OVERVIEW}}` | behaviour delta (before->after), human-readable | diff analysis + the model's understanding of the change |
| `{{JIRA_LINK}}` | issue key + URL (e.g. `SITES-1234`) | issue keys parsed from branch/commits/session; remove bullet if none |
| `{{SPEC_LINK}}` / `{{PLAN_LINK}}` / `{{ADR_LINK}}` | links to spec/plan/ADR | `docs/` in touched repos (`decisions/`, `plans/`, `proposals/`) **AND the workspace `mysticat-architecture` + `mysticat-ai-native-guidelines` docs** (where specs/ADRs/migration-plans live per the DOCUMENTATION-GUIDE 70% rule), keyed on the Jira key / branch / PR title; session context; remove bullet if none. Best-effort and create-time-local (the interactive session has all repos cloned); the §E gate is the authoritative backstop — see "Discovery scope is shared with §E" below |
| `{{OTHER_LINKS}}` | any other relevant links | session context; remove bullet if none |
| `{{AFFECTED_PROJECTS}}` | bullet list of workspace repos touched/depended-on + nature | session context + cross-repo contract reasoning (the create-time skill has no diff of untouched repos, so this is reasoned from the session and the change's contracts, not a cross-repo diff); drop section if none |
| `{{OUTSIDE_CODE_INFO}}` | manual/agent validation results + infra observations | session record; drop section if none |
| `{{TEST_PLAN}}` | (a) local e2e done + result, (b) per-env verification steps | session record + the model's plan for eph/dev/stage/prod |
| `{{DEPLOYMENT_ORDER}}` | dependent/related PRs + required merge/deploy sequence | session context, related PRs; drop section if independent |

**Hard exclusions (the skill must NOT write these into the body).** The body is for humans reviewing intent and behaviour, not a CI report:
- Code examples / snippets (reviewers read the diff).
- Counts of passing tests (e.g. "all 412 tests pass", "added 7 tests").
- Static-analysis / lint success statements (e.g. "lint clean", "type-check green").

These are enforced by the rendering step (and a skill test). A known *failure or gap* worth attention may still be described in prose — the exclusion is about pass/clean status and code, not about flagging a real problem.

**AI disclosure.** The template ends with a fixed Claude Code footer. Throughout this spec it is written in prose as `🤖 Generated with Claude Code` for readability, but its canonical rendered form is the markdown link in the companion template — `🤖 Generated with [Claude Code](https://claude.com/claude-code)` — which is the source of truth per this section. This is the team's lightweight AI-usage disclosure; the Mysticat template does not adopt the fuller checklist/disclosure form of the generic `docs/03-templates/pull-request-template.md`. The two templates coexist — the generic one for repos not using the skill, the Mysticat one (with the footer) for skill-created PRs.

**Discovery scope is shared with §E (closes the create-vs-review asymmetry).** The skill's spec/plan/ADR discovery above deliberately spans the same source set as the §E grounding gate — the touched repos' `docs/`, the workspace `mysticat-architecture` and `mysticat-ai-native-guidelines` docs, and linked Jira — so the half that *writes* the spec link and the half that *checks* it agree on where specs live. Without this the common case (a code PR in, say, `spacecat-audit-worker` whose design-of-record spec lives in `mysticat-architecture`) would ship with an empty `- Spec:` bullet from the skill, yet the gate would find that spec and not degrade — a silent disagreement that manufactures the exact "spec exists but not found" false negative. The one difference is execution context, not source set: the skill runs interactively where all repos are cloned, so it reads them from the workspace filesystem; the gate must also work in the no-clone worker and so reuses the Phase 2.1 fetch machinery (see §E). Skill-side discovery is best-effort (a miss just drops the bullet); the gate is the authoritative backstop.

**Notes.** Conditional sections drop when empty. No checklist section — repo-specific mechanical checks (cassette scrubbing, test speed markers, API-spec updates) stay enforced by each repo's pre-commit/CI; where a touched repo has critical checklist items the skill surfaces them in section 6 or 7. Workspace conventions honoured: Jira key format per workspace rules; no `#`-prefixed enumeration (GitHub auto-links them to unrelated PRs).

#### E. pr-review grounding gate (review-kit)

`pr-review` is a three-phase multi-agent skill (Triage → parallel specialist reviews → consolidate + post). The grounding gate adds two touch points:

- **Phase 1 (Triage):** gather the PR's grounding from **all available sources** — the PR body's section-4 links, the touched repos' `docs/` (specs, plans, ADRs), the `mysticat-architecture` / `mysticat-ai-native-guidelines` docs, and any linked Jira issue. From that, determine whether a **spec document** exists for the change. To be precise about scope: `mysticat-architecture` / `mysticat-ai-native-guidelines` are **not** unconditional implicit search targets — they are reached **only via the link chain** — `upstream_docs_paths`, the pr-review Phase 2.1 field the orchestrator builds from cross-repo links in the touched repo's `AGENTS.md`/`CLAUDE.md` (see the reuse note below) — i.e. they are discovered only when that repo links up to them per the "Platform Context" convention. This keeps the gate to the existing zero-config discovery model; a repo that fails to link up is the gap, surfaced by the conventions reviewer (see the reuse note below), not a reason to hardcode a repo list here.
  - **Reuse the existing Phase 2.1 cross-repo machinery — do NOT add a second discovery path.** pr-review already solves cloneless cross-repo doc discovery in its Phase 2.1: `project_docs_paths` (touched-repo `docs/`, path-only, lazy-fetched) and `upstream_docs_paths` (cross-repo references parsed from the touched repo's `AGENTS.md`/`CLAUDE.md` "Platform Context" links — e.g. the link up to `mysticat-architecture`), with host-routed lazy fetch (`gh api` for `github.com`, the matching MCP `get_file_contents` for enterprise hosts), a status-discrimination contract, the token-overlap-with-the-diff rule, and the 50-path cap. The grounding gate MUST reuse this machinery and inherit its execution-context split and status-discrimination contract, so it behaves identically interactively (local clones) and in the MysticatBot worker (`mysticat-github-service`), which clones only `mysticat-workspace` and reaches every other repo via the API. Concretely, the `mysticat-architecture` spec is reached the same way the conventions reviewer already reaches upstream docs: the touched repo's `AGENTS.md`/`CLAUDE.md` links up to it (the DOCUMENTATION-GUIDE "Platform Context" convention), so `upstream_docs_paths` picks it up and it is fetched via `get_file_contents` — no clone, no local filesystem walk assumed. If a touched repo does not link up to `mysticat-architecture`, that is itself a gap the conventions reviewer already surfaces.
- **Phase 3 (Consolidate + post):** when no spec is found (and the PR is not exempt), prepend a prominent **"⚠ Degraded review"** banner to the consolidated review and include it in the body posted to GitHub. Suggested wording: *"Degraded review — no spec document was found for this change (searched the PR links, the touched repos' docs, the architecture/guidelines docs, and linked Jira). This review covers code-level quality but could not validate the change against an agreed design, so confidence is reduced. Add a spec link (PR template section 4) and re-request review for a full-confidence pass."*

Design points:
- **Discover from all sources; degrade only on a missing spec.** Grounding is collected from every available source above. The degraded-review banner is triggered **specifically by the absence of a spec document** — the design-of-record. A missing implementation plan, ADR, or Jira link alone does NOT degrade the review (those enrich it but are not the bar); only a missing spec does.
- **Exemption (self-attested, human-visible).** Trivial/mechanical PRs (typo, dependency bump, formatting) where no spec is warranted are exempt via either a `no-spec-needed` label on the PR or an `Exemption: <reason>` bullet in section 4. Exempted PRs get no degraded banner. Consistent with §A's convenience-guard framing, the exemption is **self-attestable** — the author asserts it, the gate honours it, and there is no approval workflow — but it is **visible on the PR** (a label or a body bullet anyone can see), so a reviewer can challenge an unjustified exemption in the normal review. This keeps the signal meaningful and avoids alert fatigue without turning the gate into a hard gate.
- **Severity is advisory, not blocking.** The review still runs and posts; the banner adjusts stated confidence.
- **Complements the existing `spec-compliance-reviewer` agent.** That agent checks implementation-vs-spec *when a spec exists*; the grounding gate handles the *absence* case (no spec → spec-compliance cannot run → degraded). It also fits the Always-on `project-conventions-reviewer`'s remit of checking alignment with documented contracts.

#### F. Fallback behavior

The fallback is why the hook is a router, not a gate. Skill absent (not installed/enabled, or presence-glob finds nothing) → warn + allow: the PR is created the original way and the user sees the stderr warning. No PR is ever blocked outright by skill absence. The only hard block is a non-sanctioned raw call while the skill is present — and the model can re-issue through the skill (whose rendered body carries the `<!-- mysticat-pr-skill -->` marker and so passes on any transport), or the operator can set `MYSTICAT_PR_SKILL_BYPASS=1`.

#### G. Observability: review cost and quality by grounding outcome

The grounding gate raises an operational question worth answering with data: **what does it cost to review a change that has a spec (so the gate discovers and fetches the spec / plan / ADR / architecture docs) versus one that has none (so the gate degrades)?** This is answered by labelling the existing per-run cost metric rather than building anything new.

- **Add a low-cardinality `grounding` label** — `spec_found | degraded | exempt` — to the per-run review-cost metric already emitted by MysticatBot (`mysticat-github-service`: `mysticat_github_review_cost_usd{job_type, model}`, mirrored on CloudWatch `ReviewCost` and in the Check Run metadata JSON). Apply it to the input-token series too. Then "cost with a spec vs without" is a single split on that series — continuous, no before/after baseline window needed. The catalog entry goes in `metrics.yaml` (drift-guarded by `tests/test_metrics_catalog.py`).
- **Derive the label with no new skill output.** The degraded outcome is already present in the *posted review body* (the "⚠ Degraded review" banner from §E); the worker already re-derives verdict and findings by parsing that body, so detecting the banner is the same pattern. `exempt` is read from the `no-spec-needed` label / `Exemption:` bullet. So the minimum viable version is worker-side: one body-parse + one metric label.
- **Honest confounder.** The raw `spec_found` vs `degraded` cost split mixes two effects: (1) the gate's own discovery+fetch overhead (extra input tokens, present only when grounded) and (2) the fact that spec'd PRs tend to be larger/more complex and would cost more regardless. So the split is an **upper bound on the cost attributable to the gate** (not an upper bound on total review cost), not a clean attribution. Optional de-confounder: also emit the fetch *volume* — `grounding_docs_fetched` (count) and bytes — which needs a small skill→worker plumbing of those numbers (they are not in the posted body), letting cost be read against how much document was actually pulled in. A truly clean per-phase cost attribution is out of scope: the CLI result envelope exposes only whole-run `total_cost_usd` + `modelUsage`, and the worker breaks out per-phase *duration* but not per-phase *cost*, so the volume metric is the pragmatic substitute.

This is a Phase-3 deliverable (it ships with the grounding gate), spanning the `pr-review` skill and the `mysticat-github-service` worker; the `grounding`-label split is the required piece, the fetch-volume metric is a nice-to-have.

**Review-quality measurement (follow-up, not a Phase-3 build item).** Cost is a number the harness emits; review *quality* has no equivalent field, so it must be measured through proxies, each with a confound, and it cannot be cleanly A/B-tested (the gate applies to every PR once shipped, so a time-windowed "before vs after" compares two different PR populations, not the treatment). The approach is recorded here so the *direction* is not lost; the specific techniques below (pairwise preference, LLM-as-judge, reaction read-back) are illustrative of that direction and should be re-confirmed against tooling current at implementation time rather than treated as fixed:

- **One-time controlled eval (the real "before vs after").** Hold the PR set constant instead of comparing time windows: take a fixed sample of already-merged PRs **that have a discoverable spec** — the only population where grounding changes the review's inputs, so the only place a quality delta can exist (a no-spec PR is ungrounded both ways, leaving only the degraded banner, which is not a content change) — and replay MysticatBot's review on each **both ways** (ungrounded vs grounded; the "before" arm is produced by withholding the spec). Score the two outputs **head-to-head with pairwise preference** ("which review is more useful?"), which is far more reliable for subjective quality than absolute 1–5 scoring. Scale the pairwise judging with an LLM-as-judge **calibrated against a human-scored subset** (randomise A/B order to counter position bias). The bot already runs headless (`claude -p --output-format json`), so replaying it over a PR list is mechanical. This is the only measure of *actual* usefulness; everything below is a proxy.
- **Continuous proxies (ongoing, cheap).** (1) **👍/👎 footer reaction read-back** — the footer already prompts for reactions but nothing reads them today (write-only); a small aggregator turns them into a satisfaction trend (confound: sparse, self-selected). (2) **Verdict mix + finding-severity distribution split by the same `grounding` label** added above — reuses existing telemetry (`mysticat_github_review_findings{severity}`, `review_state`) to ask "do grounded reviews produce different verdicts / more spec-compliance findings than degraded ones?" (confound: PR complexity, as with the cost split). `ReviewStateDivergence` (already emitted) remains the standing consistency signal.

#### H. Future work: keeping the PR description in sync after creation (deferred)

Recorded as deferred follow-up (not built by this spec): a mechanism that keeps the PR description in sync when significant changes are pushed after the PR was opened. Direction is **in-session, agent-first** — chosen over per-repo GitHub Actions, which would need a `pull_request: synchronize` workflow file in every repo and drift across them.

- A **PostToolUse hook** (sibling to `pre-push-main-check.sh`) detects drift by comparing the current branch against the PR's creation-time baseline — read from a state marker the create-pr skill embeds in the body at create time (extending the `<!-- mysticat-pr-skill -->` marker with e.g. `base`/`head`/`commits`/`files`), falling back to the GitHub API (commits after `PR.createdAt`) for PRs the skill did not create. "Significant" means scope growth (files/areas absent from the original diff), not raw churn.
- **Push surfaces to watch (mirrors §B's multi-surface problem).** Code reaches a branch more than one way, so the hook must match more than `git push`: the `Bash` `git push` call (primary), and the GitHub MCP file-commit tools (`push_files` / `create_or_update_file`, which commit straight through the API with no `git push` at all). As in §B this is **Claude Code agent only** — pushes from an IDE, the web UI, or an external script are not seen and are left to the centralized backstop below.
- On significant drift the hook injects `additionalContext` that triggers the model to re-run the create-pr **update mode** — an idempotent re-render that refreshes the auto-derived sections (3, 7) and preserves the links / human prose, so the body stays in template layout by construction. **Timing:** `additionalContext` lands in the agent's loop right after the push tool result, so in the common mid-task case the agent runs update mode **in the same flow, automatically — no re-invocation needed**; it is deferred only when the push is the agent's terminal action (then it waits for the next interaction, or the backstop). Exact delivery semantics (same step vs. next user turn) are version-dependent — confirm at implementation.
- **Depends on the `create-pr` skill being present** (it owns update mode — distinct from the `pr-review` skill). The hook inherits the §B/§F skill-presence detection and fallback: skill present → nudge to update mode; skill absent → degrade to a plain drift note (or no-op), never an error. A hook cannot invoke a skill directly, so the narrative refresh is always model-driven (the same nudge pattern as §B).
- **Spec-drift flag** extends spec-compliance / §E rather than duplicating it: on a significant push, re-validate the change against the linked spec and, if it has grown beyond the spec's stated scope, surface "this change has outgrown its spec — update the spec before merge."
- Centralized walk-away coverage, if ever wanted, belongs in the existing MysticatBot webhook service (`mysticat-github-service`, which already receives org-wide PR events) on `pull_request.synchronize` — NOT a per-repo Action.

### Implementation Phases

**Phase 1 — Skill.** Land `create-pr` (plugin + skill + template) in `experience-success-skills`; enable it; verify end-to-end PR creation through the available transport, with the rendered body carrying the `<!-- mysticat-pr-skill -->` marker.

**Phase 2 — Hook.** Land `pr-route-to-skill.sh` + settings registration in `mysticat-workspace` once the skill is installable, so the presence-check has something to find. Include the matcher-vs-`.mcp.json` CI/startup assertion (§B) so a renamed/added GitHub MCP server fails loudly rather than silently slipping past the matcher.

**Phase 3 — pr-review grounding gate.** Add the Phase-1 grounding discovery and Phase-3 banner to `review-kit/skills/pr-review`, and the `grounding`-labelled review-cost split in `mysticat-github-service` (§G).

Three separate PRs (two repos). The skill PR should merge first so the hook's "present" path is exercisable; the pr-review change is independent and can land in parallel.

## Alternatives Considered

| Decision | Options | Verdict |
|---|---|---|
| Routing as security vs convenience | hard gate / security boundary vs convenience guard with override | convenience guard; a hard gate contradicts the non-goals and cannot be enforced against non-agent clients anyway |
| Recursion guard | inline `gh`-only env-var prefix; transport-agnostic in-body marker; wrapper script | in-body marker (`<!-- mysticat-pr-skill -->`) — works on gh / gh api / curl / MCP alike and removes the `gh` hardcode from the skill; the env prefix only ever guarded the `gh` command string |
| MCP/direct-API escape hatch | no override (block when skill present) vs uniform `MYSTICAT_PR_SKILL_BYPASS` env | uniform bypass env as the human escape hatch — orthogonal to the recursion guard (now the in-body marker, which already covers every surface); keeps "router not gate" |
| Routing event | PreToolUse (intercept the tool call) vs UserPromptSubmit (intercept the prompt) | PreToolUse — it sees the actual action and arguments; UserPromptSubmit fires too early and would block the whole turn |
| Hook registration | committed workspace `.claude/settings.json` vs per-user | committed workspace settings — applies to every session, reviewable in-repo |
| `gh pr create --web` | route through the skill vs allow through | allow through — it opens a browser for the human to fill the body |
| Intercept scope | creation only vs also comments/reviews | creation only — the hook never touches existing-PR interactions |
| Hook coverage | Claude Code agent only vs all clients | agent only — guard where the agent creates PRs; non-agent clients are out of scope (server-side control if ever needed) |
| Template vs repo template | replace at create time vs merge with repo template | replace (one consistent body); surface repo-specific critical items in §6/§7 |
| Conditional sections | drop-when-empty vs always render with "N/A" | drop-when-empty |
| AI disclosure | full checklist/disclosure section vs fixed footer | fixed `🤖 Generated with Claude Code` footer (lightweight) |
| Plugin placement | new `mysticat-dev` plugin vs existing `review-kit` plugin | existing `review-kit` plugin (alongside `pr-review`) — coordinated PR lifecycle, shared create-vs-review discovery parity, one install; skills auto-discover so no manifest change. (Superseded the original "new plugin" choice during implementation planning.) |
| Grounding: threshold + discovery | spec AND plan, body-only vs spec-only, all-sources | discover from all sources; degrade only on a missing spec; trivial PRs exempt |
| Degraded review severity | advisory banner vs hard block | advisory; a hard block would be hostile to small/independent changes |
| PR template storage | inline in spec/SKILL.md vs dedicated `assets/pr_template.md` file | dedicated file; read from disk, copied verbatim from the spec companion file |

## Success Criteria

### Functional Requirements
- [ ] `create-pr` opens a PR whose body is the rendered 8-section template with all `{{TOKEN}}`s filled, all `AGENT:` instruction comments stripped (the `<!-- mysticat-pr-skill -->` marker retained), and the `🤖 Generated with Claude Code` footer present.
- [ ] Empty optional placeholders/bullets are removed whole (no dangling `- Spec:`); an unresolvable token fails the skill.
- [ ] Conditional sections (5, 6, 8) are present when applicable and absent otherwise.
- [ ] The hook blocks raw `gh pr create`, direct-API PR creation, and MCP create-PR when the skill is present, and instructs the model to use the skill.
- [ ] The hook allows `gh pr create --web`, any PR-create whose resolved body carries the `<!-- mysticat-pr-skill -->` marker (gh, direct-API, or MCP), and any surface when `MYSTICAT_PR_SKILL_BYPASS=1` is set.
- [ ] The hook does NOT match existing-PR interactions (comments, reviews, lists, merges).
- [ ] The hook allows raw creation with a stderr warning when the skill is absent.
- [ ] `pr-review` posts a "degraded review" banner when no spec is discoverable across all sources and the PR is not exempt, and omits it when a spec (or an exemption) exists.

### Non-Functional Requirements
- [ ] The hook adds negligible latency and is a clean no-op on unrelated Bash calls.
- [ ] No `{{TOKEN}}` or `AGENT:` instruction comment ever reaches a published PR body (the sanctioned, invisible `<!-- mysticat-pr-skill -->` marker is the one intentional exception).
- [ ] The degraded-review gate never blocks or fails an otherwise valid review.

### Validation Plan
Hook (unit-testable via stdin fixtures, like existing hooks): unrelated Bash → no-op; `gh pr create --web` → allowed; a body carrying the `<!-- mysticat-pr-skill -->` marker → allowed (recursion guard), exercised across all three resolved-body forms — `gh pr create --body-file <tmp>` (hook reads the file), a `curl`/`gh api .../pulls` POST whose body carries the marker, and MCP `create_pull_request` with the marker in `tool_input.body`; `MYSTICAT_PR_SKILL_BYPASS=1` → allowed on every surface; `gh pr create` no marker, skill present → deny; skill absent → exit 0 + stderr warning; `gh api .../pulls` POST and `curl .../pulls` POST without the marker, skill present → deny, absent → warn+allow; `gh api .../pulls/{n}/comments` POST → no-op (creation-only scope); MCP create-PR no marker, present → deny, absent → warn+allow; `gh pr create --body-file <missing/unreadable path>` (body unresolvable at hook-fire time) → deny when the skill is present (fail-safe: an unresolvable body degrades to the raw-call path, never a silent allow).
Skill: renders all sections from a sample session; empty optional → bullet removed; footer present; the `<!-- mysticat-pr-skill -->` marker present and all `AGENT:` comments stripped; produces a valid body file and a well-formed create invocation via the available transport (MCP or gh); `npm run validate` passes; marketplace entry resolves.
pr-review: spec discoverable → no banner; no spec found → banner present in posted review; exempt PR (label or `Exemption:` bullet) → no banner; gate never blocks. **Worker no-clone fixture (the primary production path):** a PR whose spec lives in `mysticat-architecture` and is reachable only via `get_file_contents` (touched repo's `AGENTS.md` links up; `mysticat-architecture` is NOT cloned) → spec discovered through the reused Phase 2.1 `upstream_docs_paths` fetch, **no degraded banner** — pinning the D1/D2 regression so the gate can't silently under-discover in the worker. **Create-vs-review consistency:** for that same PR shape, the create-pr skill resolves the `mysticat-architecture` spec into section 4 (it is not dropped), so the skill and the gate agree.

## Dependencies

### External
- GitHub (`gh` CLI, direct REST/GraphQL API, and/or GitHub MCP) for PR creation and review posting.
- Claude Code hooks (PreToolUse) and skills (marketplace plugin install).

### Internal
- `experience-success-skills` marketplace + `enabledPlugins` so the skill is discoverable and the hook's presence-check passes.
- `review-kit` `pr-review` skill (the grounding gate modifies it).
- `mysticat-workspace` `.claude/settings.json` and `hooks/` conventions (and `.mcp.json` for the MCP matcher names).

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Recursion: hook blocks the skill's own PR-create (any transport) | High if unhandled | High | Transport-agnostic in-body marker (§A); explicit recursion-guard tests across gh `--body-file`, direct-API POST, and MCP `body` |
| Two Bash hooks now fire (pre-push + pr-route) | Certain | Low | Both must no-op cleanly on irrelevant commands; keep fast |
| Nudge not followed (model doesn't call the skill after deny) | Medium | Low | Imperative deny `message`; strong skill `description`; deny is idempotent, worst case is user intervention or bypass |
| Direct-API heuristics over/under-match; dynamic commands evade | Medium | Low | Advisory routing only; creation-only scope avoids matching comments/lists; false positive → "use the skill", false negative → raw PR |
| PR created outside the Claude Code agent (script/IDE/web) | Medium | Low | Out of scope by design (§B); team convention + skill-as-default; a server-side control could be added later if needed |
| MCP matcher drifts from `.mcp.json` server names | Low | Low | Documented as a living list to sync (§B) + loud CI/startup assertion (§B, Phase 2) |
| Claude Code hook API changes (matcher semantics, stdin shape, decision format) | Low | Medium | The hook's registration rests on the Appendix A mechanics, marked confirm-at-implementation; pin to the documented PreToolUse contract, keep the matcher as exact-name alternation, and the hook fails safe (a no-op/allow on any unrecognized input degrades to a raw PR, never a blocked session) |
| Template drift vs per-repo templates | Medium | Low | Template replaces at create time; repo checks stay in pre-commit/CI |
| Degraded-review false positives (spec exists but not found) or alert fatigue | Medium | Medium | Advisory only; all-source discovery; degrade only on missing spec; explicit exemption (§E) |
| gh unauthenticated / skill not installed | Low | Low | Fallback handles install; auth is the skill's pre-flight responsibility |

## References

- Dedicated PR template (this spec's companion): `docs/plans/2026-06-17-mysticat-pr-skill-template.md`.
- Documentation decision guide: `mysticat-architecture/DOCUMENTATION-GUIDE.md` (why this spec lives in ai-native-guidelines).
- Existing PR template: `docs/03-templates/pull-request-template.md` — it suggests AI disclosure as a practice and links to vibeproofing (`docs/05-guardrails/must-rules.md`) for rationale. Note: vibeproofing itself does NOT mandate PR AI-disclosure, so the Mysticat footer is team convention, not a MUST.
- Existing review skill: `experience-success-skills/skills/review-kit/skills/pr-review/SKILL.md` (its Phase 2.1 cross-repo discovery is the machinery the §E gate reuses). The reviewer agents live one level up at `experience-success-skills/skills/review-kit/agents/` — `spec-compliance-reviewer.md` and `project-conventions-reviewer.md` (the latter owns the `project_docs_paths` / `upstream_docs_paths` lazy-fetch + status-discrimination contract), not under `skills/pr-review/`.
- Existing workspace hooks: `mysticat-workspace/hooks/pre-push-main-check.sh`, `hooks/lint-staged.sh`.

## Appendix A — Confirmed Claude Code mechanics (research basis)

- Hooks cannot call skills directly; they block/allow tool calls and inject text the model reads.
- `PreToolUse` stdin JSON includes `tool_name` and `tool_input` (`tool_input.command` for Bash; tool params for MCP).
- Matchers: a value containing `|` is alternation of **exact tool names** (this is what we rely on for the create-PR matcher — the three literal names `Bash`, `mcp__github__create_pull_request`, `mcp__github-enterprise__create_pull_request`); a matcher may instead be a regex when it contains regex metacharacters. We deliberately use exact-name alternation, not a regex, so the matcher is unambiguous. (This reflects documented hook-matcher behavior and the team's research; confirm against the installed Claude Code version when implementing.)
- All hooks across user/project/local settings run (merge, not override); any deny wins.
- Proven block format in this workspace: stdout `{"decision":"deny","message":"..."}`; silent exit 0 = allow/fall-through.
- Skills live under `~/.claude/skills/`, `<repo>/.claude/skills/`, or plugin install paths; identified by `SKILL.md`.

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-06-17 | Rainer Friederich | Initial draft (create-pr skill + routing hook + pr-review grounding gate) |
| 2026-06-17 | Rainer Friederich | Extract PR template to dedicated file; §D references it instead of inline |
| 2026-06-17 | Rainer Friederich | Review: cover direct GitHub API surface; sentinel threat model + uniform bypass; status → Draft |
| 2026-06-17 | Rainer Friederich | Review: empty-bullet rendering contract; matcher-tracks-.mcp.json, dynamic-command + repeated-deny notes; Appendix A matcher clarification |
| 2026-06-17 | Rainer Friederich | Fold all remaining decisions inline (skill home, allow `--web`, committed-workspace registration, Claude-Code-footer disclosure, all-source grounding degrading only on missing spec, creation-only scope, agent-only coverage); removed the Open Questions section |
| 2026-06-17 | Rainer Friederich | Review: correct vibeproofing attribution (footer is team convention, not a MUST); mark Appendix A matcher semantics confirm-at-implementation |
| 2026-06-17 | Rainer Friederich | Review (solaris007): widen skill spec discovery to match §E (close create-vs-review asymmetry); §E grounding reuses pr-review Phase 2.1 cross-repo machinery (worker no-clone safe); self-attested+visible exemption; matcher-vs-.mcp.json loud-failure assertion; fix reviewer-agent paths; worker no-clone validation fixture; footer canonical markdown form; reworded AFFECTED_PROJECTS source |
| 2026-06-17 | Rainer Friederich | Review (MysticatBot, post-approval nits): clarify §E cross-repo docs are link-chain-dependent (not implicit search targets); trim template §4 comment to actionable search instructions; add "Claude Code hook API changes" risk row |
| 2026-06-17 | Rainer Friederich | Review (iuliag): replace the inline `gh`-only `MYSTICAT_PR_SKILL=1` recursion sentinel with a transport-agnostic in-body marker `<!-- mysticat-pr-skill -->` (§A); hook resolves the body per surface (gh `--body-file`/inline, gh api/curl, MCP `body`) and allows on the marker; §C drops the `gh` hardcode; updated §D, decision table, alternatives, risks, success criteria, validation, §F |
| 2026-06-17 | Rainer Friederich | Add §G observability: review-cost split by a low-cardinality `grounding` label (spec_found/degraded/exempt) on the existing cost metric, with confounder caveat + optional fetch-volume metric; plus a deferred review-quality measurement note (one-time controlled replay + pairwise/LLM-judge eval on spec-bearing PRs; continuous proxies = footer-reaction read-back + grounding-labelled verdict/finding split) |
| 2026-06-17 | Rainer Friederich | Add §H future-work note: in-session post-push PR-description sync (PostToolUse hook detects drift via a creation-time body marker → nudges create-pr update mode; watches `git push` + GitHub MCP file-commit tools, agent-only; depends on create-pr skill with §B/§F fallback; spec-drift flag extends §E; centralized backstop = MysticatBot webhook, not per-repo Actions) |
| 2026-06-18 | Rainer Friederich | Review (MysticatBot nits): §G "upper bound" clarified (cost attributable to the gate, not total); §A forward-references the §H marker extension (match on marker key, not literal); split this revision-history entry into per-change rows; §G quality methodology marked illustrative/confirm-at-implementation; validation plan adds the unresolvable `--body-file` fail-safe case |
| 2026-06-18 | Rainer Friederich | Implementation-planning reconciliation: plugin placement changed from a new `mysticat-dev` plugin to the existing `review-kit` plugin (alongside `pr-review`) — coordinated PR lifecycle, shared discovery parity, one install, skills auto-discover (no manifest change). Updated §B, §C, the overview diagram, and the Alternatives "Plugin placement" row. Done in the implementation-plan PR so the spec and plan stay consistent |
