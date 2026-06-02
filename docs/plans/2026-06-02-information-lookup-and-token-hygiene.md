# Information Lookup + Token Hygiene Refresh - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh `token-efficiency.md` with corrected facts + the missing output-side levers, add a generic `information-lookup.md` pattern doc, and wire a compact lookup-routing block + on-demand reference doc into the workspace repo.

**Architecture:** Two independent PRs. Part A (guidelines repo `mysticat-ai-native-guidelines`, branch `docs/token-hygiene-and-lookup-patterns`, which already holds the spec) edits/creates methodology docs. Part B (workspace repo `/Users/dj/work/github/adobe`, new branch off its `origin/main`) wires the live behavior. Part A and Part B do not depend on each other and can be done in either order.

**Tech Stack:** Markdown, MkDocs (Material), `make build` / `mkdocs build --strict`. This is a docs task: there are no unit tests, so the TDD loop is replaced by **edit -> run validation command -> confirm expected output -> commit**.

**Content authority:** the committed spec `docs/plans/2026-06-02-information-lookup-and-token-hygiene-design.md` (in this repo) defines all content and the verified-facts table. Each task cites the spec section that defines its content; read that section before editing. Do not re-derive facts - use the spec's verified-facts table.

**Conventions (all tasks):** Read the full target file before editing. No emojis. Use normal dash, not em-dash. No force-push, no `--amend`, no direct commits to `main`. Commit after each task.

---

## Part A - Guidelines PR

Branch `docs/token-hygiene-and-lookup-patterns` already exists (created off `origin/main`) and contains the spec + this plan. Continue on it.

### Task A1: token-efficiency.md - corrections

**Files:**
- Modify: `docs/04-configuration/token-efficiency.md`

**Content authority:** spec section "Workstream 1 - Corrections" + the "Verified reference facts (June 2026)" table.

- [ ] **Step 1: Read the file**

Run: `Read docs/04-configuration/token-efficiency.md` (full). Note the current effort table, pricing/model table, the "All models support 1M context at standard pricing." line, the caching line ("cache hits cost 90% less"), and the `~4 chars`/token heuristic if present.

- [ ] **Step 2: Fix the effort table**

Add `xhigh` and `ultracode` rows; add per-model defaults (high on Opus 4.8/4.6 + Sonnet 4.6, xhigh on Opus 4.7); document `/effort <level>`, bare `/effort` slider, and `/effort auto`. Use the spec's effort definitions verbatim for level meanings.

- [ ] **Step 3: Refresh model names/IDs to current generation**

Update the model/pricing/selection tables so Opus 4.8 (`claude-opus-4-8`) is the current Opus, Sonnet 4.6 (`claude-sonnet-4-6`), Haiku 4.5 (`claude-haiku-4-5`). Per-MTok prices are unchanged ($5/$25, $3/$15, $1/$5); only names/IDs and "current" framing change.

- [ ] **Step 4: Fix the context-window claim**

Replace "All models support 1M context at standard pricing." with the per-model reality: 1M for Opus 4.8/4.7/4.6 and Sonnet 4.6; **200k for Haiku 4.5** and the 4.5 generation.

- [ ] **Step 5: Complete the caching mechanics**

Add the write premiums (5-min = 1.25x, 1-hour = 2x), the 0.1x read, the 5-minute default TTL (Claude Code uses 5-min; 1-hour is for direct-API integrators), and an explicit "what busts the cache" list: editing CLAUDE.md / system prompt mid-session, switching model, switching effort level, switching output style.

- [ ] **Step 6: Add the tokenizer caveat**

Note that Opus 4.7+ use a new tokenizer that can use up to ~35% more tokens for the same text, so the ~4-char/token heuristic is approximate and model-dependent.

- [ ] **Step 7: Validate the build**

Run: `cd /Users/dj/work/github/adobe/mysticat-ai-native-guidelines && mkdocs build --strict 2>&1 | tail -15`
Expected: build succeeds, no warnings/errors referencing `token-efficiency.md`.

- [ ] **Step 8: Confirm the corrections landed**

Run: `grep -n "All models support 1M" docs/04-configuration/token-efficiency.md` -> Expected: no match.
Run: `grep -niE "megathink|think harder|think hard" docs/04-configuration/token-efficiency.md` -> Expected: no match (the deprecated keyword ladder must not appear).
Run: `grep -nE "xhigh|ultracode|200k|1\.25x|5-min" docs/04-configuration/token-efficiency.md` -> Expected: matches present.

