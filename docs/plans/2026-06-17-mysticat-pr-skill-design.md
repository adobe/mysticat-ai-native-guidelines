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
│  skills/mysticat-dev/skills/create-pr/                                │
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

#### A. Control surface: the sentinel and the bypass (read first)

**Threat model.** This routing is a **convenience guard** to keep PR bodies consistent, **not a security boundary**. Both markers below are trivially settable by any user or agent — intentionally, because the skill must never be a hard gate (see non-goals). Substring matching is therefore acceptable; tightening it would add fragility without adding a real control. Nothing here prevents a determined caller from opening a raw PR; the goal is to make the *templated* path the default and the *raw* path a conscious choice.

Two markers, with distinct roles:

1. **`MYSTICAT_PR_SKILL=1` — the skill's own-call sentinel (recursion guard).** A skill is just instructions; it has no special PR API. When the model runs `create-pr`, the skill ultimately executes `gh pr create`, which is itself a Bash tool call — so the hook fires again and would block the skill's own PR creation, an infinite loop. The skill avoids this by prefixing its command inline:

   ```bash
   MYSTICAT_PR_SKILL=1 gh pr create --body-file <generated-body> ...
   ```

   The hook receives the Bash command as a string in `tool_input.command`; because the sentinel is written inline, it appears in that string and the hook detects it there (it does not rely on the hook process's own environment). Rule: a PR-create command that contains `MYSTICAT_PR_SKILL=1` is allowed.

2. **`MYSTICAT_PR_SKILL_BYPASS=1` — the human/operator override (escape hatch).** Read by the hook from **its own process environment**. When set, the hook no-ops (allows) on every surface — Bash, direct API, and MCP — optionally emitting a one-line stderr note. This is the documented override for "I deliberately want a raw PR", and it is the answer to "what if the skill has a bug or the environment is MCP-only": set the env var (or disable the skill). It is what keeps the hook a router, not a gate, uniformly across surfaces — the MCP and direct-API paths cannot carry an inline sentinel, so the env override is their escape hatch.

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

**Matcher names track `.mcp.json`.** The `mcp__github__create_pull_request` / `mcp__github-enterprise__create_pull_request` entries are the *configured MCP server names* from the workspace `.mcp.json` (server name + tool name). Treat the matcher as a living list: if the GitHub MCP server is renamed, removed, or a new GitHub MCP server is added, the matcher must be kept in sync. The `Bash` arm is stable; only the MCP arm is config-coupled.

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
| `Bash` | not a PR-create pattern (no `gh pr create` / direct-API create match) | exit 0, no output (no-op) |
| `Bash` | `gh pr create --web` | exit 0, no output (allow — human fills body in browser) |
| `Bash` | PR-create command contains `MYSTICAT_PR_SKILL=1` | exit 0, no output (allow — skill's own call) |
| `Bash` | `gh pr create`, no sentinel, skill present | deny + instruct model to use the skill |
| `Bash` | `gh pr create`, no sentinel, skill absent | exit 0 + stderr warning (allow fallback) |
| `Bash` | direct-API PR-create (gh api / graphql / curl), skill present | deny + instruct model to use the skill |
| `Bash` | direct-API PR-create, skill absent | exit 0 + stderr warning (allow fallback) |
| `mcp__github*__create_pull_request` | skill present | deny + instruct model to use the skill |
| `mcp__github*__create_pull_request` | skill absent | exit 0 + stderr warning (allow fallback) |

**Output format** — use the repo's proven legacy shape (as in `pre-push-main-check.sh`): block with stdout `{"decision":"deny","message":"<imperative reason naming the skill>"}`; for the fallback warning, exit 0 and write the warning to stderr. Avoid the newer `hookSpecificOutput.permissionDecision` fields and speculative values (`"defer"`, `updatedInput`, per-hook `if:`) — unverified in research.

**Skill-presence detection.** The `create-pr` skill is distributed in the **`experience-success-skills`** repo as part of the **`mysticat-dev` plugin** (adobe-experience-success marketplace) and installed like the team's other plugins. The hook detects its presence by globbing for the skill's `SKILL.md` across the Claude Code skill roots: the plugin install root (the marketplace-installed `mysticat-dev` plugin), the project skill dir (`<repo>/.claude/skills/create-pr/SKILL.md`), and the personal skill dir (`~/.claude/skills/create-pr/SKILL.md`). Any match → present. (The implementation reads the live plugin install location from the Claude Code plugin layout rather than assuming a fixed string.)

**Scope — Claude Code agent only.** By design the hook covers only the Claude Code agent's tool calls (`Bash` and the named MCP tools). PRs opened from anywhere else — an opaque script (`python create_pr.py` using PyGithub/requests, a Node script using octokit), an IDE button, the GitHub web UI, or any non-Claude-Code tooling — are out of scope and are not intercepted. This is deliberate: the hook is a guard *for the agent*, where consistency most needs help, not an org-wide enforcement layer. Broader coverage, if ever wanted, belongs in a server-side control (e.g. a GitHub Action), not this hook.

#### C. Skill (experience-success-skills)

- Placement: new plugin `mysticat-dev` (dev-workflow skills), skill `create-pr` inside it. Layout `skills/mysticat-dev/skills/create-pr/{SKILL.md, assets/pr_template.md, scripts/}`; register in `marketplace.json`.
- SKILL.md frontmatter follows repo convention (`name`, `description`, `user-invocable`, `argument-hint`; no em-dashes in body). The description must be strong enough that the model reliably selects the skill when the hook nudges it.
- Workflow: (1) pre-flight (gh authenticated, not on default branch, branch pushed); (2) gather session context (branch, `git log` since base, diff summary, Jira keys, what was verified); (3) render the body from `assets/pr_template.md` to a temp file; (4) create the PR with the sentinel: `MYSTICAT_PR_SKILL=1 gh pr create --base <base> --title "<title>" --body-file <tmp-body> [--draft]`; (5) report the PR URL.
- Scripts: existing plugins are Python 3 stdlib. Default to no scripts; a small stdlib `render_body.py` is justified only if deterministic rendering / Jira-key extraction proves fiddly.

#### D. The bundled PR template

The template is a **dedicated standalone file** — `assets/pr_template.md` in the skill — never inlined in code or `SKILL.md`; the skill reads it from disk at render time. Its canonical source ships as a **separate file alongside this spec**, [`2026-06-17-mysticat-pr-skill-template.md`](2026-06-17-mysticat-pr-skill-template.md). The template proper is the content **between the `---` markers** of that companion file (the H1, introduction, and example outside the markers are documentation, per this repo's doc rules, and are NOT part of the PR body); at implementation that between-markers content is copied **verbatim** into the skill's `assets/pr_template.md`. The companion file holds the full eight-section template; it is intentionally not reproduced inline here, to keep a single source of truth.

Properties of the template (full text in the companion file):
- It is the single source of truth and **replaces** whatever `pull_request_template.md` lives in the target repo.
- Eight sections; sections 5, 6, and 8 are conditional (the skill drops the whole section when not applicable).
- Each section carries an `<!-- AGENT: ... -->` instruction comment (stripped after filling) and a `{{TOKEN}}` placeholder (replaced). The skill MUST replace every token, strip every comment, and fill-or-remove each conditional section; a leftover `{{TOKEN}}` is a bug and the skill should fail rather than open a PR with raw placeholders.
- A fixed `🤖 Generated with Claude Code` footer is appended at the end of every body (lightweight AI-usage disclosure — see "AI disclosure" below).

**Rendering contract for empty values.** This is the contract an implementer (or the optional `render_body.py`) MUST follow, stated here so it does not live only in a stripped instruction comment: when a placeholder — or a section-4 bullet's value — resolves to **empty/null**, the skill removes the **entire line or bullet**, not just the `{{TOKEN}}`, so no dangling `- Spec:` remains. The "leftover token is a bug → fail" rule applies only to a token the skill *cannot resolve at all*, which is distinct from a deliberately-empty optional that is removed cleanly.

**Fill-guide (placeholder → content → data source):**

| Placeholder | What the skill writes | Primary source |
|---|---|---|
| `{{ABSTRACT}}` | 1-2 sentence what-is-this | branch name, PR title, Jira summary, diff summary |
| `{{REASONING}}` | the why / trigger | Jira/issue description, commit messages, session context |
| `{{OVERVIEW}}` | behaviour delta (before->after), human-readable | diff analysis + the model's understanding of the change |
| `{{JIRA_LINK}}` | issue key + URL (e.g. `SITES-1234`) | issue keys parsed from branch/commits/session; remove bullet if none |
| `{{SPEC_LINK}}` / `{{PLAN_LINK}}` / `{{ADR_LINK}}` | links to spec/plan/ADR | `docs/` in touched repos (`decisions/`, `plans/`, `proposals/`), session context; remove bullet if none |
| `{{OTHER_LINKS}}` | any other relevant links | session context; remove bullet if none |
| `{{AFFECTED_PROJECTS}}` | bullet list of workspace repos touched/depended-on + nature | diff scope across repos + cross-repo contract reasoning; drop section if none |
| `{{OUTSIDE_CODE_INFO}}` | manual/agent validation results + infra observations | session record; drop section if none |
| `{{TEST_PLAN}}` | (a) local e2e done + result, (b) per-env verification steps | session record + the model's plan for eph/dev/stage/prod |
| `{{DEPLOYMENT_ORDER}}` | dependent/related PRs + required merge/deploy sequence | session context, related PRs; drop section if independent |

**Hard exclusions (the skill must NOT write these into the body).** The body is for humans reviewing intent and behaviour, not a CI report:
- Code examples / snippets (reviewers read the diff).
- Counts of passing tests (e.g. "all 412 tests pass", "added 7 tests").
- Static-analysis / lint success statements (e.g. "lint clean", "type-check green").

These are enforced by the rendering step (and a skill test). A known *failure or gap* worth attention may still be described in prose — the exclusion is about pass/clean status and code, not about flagging a real problem.

**AI disclosure.** The template ends with a fixed `🤖 Generated with Claude Code` footer. This is the team's lightweight AI-usage disclosure; the Mysticat template does not adopt the fuller checklist/disclosure form of the generic `docs/03-templates/pull-request-template.md`. The two templates coexist — the generic one for repos not using the skill, the Mysticat one (with the footer) for skill-created PRs.

**Notes.** Conditional sections drop when empty. No checklist section — repo-specific mechanical checks (cassette scrubbing, test speed markers, API-spec updates) stay enforced by each repo's pre-commit/CI; where a touched repo has critical checklist items the skill surfaces them in section 6 or 7. Workspace conventions honoured: Jira key format per workspace rules; no `#`-prefixed enumeration (GitHub auto-links them to unrelated PRs).

#### E. pr-review grounding gate (review-kit)

`pr-review` is a three-phase multi-agent skill (Triage → parallel specialist reviews → consolidate + post). The grounding gate adds two touch points:

- **Phase 1 (Triage):** gather the PR's grounding from **all available sources** — the PR body's section-4 links, the touched repos' `docs/` (specs, plans, ADRs), the architecture and AI-native-guidelines docs, and any linked Jira issue. From that, determine whether a **spec document** exists for the change.
- **Phase 3 (Consolidate + post):** when no spec is found (and the PR is not exempt), prepend a prominent **"⚠ Degraded review"** banner to the consolidated review and include it in the body posted to GitHub. Suggested wording: *"Degraded review — no spec document was found for this change (searched the PR links, the touched repos' docs, the architecture/guidelines docs, and linked Jira). This review covers code-level quality but could not validate the change against an agreed design, so confidence is reduced. Add a spec link (PR template section 4) and re-request review for a full-confidence pass."*

Design points:
- **Discover from all sources; degrade only on a missing spec.** Grounding is collected from every available source above. The degraded-review banner is triggered **specifically by the absence of a spec document** — the design-of-record. A missing implementation plan, ADR, or Jira link alone does NOT degrade the review (those enrich it but are not the bar); only a missing spec does.
- **Exemption.** Trivial/mechanical PRs (typo, dependency bump, formatting) where no spec is warranted are exempt via either a `no-spec-needed` label on the PR or an `Exemption: <reason>` bullet in section 4. Exempted PRs get no degraded banner. This keeps the signal meaningful and avoids alert fatigue.
- **Severity is advisory, not blocking.** The review still runs and posts; the banner adjusts stated confidence.
- **Complements the existing `spec-compliance-reviewer` agent.** That agent checks implementation-vs-spec *when a spec exists*; the grounding gate handles the *absence* case (no spec → spec-compliance cannot run → degraded). It also fits the Always-on `project-conventions-reviewer`'s remit of checking alignment with documented contracts.

#### F. Fallback behavior

The fallback is why the hook is a router, not a gate. Skill absent (not installed/enabled, or presence-glob finds nothing) → warn + allow: the PR is created the original way and the user sees the stderr warning. No PR is ever blocked outright by skill absence. The only hard block is a non-sanctioned raw call while the skill is present — and the model can re-issue through the skill (which carries the sentinel and passes), or the operator can set `MYSTICAT_PR_SKILL_BYPASS=1`.

### Implementation Phases

**Phase 1 — Skill.** Land `create-pr` (plugin + skill + template) in `experience-success-skills`; enable it; verify end-to-end PR creation with the sentinel.

**Phase 2 — Hook.** Land `pr-route-to-skill.sh` + settings registration in `mysticat-workspace` once the skill is installable, so the presence-check has something to find.

**Phase 3 — pr-review grounding gate.** Add the Phase-1 grounding discovery and Phase-3 banner to `review-kit/skills/pr-review`.

Three separate PRs (two repos). The skill PR should merge first so the hook's "present" path is exercisable; the pr-review change is independent and can land in parallel.

## Alternatives Considered

| Decision | Options | Verdict |
|---|---|---|
| Routing as security vs convenience | hard gate / security boundary vs convenience guard with override | convenience guard; a hard gate contradicts the non-goals and cannot be enforced against non-agent clients anyway |
| Recursion sentinel | env-var prefix; `--body-file`-path check; wrapper script | env-var prefix (simplest); revisit if brittle |
| MCP/direct-API escape hatch | no override (block when skill present) vs uniform `MYSTICAT_PR_SKILL_BYPASS` env | uniform bypass env; keeps "router not gate" on surfaces that cannot carry an inline sentinel |
| Routing event | PreToolUse (intercept the tool call) vs UserPromptSubmit (intercept the prompt) | PreToolUse — it sees the actual action and arguments; UserPromptSubmit fires too early and would block the whole turn |
| Hook registration | committed workspace `.claude/settings.json` vs per-user | committed workspace settings — applies to every session, reviewable in-repo |
| `gh pr create --web` | route through the skill vs allow through | allow through — it opens a browser for the human to fill the body |
| Intercept scope | creation only vs also comments/reviews | creation only — the hook never touches existing-PR interactions |
| Hook coverage | Claude Code agent only vs all clients | agent only — guard where the agent creates PRs; non-agent clients are out of scope (server-side control if ever needed) |
| Template vs repo template | replace at create time vs merge with repo template | replace (one consistent body); surface repo-specific critical items in §6/§7 |
| Conditional sections | drop-when-empty vs always render with "N/A" | drop-when-empty |
| AI disclosure | full checklist/disclosure section vs fixed footer | fixed `🤖 Generated with Claude Code` footer (lightweight) |
| Plugin placement | new `mysticat-dev` plugin vs existing plugin | new plugin; no existing plugin is a clean fit |
| Grounding: threshold + discovery | spec AND plan, body-only vs spec-only, all-sources | discover from all sources; degrade only on a missing spec; trivial PRs exempt |
| Degraded review severity | advisory banner vs hard block | advisory; a hard block would be hostile to small/independent changes |
| PR template storage | inline in spec/SKILL.md vs dedicated `assets/pr_template.md` file | dedicated file; read from disk, copied verbatim from the spec companion file |

## Success Criteria

### Functional Requirements
- [ ] `create-pr` opens a PR whose body is the rendered 8-section template with all `{{TOKEN}}`s filled, all instruction comments stripped, and the `🤖 Generated with Claude Code` footer present.
- [ ] Empty optional placeholders/bullets are removed whole (no dangling `- Spec:`); an unresolvable token fails the skill.
- [ ] Conditional sections (5, 6, 8) are present when applicable and absent otherwise.
- [ ] The hook blocks raw `gh pr create`, direct-API PR creation, and MCP create-PR when the skill is present, and instructs the model to use the skill.
- [ ] The hook allows `gh pr create --web`, the skill's sentinel-carrying call, and any surface when `MYSTICAT_PR_SKILL_BYPASS=1` is set.
- [ ] The hook does NOT match existing-PR interactions (comments, reviews, lists, merges).
- [ ] The hook allows raw creation with a stderr warning when the skill is absent.
- [ ] `pr-review` posts a "degraded review" banner when no spec is discoverable across all sources and the PR is not exempt, and omits it when a spec (or an exemption) exists.

### Non-Functional Requirements
- [ ] The hook adds negligible latency and is a clean no-op on unrelated Bash calls.
- [ ] No `{{TOKEN}}` or instruction comment ever reaches a published PR body.
- [ ] The degraded-review gate never blocks or fails an otherwise valid review.

### Validation Plan
Hook (unit-testable via stdin fixtures, like existing hooks): unrelated Bash → no-op; `gh pr create --web` → allowed; `gh pr create` + sentinel → allowed (recursion guard); `MYSTICAT_PR_SKILL_BYPASS=1` → allowed on every surface; `gh pr create` no sentinel, skill present → deny; skill absent → exit 0 + stderr warning; `gh api .../pulls` POST and `curl .../pulls` POST, skill present → deny, absent → warn+allow; `gh api .../pulls/{n}/comments` POST → no-op (creation-only scope); MCP create-PR present → deny, absent → warn+allow.
Skill: renders all sections from a sample session; empty optional → bullet removed; footer present; produces a valid body file and a well-formed sentinel-carrying invocation; `npm run validate` passes; marketplace entry resolves.
pr-review: spec discoverable → no banner; no spec found → banner present in posted review; exempt PR → no banner; gate never blocks.

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
| Recursion: hook blocks the skill's own `gh pr create` | High if unhandled | High | Sentinel (§A); explicit recursion-guard test |
| Two Bash hooks now fire (pre-push + pr-route) | Certain | Low | Both must no-op cleanly on irrelevant commands; keep fast |
| Nudge not followed (model doesn't call the skill after deny) | Medium | Low | Imperative deny `message`; strong skill `description`; deny is idempotent, worst case is user intervention or bypass |
| Direct-API heuristics over/under-match; dynamic commands evade | Medium | Low | Advisory routing only; creation-only scope avoids matching comments/lists; false positive → "use the skill", false negative → raw PR |
| PR created outside the Claude Code agent (script/IDE/web) | Medium | Low | Out of scope by design (§B); team convention + skill-as-default; a server-side control could be added later if needed |
| MCP matcher drifts from `.mcp.json` server names | Low | Low | Documented as a living list to sync (§B) |
| Template drift vs per-repo templates | Medium | Low | Template replaces at create time; repo checks stay in pre-commit/CI |
| Degraded-review false positives (spec exists but not found) or alert fatigue | Medium | Medium | Advisory only; all-source discovery; degrade only on missing spec; explicit exemption (§E) |
| gh unauthenticated / skill not installed | Low | Low | Fallback handles install; auth is the skill's pre-flight responsibility |

## References

- Dedicated PR template (this spec's companion): `docs/plans/2026-06-17-mysticat-pr-skill-template.md`.
- Documentation decision guide: `mysticat-architecture/DOCUMENTATION-GUIDE.md` (why this spec lives in ai-native-guidelines).
- Existing PR template: `docs/03-templates/pull-request-template.md` (AI-disclosure / vibeproofing).
- Existing review skill: `experience-success-skills/skills/review-kit/skills/pr-review/SKILL.md` and `agents/spec-compliance-reviewer.md`, `agents/project-conventions-reviewer.md`.
- Existing workspace hooks: `mysticat-workspace/hooks/pre-push-main-check.sh`, `hooks/lint-staged.sh`.

## Appendix A — Confirmed Claude Code mechanics (research basis)

- Hooks cannot call skills directly; they block/allow tool calls and inject text the model reads.
- `PreToolUse` stdin JSON includes `tool_name` and `tool_input` (`tool_input.command` for Bash; tool params for MCP).
- Matchers: a value containing `|` is alternation of **exact tool names** (this is what we rely on for the create-PR matcher — the three literal names `Bash`, `mcp__github__create_pull_request`, `mcp__github-enterprise__create_pull_request`); a matcher may instead be a regex when it contains regex metacharacters. We deliberately use exact-name alternation, not a regex, so the matcher is unambiguous.
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
