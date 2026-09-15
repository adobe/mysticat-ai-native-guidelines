# Mental Models for the Blackboard Architecture

Six analogies that illuminate the architecture from different angles.

> **Core abstraction:** A DAG of derived values over changing inputs, with selective recomputation.
> This pattern is independently reinvented across computer science — spreadsheets, build systems, DP, TMS, materialized views, reactive programming. What makes the blackboard distinct is the **cost profile**: each computation step costs dollars and minutes (LLM calls), not microseconds. That cost profile forces scheduling, batching, budgeting, and preemptive warmup.

---

## 1. Spreadsheet

The tightest analogy.

| Spreadsheet | Blackboard |
|---|---|
| Cell with no formula | Observation (o_*) — raw data |
| Cell with formula | Derived fact (d_*) |
| Final output cell | Assertion (a_*) |
| Cell reference (`=A1`) | `@consumes(O_HTML)` |
| Formula body | Producer logic |
| Recalculation engine | Control Service cascade |
| Dirty flag on edit | `fact.updated` → cascade invalidation |
| Circular reference error | DAG cycle detection |
| Named range | Scope (tenant, brand, site, page) |
| Workbook / Sheet / Tab / Row | Tenant / Brand / Site / Page |

Excel's recalculation engine tracks cell dependencies, detects dirty cells on edit, topologically sorts recomputation, and parallelizes independent branches. Control does the same.

**Where it diverges:** Excel formulas cost microseconds. Producers cost dollars. That's why we need scheduling, batching, and preemptive computation — things Excel doesn't need.

---

## 2. Dynamic Programming

| DP Concept | Blackboard |
|---|---|
| Subproblem | One fact computation (producer + scope) |
| Overlapping subproblems | Multiple opportunities need the same intermediate facts |
| Memoization table | Blackboard fact store |
| Recurrence relation | Producer: `d_classification = f(o_html, o_screenshot)` |
| Base cases | Observations (o_*) |
| Solution | Assertions (a_*) |
| Top-down (memoization) | Pull mode — recursive, compute on miss |
| Bottom-up (tabulation) | SiteProcessor — builds topological plan, fills level by level |

The architecture exists because of overlapping subproblems: 11 isolated agents were making ~20 duplicate LLM calls per page across 150+ intermediate facts. The blackboard is `memo[key]` — compute once, reuse everywhere.

**Top-down vs bottom-up** maps to two real execution modes:
- **Top-down:** User requests a fact → check cache → miss → recurse to dependencies
- **Bottom-up:** SiteProcessor builds topological plan (ExecutionPlanBuilder) → fills table level by level (PlanExecutor) → all facts pre-computed

Bottom-up dominates because the "cache miss" cost is too high for interactive use.

**Where it diverges:** Classical DP assumes pure, deterministic functions. LLM calls are non-deterministic — same inputs may produce slightly different outputs. This makes memoization an approximation, not exact, and is why change detection on outputs matters.

---

## 3. Build System (Make / Bazel)

| Build System | Blackboard |
|---|---|
| Source files | Observations (o_*) |
| Object files (.o) | Derived facts (d_*) |
| Final binary | Assertions (a_*) |
| Makefile rules | `@produces` / `@consumes` decorators |
| Dependency graph | Fact DAG |
| `make` | SiteProcessor + ExecutionPlanBuilder |
| Incremental rebuild | Cascade invalidation |
| Build cache | Fact store |
| `make clean` | Forced recomputation (independent of age) |
| CI scheduler | SiteScheduler (leaderless, SKIP LOCKED claiming) |
| `make -j8` | TaskWorker distributed execution (scan_site tasks) / PlanExecutor `asyncio.gather()` (per-fact, in-process) |
| Content hash (Bazel) | Change detection |

The closest real-world analog overall. The blackboard is a **build system for knowledge** where source files are web observations, compile steps are LLM producers, and the binary is actionable recommendations.

Compiler engineers solved incremental compilation decades ago with the same techniques: file-level dependency tracking, content hashing to skip unchanged inputs, parallel compilation of independent units.

---

## 4. Truth Maintenance System (TMS)

