# Mysticat PR Skill + PR-Routing Hook + pr-review Grounding Gate

| Field | Value |
|-------|-------|
| **Status** | Draft / Review |
| **Author** | Rainer Friederich |
| **Created** | 2026-06-17 |
| **Updated** | 2026-06-17 |
| **Decided** | N/A |
| **Approvers** | N/A |
| **Jira** | N/A |

> Spec only — no implementation in this document. Cross-repo references use repo-relative paths anchored at each repo root (e.g. `mysticat-workspace/hooks/...`, `experience-success-skills/skills/...`).

## Summary

Proposes three coordinated changes so that pull requests are created and reviewed against one consistent, team-owned standard:

1. A Claude Code **`create-pr` skill** (in `experience-success-skills`) that opens a GitHub PR from a single skill-bundled template — eight narrative sections the skill fills from the current session.
2. A **PreToolUse hook** (in `mysticat-workspace`) that routes both `gh pr create` and the GitHub MCP create-PR tools through that skill, falling back to the normal path with a warning when the skill is unavailable.
3. A **`pr-review` grounding gate** (in `experience-success-skills` / `review-kit`) that scans a PR for linked spec / implementation-plan material and emits a **"degraded review"** notice when none is found, so reviewers know the change could not be validated against an agreed design.

Together: the template *captures* the spec/plan links, the hook *ensures the template is used*, and pr-review *enforces* that grounding exists.

## Problem Statement

### Current State
- PRs are opened two ways with no shared structure: `gh pr create` in a Bash call, and the GitHub MCP create-PR tools (`mcp__github__create_pull_request` plus the enterprise variant).
- Per-repo `pull_request_template.md` files are inconsistent (detailed checklist, minimal, or none). This repo also has a generic AI-disclosure PR template (`docs/03-templates/pull-request-template.md`) not wired to any automation.
- `pr-review` (review-kit) runs a strong multi-agent review but does not check whether a PR is grounded in a spec or implementation plan, so a change with no agreed design is reviewed with the same apparent confidence as one that has one.

### Desired State
- One team-owned PR template travels with a skill and is filled automatically from session context.
- PR creation is routed through the skill regardless of which surface (gh or MCP) the agent reaches for, and degrades gracefully when the skill is absent.
- `pr-review` flags ungrounded PRs as degraded reviews, closing the loop between "PR template asks for a spec/plan link" and "review checks it is there".

### Gap Analysis
- No single source of truth for PR body structure.
- No automation encouraging or enforcing a consistent body.
- Two distinct creation surfaces (gh, MCP) to cover.
- Must not break PR creation where the skill is not installed.
- Review confidence is not adjusted for absence of a spec/plan.

## Goals and Non-Goals

### Goals
- A single `create-pr` skill that creates a GitHub PR using a template bundled with the skill, not pulled from the target repo.
- The template has static sections and session-derived sections the skill fills automatically.
- A workspace hook that intercepts both PR-creation surfaces and routes them through the skill.
- Graceful fallback: if the skill is unavailable, the hook lets the normal `gh`/MCP call proceed and emits a warning (does not block).
- A `pr-review` enhancement that detects missing spec/implementation-plan grounding and surfaces a "degraded review" notice in the consolidated review.
- Follow existing `experience-success-skills` plugin/skill conventions and existing `mysticat-workspace` hook conventions.

### Non-Goals
- Replacing or deleting per-repo `pull_request_template.md` files (the skill template supersedes them at create time; the files stay).
- Auto-merging, review-requesting, or PR lifecycle management beyond creation.
- Changing how branches/commits are produced. The skill assumes the branch is pushed (or pushes as part of its flow).
- Forcing the skill on. The hook is a router with a fallback, not a hard gate.
- Making the degraded-review notice a hard block. It annotates and reduces stated confidence; it does not fail the review.

## Proposed Solution

### Overview

Three artifacts working together:

```
┌─────────────────────────────────────────────────────────────────────┐
│ mysticat-workspace                                                    │
│  .claude/settings.json  ──registers──▶  hooks/pr-route-to-skill.sh    │
│        (PreToolUse: Bash + mcp github create-PR matchers)             │
└───────────────────────────────┬──────────────────────────────────────┘
                                 │ intercepts gh pr create / MCP create-PR
                                 ▼
                  ┌──────────────────────────────┐
                  │  Is the create-pr skill there?│
                  └───────────┬───────────┬───────┘
                         yes  │           │  no
                              ▼           ▼
                 deny + instruct      exit 0 + stderr warning
                 "use the skill"      (gh/MCP call proceeds)
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│ experience-success-skills                                            │
│  skills/<plugin>/skills/create-pr/                                    │
│        SKILL.md                  ← gather session context            │
│        assets/pr_template.md     ← the bundled 8-section template     │
│                                                                       │
│  skills/review-kit/skills/pr-review/  (grounding gate)               │
│        Phase 1: scan PR for spec/plan links → degraded flag          │
│        Phase 3: prepend "degraded review" banner when ungrounded     │
└─────────────────────────────────────────────────────────────────────┘
```

