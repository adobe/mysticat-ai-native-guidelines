# Mysticat PR Skill + PR-Routing Hook + pr-review Grounding Gate - Implementation Plan

> Tasks use checkbox (`- [ ]`) syntax for tracking; implement one task at a time and commit after each.

**Goal:** Implement the three coordinated deliverables defined in the spec: (1) a `create-pr` skill in `experience-success-skills` (in the existing `review-kit` plugin, alongside `pr-review`) that opens a GitHub PR from one skill-bundled 8-section template; (2) a PreToolUse routing hook in `mysticat-workspace` that routes all three PR-creation surfaces (`gh pr create`, direct GitHub API, GitHub MCP) through that skill with a graceful fallback; (3) a `pr-review` grounding gate in `experience-success-skills` / `review-kit` plus the `grounding`-labelled review-cost split in `mysticat-github-service`.

**Architecture:** Three independent PRs across two implementation repos (plus a metrics change in a third). They are sequenced by one soft dependency: the skill PR (Part 1) should merge first so the hook's "skill present" path is exercisable (Part 2). The pr-review grounding gate (Part 3) is independent and can land in parallel.

- **Part 1 - Skill** lands in `experience-success-skills` (branch off its `origin/main`).
- **Part 2 - Hook** lands in `mysticat-workspace` (branch off its `origin/main`).
- **Part 3 - Grounding gate** spans `experience-success-skills` (`review-kit/skills/pr-review` + the two reviewer personas) and `mysticat-github-service` (the worker metric). It may be one cross-repo coordinated PR pair or two PRs; keep the worker change behind the same review-body banner the skill emits so the two halves are decoupled at runtime.

**Tech Stack:** Markdown skills (SKILL.md), Python 3 stdlib (optional skill helper + its `unittest` tests), Bash hooks (`{"decision":"deny"}` JSON contract) with stdin-fixture tests, Python 3.13 + pytest for the `mysticat-github-service` worker. Validation commands: `npm run validate` (skills), `bash test/test_*.sh` (hooks), `pytest` (worker).

**Content authority:** the committed spec `docs/plans/2026-06-17-mysticat-pr-skill-design.md` (this repo) defines all design decisions; the companion `docs/plans/2026-06-17-mysticat-pr-skill-template.md` defines the verbatim PR-body template. Each task below cites the spec section (`spec §X`) it implements. Read that section before editing. Do not re-derive decisions - the spec resolved them inline.

**Conventions (all tasks):** Read the full target file before editing. No emojis in skill/persona/review-output content. Use normal dash, not em-dash (`experience-success-skills/AGENTS.md` em-dash ban - they leak into review output). No `#`-prefixed enumeration in PR bodies (GitHub auto-links to unrelated PRs). No force-push, no `--amend`, no direct commits to `main`; feature branch per repo. Commit after each task. The `experience-success-skills` SKILL.md dir name MUST equal the frontmatter `name` (validator enforces). `.mcp.json` is secret-bearing and gitignored; only read/reference `.mcp.json.template`.

---

## Part 1 - `create-pr` skill (experience-success-skills)

**Spec authority:** §C (skill), §D (template + fill-guide + hard exclusions + rendering contract), §A (the in-body marker).

> **Deviation from spec §C (plugin placement).** The spec chose a new `mysticat-dev` plugin ("no existing plugin is a clean fit"). This plan instead places `create-pr` in the existing **`review-kit`** plugin, alongside `pr-review`. Rationale: Part 3's grounding gate already modifies `review-kit`; `create-pr` and `pr-review` are explicitly coordinated (the template captures the spec link that the §E gate then checks); one plugin install covers the whole PR lifecycle; and the create-vs-review parity logic lives in one place. This supersedes the spec §C decision and the "Plugin placement" alternatives row - update the spec to match (or note the supersession there).

