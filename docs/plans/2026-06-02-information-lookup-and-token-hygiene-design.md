# Information Lookup + Token Hygiene Refresh - Design Spec

**Status**: Review
**Date**: 2026-06-02
**Author**: DJ (with Claude)
**Locations**:
- `docs/04-configuration/token-efficiency.md` (edit)
- `docs/04-configuration/information-lookup.md` (new)
- `mkdocs.yml`, `README.md`, `AGENTS.md`, `docs/index.md`, `docs/examples/workspace-claude-md.md` (nav + example updates)
- Workspace repo `/Users/dj/work/github/adobe`: `CLAUDE.md` (edit), `docs/claude/reference-information-lookup.md` (new) - separate PR

## Purpose

Close the gaps found by comparing our guidelines against the adobe.com/Milo Claude Code bootcamp wiki (Confluence space `adobedotcom`, re-validated June 2026):

- **Foundations - Core Concepts** (pageId 3848420907)
- **Token Hygiene** (pageId 3908058044)
- **Lookup Tools & the Decision Tree** (pageId 3848422792)

The comparison found we already cover ~70% of the token material, often deeper (real pricing, incident citations, cost formulas), but with stale facts and one missing category (the output side). The lookup/routing/research patterns are mostly absent and are the highest-value additions. Principle: **import their patterns, not their plumbing** - our setup automation (`init.sh`/`.mcp.json`/Vault), git-safety hooks, and cost modeling are already ahead.

This work spans two tiers per `mysticat-architecture/DOCUMENTATION-GUIDE.md`: methodology content goes to `mysticat-ai-native-guidelines`; repo-operational behavior goes to the workspace repo.

## Verified reference facts (June 2026)

Source: `platform.claude.com/docs/en/about-claude/models/overview` and `/pricing`. Implementer should use these exact values and re-confirm if the docs have moved.

**Model lineup / context windows / output:**

| Model | API ID | Context | Max output | Input/Output $/MTok | Effort default | Notes |
|---|---|---|---|---|---|---|
| Opus 4.8 | `claude-opus-4-8` | 1M | 128k | $5 / $25 | high | current Opus; adaptive thinking |
| Opus 4.7 | `claude-opus-4-7` | 1M | 128k | $5 / $25 | xhigh | new tokenizer (see below) |
| Opus 4.6 | `claude-opus-4-6` | 1M | 128k | $5 / $25 | high | |
| Sonnet 4.6 | `claude-sonnet-4-6` | 1M | 64k | $3 / $15 | high | |
| Haiku 4.5 | `claude-haiku-4-5` | **200k** | 64k | $1 / $5 | n/a | fastest |

- **Context window correction:** 1M applies only to Opus 4.8/4.7/4.6 and Sonnet 4.6. Haiku 4.5, Opus 4.5, and Sonnet 4.5 are **200k**. Our current "all models support 1M" line is wrong.
- **Tokenizer caveat:** Opus 4.7+ use a new tokenizer that can use **up to ~35% more tokens** for the same text. The "~4 chars/token" heuristic needs this caveat.

**Prompt caching multipliers (relative to base input):**

| Operation | Multiplier | Opus / Sonnet / Haiku per MTok | Duration |
|---|---|---|---|
| Cache read (hit) | 0.1x | $0.50 / $0.30 / $0.10 | matches preceding write |
| 5-min cache write | 1.25x | $6.25 / $3.75 / $1.25 | 5 min |
| 1-hour cache write | 2x | $10 / $6 / $2 | 1 hour |

Claude Code uses the **5-minute TTL** by default; the 1-hour TTL is for direct-API integrators. A 5-min cached prefix pays back the write premium after one read.

**Effort levels:** `low / medium / high / xhigh / max`, plus `ultracode` (sets extra-high effort and orchestrates dynamic workflows). Set per session with `/effort <level>`, bare `/effort` for a slider, `/effort auto` to reset to model default.