**Routing mechanism (researched, confirmed).** A Claude Code hook cannot directly invoke a skill — hooks are shell commands run by the harness; skills are invoked by the model. The hook therefore *blocks* the PR-creation tool call and *injects an instruction* telling the model to call the skill. The model then chooses to invoke it. This is a reliable block plus a strong nudge (not a hard guarantee — see Risks).

### Technical Design

#### A. The recursion trap and the sentinel (read first)

A skill is just instructions — it has no special PR API. When the model runs `create-pr`, the skill ultimately executes `gh pr create`. That call is itself a Bash tool call, so the hook fires again and would block the skill's own PR creation, an infinite loop.

**Solution: an inline environment-variable sentinel on the command string.**

```bash
MYSTICAT_PR_SKILL=1 gh pr create --body-file <generated-body> ...
```

- The hook receives the Bash command as a string in `tool_input.command`. Because the sentinel is written inline, it appears in that string, so the hook detects it there — it does not depend on the hook process's own environment.
- Rule: command contains `gh pr create` AND does not contain `MYSTICAT_PR_SKILL=1` → block & route. Sentinel present → allow.
- The MCP create-PR tools have no sentinel and no legitimate skill use (the skill always uses `gh` so it can pass `--body-file`). The hook blocks them whenever the skill is present, and falls back when it is absent.

#### B. Hook (mysticat-workspace)

- Script: `mysticat-workspace/hooks/pr-route-to-skill.sh` (executable). Mirrors the existing hook style (`pre-push-main-check.sh`, `lint-staged.sh`): read JSON from stdin, inspect `tool_input`, emit a JSON decision or nothing.
- Registration in `mysticat-workspace/.claude/settings.json` under `PreToolUse`, using the repo's directory-walk command pattern. One matcher entry covers both surfaces:

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

**Decision table:**