**Repo facts (verified):**
- Placement: `skills/review-kit/skills/create-pr/{SKILL.md, assets/pr_template.md, scripts/, tests/}` (a new skill dir inside the existing `review-kit` plugin; `review-kit` already holds `pr-review`, `triage-pr-reviews`, `implement-pr-reviews`, `review-*`). No new plugin, no `plugin.json`, no `marketplace.json` change.
- Validator (`scripts/validate-skills.py`, run via `npm run validate`) allows frontmatter keys: `name, description, license, allowed-tools, metadata, compatibility, user-invocable, argument-hint, model` and nothing else; `name` must be lowercase `[a-z0-9][a-z0-9-]*`, no `--`, and equal the parent dir name; `description` <= 1024 chars.
- `AGENTS.md` requires invocable skills to carry `name, description, user-invocable: true, argument-hint`. No SKILL.md in the repo uses `allowed-tools` today; only `pr-review` uses `model:`.
- CI (`.github/workflows/ci.yml`, Python 3.12): `validate` job (`npm run validate` + persona-reference check), `script-tests` job (stdlib `unittest discover`). A new Python helper with tests needs its dir added to the `script-tests` job.
- Closest existing PR-creation convention: `skills/domain-expert/skills/develop-llmo-feature/SKILL.md` "4d - Push and open PR" (MCP-first: `mcp__github__create_pull_request` for `adobe/spacecat-*`, `mcp__github-enterprise__*` / `mcp__adobe-ghec__*` per host; reserve `gh pr create` for what MCP cannot do).

### Task 1.1: Author the bundled PR template (copied verbatim from the spec companion)

**Files:**
- Create: `skills/review-kit/skills/create-pr/assets/pr_template.md`

**Content authority:** §D + the companion `2026-06-17-mysticat-pr-skill-template.md`. The template body is the content **between the two `---` markers** of the companion file (the H1, intro, and example outside the markers are documentation and are NOT part of the body).

- [ ] **Step 1: Copy the between-markers block verbatim** into `assets/pr_template.md`. It starts with `<!-- mysticat-pr-skill -->` (the first line) and ends with the `🤖 Generated with [Claude Code](https://claude.com/claude-code)` footer.
- [ ] **Step 2: Confirm fidelity.** The file MUST contain: the 8 sections; the `<!-- AGENT: ... -->` instruction comment on each; one `{{TOKEN}}` per section (section 4 has the 5 bullet tokens); the `[CONDITIONAL]` markers on sections 5, 6, 8; and the literal first-line marker `<!-- mysticat-pr-skill -->`.
- [ ] **Step 3: Verify** -> Run `grep -c '{{' assets/pr_template.md` (expect the placeholder count) and `head -1 assets/pr_template.md` -> Expected: `<!-- mysticat-pr-skill -->`.

### Task 1.2: Write `SKILL.md` (the workflow)

**Files:**
- Create: `skills/review-kit/skills/create-pr/SKILL.md`

**Content authority:** §C (workflow steps 1-5), §D (fill-guide table, rendering contract, hard exclusions), §A (marker is the one comment NOT stripped).

