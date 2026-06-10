# Agent-Ergonomic Refactoring

## Overview

Most of these guidelines describe how to set up an agent-ready environment: instruction files, hooks, enforcement gates, legible documentation. They implicitly assume a codebase you can shape from the start. This document covers the harder, more common case: **retrofitting an existing codebase** — one with years of accumulated string dispatch, copy-paste seams, god-files, and a test suite that breaks on every rename — into a shape where agents reliably produce correct changes. Where [Mechanical Enforcement](mechanical-enforcement.md) describes the gates a finished environment enforces absolutely, this document covers how to sequence the retrofit that *adds* those gates to a codebase that cannot yet pass them.

The core observation from doing this in practice: when agents repeatedly produce wrong implementations in a codebase, the cause is usually structural, not a model limitation. Agents imitate the code they read and follow the path of least resistance. If the wrong implementation is the easy one, agents (and humans) will keep producing it. The fix is to refactor until **the correct implementation is the path of least resistance** — and to do that refactoring safely in a codebase that resists change.

This document covers six patterns: the agent-ergonomics audit, find-all-usages design, the ratchet pattern, mechanical verification of behavior-preserving refactors, test suites that permit refactoring, and scaffolding as steering. They were developed during a production retrofit (the `adobe-rnd/llmo-data-retrieval-service` epic, issue 2066) triggered by a cross-service migration that took ~50 PRs and broke repeatedly — a retro showed every failure traced to structure, not bad luck.

## The Core Principle

> Make the correct thing the easy thing. An agent editing one call site should have a **local signal** for every contract it must honor (types, required arguments, a single client method), and a failure should be **loud and close to its cause** — not a silent production error surfaced days later.

Two corollaries drive everything below:

- **Agents imitate.** In a file with 30 broad `except Exception` blocks, the agent's 31st handler will be a broad except. Structure is the strongest prompt you have.
- **Agents can only honor contracts they can find.** Any contract that lives in a reviewer's head, a wiki page, or a string literal in another repository will be violated at agent speed.

## The Agent-Ergonomics Audit

Before refactoring, audit. The goal is an evidence-backed backlog, not a vibes-based rewrite plan.

### Running the audit

Run parallel investigation agents, each with one dimension, over the full codebase:

| Dimension | What it hunts |
|-----------|---------------|
| Architecture & layering | Intended layer rules and where they are violated; competing abstractions; live-vs-dead twin code paths (V1/V2) |
| Grep-hostility | Everything that breaks find-all-references (see next section) |
| Duplication & smells | Copy-paste seams, god-files, mega-functions, exception swallowing, logging drift |
| Test ergonomics | Implementation pinning, mock-call assertions, fixture sprawl, mega test files |
| Docs & navigation | Stale specs, missing package-level docs, unindexed script surfaces |

Rules for audit output:

- **MUST** back every finding with concrete `file:line` evidence and a rough blast-radius count — "string dispatch exists" is not actionable; "provider IDs appear as bare literals 143 times, 10 if/elif sites in scheduler.py" is.
- **SHOULD** cross-check findings against the original incident retro — audits regularly *correct* the retro (in the reference case, a suspected duplicate client turned out to be one client with duplicated scope-derivation logic, which changes the fix entirely).
- **SHOULD** re-audit after a tranche of fixes lands; the second pass finds seams the first pass could not see past.

### The issue template

File each finding as an issue with four mandatory sections:

```markdown
## Problem
<file:line evidence, counts, blast radius>

## Why this trips up a coding agent
<the failure mode from the agent's perspective: what local signal is
missing, what the agent cannot find, what it will imitate>

## Proposed seam
<the structural fix: chokepoint, registry, typed contract, base class>

## Safety / sequencing
<how to verify behavior is preserved; what this is gated by or gates>
```

The "why this trips up a coding agent" section is the discipline: if you cannot articulate the agent failure mode, the issue is ordinary tech debt and belongs in a different backlog. The "safety / sequencing" section is what turns a finding list into an executable plan.

## Find-All-Usages: Design Code for Static Discovery