| Tool | Condition | Action |
|---|---|---|
| `Bash` | command does not contain `gh pr create` | exit 0, no output (no-op) |
| `Bash` | contains `gh pr create` and `MYSTICAT_PR_SKILL=1` | exit 0, no output (allow — skill's own call) |
| `Bash` | contains `gh pr create`, no sentinel, skill present | deny + instruct model to use the skill |
| `Bash` | contains `gh pr create`, no sentinel, skill absent | exit 0 + stderr warning (allow fallback) |
| `mcp__github*__create_pull_request` | skill present | deny + instruct model to use the skill |
| `mcp__github*__create_pull_request` | skill absent | exit 0 + stderr warning (allow fallback) |

**Output format** — use the repo's proven legacy shape (as in `pre-push-main-check.sh`): block with stdout `{"decision":"deny","message":"<imperative reason naming the skill>"}`; for the fallback warning, exit 0 and write the warning to stderr. Avoid the newer `hookSpecificOutput.permissionDecision` fields and speculative values (`"defer"`, `updatedInput`, per-hook `if:`) — unverified in research.

**Skill-presence detection** — glob for the skill's `SKILL.md` across known roots: marketplace install path (`~/.claude/plugins/**/skills/create-pr/SKILL.md`), project (`<repo>/.claude/skills/create-pr/SKILL.md`), personal (`~/.claude/skills/create-pr/SKILL.md`). Any match → present.

#### C. Skill (experience-success-skills)

- Placement: new plugin `mysticat-dev` (dev-workflow skills), skill `create-pr` inside it. Layout `skills/mysticat-dev/skills/create-pr/{SKILL.md, assets/pr_template.md, scripts/}`; register in `marketplace.json`.
- SKILL.md frontmatter follows repo convention (`name`, `description`, `user-invocable`, `argument-hint`; no em-dashes in body). The description must be strong enough that the model reliably selects the skill when the hook nudges it.
- Workflow: (1) pre-flight (gh authenticated, not on default branch, branch pushed); (2) gather session context (branch, `git log` since base, diff summary, Jira keys, what was verified); (3) render the body from `assets/pr_template.md` to a temp file; (4) create the PR with the sentinel: `MYSTICAT_PR_SKILL=1 gh pr create --base <base> --title "<title>" --body-file <tmp-body> [--draft]`; (5) report the PR URL.
- Scripts: existing plugins are Python 3 stdlib. Default to no scripts; a small stdlib `render_body.py` is justified only if deterministic rendering / Jira-key extraction proves fiddly.

#### D. The bundled PR template

The template is a **dedicated standalone file** — `assets/pr_template.md` in the skill — never inlined in code or `SKILL.md`; the skill reads it from disk at render time. Its canonical source ships as a **separate file alongside this spec**, [`2026-06-17-mysticat-pr-skill-template.md`](2026-06-17-mysticat-pr-skill-template.md), and is copied **verbatim** into the skill's `assets/` at implementation. That companion file holds the full eight-section template (placeholders + instruction comments); it is intentionally not reproduced inline here, to keep a single source of truth.

Properties of the template (full text in the companion file):
- It is the single source of truth and **replaces** whatever `pull_request_template.md` lives in the target repo.
- Eight sections; sections 5, 6, and 8 are conditional (the skill drops the whole section when not applicable).
- Each section carries an `<!-- AGENT: ... -->` instruction comment (stripped after filling) and a `{{TOKEN}}` placeholder (replaced). The skill MUST replace every token, strip every comment, and fill-or-remove each conditional section; a leftover `{{TOKEN}}` is a bug and the skill should fail rather than open a PR with raw placeholders.

**Fill-guide (placeholder → content → data source):**

| Placeholder | What the skill writes | Primary source |
|---|---|---|
| `{{ABSTRACT}}` | 1-2 sentence what-is-this | branch name, PR title, Jira summary, diff summary |
| `{{REASONING}}` | the why / trigger | Jira/issue description, commit messages, session context |
| `{{OVERVIEW}}` | behaviour delta (before->after), human-readable | diff analysis + the model's understanding of the change |
| `{{JIRA_LINK}}` | issue key + URL (e.g. `SITES-1234`) | issue keys parsed from branch/commits/session; omit bullet if none |
| `{{SPEC_LINK}}` / `{{PLAN_LINK}}` / `{{ADR_LINK}}` | links to spec/plan/ADR | `docs/` in touched repos (`decisions/`, `plans/`, `proposals/`), session context; omit bullet if none |
| `{{OTHER_LINKS}}` | any other relevant links | session context; omit bullet if none |
| `{{AFFECTED_PROJECTS}}` | bullet list of workspace repos touched/depended-on + nature | diff scope across repos + cross-repo contract reasoning; drop section if none |
| `{{OUTSIDE_CODE_INFO}}` | manual/agent validation results + infra observations | session record; drop section if none |
| `{{TEST_PLAN}}` | (a) local e2e done + result, (b) per-env verification steps | session record + the model's plan for eph/dev/stage/prod |
| `{{DEPLOYMENT_ORDER}}` | dependent/related PRs + required merge/deploy sequence | session context, related PRs; drop section if independent |

**Hard exclusions (the skill must NOT write these into the body).** The body is for humans reviewing intent and behaviour, not a CI report:
- Code examples / snippets (reviewers read the diff).
- Counts of passing tests (e.g. "all 412 tests pass", "added 7 tests").
- Static-analysis / lint success statements (e.g. "lint clean", "type-check green").

These are enforced by the rendering step (and a skill test). A known *failure or gap* worth attention may still be described in prose — the exclusion is about pass/clean status and code, not about flagging a real problem.

**Notes.** Conditional sections drop when empty (chosen default; alternative is render-with-N/A). No checklist section — repo-specific mechanical checks (cassette scrubbing, test speed markers, API-spec updates) stay enforced by each repo's pre-commit/CI; where a touched repo has critical checklist items the skill surfaces them in section 6 or 7. Workspace conventions honoured: Jira key format per workspace rules; no `#`-prefixed enumeration (GitHub auto-links them to unrelated PRs).

**Reconciliation with this repo's existing PR template.** `docs/03-templates/pull-request-template.md` is a generic, checklist-and-AI-disclosure template (tied to the "vibeproofing" MUST rule). The Mysticat template is narrative/evidence oriented and currently has no AI-usage disclosure section. Whether to fold an AI-disclosure section into the Mysticat template is open question O7.

#### E. pr-review grounding gate (review-kit)

`pr-review` is a three-phase multi-agent skill (Triage → parallel specialist reviews → consolidate + post). The grounding gate adds two touch points:

- **Phase 1 (Triage):** after fetching PR metadata, scan the PR body's section 4 "Required information" for a linked **spec** and/or **implementation plan** (and ADR). Optionally also probe the touched repos and the architecture/guidelines docs for a matching spec/plan. Compute a `grounded` boolean.
- **Phase 3 (Consolidate + post):** when not grounded, prepend a prominent **"⚠ Degraded review"** banner to the consolidated review and include it in the body posted to GitHub. Suggested wording: *"Degraded review — no linked spec or implementation plan was found. This review covers code-level quality but could not validate the change against an agreed design, so confidence is reduced. Add a spec/plan link (PR template section 4) and re-request review for a full-confidence pass."*

Design points:
- **Severity is advisory, not blocking.** The review still runs and posts; the banner adjusts stated confidence.
- **Complements the existing `spec-compliance-reviewer` agent.** That agent checks implementation-vs-spec *when a spec exists*; the grounding gate handles the *absence* case (no spec → spec-compliance cannot run → degraded). It also fits the Always-on `project-conventions-reviewer`'s remit of checking alignment with documented contracts.
- **Grounding threshold** (what counts as grounded) and **discovery scope** (PR-body link only vs repo/Jira discovery) are open questions O8/O9.

#### F. Fallback behavior

The fallback is why the hook is a router, not a gate. Skill absent (not installed/enabled, or presence-glob finds nothing) → warn + allow: the PR is created the original way and the user sees the stderr warning. No PR is ever blocked outright by skill absence. The only hard block is a non-sanctioned raw call while the skill is present — and the model can re-issue through the skill (which carries the sentinel and passes).

### Implementation Phases

**Phase 1 — Skill.** Land `create-pr` (plugin + skill + template) in `experience-success-skills`; enable it; verify end-to-end PR creation with the sentinel.

**Phase 2 — Hook.** Land `pr-route-to-skill.sh` + settings registration in `mysticat-workspace` once the skill is installable, so the presence-check has something to find.

**Phase 3 — pr-review grounding gate.** Add the Phase-1 scan and Phase-3 banner to `review-kit/skills/pr-review`.

Three separate PRs (two repos). The skill PR should merge first so the hook's "present" path is exercisable; the pr-review change is independent and can land in parallel.

## Alternatives Considered

| Decision | Options | Verdict |
|---|---|---|
| Recursion sentinel | env-var prefix; `--body-file`-path check; wrapper script | env-var prefix (selected, simplest); revisit if brittle |
| Routing event | PreToolUse (intercept the tool call) vs UserPromptSubmit (intercept the prompt) | PreToolUse — it sees the actual action and arguments; UserPromptSubmit fires too early and would block the whole turn |
| Template vs repo template | replace at create time vs merge with repo template | replace (one consistent body); surface repo-specific critical items in §6/§7 |
| Conditional sections | drop-when-empty vs always render with "N/A" | drop-when-empty (selected); flip if reviewers want a fixed shape |
| Plugin placement | new `mysticat-dev` plugin vs existing plugin | new plugin (no existing plugin is a clean fit) |
| Degraded review severity | advisory banner vs hard block | advisory (selected); a hard block would be hostile to small/independent changes |
| PR template storage | inline in spec/SKILL.md vs dedicated `assets/pr_template.md` file | dedicated file (selected); read from disk, copied verbatim from the spec companion file |

## Success Criteria

### Functional Requirements
- [ ] `create-pr` opens a PR whose body is the rendered 8-section template with all `{{TOKEN}}`s filled and all instruction comments stripped.
- [ ] Conditional sections (5, 6, 8) are present when applicable and absent otherwise.
- [ ] The hook blocks raw `gh pr create` and MCP create-PR when the skill is present, and instructs the model to use the skill.
- [ ] The hook allows the skill's sentinel-carrying `gh pr create` (recursion guard).
- [ ] The hook allows raw creation with a stderr warning when the skill is absent.
- [ ] `pr-review` posts a "degraded review" banner when no spec/implementation plan is found, and omits it when grounding exists.

### Non-Functional Requirements
- [ ] The hook adds negligible latency and is a clean no-op on unrelated Bash calls.
- [ ] No `{{TOKEN}}` or instruction comment ever reaches a published PR body.
- [ ] The degraded-review gate never blocks or fails an otherwise valid review.

### Validation Plan
Hook (unit-testable via stdin fixtures, like existing hooks): unrelated Bash → no-op; `gh pr create` + sentinel → allowed (recursion guard); `gh pr create` no sentinel, skill present → deny; skill absent → exit 0 + stderr warning; MCP create-PR present → deny; absent → warn+allow; `gh pr create --web` → per O5.
Skill: renders all sections from a sample session; produces a valid body file and a well-formed sentinel-carrying invocation; `npm run validate` passes; marketplace entry resolves.
pr-review: grounded PR → no banner; ungrounded PR → banner present in posted review; gate never blocks.

## Dependencies

### External
- GitHub (`gh` CLI and/or GitHub MCP) for PR creation and review posting.
- Claude Code hooks (PreToolUse) and skills (marketplace plugin install).

### Internal
- `experience-success-skills` marketplace + `enabledPlugins` so the skill is discoverable and the hook's presence-check passes.
- `review-kit` `pr-review` skill (the grounding gate modifies it).
- `mysticat-workspace` `.claude/settings.json` and `hooks/` conventions.

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Recursion: hook blocks the skill's own `gh pr create` | High if unhandled | High | Sentinel (§A); explicit recursion-guard test |
| Two Bash hooks now fire (pre-push + pr-route) | Certain | Low | Both must no-op cleanly on irrelevant commands; keep fast |
| Nudge not followed (model doesn't call the skill after deny) | Medium | Low | Imperative deny `message`; strong skill `description`; worst case is a re-blocked raw call or manual invocation |
| Template drift vs per-repo templates | Medium | Low | Template replaces at create time; repo checks stay in pre-commit/CI |
| Degraded-review false positives (spec exists but not linked) | Medium | Medium | Advisory only; discovery scope (O9) can probe repo/Jira, not just the body |
| gh unauthenticated / skill not installed | Low | Low | Fallback handles install; auth is the skill's pre-flight responsibility |

## Open Questions

- **O1 — Sentinel mechanism.** Env-var prefix (recommended) vs `--body-file`-path check vs wrapper script.
- **O2 — Exact plugin install path** for the presence-check glob; confirm against a real install.
- **O3 — Conditional sections** drop-when-empty (chosen) vs render-with-N/A.
- **O4 — Plugin placement.** New `mysticat-dev` plugin (recommended) vs existing plugin.
- **O5 — `gh pr create --web` scope.** Likely allow through (lets the human fill the body); decide whether to exempt.
- **O6 — Hook registration location.** Committed workspace `.claude/settings.json` (recommended) vs per-user.
- **O7 — AI-disclosure reconciliation.** Should the Mysticat template fold in an AI-usage disclosure section (per `03-templates/pull-request-template.md` and the vibeproofing MUST rule)?
- **O8 — Grounding threshold.** Is a PR "grounded" by a spec OR a plan, or does it need both? Do trivial/mechanical PRs get an exemption?
- **O9 — Grounding discovery scope.** PR-body section-4 links only, or also probe touched repos / architecture docs / linked Jira for a spec/plan?

## References

- Dedicated PR template (this spec's companion): `docs/plans/2026-06-17-mysticat-pr-skill-template.md`.
- Documentation decision guide: `mysticat-architecture/DOCUMENTATION-GUIDE.md` (why this spec lives in ai-native-guidelines).
- Existing PR template: `docs/03-templates/pull-request-template.md` (AI-disclosure / vibeproofing).
- Existing review skill: `experience-success-skills/skills/review-kit/skills/pr-review/SKILL.md` and `agents/spec-compliance-reviewer.md`, `agents/project-conventions-reviewer.md`.
- Existing workspace hooks: `mysticat-workspace/hooks/pre-push-main-check.sh`, `hooks/lint-staged.sh`.

## Appendix A — Confirmed Claude Code mechanics (research basis)

- Hooks cannot call skills directly; they block/allow tool calls and inject text the model reads.
- `PreToolUse` stdin JSON includes `tool_name` and `tool_input` (`tool_input.command` for Bash; tool params for MCP).
- Matchers: `|`-separated exact names; regex supported; MCP tool names like `mcp__github__create_pull_request` are matchable.
- All hooks across user/project/local settings run (merge, not override); any deny wins.
- Proven block format in this workspace: stdout `{"decision":"deny","message":"..."}`; silent exit 0 = allow/fall-through.
- Skills live under `~/.claude/skills/`, `<repo>/.claude/skills/`, or plugin install paths; identified by `SKILL.md`.

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-06-17 | Rainer Friederich | Initial draft (create-pr skill + routing hook + pr-review grounding gate) |
| 2026-06-17 | Rainer Friederich | Extract PR template to dedicated file; §D references it instead of inline |