- [ ] **Step 1: Frontmatter.** `name: create-pr`, a strong `description` (must reliably win selection when the hook nudges - phrase it "Use when creating / opening a GitHub pull request ..."), `user-invocable: true`, `argument-hint: "[base-branch] [--draft]"`. No em-dashes in body.
- [ ] **Step 2: Workflow - pre-flight (§C step 1).** Document: a PR-creation transport is available and authenticated (GitHub MCP `create_pull_request` connected, or `gh auth status` ok); NOT on the default branch; branch is pushed (or push as part of the flow).
- [ ] **Step 3: Workflow - gather session context (§C step 2).** Branch name, `git log <base>..HEAD`, diff summary, Jira keys (parse from branch/commits/session), what was verified this session.
- [ ] **Step 4: Workflow - render the body (§C step 3).** Read `assets/pr_template.md`; fill every `{{TOKEN}}` per the §D fill-guide table; strip every `<!-- AGENT: ... -->` comment; fill-or-drop conditional sections 5/6/8; apply the empty-value rendering contract (remove the **entire line/bullet** when a value is empty - no dangling `- Spec:`); **retain** the `<!-- mysticat-pr-skill -->` marker; keep the footer. Write to a temp file. A `{{TOKEN}}` the skill cannot resolve at all is a bug -> fail rather than open a PR with raw placeholders.
- [ ] **Step 5: Encode the hard exclusions (§D).** State explicitly the body must NOT contain code snippets, passing-test counts, or lint/type-check success statements. A real failure/gap may still be described in prose.
- [ ] **Step 6: Encode spec/plan discovery scope (§D + §E parity).** Spec/plan/ADR discovery searches the touched repos' `docs/` (`decisions/`, `plans/`, `proposals/`) AND the workspace `mysticat-architecture` + `mysticat-ai-native-guidelines` docs, keyed on Jira key / branch / PR title. Best-effort (a miss drops the bullet). This MUST match the §E gate's source set so the writer and the checker agree on where specs live (closes the create-vs-review asymmetry).
- [ ] **Step 7: Workflow - create the PR (§C step 4).** Pick transport with NO `gh` hardcode: prefer GitHub MCP `create_pull_request` when connected (rendered body as `body`); else `gh pr create --base <base> --title "<title>" --body-file <tmp> [--draft]`; else direct-API `gh api`/`curl` POST. Always submit through a hook-resolvable body form (§A) so the in-body marker guards recursion on every surface.
- [ ] **Step 8: Workflow - report (§C step 5).** Print the PR URL.
- [ ] **Step 9: Validate** -> Run `npm run validate` -> Expected: passes (SKILL.md dir name equals `name`, frontmatter keys allowed).

### Task 1.3: Optional deterministic renderer + tests

**Files (only if rendering proves fiddly - §C says default to no scripts):**
- Create: `skills/review-kit/skills/create-pr/scripts/render_body.py` (Python 3 stdlib only)
- Create: `skills/review-kit/skills/create-pr/tests/test_render_body.py` (stdlib `unittest`)
- Modify: `.github/workflows/ci.yml` (add the new tests dir to the `script-tests` job)

> **Why Python (not shell).** Python 3 stdlib is the established skill-helper convention here (51 Python helpers vs 2 shell), and Python 3.12 is already a hard repo dependency - `scripts/validate-skills.py` (run by `npm run validate`) and every CI job require it - so a Python helper adds no new portability burden. The default path uses NO helper at all: the model renders the body inline per the §D contract, and a script is added only when deterministic token-replacement / empty-bullet removal proves unreliable inline.

- [ ] **Step 1: Decide.** Default to no script. Add `render_body.py` only if deterministic token replacement / empty-bullet removal / Jira-key extraction is hard to do reliably inline.
- [ ] **Step 2: If added, implement** the §D rendering contract: replace tokens, strip `AGENT:` comments, retain the `mysticat-pr-skill` marker, drop empty lines/bullets and empty conditional sections, append footer, fail on an unresolvable token.
- [ ] **Step 3: Tests** mirror existing stdlib `unittest` style: all sections rendered from a sample context; empty optional -> bullet removed (no dangling `- Spec:`); footer present; marker present; all `AGENT:` comments stripped; unresolvable token -> raises.
- [ ] **Step 4: Wire CI.** Add the tests dir to the `script-tests` `unittest discover` invocation. Run locally: `python3 -m unittest discover skills/review-kit/skills/create-pr/tests` -> Expected: all pass.

### Task 1.4: Part 1 acceptance

- [ ] `create-pr` opens a PR whose body is the rendered 8-section template, all tokens filled, all `AGENT:` comments stripped, the `<!-- mysticat-pr-skill -->` marker retained, footer present (spec Success Criteria).
- [ ] Empty optional placeholders/bullets removed whole; unresolvable token fails the skill.
- [ ] Conditional sections 5/6/8 present when applicable, absent otherwise.
- [ ] `npm run validate` passes; the `create-pr` skill is discovered under the `review-kit` plugin.

---