| TMS Concept | Blackboard |
|---|---|
| Belief | Fact |
| Justification record | Dependency edge (which inputs produced this fact) |
| Assumption (unjustified) | Observation (o_*) — accepted without derivation |
| Derived belief | Derived fact (d_*) |
| Belief revision | Re-scan produces different result → cascade update |
| Non-monotonic reasoning | Issue disappears on re-scan → retract derived facts |
| Dependency-directed backtracking | Cascade invalidation (recompute only affected downstream) |

TMS (Doyle, 1979) tracks **why** each belief is held. Every derived belief has a justification record — the premises that support it. When a premise is retracted, the TMS walks the justification chain and retracts anything no longer supported.

**What maps cleanly:** The existing infrastructure is JTMS-style retraction. `derived_from` edges are justification records. `DependencyResolver.cascade_obsolescence()` walks those edges to retract downstream facts. `is_obsolete` is the "belief out" flag.

**Where the gap is:** The blackboard tracks dependencies at edge granularity (`d_cwv_issue` depends on `o_html`) but not at value granularity (*which aspect* of `o_html` justified the issue). The producer bridges this gap — it evaluates the inputs and decides whether the belief still holds by returning a value or `None`. See [fact-lifecycle-rescan.md](../decisions/fact-lifecycle-rescan.md) for the full design.

---

## 5. Materialized Views

| Database Concept | Blackboard |
|---|---|
| Base table | Observations (o_*) |
| Materialized view | Derived fact (d_*) |
| View definition (SQL) | Producer logic |
| `REFRESH MATERIALIZED VIEW` | SiteScheduler triggering scans → producers re-run |
| `REFRESH ... CONCURRENTLY` | Change detection (update only if result differs) |
| Incremental view maintenance | Cascade policies |
| Stale view | Fact eligible when touched after `Fact.max_staleness_hours` |
| View-on-view dependency | DAG: derived fact depending on another derived fact |

The blackboard is a system of materialized views where the "query" is an LLM call instead of SQL. Incremental view maintenance is an active database research area — Oracle, Postgres, and Snowflake each have different refresh strategies. The cascade system solves the same problem.

`Fact.max_staleness_hours` is specifically lazy: a positive value makes a fact eligible only when it is touched after that many hours, `0` makes every touch eligible, and `None` means age alone never makes it eligible. It does not delete facts or schedule refreshes. Explicit schedules and signals decide when to touch facts, while change detection can suppress unnecessary work after an eligibility check. `ttl_hours` remains only as a deprecated compatibility alias.

---

## 6. Reactive Programming (MobX / Vue Computed)

| Reactive Concept | Blackboard |
|---|---|
| Observable value | Observation (o_*) |
| Computed / derived | Derived fact (d_*) |
| Reaction / effect | Assertion delivered to user |
| Dependency tracking | `@consumes` decorator |
| Auto-rerun on change | Cascade policies |
| Batched updates (`runInAction`) | Batched execution mode |
| Equality check on computed | Change detection (skip cascade if output unchanged) |
| Scheduler | SiteScheduler + SiteProcessor |

In MobX, `computed(() => ...)` auto-tracks dependencies and re-runs on change. The `@consumes`/`@produces` decorators are the same pattern.

**Where it diverges:** Reactive frameworks assume cheap, synchronous recomputation. The blackboard adds an **economics layer** — scheduling, batching, budgeting, rate limiting — because each recomputation costs real dollars. Any reactive system operating at LLM cost profiles would need the same infrastructure.

---

## Which Analogy When

| Audience | Use | It Explains |
|---|---|---|
| **Stakeholders** | Spreadsheet | "Cells with formulas that auto-recalculate" |
| **Data engineers** | Materialized Views | Refresh strategies, staleness, incremental maintenance |
| **Backend engineers** | Build System | Incremental rebuild, DAG, parallel execution |
| **AI/ML engineers** | Dynamic Programming | Memoization, overlapping subproblems, cost savings |
| **Architects** | Truth Maintenance | Belief retraction, non-monotonic reasoning, lifecycle |
| **Frontend engineers** | Reactive Programming | Dependency tracking, auto-recomputation, batching |