- [ ] **Step 9: Commit**

```bash
git add docs/04-configuration/token-efficiency.md
git commit -m "docs(token-efficiency): correct effort table, model lineup, context windows, caching mechanics"
```

### Task A2: token-efficiency.md - additions

**Files:**
- Modify: `docs/04-configuration/token-efficiency.md`

**Content authority:** spec section "Workstream 1 - Additions".

- [ ] **Step 1: Add the "The output side" section**

Add a new section covering, largest lever first: thinking effort (output, never cached); surgical/diff edits vs full-file rewrite (reinforce "make minimal edits, don't reprint the file"); narration/prose verbosity; scope of generated output; output styles (Explanatory/Learning are longer; switching style mid-session busts the cache). Mention `ultrathink` as the surviving per-turn deep-think keyword. Do NOT add the deprecated `think`/`think hard`/`megathink` ladder.

- [ ] **Step 2: Add `/rewind`**

In the existing `/clear`/`/compact` guidance, add `/rewind` - undo a single wrong turn while keeping the cache, vs `/clear` which drops history.

- [ ] **Step 3: Add the skill-description budget failure mode**

Skills are deferred (not context bloat), but their descriptions share the ~1% `skillListingBudgetFraction`; overflow silently truncates descriptions so a skill stops firing with no error. Curate skills; check `/doctor`/`/skills`. Frame as a reliability risk. Confirm the exact default fraction against current Claude Code settings docs while writing.

- [ ] **Step 4: Add the cache-bust caveat to mid-session switching**

Where the doc currently encourages mid-session `/model` switching, add: switching model/effort/style mid-session busts the per-prefix cache; prefer a subagent for a cheaper sub-task over flipping the main model; edit CLAUDE.md between sessions.

- [ ] **Step 5: Add "trim what you paste in"**

Large logs, JSON blobs, and full-resolution screenshots pasted by the user become permanent re-read context; paste the relevant slice.

- [ ] **Step 6: Soften the hard "<200 lines" CLAUDE.md rule**

Reframe the "SHOULD keep CLAUDE.md under 200 lines" guidance toward "stable + high-signal (~100-200 lines), don't starve it; editing it mid-session busts the cache." Keep the signal-dilution point; drop the implication that lower line count is the goal.

- [ ] **Step 7: Validate the build**

Run: `mkdocs build --strict 2>&1 | tail -15`
Expected: build succeeds, no warnings/errors referencing `token-efficiency.md`.

- [ ] **Step 8: Commit**

```bash
git add docs/04-configuration/token-efficiency.md
git commit -m "docs(token-efficiency): add output-side levers, /rewind, skill-budget risk, cache-bust + paste hygiene"
```

### Task A3: new generic `information-lookup.md` + nav

**Files:**
- Create: `docs/04-configuration/information-lookup.md`
- Modify: `mkdocs.yml`, `README.md`, `AGENTS.md`, `docs/index.md`, `docs/examples/workspace-claude-md.md`

**Content authority:** spec section "Workstream 2". Write tool-agnostic (placeholder orgs/keys), matching the repo's public-shaped style (see `cross-tool-setup.md` / `mcp/overview.md` for tone).

- [ ] **Step 1: Create the doc**

Create `docs/04-configuration/information-lookup.md` with the six sections from spec WS2: (1) the "don't ask the human for what you can look up" principle; (2) local-docs-first (read where you would write; AGENTS.md progressive discovery; external = secondary/stale); (3) the generic decision tree (from the spec); (4) fan-out research + disk-cache-with-freshness; (5) RAG/discovery trust model (pointer vs quote); (6) follow-all-linked-resources-first. H1 title + brief intro per the repo's Document Structure standard. Cross-link to `token-efficiency.md` and `vibecoding-best-practices.md`.

- [ ] **Step 2: Add to mkdocs nav**

In `mkdocs.yml`, under the `Configuration:` section, after the `Cross-Tool Setup` entry (currently `- Cross-Tool Setup: 04-configuration/cross-tool-setup.md`), add:

```yaml
    - Information Lookup: 04-configuration/information-lookup.md
```

- [ ] **Step 3: Add nav entries to README.md, AGENTS.md, docs/index.md**