## Part 2 - PreToolUse routing hook (mysticat-workspace)

**Spec authority:** §A (marker + bypass), §B (hook, matcher, scope, decision table, presence detection), §F (fallback). **Depends on Part 1** being installable so the presence check has something to find.

**Repo facts (verified):**
- Mirror `hooks/pre-push-main-check.sh` exactly: `#!/usr/bin/env bash`, `set -euo pipefail`, `input=$(cat)`, parse with `jq -r '... // empty'`, allow = silent `exit 0`, deny = print single-line `{"decision":"deny","message":"..."}` to stdout via heredoc. Guard every external call with `|| exit 0` / `2>/dev/null` so the hook never hard-errors.
- Register in the **committed** `.claude/settings.json` (symlink to the workspace root; applies to all sessions). There is one existing PreToolUse entry (`"matcher": "Bash"`). Add a **new** array object - do not merge into the Bash one.
- Directory-walk wrapper command pattern (mirror verbatim, swapping the script name):
  `bash -c 'd=$PWD; while [ "$d" != / ] && [ ! -x "$d/hooks/pr-route-to-skill.sh" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && exec "$d/hooks/pr-route-to-skill.sh"'`
  Use `exec` (not the `file=$(cat|jq)` wrapper variant) so the script reads stdin itself.
- GitHub MCP server names from `.mcp.json.template`: `github` (github.com) and `github-enterprise` (git.corp.adobe.com). `reference-tools.md` documents a third per-user server `adobe-ghec` (GHEC EMU orgs) not in the template today - enumerate it in the matcher for forward-compat.
- `deny` wins over an `allow` permission even though `mcp__github__create_pull_request` is in the (gitignored) `settings.local.json` allowlist - the routing hook still fires.
- Do NOT touch `lib/hooks.sh` (it only symlinks git-native hooks; Claude Code hooks live in settings only). `chmod +x` the new script.
- Hook test precedent: per-script `test/test_<name>.sh` + paths-scoped `.github/workflows/test-<name>.yml` (mirror `test/test_lint_staged.sh` + `test-lint-staged.yml`: `set -uo pipefail`, `pass`/`fail` counters, SKIP-if-missing-`jq`, `mktemp -d` sandbox + `trap`). No existing PreToolUse-hook test and no settings-vs-`.mcp.json` consistency test exist - this task establishes both.

### Task 2.1: Write `hooks/pr-route-to-skill.sh`

**Files:**
- Create: `mysticat-workspace/hooks/pr-route-to-skill.sh` (chmod +x)

**Content authority:** §A decision table, §B scope + presence detection, §F fallback.