The single most valuable property of an agent-ergonomic codebase: **every usage site of every contract is statically findable.** An agent asked to rename, extend, or migrate something must be able to enumerate all affected sites with grep or find-references — and know that the enumeration is complete. [ACI Design](../04-configuration/aci-design.md) covers making search and docs agent-friendly; this is the complement: making the *code itself* discoverable.

### Grep-hostile patterns and their fixes

| Anti-pattern | Why agents miss sites | Fix |
|--------------|----------------------|-----|
| String-keyed dispatch (`if provider == "foo"` scattered across files) | No enforcement that a grep found every branch | One StrEnum + one registry; dispatch only through it |
| `importlib` / `getattr` over dotted-path strings | Find-references is blind; renames break routing at runtime | Static imports at a single registration point |
| Cross-plane name contracts (infra code writes `"JOBS_TABLE"`, runtime reads `os.environ["JOBS_TABLE"]` — two hand-typed strings) | The two planes never appear in one search; renames produce silent `None` config | A shared name-constant registry imported by **both** planes, plus a structural guard test that registered names never reappear as bare literals |
| Optional cross-cutting parameters (auth scope, tenant ID) threaded ad hoc | Nothing forces a new call site to pass them | A **chokepoint**: one client method with a required, typed parameter (`scope: Scope`), so omission is a type error, not a production 403 |
| Untyped dict payloads across module boundaries | Field names invisible; consumers grep for `.get("field")` and miss | TypedDict / model classes at every boundary (see [Anti-Patterns: Stringly Typed](anti-patterns.md#stringly-typed)) |
| Test mocks patched by string path (`patch("pkg.mod._helper")`) | A rename breaks dozens of tests with no static signal | Patch at I/O boundaries; see test section below |

### Rules

- **MUST** route extensible dispatch (providers, handlers, job types) through a typed registry with an enum key — adding a member without registering it must fail a structural test, not a production request.
- **MUST** define any name shared across planes (IaC ↔ runtime, producer ↔ consumer) as a single constant imported by both sides.
- **SHOULD** add a structural guard per migrated contract: a test that fails if a registered name/key reappears as a bare literal anywhere in the tree.
- **SHOULD NOT** rely on convention ("we always pass scope") for contracts whose violation is an incident — encode them in types.

## The Ratchet Pattern

Brownfield codebases have debts too large to fix in one PR: hundreds of broad excepts, thousands of untyped signatures. Absolute enforcement ([Mechanical Enforcement](mechanical-enforcement.md)) would fail every build; fixing first and enforcing after means the debt grows while you fix. The ratchet resolves this: **freeze the measured baseline, and fail CI only when a count increases.**

### Mechanics

1. Count the pattern per file (grep/AST — must be near-zero CI cost) and commit the counts as a baseline file.
2. A CI check fails any PR whose per-file count **exceeds** baseline.
3. Decreases auto-tighten the baseline (or are committed alongside the fix), so the count only moves down.

```
src/foo.py: broad-except count 31 > baseline 30
Rule: ratchet/broad-except
Fix: narrow the new except at src/foo.py:214 to a specific exception,
     or use the taxonomy in src/common/exceptions.py
See: issue 2072
```

Error output MUST follow the agent-friendly format ([Mechanical Enforcement](mechanical-enforcement.md#agent-friendly-error-messages)) — the whole point of a ratchet is to redirect the agent at the moment it is about to imitate the wrong pattern, and a bare "counts exceeded" sends it guessing.

### Variants

- **Report → enforce two-phase:** ship the check in report mode (prints the gap table, always exits 0), let the team see it, then flip an env var to enforce. Lowers the social cost of adding a gate; set a date for the flip or it stays report-mode forever.
- **Per-file-ignores as baseline:** for linters, enable the rule globally and generate the per-file ignore list from current violations. New files get the rule immediately; existing files ratchet down as touched.
- **Grow-only scopes:** for tools with a coverage scope (type-checker `files = [...]`), the ratchet is that the list only grows — add each package as it gets typed.

### Rules

- **MUST** pin the exact version of any tool whose output feeds a baseline. Clone detectors, linters, and type checkers change their findings between majors; an unpinned tool silently invalidates the baseline and the gate passes vacuously. (Observed in production: an unpinned duplicate-code detector jumped a major version and the baseline went stale without a single CI failure.)
- **MUST** set thresholds at the *current* baseline, not an aspirational target — a ratchet that fails unrelated PRs on day one gets deleted, not respected.
- **MUST NOT** confuse ratchets with correctness gates. A ratchet freezes a known debt; it does not catch new mistake classes. Structural fixes remain the priority; the ratchet keeps the hole from deepening while you dig out.
- **SHOULD** inventory existing dormant tooling before building new gates — in the reference retrofit, most ratchet machinery already existed (a coverage-targets script with an unflipped enforce mode, an installed-but-never-invoked dead-code detector, a fragility scorer not wired into CI). Flipping switches is cheaper than building them.

## Verifying Behavior-Preserving Refactors

Structural refactoring at agent speed is only safe when "this changed nothing" is mechanically checkable. Three patterns:

### Empty-artifact-diff gates

When code generates a deterministic artifact (IaC synthesis, codegen, serialized config), a behavior-preserving refactor must produce a **byte-identical artifact**. Synthesize before and after, normalize (sort keys, mask content hashes), and diff. An empty diff is proof — reviewable in seconds, regardless of how many call sites the refactor touched. Constant extraction, dedup, and rename refactors across hundreds of sites become safe mechanical work.

### Grow-only structural guards

When migrating a contract incrementally (e.g., names into a registry), the guard test enforces only what has been migrated: each name joins the guard's enforcement list in the same change that migrates its last bare literal. The guard stays green throughout the migration, and every protected name stays protected forever. Never add a name to the guard before it is fully migrated — a guard that needs exemptions teaches agents that exemptions are normal.

### Atomic migration units

Define the unit of migration so that no transition window exists where a contract is half-enforced. For a cross-plane name: the write side, every read site, and the guard entry move in **one** change. Sequencing tranches of such atomic units is how a 163-name migration ships as a series of small, individually-safe PRs.

### Rules

- **MUST** define, per refactoring issue, the mechanical check that proves behavior is preserved (artifact diff, green characterization tests, structural guard) — "carefully reviewed" is not a check. Prefer checks the agent can run at edit time ([Mechanical Enforcement: Edit-Time](mechanical-enforcement.md#1-edit-time-hooks-and-linters)) — a verification loop that only closes in CI costs a full round-trip per attempt.
- **SHOULD** stage multi-site refactors as: new seam added alongside old → call sites flipped incrementally → old seam deleted last. Every intermediate state is shippable. This is Fowler's [parallel change](https://martinfowler.com/bliki/ParallelChange.html) (expand–contract) applied at PR granularity.

## Test Suites That Permit Refactoring

A test suite can be the main obstacle to the refactoring it should enable. The failure mode: tests pinned to the internal call graph — patching private functions by string path, asserting that mocks were called, hardcoding dates — break on every rename even when behavior is unchanged. The agent then cannot distinguish real regressions from name-pin noise, and either reverts good changes or "fixes" tests by pinning them harder.

One terminology note: Feathers' characterization tests (*Working Effectively with Legacy Code*) are also called *pinning tests* — those pin observable **behavior** before a refactor and are exactly the safety net you want. The pinning this section removes is **implementation**-pinning: tests welded to the internal call graph rather than to behavior.

### Measure pinning before restructuring

Score the suite mechanically (a small AST script suffices):

| Signal | Why it blocks refactoring |
|--------|--------------------------|
| `patch()` targets with `_`-prefixed names | Freezes private implementation details by name |
| `mock.assert_called*` assertions | Verifies wiring, not behavior; breaks on any restructure |
| Hardcoded dates with no frozen clock | Pins time by literal; flakes at boundaries |
| Patch count per test (>3) | The unit does too much, or the test belongs in a higher tier |

Weight and rank per file; the highest-scoring files are the de-pinning order. Critically: **the production function you most want to extract is usually the most-pinned one** — in the reference codebase, the prime extraction candidate was patched by name 42 times. De-pinning is therefore a *prerequisite* for god-file splits, not a cleanup afterthought.

### Reduce with evidence, not judgment

Suites grown by copy-paste contain tests that add nothing. Before deleting:

- **Mutation sampling** per module: tests that kill no mutants are deletion *candidates* — equivalent mutants and sampling variance produce false "worthless test" verdicts, so confirm intent before deleting.
- **Coverage contexts** (`--cov-context=test`): a test whose covered lines are a strict subset of another's is a dedup candidate.
- **Convert, don't only delete:** mock-call tests with real intent become component tests (in-memory fakes of the I/O layer, assertions on real state); the rest go.
- **Golden/table-driven tests at real seams** (parsers, classifiers, exporters): one golden test with N cases replaces N brittle mock tests and documents the contract.

### Rules

- **MUST** patch at I/O boundaries (HTTP, storage, queues — via fakes like moto/responses or recorded cassettes), not at private functions.
- **MUST** mark tests whose guarantee must outlive any rewrite (e.g., a `regression` marker: "never delete without migrating the guarantee elsewhere") before starting bulk reduction.
- **SHOULD** rewrite a module's tests behaviorally at the moment a structural refactor forces touching them anyway — never as a standalone big-bang project.
- **SHOULD** tier tests by behavior and speed markers and gate PRs on the fast tiers — agent throughput dies behind a 45-minute suite (see [Mechanical Enforcement](mechanical-enforcement.md#3-ci-time-pipeline-gates)).

## Scaffolding as Steering

Rules tell agents what to do; scaffolding pre-builds the path so the correct starting point is the generated one. For any package shape that recurs (providers, handlers, plugins), provide a generator (`just new-provider <name>`) that emits the skeleton wired to the shared base classes, the registry entry, the mirrored test skeleton, and the infra checklist.

Without it, an agent's natural move is to copy the nearest existing example — which in a brownfield codebase is often a 5,000-line accretion of every historical quirk. The generator converts "imitate the neighbor" from a liability into the mechanism of correctness. Pair it with a conformance test (parametrized over the registry) asserting every instance exposes the required surface, so the pattern stays enforced rather than just documented.

## Sequencing the Retrofit

Order the work by **safety and protective value**, not by impact ranking — each step either carries zero production risk or is mechanically verified, and each makes the steps after it safer:

1. **Ratchets first.** Zero production risk, and every later refactor benefits from frozen baselines from day one.
2. **Docs and navigation in parallel.** Zero risk, and they reduce the error rate of every subsequent agent session.
3. **Mechanical migrations next** (constant extraction, name registries) — verified by empty-artifact diffs and structural guards, so they need no support from the test suite and can proceed before de-pinning.
4. **Chokepoint/registry refactors** — behavior-preserving by construction, staged old-alongside-new. Do **not** rename or move functions while tests still pin them by string path.
5. **Test de-pinning** — the gate for everything structural: it converts the suite from rename-hostile to rename-safe, which is what the next step consumes.
6. **God-file splits and shared-base extraction last**, module by module, rewriting each module's tests behaviorally as the split forces touching them — the highest-blast-radius work, attempted only once ratchets, guards, and de-pinned tests protect it.

Group the backlog into dependency tiers and state the execution order separately — "what depends on what" and "what to do first" are different orderings, and conflating them confuses both humans and agents reading the epic.

- **MUST** keep every merge independently deployable — in continuously-deployed services, a half-staged refactor sitting on the main branch ships with the next unrelated deploy.
- **SHOULD** run the failure-driven loop continuously: every agent failure during the retrofit is evidence for the next audit pass (see [Harness Engineering: The Environment Audit Mindset](../01-foundations/harness-engineering.md#the-environment-audit-mindset)).

## See Also

- [Mechanical Enforcement](mechanical-enforcement.md) - Enforcement points, agent-friendly errors, structural tests — the absolute-enforcement complement to ratchets
- [Anti-Patterns](anti-patterns.md) - Stringly Typed, Exception Swallowing, Copy-Paste Programming — the patterns this retrofit removes
- [ACI Design](../04-configuration/aci-design.md) - Agent-Computer Interface: search, navigation, docs, error design
- [Harness Engineering](../01-foundations/harness-engineering.md) - The environment audit mindset and application legibility
- [AI Readiness Checklist](../06-adoption/ai-readiness-checklist.md) - Assessing a repo's starting point