Read each file, find where `token-efficiency.md` / `cross-tool-setup.md` are linked under Configuration, and add an `Information Lookup` link alongside, matching the surrounding format.

- [ ] **Step 4: Add the routing block to the example**

In `docs/examples/workspace-claude-md.md`, add a short example "Information Lookup" block (the generic artifact->tool + local-docs-first form) near the existing "MCP Routing" table.

- [ ] **Step 5: Validate the build (catches broken nav/links)**

Run: `mkdocs build --strict 2>&1 | tail -20`
Expected: build succeeds; `information-lookup.md` appears in `site/`; no "is not included in the nav" or broken-link warnings.

Run: `test -f site/04-configuration/information-lookup/index.html && echo OK`
Expected: `OK`.

- [ ] **Step 6: Commit**

```bash
git add docs/04-configuration/information-lookup.md mkdocs.yml README.md AGENTS.md docs/index.md docs/examples/workspace-claude-md.md
git commit -m "docs: add information-lookup pattern (routing, fan-out research, RAG trust, follow-links)"
```

### Task A4: guidelines PR gate + open PR

- [ ] **Step 1: Full validation pass**

Run: `mkdocs build --strict 2>&1 | tail -20`
Expected: clean build.
Run: `grep -niE "megathink|think harder" docs/04-configuration/token-efficiency.md` -> Expected: no match.

- [ ] **Step 2: Review the diff**

Run: `git diff origin/main --stat` and skim `git diff origin/main`. Confirm only the intended files changed and the verified facts match the spec table.

- [ ] **Step 3: Push the branch**

```bash
git push -u origin docs/token-hygiene-and-lookup-patterns
```

- [ ] **Step 4: Draft the PR body, show it to the user for approval, then open**

Draft the PR body (summary + the two-PR note + validation evidence). Show it to the user. After approval, open via `mcp__github__create_pull_request` (repo `adobe/mysticat-ai-native-guidelines`, base `main`). Do not open before the user approves the body.

---

## Part B - Workspace PR

Workspace repo root: `/Users/dj/work/github/adobe`.

### Task B0: branch setup

- [ ] **Step 1: Verify git state and branch from origin/main**

```bash
cd /Users/dj/work/github/adobe && git fetch origin main --quiet && git status --short && git checkout -b docs/information-lookup-routing origin/main && git branch --show-current
```
Expected: clean status, branch `docs/information-lookup-routing` created off `origin/main`.

### Task B1: compact Information Lookup block in workspace CLAUDE.md

**Files:**
- Modify: `/Users/dj/work/github/adobe/CLAUDE.md`

**Content authority:** spec section "Workstream 3 -> CLAUDE.md compact block". Keep within ~25 lines.

- [ ] **Step 1: Read CLAUDE.md and note the existing "GitHub Repo-to-tool routing" section**

Run: `Read /Users/dj/work/github/adobe/CLAUDE.md`. The new block reuses (does not duplicate) the existing GitHub routing.

- [ ] **Step 2: Insert the block**

Add a new `## Information Lookup` section. Draft (final wording may be tightened, keep all routing rows):

```markdown
## Information Lookup

Don't ask me for context you can look up yourself.

**Conceptual / "how does X work" / "is there an ADR about Y" / "what's our standard or process for Z" -> local docs first** (canonical, free, AGENTS.md-indexed):
- platform arch / cross-service contracts / ADRs / ops -> `mysticat-architecture/` (start at its `AGENTS.md`; ADRs in `platform/decisions/`)
- org RFC / principle / cross-team standard -> `aem-sites-architecture/` (`AGENTS.md` + `rfc-*/SKILL.md`; some are installed skills, check `/skills`)
- team process / AI & tooling practice -> `mysticat-ai-native-guidelines/`
- one service's implementation detail -> that repo's `docs/` + `AGENTS.md`
- which-tier map: `mysticat-architecture/DOCUMENTATION-GUIDE.md` (read-side mirror of the Information Hierarchy above)

**Specific artifact (ID/URL) -> its tool:**
- Jira (`SITES-`/`MWPW-`, jira.corp URL) -> `mcp__mcp-atlassian__jira_*`
- `wiki.corp.adobe.com` URL -> `mcp__mcp-atlassian__confluence_get_page`
- Slack URL/thread -> `mcp__slack__*`
- GitHub PR/repo -> github MCP by host (see Repo-to-tool routing above)
- Lambda/service logs -> Coralogix (`mcp__coralogix__*`); Splunk secondary
- sites/audits/opportunities/scrapes -> Postgres MCP, `sites-optimizer` query skills, or `spacecat-mcp`
- "has anyone discussed X / where is Y documented?" -> local docs first, then fan out `confluence_search` + `jira_search` + Slack search (no single cross-source discovery tool)

Trust AI search for *where* something lives, not the exact quote/name/date - cross-check against the source before citing. When reading a ticket/thread/PR, open all linked resources before starting. Prefer minimal/surgical edits (don't reprint files); be concise.

For deep-dive/fan-out research, read and follow `docs/claude/reference-information-lookup.md`.
```