- [ ] **Step 1: Read** `hooks/pre-push-main-check.sh` and `hooks/lint-staged.sh` for the exact style.
- [ ] **Step 2: Bypass first (§A.2).** If `MYSTICAT_PR_SKILL_BYPASS=1` in the hook env -> `exit 0` (optional one-line stderr note). Short-circuits every surface.
- [ ] **Step 3: Resolve the PR body per surface (§A) and allow on the marker.** For `Bash`: read `.tool_input.command`; for `--body/-b` use inline text, for `--body-file/-F <path>` read that file, for `gh api .../pulls -f body=<text|@file>` / `--input <file>` and `curl -d/--data <text|@file>` read the field or referenced file. For MCP: read `.tool_input.body`. If the resolved body contains the marker **key** `mysticat-pr-skill` (match the key, not the literal string - §H may extend the marker with `base`/`head`/`commits`/`files`) -> `exit 0` (allow; skill's own templated output, any transport).
- [ ] **Step 4: Scope - creation only (§B).** Treat a `Bash` command as a PR-create attempt ONLY when it matches: `gh pr create` (but NOT `gh pr create --web` -> allow through); `gh api` + POST to the `pulls` **collection** with create fields (NOT `.../pulls/{n}` sub-resources, NOT GET lists); `gh api graphql` + `createPullRequest`; `curl` + a GitHub API host + POST to `/pulls` collection. Anything else (comments, reviews, lists, merges, edits) -> `exit 0` no-op.
- [ ] **Step 5: Detect skill presence (§B).** Glob for `create-pr/SKILL.md` across skill roots: the marketplace-installed `review-kit` plugin install root (read the live Claude Code plugin layout, do not assume a fixed string), `<repo>/.claude/skills/create-pr/SKILL.md`, and `~/.claude/skills/create-pr/SKILL.md`. Any match -> present.
- [ ] **Step 6: Decision (§A decision table).** No marker + create attempt + skill present -> deny with an imperative `message` naming the `create-pr` skill. No marker + create attempt + skill absent -> `exit 0` + stderr warning (allow fallback). Unresolvable `--body-file` (missing/unreadable) -> fail-safe: deny when the skill is present (degrade to the raw-call path, never a silent allow).
- [ ] **Step 7: Output format.** Use the legacy shape (`{"decision":"deny","message":"..."}` on stdout; stderr warning + `exit 0` for fallback). Do NOT use `hookSpecificOutput.permissionDecision` or speculative fields.
- [ ] **Step 8: `chmod +x hooks/pr-route-to-skill.sh`.**

### Task 2.2: Register the hook in committed settings

**Files:**
- Modify: `mysticat-workspace/.claude/settings.json` (the committed workspace file - edit via the workspace root, it is a symlink target)

- [ ] **Step 1: Add a new `PreToolUse` array object** with matcher `"Bash|mcp__github__create_pull_request|mcp__github-enterprise__create_pull_request"` (add `|mcp__adobe-ghec__create_pull_request` for forward-compat) and the directory-walk wrapper command for `pr-route-to-skill.sh`. The `Bash` arm routes the direct-API/`gh` surfaces (they are Bash commands); the MCP arms route the MCP tool calls.
- [ ] **Step 2: Confirm** the existing `"matcher": "Bash"` (pre-push) entry is untouched; both Bash hooks now fire and must each no-op cleanly on irrelevant commands.

### Task 2.3: Hook tests + matcher-vs-`.mcp.json` assertion

**Files:**
- Create: `mysticat-workspace/test/test_pr_route_to_skill.sh`
- Create: `mysticat-workspace/.github/workflows/test-pr-route-to-skill.yml`
- Create (or fold into the above): a matcher-vs-`.mcp.json` consistency check (§B Phase-2 loud-failure assertion)

**Content authority:** spec Validation Plan (the enumerated hook cases) + §B assertion.

- [ ] **Step 1: Stdin-fixture cases** (mirror `test/test_lint_staged.sh` structure). Cover: unrelated Bash -> no-op; `gh pr create --web` -> allow; body with the `mysticat-pr-skill` marker -> allow, across all three resolved-body forms (`gh pr create --body-file <tmp>`, `curl`/`gh api .../pulls` POST with marker in body, MCP with marker in `tool_input.body`); `MYSTICAT_PR_SKILL_BYPASS=1` -> allow on every surface; `gh pr create` no marker, skill present -> deny, skill absent -> exit 0 + stderr warning; `gh api .../pulls` POST and `curl .../pulls` POST no marker, present -> deny, absent -> warn+allow; `gh api .../pulls/{n}/comments` POST -> no-op (creation-only scope); MCP create-PR no marker, present -> deny, absent -> warn+allow; `gh pr create --body-file <missing path>` -> deny when skill present (fail-safe). Use a SKIP-if-missing-`jq` guard, `mktemp -d` sandbox + `trap`, `pass`/`fail` counters, final tally `exit 1` on any failure.
- [ ] **Step 2: Matcher-vs-`.mcp.json` assertion (§B).** Add a check that every `mcp__*__create_pull_request` name in the settings matcher resolves to a GitHub MCP server declared in the workspace `.mcp.json` (or `.mcp.json.template` for CI, since `.mcp.json` is gitignored) and, conversely, every GitHub-MCP server there is covered by the matcher; a mismatch fails with the offending name.
- [ ] **Step 3: CI workflow** - paths-scoped to the hook, the test, the workflow, settings, and the mcp template; `ubuntu-latest`; `bash test/test_pr_route_to_skill.sh`.
- [ ] **Step 4: Run locally** -> `bash test/test_pr_route_to_skill.sh` -> Expected: all cases pass.

### Task 2.4: Part 2 acceptance

- [ ] Hook denies raw `gh pr create`, direct-API PR creation, and MCP create-PR when the skill is present and names the skill.
- [ ] Hook allows `gh pr create --web`, any PR-create whose resolved body carries the marker (all transports), and any surface under `MYSTICAT_PR_SKILL_BYPASS=1`.
- [ ] Hook does NOT match existing-PR interactions (comments, reviews, lists, merges).
- [ ] Hook allows raw creation + stderr warning when the skill is absent; negligible latency, clean no-op on unrelated Bash.

---

## Part 3 - pr-review grounding gate + observability

**Spec authority:** §E (grounding gate, reuse Phase 2.1), §G (cost split by `grounding` label). Spans `experience-success-skills` (review-kit) and `mysticat-github-service` (worker metric). Independent of Parts 1-2; can land in parallel.

### Part 3A - Grounding gate (experience-success-skills / review-kit)

**Repo facts (verified):**
- `pr-review` is a 3-phase skill: `skills/review-kit/skills/pr-review/SKILL.md`. Phase 1 Triage, Phase 2 Review (2.1 builds the brief), Phase 3 Consolidate + post.
- Phase 2.1 already solves cloneless cross-repo doc discovery: `project_docs_paths` (touched-repo docs, path-only, token-overlap-with-diff rule, 20-cap), `upstream_docs_paths` (cross-repo refs parsed from the touched repo's `AGENTS.md`/`CLAUDE.md` "Platform Context" links; `{host,owner,repo,ref,path}`; host-routed lazy fetch - `gh api` for github.com, MCP `get_file_contents` for enterprise; 10-cap), plus a 50-path CLAUDE.md cap and the status-discrimination contract (`gh api --include`, suppress only 404, log any other non-200).
- Reviewer personas live one level up at `skills/review-kit/agents/`: `spec-compliance-reviewer.md` (checks impl-vs-spec only WHEN a spec exists) and `project-conventions-reviewer.md` (owns the `project_docs_paths`/`upstream_docs_paths` lazy-fetch + status-discrimination contract; has a `status: decided|proposed|...` frontmatter filter where only `decided` is flaggable).
- `AGENTS.md` cross-skill rule: `pr-review` is the canonical pattern source; any Phase 2/3 mechanics change MUST be mirrored into `review-kit/skills/review-practices/SKILL.md`.
- CI enforces a Scout probe-name coupling grep gate and persona-reference checks; keep coupled tokens in sync.

**Files:**
- Modify: `skills/review-kit/skills/pr-review/SKILL.md` (Phase 1 grounding discovery; Phase 3 banner)
- Modify: `skills/review-kit/skills/review-practices/SKILL.md` (mirror Phase 2/3 changes - AGENTS.md rule)
- Possibly modify: `skills/review-kit/agents/spec-compliance-reviewer.md` / `project-conventions-reviewer.md` (only if the gate adds a discovery responsibility to a persona)

- [ ] **Step 1: Read** `pr-review/SKILL.md` (Phases 1-3, esp. 2.1), `review-practices/SKILL.md`, and both reviewer personas.
- [ ] **Step 2: Phase 1 - discover grounding from all sources (§E).** Determine a `has-spec` flag by gathering from the section-4 PR-body links, the touched repos' `docs/`, and - reached ONLY via the link chain (`upstream_docs_paths` from the touched repo's `AGENTS.md`/`CLAUDE.md` "Platform Context" links) - the `mysticat-architecture` / `mysticat-ai-native-guidelines` docs, plus any linked Jira. **Reuse the existing Phase 2.1 machinery - do NOT add a second discovery path.** Inherit its execution-context split (local clones interactively; `get_file_contents` in the no-clone worker) and status-discrimination contract.
- [ ] **Step 3: Degrade only on a missing spec (§E).** A missing plan/ADR/Jira alone does NOT degrade. Honor the self-attested, human-visible exemption: a `no-spec-needed` label OR an `Exemption: <reason>` bullet in section 4 -> no banner.
- [ ] **Step 4: Phase 3 - banner (§E).** When no spec is found and the PR is not exempt, prepend a prominent `⚠ Degraded review` banner to the consolidated review and include it in the GitHub-posted body. Use the spec's suggested wording (searched the PR links, touched-repo docs, architecture/guidelines docs, linked Jira; confidence reduced; add a spec link in section 4 and re-request review). Advisory only - never block or fail the review.
- [ ] **Step 5: Mirror to `review-practices`** per the AGENTS.md cross-skill rule.
- [ ] **Step 6: Validate** -> `npm run validate`; run the review-kit fixtures (`bash skills/review-kit/scripts/run-fixtures.sh`). Keep any Scout probe-name coupling grep gate satisfied.

### Part 3B - `grounding`-labelled review-cost split (mysticat-github-service)

**Repo facts (verified):**
- Catalog `metrics.yaml`: `mysticat_github_review_cost_usd` labels `[service, environment, job_type, model]`; `mysticat_github_review_input_tokens` same labels; `mysticat_github_review_findings` labels `[service, environment, severity]`. Drift guard `tests/test_metrics_catalog.py` checks metric **names** only (adding a label does NOT trip it).
- `src/worker/steps/amp.py`: `_ALLOWED_LABELS` frozenset MUST gain `"grounding"` or `_build_series` raises `ValueError`. `emit_amp_success(...)` builds the cost + input/output-token series - add a `grounding: str` kwarg and thread it into the cost and input-token dicts.
- `src/worker/steps/parser.py`: body-parsing helpers (`count_findings`, `_count_new_format`/`_count_legacy_format` with the ```` ``` ````-fence-skipping idiom, `_classify_review`). Add `detect_grounding(body) -> str` ("spec_found" | "degraded" | "exempt") here, None-safe/best-effort like `count_findings`.
- `src/worker/pipeline.py`: after `findings = count_findings(posted["body"])` (~line 593) compute `grounding = detect_grounding(posted["body"])`; thread it into `emit_success_metrics(...)` (~695-704, CloudWatch) and `emit_amp_success(...)` (~705-717, AMP), and into the Check Run metadata dict (~657-670).
- Label reading: `src/worker/steps/label.py` is write-only (`add_label`). For the `no-spec-needed` label add a `list_labels` helper (mirror `add_label`'s `gh api .../issues/{n}/labels` shape) OR parse the `Exemption:` bullet from the body in `detect_grounding`. Worker clones only `mysticat-workspace` + 3 context repos + skills repo (`workspace.py` `_CONTEXT_REPOS`); the PR repo is reached via `gh api`.
- Tests: pytest, `tests/steps/test_amp.py` (must keep `test_build_series_rejects_unknown_label` green and assert the `grounding` value lands in the snappy/protobuf wire), `tests/steps/test_metrics.py` (CloudWatch dimensions), `tests/steps/test_parser.py` (inline-body `detect_grounding` cases), `tests/test_pipeline.py` (assert `grounding` threaded into mocked emitters). Closest precedent: `docs/plans/2026-06-03-stage-duration-dedup-metrics-worker.md`.

- [ ] **Step 1: `detect_grounding(body)`** in `parser.py` - reuse the fence-skipping loop; return `exempt` on the `Exemption:` bullet (and/or label lookup), `degraded` on the `⚠ Degraded review` banner, else `spec_found`. None-safe (`if not body: return ...`).
- [ ] **Step 2: Allow the label.** Add `"grounding"` to `_ALLOWED_LABELS` in `amp.py`; add a `grounding` kwarg to `emit_amp_success` and thread it into the `M_COST` and `M_INPUT_TOKENS` series.
- [ ] **Step 3: Wire the pipeline.** Compute `grounding` after `count_findings`; pass to `emit_amp_success` and (optionally) `emit_success_metrics` + the Check Run metadata. Decide CloudWatch mirror vs AMP-only: follow the `review_state` precedent (AMP-only) to avoid CloudWatch dimension-cardinality growth - recommend **AMP-only** for the `grounding` label, matching `metrics.yaml`.
- [ ] **Step 4: Update the catalog.** Add `grounding` to the `labels:` lists of `mysticat_github_review_cost_usd` and `mysticat_github_review_input_tokens` in `metrics.yaml`.
- [ ] **Step 5 (nice-to-have, §G).** `grounding_docs_fetched` (count) + bytes for cost-vs-volume reading - needs skill->worker plumbing of those numbers; defer unless cheap.
- [ ] **Step 6: Tests** - `test_parser.py` for `detect_grounding`; `test_amp.py` for the label on the wire + the unknown-label guard still green; `test_pipeline.py` for threading; `test_metrics_catalog.py` stays green (names unchanged). Run `pytest` -> Expected: all pass.

### Part 3C - acceptance

- [ ] `pr-review` posts the degraded banner when no spec is discoverable across all sources and the PR is not exempt; omits it when a spec or exemption exists; never blocks.
- [ ] Worker no-clone fixture: a PR whose spec lives in `mysticat-architecture`, reachable only via `get_file_contents` (touched repo links up; arch repo NOT cloned) -> spec discovered, NO banner (pins the under-discovery regression).
- [ ] Create-vs-review consistency: for that same PR shape, the `create-pr` skill resolves the `mysticat-architecture` spec into section 4 (not dropped) - skill and gate agree.
- [ ] The `grounding` label (`spec_found|degraded|exempt`) is emitted on the cost + input-token series; "cost with a spec vs without" is a single split (upper bound on cost attributable to the gate, not total - §G confounder).

---

## Deployment & merge order (spec §8 / Implementation Phases)

1. **Part 1 (skill)** merges first so the hook's "present" path is exercisable.
2. **Part 2 (hook)** merges once the skill is installable (presence check has something to find); include the matcher-vs-`.mcp.json` assertion.
3. **Part 3 (grounding gate + metric)** is independent and can land in parallel; the worker metric (3B) and the skill banner (3A) are decoupled at runtime via the posted review body.

## Deferred (not in this plan - spec §H)

Post-creation PR-description sync (a PostToolUse drift hook -> `create-pr` update mode, watching `git push` + GitHub MCP file-commit tools; spec-drift flag extending §E; centralized backstop in the `mysticat-github-service` webhook on `pull_request.synchronize`). Recorded in the spec as future work; do not build here. Note that §H extends the body marker with `base`/`head`/`commits`/`files`, which is why Part 2's recursion guard matches the marker **key**, not the literal string.

## References

- Spec: `docs/plans/2026-06-17-mysticat-pr-skill-design.md`
- PR template (companion, verbatim source for `assets/pr_template.md`): `docs/plans/2026-06-17-mysticat-pr-skill-template.md`
- Skill conventions: `experience-success-skills/AGENTS.md`, `README.md`, `scripts/validate-skills.py`, `.github/workflows/ci.yml`
- Hook conventions: `mysticat-workspace/hooks/pre-push-main-check.sh`, `hooks/lint-staged.sh`, `.claude/settings.json`, `test/test_lint_staged.sh`, `.mcp.json.template`
- Reused review machinery: `experience-success-skills/skills/review-kit/skills/pr-review/SKILL.md` (Phase 2.1), `agents/spec-compliance-reviewer.md`, `agents/project-conventions-reviewer.md`
- Worker metric precedent: `mysticat-github-service/metrics.yaml`, `src/worker/steps/{amp.py,parser.py,metrics.py}`, `src/worker/pipeline.py`, `docs/plans/2026-06-03-stage-duration-dedup-metrics-worker.md`
