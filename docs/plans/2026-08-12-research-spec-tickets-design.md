# Research to Tickets: The First Mile of the Delivery Pipeline

| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Author** | Rainer Friederich |
| **Created** | 2026-08-12 |
| **Updated** | 2026-08-12 |
| **Decided** | N/A |
| **Approvers** | TBD |
| **Jira** | N/A (epic to be filed on adoption) |

## Summary

Extend the spec-to-shipped delivery chain upstream with three skills — a research/grilling skill, a spec-writing skill, and a ticket-creation skill — plus one unified spec contract, a machine lint for it, and a spec-PR mode for `create-pr`. Together they turn research into whichever outcome it warrants: a validated spec that the existing chain (`/implement` → `ship-feature`, which opens each PR through `create-pr`, → `pr-review-cycle` → `pr-validate`) consumes but nothing today authors, a directly filed work item, or recorded knowledge — and, where the PM requires it, decompose a spec into tickets. Every stage, including review and validation, is designed to run agent-to-agent in the end state; human touchpoints are built as policy points with explicit removal criteria, not permanent fixtures.

## Problem Statement

### Current State

The delivery chain in `adobe/experience-success-skills` starts from the assumption that a spec already exists at a URL resolvable to a commit SHA. That chain is under active development ( https://github.com/adobe/experience-success-skills/pull/160 ) and its downstream continuation, the spec-to-production procedure, is designed in this repository ( https://github.com/adobe/mysticat-ai-native-guidelines/pull/45 ). Upstream of the chain, no general-purpose spec-creation procedure exists: the lifecycle docs instruct a manual `cp docs/03-templates/spec-proposal.md`, and the one skill that authors specs today — `develop-llmo-feature` — is LLMO-scoped, carries its own divergent template, routes to a `docs/specs/` tree that exists in neither repo, and feeds nothing downstream.

The consequences are visible in the estate today:

- Spec bodies in `mysticat-architecture` have drifted into at least seven incompatible requirement styles, three filename conventions, and ad-hoc type prefixes (sampled 2026-08-12 across `products/`, `platform/`, `future/`, `migration/`, `research/`), while the mandated YAML frontmatter is followed consistently even though nothing yet enforces it — the Phase 1 lint would be the first machine check, not an extension of one. Several specs carry a second status line in the body that contradicts their own frontmatter (`status: decided` above, `**Status:** Architectural Vision (PARTIALLY IMPLEMENTED)` below) — exactly the block↔prose disagreement the lint targets, live in the estate today. Quality varies as widely as structure: some sampled specs carry rigorous numbered requirements with coverage maps while others state no requirements, acceptance criteria, or edge cases at all — and which one a downstream consumer gets is a function of who wrote it, not of what the work needed.
- The downstream de-facto spec schema is checked but never authored: the spec-compliance reviewer checks requirements coverage, task completeness with status, edge cases, surface-area updates, and technical-approach alignment; on the incoming chain, `/implement` parses a repos/branch declaration while `ship-feature` imposes no structural entry requirement at all — so the gap surfaces as review findings instead of authoring-time fixes.
- Research findings mostly land in the workspace's local scratch directory and die there — not because git refuses them (the directory is committable) but because no step commits or places them; no skill files Jira issues; no traceability fields connect specs, tickets, and PRs.
- The `spec-proposal.md` template itself carries no YAML frontmatter, so a spec created from it violates `mysticat-architecture`'s own governance on arrival.

### Desired State

A user (initially) or an upstream signal (eventually) enters the pipeline with a problem statement and leaves with what the research actually warrants: durable findings always; a validated spec merged into the scope-appropriate spec home at a commit SHA when the work is spec-worthy; a directly filed Jira bug/story or GitHub issue when the outcome is task- or defect-shaped; and — when the PM requires ticket tracking for spec-driven work — epic-linked Jira stories with blocking edges. From the merged spec the existing chain runs to a shipped, validated PR set; the spec's work-package table is the decomposition of record whether or not tickets exist. One spec contract is authored, linted, reviewed, parsed, and amended by machines; humans set policy, answer batched escalations, audit samples, and authorize production.

### Gap Analysis

- No research skill: investigation results are not converted into durable, evidence-anchored documents.
- No spec-writing skill: templates exist but nothing fetches, fills, validates, or places them, which is why body structure drifted.
- No ticket skill: Jira conventions exist only as prose rules; nothing decomposes a spec into stories, sets epic links, or writes ticket keys back.
- No spec-PR path: a PR whose diff *is* a spec breaks the current PR template (mandatory test plan, self-referential spec link) and meets the grounding gate on the wrong axis — it either self-links and passes on a self-reference, or omits the link and draws a degraded-review banner asking for the very spec it adds.
- Prose-only contracts: repos, branches, and merge order are inferred from prose by regex and heuristics — a liability once no human catches a misparse.
- No return edge: an intentional spec deviation disclosed in a PR triggers a nudge to update the spec that nothing consumes.

## Goals and Non-Goals

### Goals

- Three user-invocable skills in the `feature-delivery` plugin covering research/grilling, spec synthesis, and ticket creation, runnable in one session or standalone.
- One unified spec template that satisfies the downstream consumers by construction: the compliance-reviewer schema, the `/implement` parse targets, and `mysticat-architecture` frontmatter governance — including a machine-readable block for repos, branches, work-package edges, and merge order.
- A deterministic spec lint enforcing the template in every spec home's CI, with block↔prose agreement checks.
- A spec-PR mode for `create-pr` requiring zero changes to the review gate (it rides the existing exemption-bullet contract).
- An optional ticket stage — run only for work whose PM requires Jira tracking — encoding the SITES conventions: stories under the feature epic, blocking edges as issue links, spec URL as remote link, story keys written back into spec frontmatter.
- A spec amendment flow expressing changes as ADDED / MODIFIED / REMOVED deltas, closing the deviation-nudge return edge.
- Every human gate built as a consultable policy point: decisions answered from a policy layer, glossary, and ADRs before anyone is asked; human answers written back so the same question is never asked twice.

### Non-Goals

- Implementing the spec-to-production procedure (sibling design, own document).
- Replacing or modifying the review machinery (`pr-review`, `pr-review-cycle`, `pr-validate`) beyond the `create-pr` spec-PR mode and the machine-readable-block parsing added to `/implement` (Phases 2 and 3).
- Spec-as-source regeneration (humans edit only the spec, code is generated): deliberately rejected — it inherits Model-Driven Development's failure modes plus LLM non-determinism. This pipeline is spec-anchored: the spec is retained and amended, code is written against it.
- `create-tickets` publishing to GitHub issues: Jira is the canonical tracker for spec decomposition. GitHub issues appear only as entry points and as the task/defect exit's filing target where the receiving repo tracks its work there.
- Unattended dispatch of implementation sessions in v1 — v1 is Phases 1–8; dispatch and gate flips are Phase 9, post-v1, gated on the autonomy ladder.

## Proposed Solution

### Overview

```
grill-feature ──same session──▶ write-spec ──spec PR merged @ SHA──▶ /implement → ship-feature
 (frontier interview,            (synthesis, validation,             → (PR via create-pr) → pr-review-cycle
  research, glossary/ADR          spec PR into the                   → pr-validate → [ship-to-production]
  side-writes)                    scope-selected home)                        │
     │                                │      ▲                                │
     │                                │      └── amendment loop (deltas) ─────┘
     │                                │          from disclosed deviations
     │                                │
     │                                └──▶ [create-tickets] (optional, PM-required work only:
     │                                      work packages → Jira stories with edges; runs after
     │                                      the spec merges, mirrors the work-package table)
     │
     ├──▶ task/defect exit: Jira bug/story or GitHub issue, evidence attached (no spec)
     └──▶ knowledge exit: findings + glossary + ADRs only (no work item)
```

Skill names are placeholders pending decision (see Open Questions).

### Technical Design

**`grill-feature`** — a frontier-driven interview. **Entry is anything addressable:** a Slack conversation or thread permalink, a Jira issue key, a GitHub issue or PR URL, an incident or postmortem, a customer-feedback record, a research file, or plain prose. The skill normalizes whatever it is handed into the same initial problem frame — fetch the full content (thread replies, issue comments, linked material), extract the problem statement, prior decisions, and stakeholders, and record the source in the evidence ledger as provenance. External text is treated as untrusted input throughout: a Slack message or issue body contributes requirement *candidates* to be verified and decided, never instructions to be executed. From that frame the interview runs identically regardless of entry: map the design tree, ask the whole frontier of currently-answerable questions per round (numbered, each with a recommended answer), recompute after answers. Facts are the agent's job — fact-finding sub-agents use the workspace's verified evidence recipes (the PostgREST/Athena query skills, Splunk recipes, Scout) and return the reproduction (query, source, date) with every claim, never just the answer. Decisions are answered from the decision-policy layer, the glossary, and prior ADRs first; only unanswered decisions go to the user, and every answer is written back as policy, a glossary term, or an ADR (via the existing `new-adr` skill). Done means: empty frontier, confirmed shared understanding, durable findings moved to `mysticat-architecture/research/` — and **an explicit exit**. Research does not always yield a spec; the phase ends in exactly one of three outcomes:

1. **Spec warranted** — the work is large, cross-repo, or design-heavy: hand off to `write-spec` (full or light lane).
2. **Task- or defect-shaped** — the finding is small and self-evident: file it directly as a work item, evidence and provenance attached, no spec — or, when the research entered from an existing Jira issue or GitHub issue, enrich that item with the evidence instead of filing a duplicate. Jira per the SITES conventions (Bug for defects, Story otherwise; Task only when explicitly requested and only under a Story, never under an Epic), or a GitHub issue where the receiving repo tracks its work there. The eventual PR uses the existing no-spec exemption lane.
3. **Knowledge only** — the research answered a question but names no work: the findings, the glossary entries, and any ADRs are the whole output.

The exit is a decision recorded with a reason, not a default — so a session that produced only a bug report is a completed pipeline run, not an abandoned one.

**Spec placement** — a spec lands in one of three homes based on its scope: `mysticat-architecture` (platform and product architecture), `mysticat-ai-native-guidelines` (AI-native process and methodology — this document's own home), or `serenity-docs` (Adobe Brand Visibility / Serenity designs, which carries its own CONTRIBUTING naming and status taxonomy). `write-spec` classifies the scope and places accordingly — the same classify-then-place step the `new-adr` skill implements for decisions. The unified template and the lint apply identically in all three homes; `mysticat-architecture`'s `DOCUMENTATION-GUIDE.md`, which today does not name `serenity-docs`, is updated in Phase 1 to encode the rule.

**`write-spec`** — synthesis without re-interviewing. Fetches the canonical template from this repository (the `new-adr` pattern), fills it from the conversation, codebase, glossary, and ADRs. Requirements are written in EARS patterns (`WHEN <trigger> THE SYSTEM SHALL <response>`; Kiro's `SHALL CONTINUE TO` extension to EARS for regression-preserving bugfix specs). Unresolved points carry explicit `NEEDS CLARIFICATION` markers that must reach zero — or move to Open Questions with a phase (before implementation, during implementation, or out of scope) — before the PR opens. Validation is layered: mechanical lint, claim verification (every load-bearing claim executed, not read; unanchored claims demoted to assumptions), requirements↔work-package coverage both directions, an adversarial panel (`review-architecture` in its five-persona production-readiness mode, with an extended pre-check gate), and executable acceptance (each criterion provably failing at the base commit; each work package answering "what can I demo?"). Publishes as a spec PR into the scope-selected spec home via `create-pr` spec-PR mode; the spec PR merges only with at least one approving human review, which also asserts that every open question tagged *before implementation* is resolved. The verdict vocabulary is `pr-validate`'s, defined normatively in the middle-stage design of record ( https://github.com/adobe/mysticat-ai-native-guidelines/pull/48 ): validated / defect found / could not validate / skipped — never rounded up.

**`create-tickets`** — an **optional stage**: it runs only when the PM requires Jira tracking for the work. The spec's work-package table is the decomposition of record either way — implementation sessions and merge order derive from the spec, and tickets, when created, mirror the table rather than replace it. It runs after the spec PR merges, so every story links the spec at a stable SHA. It reads the work-package table (the table and the tickets are the same list), quizzes on granularity and blocking edges (a critic agent in the end state), then publishes blockers-first: SITES stories under the epic (`customfield_11800`), components ASO/LLMO, blocking edges as issue links, spec URL as a remote link, story keys written back into the spec's `jira:` frontmatter. Work packages are sliced per repo, always; cross-repo work defaults to expand/contract as three separately mergeable phases, each still sliced into per-repo work packages, with the contract step dated in the spec; past roughly 10 owning teams or 30 PRs (Chromium's published large-scale-change threshold) the spec must plan generated changes, not hand-written ones.

**Orchestration discipline** — every stage runs orchestration-first per the agent orchestration guide ( https://github.com/adobe/mysticat-ai-native-guidelines/pull/46 ): the main thread holds decisions, synthesis, and user interaction only. Fact-finding during grilling, codebase exploration, the adversarial validation and refutation passes, and the panel reviews are delegated to sub-agents that return condensed findings under the delivery contract matching their spawn shape — the unnamed single-channel form for fan-out (the full findings are the completion message), the named two-channel form only where mid-flight interaction is needed — so completed work cannot silently fail to arrive. Heavy artifacts (diffs, query outputs, draft bodies) travel by file path, never through the conversation.

**The unified spec contract** (the Phase 1 deliverable) — reconciles this repository's `spec-proposal.md` with `mysticat-architecture` frontmatter and the downstream de-facto schema. Frontmatter adds `jira:` (epic + stories, present when the PM requires ticket tracking) and `prs:` fields, and splits freshness into `updated` (content changed) and `verified` (a human or agent confirmed it still true). The body carries: problem statement · goals and non-goals · technical approach · EARS requirements · a work-package table — WP, a combined "Repo · branch" column (the shape `/implement` already recognizes), blocked-by, demo path — plus the literal session line and stacking/interactive-step declarations · acceptance criteria (red at base) · edge cases · surface-area updates · testing seams · out of scope · alternatives considered with drawbacks · open questions with phases · references. A fenced machine-readable block mirrors repos, branches, edges, and merge order; prose is for reasoning, agents parse the block, the lint guarantees the two agree. Three lanes match process to blast radius: No spec (the existing exemption path) · Light spec (single repo, one work package, one page) · Full spec (everything above; panel pass default for platform scope).

**`create-pr` spec-PR mode** (the Phase 2 deliverable) — for a PR whose diff is the spec: section 3 describes the delta to the design of record; section 4 drops the self-referential spec link and emits the exemption bullet the review gate already parses, so no gate change is needed and the PR is classified exempt instead of self-grounding or degraded; the deviations section (already conditional on a spec being found) never renders; the test plan is replaced by a review-and-adoption plan; the deployment-order section renders from the work-package edges when the spec defines a multi-PR set.

**Amendments** — a disclosed intentional deviation, or any post-merge learning, becomes an amendment PR expressed as ADDED / MODIFIED / REMOVED sections against the current spec, giving amendments merge semantics instead of rewrites.

**End-state automation** — all of the above is built agent-consumable from v1: judgment gates consult policy before asking; artifacts carry schemas, not just prose; outcomes are recorded as structured state alongside the human-readable comment; every gate returns pass/fail or delegates to an adversarial panel with a decision rule; failure modes stop loudly rather than proceed plausibly. Each human gate carries a flip criterion (for example: the clarifying-question rate per spec approaching zero is the evidence that specs are complete enough to skip the human clarify step). The any-source entry contract is what the unattended form will ride on: a labeled Jira ticket or an escalated Slack triage entering the pipeline with no human prompt (Phase 9, post-v1). Production authorization remains per-promotion and human — deliberately last, possibly never automated.

### Implementation Phases

**Phase 0: Gate.** The chain this design extends is under active development ( https://github.com/adobe/experience-success-skills/pull/160 ): that PR adds the entry skill (`/implement`), `ship-feature`, `pr-review-cycle`, and `pr-validate`, while `create-pr` predates it and is identical on `main` and the branch. The phases that build on the four added skills — Phase 3 onward — start only after that PR merges, and every contract reference to them (parse targets, gate strings) MUST be re-verified against the merged state, because those contracts track a moving branch. Phases 1 and 2 depend only on contracts stable on `main` (the template repos and `create-pr`) and may proceed before the gate.

**Phase 1: Contract.** Rewrite `docs/03-templates/spec-proposal.md` (frontmatter, EARS requirements, work-package table, machine-readable block, lanes), update the lifecycle doc that currently instructs a manual `cp`, encode the three-home placement rule in `DOCUMENTATION-GUIDE.md`, and land a shared `validate-spec.py` in the CI of all three spec homes with a mutation-tested fixture per rule.

**Phase 2: Spec-PR mode.** Extend `create-pr` in `adobe/experience-success-skills`; usable immediately for publishing specs (including amendments to the sibling spec-to-production design) through the normal review machinery.

**Phase 3: `write-spec`** — the synthesis skill with the layered validation. In the same change-set, `/implement` learns to read the machine-readable block, with the work-package table and session line remaining the prose fallback it already recognizes.

**Phase 4: `create-tickets`.**

**Phase 5: `grill-feature`** — last, because `write-spec` is useful without it and the reverse is not true.

**Phase 6: Amendment flow** and the pipeline overview doc in `02-lifecycle`.

**Phase 7: Decision-policy layer**, seeded from the first grilling sessions' answers.

**Phase 8: Dogfood** — run the chain on the spec-to-production design: file its epic, re-issue it through the template, ticket its open questions. Phases 1–8 are v1.

**Phase 9 (post-v1): Dispatcher and gate flips**, only against autonomy-ladder evidence.

## Alternatives Considered

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| Adopt the aihero skill chain as-is | Proven mechanics; minimal build | Specs as tracker issues (chain needs commit-SHA URLs); GitHub tickets (Jira is canonical); user-story template is the wrong shape for architectural work — its own author's stated limitation | Rejected (mechanics ported, artifacts re-targeted) |
| Adopt GitHub Spec Kit or Kiro | Mature templates; active ecosystems | Parallel doc system beside `mysticat-architecture` governance; no integration with review-kit personas or the PR-body contracts; reproduced overhead-inversion findings (a measured ~10× wall-clock on a small feature — the Scott Logic reference) with no scale-down path into our exemption lane | Rejected (their conventions — clarification markers, EARS, phase gates — adopted piecemeal) |
| One end-to-end mega-skill | Single entry point | Documented failure mode: file-writing silently skipped when a grilling skill runs inside an orchestration layer; violates one-clean-context-per-unit; unusable standalone | Rejected |
| Specs as Jira issues | Tracker-native; no PR ceremony | No commit-SHA pinning for `/implement`; no review machinery; large specs outgrow what a tracker serves back | Rejected |
| Status quo (manual template copy) | No build cost | Structural drift and author-dependent spec quality are the status quo's documented output — some specs rigorous, others without requirements or acceptance criteria at all | Rejected |

### Decision Rationale

Three separate user-invoked skills publishing through the existing PR/review machinery is the only option that reuses what already works (the persona roster, the challenge criteria, the validation vocabulary, the PR-body contracts), keeps each stage independently useful, and leaves an honest scale-down path — while the spec-PR mode makes the spec itself subject to the same review rigor as the code it will govern. The layered validation is the quality mechanism, not the template alone: a template guarantees the sections exist, while claim verification, coverage checks, the adversarial panel, and red-at-base acceptance criteria are what guarantee the content in them is good — a floor every spec clears regardless of author.

## Success Criteria

### Functional Requirements

- [ ] `write-spec` output is parsed by `/implement` from the machine-readable block with zero prose inference, and passes the spec lint on first publish.
- [ ] A spec PR opened in spec-PR mode receives no degraded-review banner and no unresolvable-token failure.
- [ ] For work the PM requires tickets for, `create-tickets` produces epic-linked SITES stories, blockers-first, with blocking links and the spec as remote link, and the story keys appear in the spec's frontmatter in the same change; spec-driven work without that requirement runs spec-to-implementation with no story decomposition (the task/defect exit's single work item is a separate path and unaffected).
- [ ] `grill-feature` accepts any supported entry point — a Slack permalink, a Jira key, a GitHub issue or PR URL, a file path, or prose — and normalizes it into the same problem frame with the source recorded as provenance; the interview from that point is entry-independent.
- [ ] A research run that exits task- or defect-shaped files a correctly typed work item (Jira Bug for defects, Story otherwise — Task only when explicitly requested and only under a Story; or a GitHub issue where the repo tracks work there) with the evidence attached, and records the no-spec exit decision with its reason.
- [ ] A knowledge-only exit leaves durable findings in the research home with provenance, any glossary/ADR side-writes in place, and the exit decision recorded — with no work item and no spec created.
- [ ] Every load-bearing factual claim in a generated spec carries an anchor (query + date, file @ SHA, or probe result); unanchored statements appear only under assumptions or open questions.
- [ ] A disclosed intentional deviation can be turned into an amendment PR expressed as ADDED / MODIFIED / REMOVED deltas.
- [ ] The lint rejects: missing frontmatter fields, non-EARS requirements, a work package spanning repos, an expand/contract set without a dated contract step, and block↔prose disagreement — each rule pinned by a fixture that fails when the rule is deleted, and the same lint running in the CI of all three spec homes.

### Non-Functional Requirements

- [ ] Light-spec lane: a single-repo feature produces at most one page of spec; time-to-first-commit does not rise while escaped defects stay flat (the over-paying trip-wire).
- [ ] Grilling never asks a question the policy layer, glossary, or an existing ADR already answers.
- [ ] The clarifying-question rate in downstream implementation sessions per spec trends toward zero — the leading indicator that specs are complete.

### Validation Plan

- [ ] Dogfood: run the full chain on the spec-to-production design and compare its output against that document's known gaps (missing epic, template drift, unticketed open questions).
- [ ] Run one real feature end-to-end from grilling to merged, validated PRs; count review rounds and spec amendments against a pre-pipeline baseline feature.
- [ ] Mutation-test the lint: delete each rule, confirm its fixture fails.

## Dependencies

### External Dependencies

- Atlassian MCP (Jira): entry-point reads, story and bug creation, links, remote links.
- Slack MCP: entry-point reads (conversations and threads as pipeline entries).
- GitHub (`gh`, MysticatBot review pipeline): entry-point reads (issues, PRs), spec PRs, and task/defect-exit issue filing.
- Workspace tooling: `mani` (repo registry the work-package validation checks against), `mise run wt` sessions.

### Internal Dependencies

- `adobe/experience-success-skills` PR 160 — adds the four skills this design builds on (`/implement`, `ship-feature`, `pr-review-cycle`, `pr-validate`), **in active development**: hard gate for Phase 3 onward; contracts re-verified at merge. `create-pr`, which Phase 2 extends, predates that PR and is identical on `main`.
- The spec-to-production design ( https://github.com/adobe/mysticat-ai-native-guidelines/pull/45 ) — sibling stage; shares the PR-body section contracts and the work-package-derived deployment order.
- The agent orchestration guide ( https://github.com/adobe/mysticat-ai-native-guidelines/pull/46 , in review; lands as `docs/01-foundations/agent-orchestration.md` in this repository) — the parallelism primitives and the spawn-shape delivery contracts every stage's sub-agent work follows.
- The three spec homes — `mysticat-architecture` (frontmatter governance, `DOCUMENTATION-GUIDE.md` placement rules, the `new-adr` skill), this repository (templates, lifecycle docs), and `serenity-docs` (CONTRIBUTING naming and status taxonomy) — each carrying the lint in CI.
- Workspace Jira conventions (SITES, epic custom field, issue-type rules, components) and the review-kit persona roster.

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Middle-layer contracts shift before this ships (PR 160 in flight) | High | Medium | Phase 0 gate on the phases consuming the four added skills; contracts pinned to merged SHAs; seam list re-verified at implementation start |
| Overhead inversion on small work (the most reproduced industry failure) | High | Medium | Three lanes; No-spec lane already exists; trip-wire metric watched |
| Spec drift misleading agent implementers | Medium | High | Amendment loop with delta grammar; `updated`/`verified` split; re-verification of the evidence ledger at implementation-session start |
| Review bottleneck moves to humans as generation scales | Medium | Medium | Panel + challenge criteria concentrate human attention on verified findings; sampled audit replaces per-item approval as gates flip |
| Policy write-backs encode a wrong answer permanently | Low | High | Write-backs are PRs reviewed like code; ADR supersession applies |

## Open Questions

- [ ] Skill names (`grill-feature` / `write-spec` / `create-tickets` are placeholders; the aihero names collide with an installed workspace skill). *(before implementation)*
- [ ] Panel pass default: mandatory for platform scope, opt-in otherwise? *(before implementation)*
- [ ] Light-spec lane cutoff, and whether the lane is author-chosen or lint-derived from the work-package table. *(before implementation)*
- [ ] RFD-style sequential numbering for `mysticat-architecture` specs vs filename-as-identity. *(before implementation)*
- [ ] ADR placement: keep central in `platform/decisions/` vs per-repo ADRs cross-linked to central specs. *(during implementation)*
- [ ] Where the machine-consultable decision-policy layer lives and who reviews write-backs. *(during implementation)*
- [ ] Dispatcher shape (cron skill, workflow, or service) and which environments may start sessions unattended. *(out of scope — post-v1; gate flips are evidence-driven)*
- [ ] The glossary home: `mysticat-architecture/platform/concepts/` (already holds internal vocabulary definitions) or `context/` (documented as external reference material). *(before implementation)*
- [ ] How the unified template reconciles with `serenity-docs`' existing CONTRIBUTING header and status taxonomy — adopt, map, or migrate. *(before implementation)*
- [ ] Convergence with `develop-llmo-feature` — it classifies placement against the same guide with its own divergent template, so Phase 1 must at least reconcile the two templates; whether its spec phase fully hands off at `write-spec` is the open half. *(template reconciliation: before implementation; full convergence: out of scope)*

## References

- https://github.com/adobe/experience-success-skills/pull/160 — the delivery chain under development
- https://github.com/adobe/mysticat-ai-native-guidelines/pull/45 — spec-to-production design (sibling stage)
- https://github.com/adobe/mysticat-ai-native-guidelines/pull/48 — middle-stage design of record and delivery-pipeline overview: the chain's contracts, work-item lanes, human gates, and the normative verdict vocabulary
- https://github.com/adobe/mysticat-ai-native-guidelines/pull/46 — agent orchestration guide: sub-agent primitives and delivery contract used by every stage
- https://www.aihero.dev/skills-grill-with-docs · https://www.aihero.dev/skills-to-spec · https://www.aihero.dev/skills-to-tickets — the skill-chain mechanics ported here
- https://github.com/mattpocock/skills — the aihero skill-chain implementation (grilling, domain-modeling, to-spec, to-tickets, tdd)
- https://github.com/github/spec-kit · https://kiro.dev/docs/specs/ · https://openspec.dev/ — clarification markers, EARS in practice, delta specs
- https://github.com/bmad-code-org/BMAD-METHOD · https://tessl.io/ — agent-orchestrated planning (document sharding) and the spec-as-source counter-position this design rejects
- https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html — spec-first / spec-anchored / spec-as-source taxonomy
- https://blog.scottlogic.com/2025/11/26/putting-spec-kit-through-its-paces-radical-idea-or-reinvented-waterfall.html — the measured ~10× overhead-inversion case
- https://chromium.googlesource.com/chromium/src/+/HEAD/docs/process/lsc/large_scale_changes.md — the published large-scale-change threshold adopted for work-package fan-out
- https://alistairmavin.com/ears/ — EARS requirement patterns
- https://www.industrialempathy.com/posts/design-docs-at-google/ · https://raw.githubusercontent.com/rust-lang/rfcs/master/0000-template.md · https://basecamp.com/shapeup/1.2-chapter-03 — the classic traditions the template reconciles
- https://abseil.io/resources/swe-book/html/ch22.html · https://www.martinfowler.com/bliki/ParallelChange.html — large-scale-change and expand/contract mechanics
- https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents · https://code.claude.com/docs/en/best-practices — context economy and verification-over-specification

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-08-12 | Rainer Friederich | Initial draft |