- [ ] **Step 3: Confirm routing names match .mcp.json**

Run: `cd /Users/dj/work/github/adobe && for s in mcp-atlassian slack github coralogix; do grep -q "\"$s\"" .mcp.json && echo "OK $s" || echo "CHECK $s"; done`
Expected: `OK` for each (server keys exist; the tool prefix `mcp__<key>__` follows from the key). If a key differs, correct the block to match `.mcp.json`.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude): add Information Lookup routing block (local-docs-first + artifact->tool)"
```

### Task B2: on-demand reference doc (NOT @imported)

**Files:**
- Create: `/Users/dj/work/github/adobe/docs/claude/reference-information-lookup.md`

**Content authority:** spec section "Workstream 3 -> reference-information-lookup.md".

- [ ] **Step 1: Create the reference doc**

Create `docs/claude/reference-information-lookup.md` with: the full fan-out research + synthesis + disk-cache pattern (cache to a gitignored scratch path; align with any existing workspace scratch convention from `init.sh` / `docs/claude/reference-developer-setup.md`, defaulting to `$HOME/.claude-scratch/<cwd-slug>/research/claude-research-<topic>.md`; include freshness handling: use if < ~2 weeks, re-run if older, skip on explicit "fresh"); the expanded RAG/discovery trust model + calibration; the follow-links elaboration; and the verify-loaded routine (`/skills`, `/mcp`, `/context`, `/doctor`).

- [ ] **Step 2: Confirm it is referenced by pointer, NOT @imported**

Run: `cd /Users/dj/work/github/adobe && grep -n "@import.*reference-information-lookup" CLAUDE.md` -> Expected: no match.
Run: `grep -n "reference-information-lookup" CLAUDE.md` -> Expected: exactly the one pointer line from Task B1.

- [ ] **Step 3: Confirm existing @import targets still resolve**

Run: `cd /Users/dj/work/github/adobe && while read -r f; do [ -e "$f" ] && echo "OK $f" || echo "MISSING $f"; done < <(grep -oE '@import [^ ]+' CLAUDE.md | awk '{print $2}')`
Expected: `OK` for every imported file; no `MISSING`.

- [ ] **Step 4: Commit**

```bash
git add docs/claude/reference-information-lookup.md
git commit -m "docs(claude): add on-demand information-lookup reference (fan-out research, RAG trust, verify routine)"
```

### Task B3: workspace PR gate + open PR

- [ ] **Step 1: Sanity-check the block size and diff**

Run: `git diff origin/main --stat` and confirm only `CLAUDE.md` + `docs/claude/reference-information-lookup.md` changed. Confirm the `## Information Lookup` block is ~25 lines.

- [ ] **Step 2: Push the branch**

```bash
git push -u origin docs/information-lookup-routing
```

- [ ] **Step 3: Draft PR body, show user for approval, then open**

Draft the PR body (note this changes how Claude behaves in this workspace every session; include the @import-vs-pointer rationale and validation evidence). Show it to the user. After approval, open via the appropriate GitHub MCP for this repo's host. Do not open before approval.

---

## Self-review notes (author)

- **Spec coverage:** WS1 corrections -> A1; WS1 additions -> A2; WS2 -> A3; WS3 CLAUDE.md block -> B1; WS3 reference doc -> B2; placement/PR strategy/gates -> A4/B0/B3. All spec sections map to a task.
- **Independence:** Part A and Part B touch different repos and do not reference each other's outputs; either order works.
- **No silent truncation:** the only deliberate scope limit is the on-demand (non-imported) reference doc, which is called out explicitly in B2's validation.