**Skill listing budget:** skill names + descriptions load up front and share a budget defaulting to ~1% of the context window (`skillListingBudgetFraction`, raisable in `settings.json`). On overflow, the least-used descriptions are shortened or dropped, which can make a skill silently stop firing. Confirm the exact default against the current Claude Code settings docs when writing; check live state with `/doctor` or `/skills`.

## Scope and non-goals

**In scope:** the three workstreams below.

**Non-goals:**
- No new MCP servers, no setup-automation changes (`init.sh`/`.mcp.json` already exceed the wiki's manual flow).
- No git-safety changes (deny rules + `pre-push-main-check.sh` hook already cover Layers 1-3).
- No Foundations "from-zero" primer (token/box/Chrome metaphors). Our audience assumes these. Revisit separately if onboarding demand appears.
- No attempt to build a cross-source discovery tool (we have no Fluffyjaws equivalent); the fan-out pattern over local + per-source tools is the mitigation.

## Workstream 1 - `token-efficiency.md` (guidelines PR)

Edit `docs/04-configuration/token-efficiency.md` in place. Preserve its structure, tables, anti-pattern catalog, and source-link style.

### Corrections

1. **Effort table** (currently low/med/high/max): add `xhigh`, `ultracode`; add per-model defaults (high on Opus 4.8/4.6 + Sonnet 4.6, xhigh on Opus 4.7); document `/effort` slider and `/effort auto`.
2. **Model names**: refresh the pricing/selection tables to the current generation (Opus 4.8 as current Opus). Prices for Opus/Sonnet/Haiku are unchanged from the 4.6/4.5 figures already in the doc; only names/IDs and the "current" framing change.
3. **Context windows**: replace "all models support 1M" with the per-model reality (1M for Opus 4.8/4.7/4.6 + Sonnet 4.6; 200k for Haiku 4.5 and the 4.5 generation).
4. **Caching mechanics**: add the 1.25x (5-min) / 2x (1-hour) write premiums, the 0.1x read, the 5-minute default TTL, and an explicit list of **what busts the cache** (editing CLAUDE.md/system prompt mid-session, switching model, switching effort level, switching output style).
5. **Tokenizer caveat**: note that Opus 4.7+ may use ~35% more tokens for the same text, so the ~4-char heuristic is approximate and model-dependent.

### Additions

1. **New section "The output side"** - the doc is currently almost all input-side. Cover, largest lever first:
   - Thinking effort as the biggest output lever (reasoning billed as output, never cached).
   - Surgical/diff edits vs full-file rewrites (Claude Code defaults to diff edits; reinforce with "make minimal edits, don't reprint the file").
   - Narration/prose verbosity (standing "be concise" instruction).
   - Scope of generated output (ask for the core function, not the whole module + tests + docs unless needed).
   - Output styles as system-prompt-level verbosity (Explanatory/Learning are longer by design; changing style mid-session busts the cache).
   - Note: the deprecated `think`/`think hard`/`megathink` keyword ladder is **not** taught here and must not be added; only `ultrathink` survives as a per-turn keyword. Mention `ultrathink` for a one-off deep think.
2. **`/rewind`** - undo a single wrong turn while keeping the cache, vs `/clear` which drops history. Add to the existing `/clear`/`/compact` guidance.
3. **Skill-description budget failure mode** - skills are deferred (not context bloat), but their descriptions share the ~1% `skillListingBudgetFraction`; overflow silently truncates descriptions so a skill stops firing with no error. Curate skills and check `/doctor`/`/skills`. Frame as a reliability risk, not a cost one.
4. **Cache-bust caveat on mid-session switching** - our doc currently encourages mid-session `/model` switching with no caveat. Add: switching model/effort/style mid-session busts the per-prefix cache; prefer a subagent for a cheaper sub-task over flipping the main session's model; edit CLAUDE.md between sessions.
5. **Trim pasted input** - large logs, JSON blobs, and full-resolution screenshots pasted by the user become permanent re-read context; paste the relevant slice.
6. **Soften the hard "<200 lines" CLAUDE.md rule** - reframe toward "stable + high-signal (~100-200 lines), don't starve it; editing it mid-session busts the cache." Keep the signal-dilution point; drop the implication that lower line count is the goal.

## Workstream 2 - `information-lookup.md` (guidelines PR, new, generic)

New file `docs/04-configuration/information-lookup.md`, written tool-agnostic (placeholder orgs/keys, matching the repo's public-shaped style). Add nav entries to `mkdocs.yml`, `README.md`, `AGENTS.md`, and `docs/index.md`; add the routing block to `docs/examples/workspace-claude-md.md`.

Sections:

1. **The principle** - "Don't ask the human for context you can look up yourself." The human is the fallback, not the default (consistent with `vibecoding-best-practices.md` AI-access priority stack).
2. **Local docs first** - prefer local, authoritative, AGENTS.md-indexed repo docs over external discovery. They are canonical, free to read, and structured for progressive discovery. This is the read-side mirror of the write-side documentation hierarchy (where you would *write* a doc is where you *read* it). External wikis/Slack are secondary and may be stale (matches the PREFER/AVOID discoverability tiering already in `vibecoding-best-practices.md`).
3. **The decision tree** (generic form):

   ```
   1. Specific artifact with an ID/URL?  -> its direct tool
      ticket ID / tracker URL -> tracker tool   | wiki URL -> wiki fetch tool
      chat URL/thread -> chat tool              | code-host PR/repo URL -> code-host tool (by host)
   2. Conceptual? ("how does X work", "is there a decision about Y", "what's our standard/process for Z")
      -> LOCAL DOCS FIRST: follow the AGENTS.md progressive-discovery chain
         (repo -> platform/architecture index -> specific doc); org standards in the org RFC repo;
         process/methodology in the methodology repo; one-service detail in that repo.
      -> only if not found locally: fan out to external search (wiki + chat + tracker),
         treated as secondary and cross-checked (RAG trust model).
   3. Logs / data / observability -> the corresponding telemetry/data tools.
   ```
4. **Fan-out research + cache** - for "deep dive / full context / everything we know about X" requests: (a) check a disk cache first (freshness: use if < ~2 weeks, re-run if older, skip on explicit "fresh"); (b) if no hit, fan out in parallel across the local repos (grep + AGENTS.md indices) **and** external/per-source tools; (c) synthesize with every fact cited to its source; (d) cache the synthesis (not raw search output) to a gitignored scratch path with a `Generated:`/`Sources:` header. Note this pairs with the `deep-research` and `dispatching-parallel-agents` skills.
5. **RAG / discovery trust model** - AI discovery/search is good for finding *where* something lives, unreliable for the exact quote/name/date/number. Trust the pointer, cross-check the specifics against the direct source before citing. Calibrate by querying something you already know.
6. **Follow all linked resources first** - when reading a ticket/thread/PR, open all linked wikis/threads/docs/PRs (with the matching tool per link type) before starting work.

## Workstream 3 - workspace wiring (workspace repo PR)

The workspace `CLAUDE.md` is loaded every turn, and its `@import`ed `docs/claude/reference-*.md` files load with it. To actually save signal budget, the detailed doc is **referenced by a pointer line, not `@import`ed** - read on demand when a deep-dive is requested.

### `CLAUDE.md` - compact "Information Lookup" block (~20-25 lines, always loaded)

Add a section with this content (final wording during implementation):

- "Don't ask me for context you can look up yourself."
- **Local docs first** for conceptual/architecture/decision/standard/process questions, with the three entry points and the canonical map:
  - platform architecture / cross-service contracts / ADRs / ops -> `mysticat-architecture/` (start at its `AGENTS.md` index; ADRs under `platform/decisions/`)
  - org-level RFC / principle / cross-team standard -> `aem-sites-architecture/` (`AGENTS.md` + `rfc-*/SKILL.md`; some are installed skills, check `/skills`)
  - team process / AI & tooling practice -> `mysticat-ai-native-guidelines/`
  - one service's implementation detail -> that repo's `docs/` + `AGENTS.md`
  - which-tier map = `mysticat-architecture/DOCUMENTATION-GUIDE.md` (read-side mirror of the existing Information Hierarchy)
- **Artifact -> tool** (specific ID/URL):
  - Jira (`SITES-`/`MWPW-`, jira.corp URL) -> `mcp__mcp-atlassian__jira_*`
  - `wiki.corp.adobe.com` URL -> `mcp__mcp-atlassian__confluence_get_page`
  - Slack URL/thread -> `mcp__slack__*`
  - GitHub PR/repo -> github MCP by host (reuse the existing "Repo-to-tool routing": `mcp__github__*` / `mcp__adobe-ghec__*` / `mcp__github-enterprise__*`)
  - Lambda/service logs -> Coralogix (`mcp__coralogix__*`), Splunk secondary
  - sites/audits/opportunities/scrapes -> Postgres MCP or the `sites-optimizer` query skills / `spacecat-mcp`
  - "has anyone discussed X / where is Y documented?" -> local docs first, then fan out `confluence_search` + `jira_search` + slack search (no single cross-source discovery tool)
- One-line **RAG trust** reminder (trust the pointer, cross-check names/dates/numbers before citing).
- One-line **follow-links** reminder (open linked resources before starting work).
- One-line **output discipline** (prefer minimal/surgical edits, don't reprint files; be concise).
- Pointer: "For deep-dive/fan-out research, read and follow `docs/claude/reference-information-lookup.md`."

### `docs/claude/reference-information-lookup.md` (new, on-demand, NOT `@import`ed)

- Full fan-out research + synthesis + disk-cache pattern, adapted to our tools. Cache to a gitignored scratch location; align with any existing workspace scratch convention (check `init.sh` / `reference-developer-setup.md`), defaulting to `$HOME/.claude-scratch/<cwd-slug>/research/claude-research-<topic>.md` if none exists. Include freshness handling.
- Expanded RAG/discovery trust model + calibration guidance.
- Follow-links elaboration.
- Verify-loaded routine: `/skills`, `/mcp`, `/context`, `/doctor`.

Do **not** add an `@import` line for this file; add only the pointer in `CLAUDE.md`.

## Cross-repo placement and PR strategy

- **PR 1 - guidelines** (`mysticat-ai-native-guidelines`, branch `docs/token-hygiene-and-lookup-patterns`): Workstreams 1 + 2 + this spec.
- **PR 2 - workspace** (`/Users/dj/work/github/adobe`, own branch off its `origin/main`): Workstream 3.

Both branch explicitly from `origin/main`. PR bodies shown for approval before posting. No force-push, no amend, no direct main commits.

## Validation gates

- **Guidelines PR:** `mkdocs build --strict` succeeds (catches broken nav/links); markdownlint if configured; all relative cross-links resolve; `mkdocs.yml` + `README.md` + `AGENTS.md` + `docs/index.md` nav updated for the new file; no occurrence of the deprecated think-keyword ladder; verified facts match the table above.
- **Workspace PR:** `CLAUDE.md` still parses and all `@import` targets exist (the new reference doc is intentionally **not** imported - confirm it is pointer-referenced only); the compact block stays within ~25 lines; the routing names match `.mcp.json` server names exactly (e.g. `mcp__slack__*`, `mcp__coralogix__*`).
- Each gate runs before its PR is opened; self-correct on failure before proceeding.

## Risks / considerations

- **Always-loaded weight**: the compact block adds ~20-25 lines to every turn. Mitigated by keeping detail in the non-imported reference doc; net effect should be a wash or better once it stops Claude re-asking "which tool / which repo."
- **Routing drift**: MCP server names can change; the validation gate cross-checks against `.mcp.json`. The block reuses the existing Repo-to-tool routing rather than duplicating it.
- **Reference-doc reliability**: a pointer is slightly less reliable than inline. The high-frequency rules (artifact->tool, local-first) stay inline; only the lower-frequency research/verify detail is on demand, with a CLAUDE.md trigger line so it still fires.
