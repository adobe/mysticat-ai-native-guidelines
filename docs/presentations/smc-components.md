# Blackboard Architecture

## Service Interactions Deep Dive

> **Last Updated:** 2026-09-15
> **Note:** This document describes the **target architecture**. Current implementation uses direct method calls (not SNS/SQS). See implementation status notes on each slide.

---

# Slide 1: The 4 Services at a Glance

```mermaid
flowchart TB
    subgraph EventBus["SNS EVENT BUS (fan-out)"]
        direction LR
        drs_events["drs-events"]
        bb_events["blackboard-events"]
    end

    subgraph Services
        DRS["<b>DRS</b><br/><i>Fetchers</i><br/><br/>External data fetch<br/>HTML, screenshots,<br/>GSC, GA4, Ahrefs"]

        BB["<b>BLACKBOARD</b><br/><i>Long Term Memory</i><br/><br/>Store facts<br/>Track dependencies<br/>Freshness eligibility"]

        CTRL["<b>CONTROL</b><br/><br/><br/>Orchestration<br/>Scheduling<br/>Policies"]

        REASON["<b>REASONING</b><br/><i>Compute</i><br/><br/>AI agents<br/>Derive facts<br/>Produce assertions"]
    end

    DRS -->|"observation.*"| drs_events
    BB -->|"fact.*"| bb_events

    drs_events --> BB
    drs_events --> CTRL
    bb_events --> CTRL

    CTRL -->|"SQS: refresh"| DRS
    CTRL -->|"SQS: compute"| REASON
    CTRL -->|"SQS: invalidate"| BB

    REASON <-->|"SDK/API"| BB

    style DRS fill:#e1f5fe
    style BB fill:#fff3e0
    style CTRL fill:#f3e5f5
    style REASON fill:#e8f5e9
```

## Service Roles

| Service | Responsibility |
|---------|----------------|
| **DRS** | Fetch external data (HTML, screenshots, GSC, GA4, Ahrefs) |
| **Blackboard** | Central fact store, dependency tracking, freshness eligibility |
| **Control** | Orchestration, scheduling, cascade policies |
| **Reasoning** | AI agents that consume facts and produce derived facts |

`Fact.max_staleness_hours` controls lazy eligibility, not expiry: positive `N` becomes eligible only when touched after `N` hours, `0` is always eligible (with change detection still able to suppress work), and `None` is force-or-signal-only. The field neither deletes facts nor schedules refreshes; `ttl_hours` is a deprecated compatibility alias.

---

# Slide 2: DRS <-> Blackboard

## Pattern: Notify + Pointer

```mermaid
sequenceDiagram
    participant CTRL as Control
    participant DRS as DRS
    participant S3 as S3
    participant BB as Blackboard

    CTRL->>DRS: SQS: refresh(o_html, scope)
    DRS->>S3: Store raw HTML
    S3-->>DRS: s3://bucket/path/html.json
    DRS->>BB: SNS: observation.ready
    Note over BB: Stores fact with<br/>S3 pointer only
    BB->>CTRL: SNS: fact.created
```

## Why Notify + Pointer?

- **Large data** (HTML, screenshots, Lighthouse) stays in S3
- **Facts table** stores only pointers + metadata
- **Efficient queries** without loading blobs

> **Implementation Status:** Pattern partially implemented. DRS stores results, `ObservationBridge` processes them, but uses direct method calls instead of SNS events. Screenshots stored as inline base64 (not S3 pointers).

---

# Slide 3: DRS <-> Control

## Control Commands DRS to Fetch Data

```mermaid
flowchart LR
    subgraph Control
        SCHED["Scheduler<br/>(cron, touch)"]
        API["API<br/>(/trigger)"]
        CASCADE["Cascade<br/>Policy"]
    end

    subgraph DRS
        FETCH["Fetcher"]
    end

    SCHED -->|"SQS: refresh"| FETCH
    API -->|"SQS: refresh"| FETCH
    CASCADE -->|"SQS: batch"| FETCH

    FETCH -->|"SNS: observation.ready"| Control
    FETCH -->|"SNS: observation.failed"| Control

    style SCHED fill:#f3e5f5
    style API fill:#f3e5f5
    style CASCADE fill:#f3e5f5
    style FETCH fill:#e1f5fe
```

## Commands (Control -> DRS via SQS)

| Command | Purpose |
|---------|---------|
| `refresh(key, scope)` | Fetch fresh observation (o_html, o_screenshot, etc.) |
| `batch(operations[])` | Batch fetch multiple pages/observations |

## Events (DRS -> Control via SNS)

| Event | Trigger |
|-------|---------|
| `observation.ready` | Fetch completed successfully |
| `observation.failed` | Fetch failed (triggers retry/alert) |
| `batch.completed` | Batch job finished |

## Trigger Sources

- **Scheduled**: Control's cron touches facts (for example, a weekly scan); `Fact.max_staleness_hours` is checked then
- **Manual**: API call to `/v1/control/trigger`
- **Cascade**: Upstream fact changed or emitted an explicit signal

> **Implementation Status:** TierScheduler orchestrates scans and DRS calls. Currently uses direct Python method calls, not SQS queues. SNS events planned for Phase 3.

---

# Slide 4: TierScheduler - Main Computation Path

> **Note on execution model:** HA mode with distributed TaskWorkers is the required production architecture (see Slide 7b and 10). PlanExecutor shown in this slide is the current interim path (used in all modes today — Phase 3 not yet wired). See [ha-architecture.md](../decisions/ha-architecture.md).

## Scheduled Scans Drive Fact Computation

```mermaid
flowchart TB
    subgraph TierScheduler["TierScheduler (Main Loop)"]
        SCHED["run_scheduled_scans()"]
        SITE["_scan_site()"]
        CASCADE["_execute_cascade()"]
    end

    subgraph Execution["Plan Execution"]
        BUILDER["ExecutionPlanBuilder<br/>Build DAG from goals"]
        EXECUTOR["PlanExecutor<br/>Parallel execution (max 4)"]
    end

    subgraph Services
        OBS["ObservationRegistry<br/>Store o_html, o_screenshot"]
        REASON["ReasoningService<br/>compute_with_skip_check()"]
        BB["Blackboard<br/>store_fact()"]
    end

    SCHED -->|"for each site due"| SITE
    SITE -->|"1. store observations"| OBS
    SITE -->|"2. execute cascade"| CASCADE
    CASCADE --> BUILDER
    BUILDER -->|"sorted DAG"| EXECUTOR
    EXECUTOR -->|"for each ready node"| REASON
    REASON -->|"store result"| BB
    OBS --> BB

    style SCHED fill:#f3e5f5
    style EXECUTOR fill:#e8f5e9
    style BB fill:#fff3e0
```

## Execution Flow

| Step | Component | Action |
|------|-----------|--------|
| 1 | TierScheduler | Check which sites are due (by tier frequency) |
| 2 | ObservationRegistry | Store observations (o_html, o_screenshot, o_pagespeed) |
| 3 | ExecutionPlanBuilder | Build DAG from goal facts, topologically sort |
| 4 | PlanExecutor (current interim) / TaskWorker (HA target) | Execute nodes in parallel (respecting dependencies) |
| 5 | ReasoningService | Semantic diff check → compute → store to Blackboard |

## Key Features

- **Distributed execution**: 75 concurrent coroutines per worker pod via PostgreSQL task queue (production)
- **Cascade skip**: If upstream unchanged, downstream automatically skipped
- **Semantic diff**: `compute_with_skip_check()` detects unchanged inputs
- **Goal-driven**: Tier config specifies `enabled_opportunity_types` as goals

> **This is how 95%+ of fact computation happens** - via scheduled tier scans, not event-driven cascades. Currently runs via PlanExecutor in-process (interim). HA mode with distributed TaskWorkers is the required production architecture (Phase 3 wires this).

---

# Slide 4b: Cascade Policies (Secondary Mechanism)

## Event-Driven Cascades for Ad-Hoc Triggers

```mermaid
flowchart LR
    subgraph Blackboard
        STORE["store_fact()"]
        EMIT["_emit_event()"]
    end

    subgraph Control
        HANDLER["handle_event()"]
        POLICY["CascadePolicies<br/>get_actions()"]
    end

    subgraph Reasoning
        COMPUTE["compute_with_skip_check()"]
    end

    STORE --> EMIT
    EMIT -->|"callback: fact.created"| HANDLER
    HANDLER --> POLICY
    POLICY -->|"action: compute"| COMPUTE
    COMPUTE -->|"store result"| STORE

    style STORE fill:#fff3e0
    style EMIT fill:#fff3e0
    style HANDLER fill:#f3e5f5
    style POLICY fill:#f3e5f5
    style COMPUTE fill:#e8f5e9
```

## When Cascade Policies Are Used

| Trigger | Example |
|---------|---------|
| **External observation push** | SpaceCat sends new CWV data → triggers dependent derivations |
| **Manual fact creation** | API call creates o_html → policies trigger d_page_classification |
| **Distributed task queue** | TaskWorkers process compute_fact tasks from PostgreSQL queue (primary production path) |

## Event Types

| Event | Handler | Status |
|-------|---------|--------|
| `fact.created` | `_on_fact_created()` | ✅ Looks up policies, triggers compute |
| `fact.updated` | `_on_fact_updated()` | ✅ Falls back to on_created policies |
| `fact.removed` | `_on_fact_removed()` | ✅ Triggers downstream recomputation |
| `fact.stale` | `_on_fact_stale()` | ⏳ Explicit signal logs only; no autonomous refresh |

## Policy Structure

```python
CascadePolicy(
    trigger_fact_key="o_html",      # When this fact changes...
    trigger_event_type="on_created",
    action_type="compute",           # ...compute this target
    action_target="d_page_classification",
    scope_filter={"tiers": ["paid_starter", "paid_pro"]},  # Optional tier filtering
)
```

> **Note:** HA mode is the required production architecture: SiteScheduler claims due sites, TaskWorker executes tasks from the distributed PostgreSQL queue. Currently, PlanExecutor is used in all modes for per-page cascades (Phase 3 not yet wired).

---

# Slide 5: Blackboard <-> Reasoning

## Direct SDK Calls (Same Process)

```mermaid
sequenceDiagram
    participant EXEC as PlanExecutor
    participant REASON as ReasoningService
    participant BB as Blackboard
    participant PROD as Producer

    EXEC->>REASON: compute_with_skip_check(fact_key, scope)
    REASON->>BB: consume_with_ids([inputs], scope)
    BB-->>REASON: Input facts + fact_ids
    REASON->>REASON: Check semantic diff (inputs unchanged?)
    alt Inputs unchanged
        REASON-->>EXEC: ComputeResult(skipped=True)
    else Inputs changed
        REASON->>PROD: producer.compute(scope, context)
        PROD-->>REASON: Result value
        REASON->>BB: store_fact(key, value, derived_from=input_ids)
        BB->>BB: _emit_event("fact.created")
        BB-->>REASON: Stored fact
        REASON-->>EXEC: ComputeResult(fact=stored_fact)
    end
```

## SDK Calls (Reasoning -> Blackboard)

| Call | Purpose |
|------|---------|
| `blackboard.consume(fact_keys, scope)` | Get input facts for computation |
| `blackboard.consume_with_ids(fact_keys, scope)` | Get inputs + their IDs for lineage |
| `blackboard.store_fact(key, value, derived_from)` | Write derived fact with lineage |

---

# Slide 6: Control <-> Reasoning

## TaskWorker / PlanExecutor Orchestrates Fact Computation

```mermaid
flowchart TB
    subgraph Control["Control (TierScheduler)"]
        BUILDER["ExecutionPlanBuilder"]
        EXEC["PlanExecutor"]
    end

    subgraph Reasoning["Reasoning Service"]
        COMPUTE["compute_with_skip_check()"]
        REG["ProducerRegistry"]
        PROD["Producer<br/>(AI Agent)"]
    end

    subgraph Blackboard
        FACTS[(Facts)]
    end

    BUILDER -->|"build DAG"| EXEC
    EXEC -->|"for each ready node"| COMPUTE
    COMPUTE --> REG
    REG -->|"lookup @produces"| PROD
    PROD -->|"consume inputs"| FACTS
    FACTS -->|"input facts"| PROD
    PROD -->|"store result"| FACTS

    style BUILDER fill:#f3e5f5
    style EXEC fill:#f3e5f5
    style COMPUTE fill:#e8f5e9
    style PROD fill:#e8f5e9
    style FACTS fill:#fff3e0
```

## Execution Model

| Aspect | Implementation |
|--------|----------------|
| **HA target (required for production)** | Task queue enqueue → TaskWorker claims via SKIP LOCKED |
| **Current interim** | PlanExecutor runs in-process (used in all modes today; Phase 3 wires task queue) |
| **Parallelism** | 75 concurrent coroutines per worker pod |
| **Skip detection** | Semantic diff on input facts |
| **Cascade skip** | If upstream skipped, downstream auto-skipped |

## Reasoning Computation Flow

1. PlanExecutor (current interim) or TaskWorker (HA target) calls `reasoning.compute_with_skip_check(fact_key, scope)`
2. Lookup `@produces("d_page_classification")` → finds `PageClassificationProducer`
3. Get `@consumes` → needs `o_html`, `o_screenshot_desktop`
4. Call `blackboard.consume_with_ids()` to get inputs + their fact IDs
5. **Semantic diff check**: Compare current inputs vs inputs used for existing fact
6. If unchanged → return existing fact (skip computation)
7. If changed → execute `producer.compute()` → store result with lineage

## HA Task Queue Execution

```
TierScheduler._execute_cascade()
  └── task_queue.enqueue_task(handle_compute_fact, {fact_key, scope})

TaskWorker (separate process)
  └── claim_task() → SKIP LOCKED query
        └── handle_compute_fact() → reasoning.compute_with_skip_check()
```

| Aspect | Implementation |
|--------|----------------|
| **Claiming** | PostgreSQL `SKIP LOCKED` for contention-free task claiming |
| **Parallelism** | 75 concurrent coroutines per worker pod |
| **Lease renewal** | Every 100s, 30s timeout grace |
| **Task types** | `handle_compute_fact`, `handle_scan_site` |
| **Env vars** | `CONTROL_HA_ENABLED=true`, `CONTROL_HA_TASK_WORKER=true` |

> See **Slide 10** for full HA architecture (leaderless workers, Aurora sizing).

---

# Slide 7: Complete Flow Example

## Scenario: Page HTML Changes -> Cascade to Recommendations

```mermaid
sequenceDiagram
    participant CTRL as Control
    participant DRS as DRS
    participant S3 as S3
    participant BB as Blackboard
    participant REASON as Reasoning
    participant DATA as Data Service

    Note over CTRL: 1. Scheduled touch requests refresh
    CTRL->>DRS: refresh o_html

    Note over DRS: 2. Fetch HTML
    DRS->>S3: Store raw HTML
    DRS->>BB: observation.ready

    Note over BB: 3. Store fact pointer
    BB->>CTRL: fact.created {o_html}

    Note over CTRL: 4. Policy matches
    CTRL->>REASON: compute d_webpage_context

    Note over REASON: 5. Execute agent
    REASON->>BB: consume([o_html])
    BB-->>REASON: HTML content
    REASON->>BB: store(d_webpage_context)

    Note over BB: 6. Cascade continues
    BB->>CTRL: fact.created {d_webpage_context}
    CTRL->>REASON: compute d_page_classification

    Note over REASON: 7. Chain until final
    REASON->>BB: store(a_guidance_hotlctr)

    Note over DATA: 8. Update projections
    BB->>DATA: PostgreSQL trigger
    DATA->>DATA: Refresh opportunities view
```

## Design Principles

| Principle | Description |
|-----------|-------------|
| **Reflective pattern** | Control (meta-level) decides; others execute |
| **Event-driven** | All services decouple via SNS/SQS |
| **Explicit dependencies** | `@consumes/@produces` decorators |
| **Idempotent commands** | Safe retries and deduplication |

---

# Slide 7b: HA Task Queue Flow

## Scenario: TierScheduler Triggers Site Scan with Distributed Workers

```mermaid
sequenceDiagram
    participant SCHED as TierScheduler
    participant BUILDER as ExecutionPlanBuilder
    participant TQ as TaskQueue (PostgreSQL)
    participant W1 as Worker-1
    participant W2 as Worker-2
    participant REASON as ReasoningService
    participant BB as Blackboard

    Note over SCHED: 1. Check due sites
    SCHED->>SCHED: run_scheduled_scans()
    SCHED->>SCHED: site "example.com" is due

    Note over BUILDER: 2. Build execution plan
    SCHED->>BUILDER: build_plan(goals=[a_guidance_hotlctr])
    BUILDER-->>SCHED: DAG: o_html → d_page_class → a_guidance

    Note over TQ: 3. Enqueue all tasks
    SCHED->>TQ: enqueue(compute_fact, o_html)
    SCHED->>TQ: enqueue(compute_fact, d_page_class, deps=[o_html])
    SCHED->>TQ: enqueue(compute_fact, a_guidance, deps=[d_page_class])

    Note over W1,W2: 4. Workers claim tasks (SKIP LOCKED)
    W1->>TQ: SELECT ... FOR UPDATE SKIP LOCKED
    TQ-->>W1: task: compute_fact(o_html)
    W1->>W1: lease_expires_at = now() + 5min

    Note over W1: 5. Execute observation
    W1->>REASON: compute_with_skip_check(o_html, scope)
    REASON->>BB: store_fact(o_html, html_content)
    W1->>TQ: mark_completed(o_html)

    Note over W2: 6. Deps ready, claim next
    W2->>TQ: SELECT ... WHERE deps satisfied SKIP LOCKED
    TQ-->>W2: task: compute_fact(d_page_class)
    W2->>REASON: compute_with_skip_check(d_page_class, scope)
    REASON->>BB: consume(o_html) → store(d_page_class)
    W2->>TQ: mark_completed(d_page_class)

    Note over W1: 7. Final task
    W1->>TQ: SELECT ... WHERE deps satisfied
    TQ-->>W1: task: compute_fact(a_guidance)
    W1->>REASON: compute_with_skip_check(a_guidance, scope)
    REASON->>BB: consume(d_page_class) → store(a_guidance)
    W1->>TQ: mark_completed(a_guidance)

    Note over TQ: 8. All tasks done
    TQ-->>SCHED: scan complete
```

## Key Differences from Event-Driven Flow

| Aspect | Event-Driven (Slide 7) | HA Task Queue (This Slide) |
|--------|------------------------|----------------------------|
| **Trigger** | Fact events cascade one-by-one | All tasks enqueued upfront from DAG |
| **Parallelism** | Sequential cascade | Multiple workers claim in parallel |
| **Failure handling** | Event replay | Lease expiry → task re-claimed |
| **Visibility** | Implicit in event flow | Explicit task queue with status |

## Task Queue States

```
┌─────────┐    claim     ┌────────────┐   success   ┌───────────┐
│ PENDING │─────────────▶│ PROCESSING │────────────▶│ COMPLETED │
└─────────┘              └────────────┘             └───────────┘
     │                         │
     │                         │ lease expires
     │                         ▼
     │                   ┌────────────┐
     └───────────────────│  PENDING   │ (re-claimable)
                         └────────────┘
```

---

# Slide 8: Control - Customer Tier Configuration

## Control Manages Per-Tenant and Per-Site Entitlements

```mermaid
flowchart TB
    subgraph ConfigManager["Control: ConfigManager"]
        direction TB

        subgraph Tiers
            PLG["<b>PLG Free</b><br/>5 sites<br/>50 pages<br/>2 opp types<br/>weekly"]
            STARTER["<b>Paid Starter</b><br/>10 sites<br/>200 pages<br/>all types<br/>weekly"]
            STANDARD["<b>Paid Standard</b><br/>25 sites<br/>500 pages<br/>all types<br/>daily"]
            ENT["<b>Enterprise</b><br/>100 sites<br/>unlimited<br/>custom<br/>daily"]
        end
    end

    TENANT["Tenant<br/>adobe-customer-123"]
    SITE1["Site A<br/>example.com"]
    SITE2["Site B<br/>blog.example.com"]

    TENANT --> STANDARD
    SITE1 -->|"override: all pages"| ENT
    SITE2 --> STANDARD

    style PLG fill:#ffcdd2
    style STARTER fill:#fff9c4
    style STANDARD fill:#c8e6c9
    style ENT fill:#bbdefb
```

## Tier Hierarchy

| Tier | Sites | Pages/Site | Scan Freq | Opportunities | Features |
|------|-------|------------|-----------|---------------|----------|
| `plg_free` | 5 | 50 | weekly | 2 types only | Basic |
| `paid_starter` | 10 | 200 | weekly | All types | + Preflight |
| `paid_standard` | 25 | 500 | daily | All types | + API access |
| `paid_enterprise` | 100 | unlimited | daily | All + custom | Full |

## Scan Scope Options

| Scope | Description |
|-------|-------------|
| `all` | Every discovered page (paid customers) |
| `top_n` | Top N pages by traffic (default) |
| `sampled` | Statistical sample across page types |
| `sitemap_only` | Only pages in sitemap.xml |

---

# Slide 9a: Thinkers - The Compute Challenge (PLANNED)

> **Implementation Status:** This slide describes **planned compute flavours** (Lambda/Fargate/K8s routing). HA mode with distributed TaskWorkers is the required production architecture. Currently, PlanExecutor runs in-process in all modes (interim, max 4 concurrent via `CONTROL_EXECUTOR_MAX_PARALLEL`). Phase 3 wires the task queue.

## Problem: Reasoning Tasks Have Vastly Different Resource Needs

```mermaid
xychart-beta
    title "Compute Requirements Vary 1000x"
    x-axis ["Rule-based", "Single LLM", "Multi-step", "Site-wide", "Full reprocess"]
    y-axis "Duration (log scale)" 0 --> 100
    bar [0.1, 10, 300, 3600, 7200]
```

## Resource Variance

| Task                                                   | Duration | Memory | Compute |
|--------------------------------------------------------|----------|--------|---------|
| Rule-based classifier                                  | < 100ms | 128MB | CPU |
| Single LLM call                                        | 1-10s | 512MB | CPU + API |
| Multi-step agents                                      | 30s-5min | 2GB | CPU + API |
| Site-wide analysis                                     | 5min-1hr | 8GB | CPU + API |
| Complex coding agents, Claude Code/skills + sandboxing | 1hr+ | 16GB+ | CPU + GPU |

## Why Single Environment Fails

| If we only use... | Problem                                               |
|-------------------|-------------------------------------------------------|
| In-process only   | Long tasks block the service, OOM risk, not sandboxed |
| Lambda only       | 15min timeout, cold starts, no GPU                    |
| K8s only          | Overkill for simple tasks, slow spin-up               |

**We need tiered compute.**

---

# Slide 9b: Thinkers - Four Compute Environments (PLANNED)

> **Implementation Status:** Only **In-Process** tier is implemented. Lambda/Fargate/K8s routing is designed but not yet built. See [design-compute-flavours.md](../future/design-compute-flavours.md).

## Solution: Match Task to Appropriate Infrastructure

```mermaid
flowchart LR
    subgraph Environments
        direction TB

        IN["<b>IN-PROCESS</b><br/>< 1s<br/>128MB<br/>Same process<br/>Zero latency"]

        LAMBDA["<b>AWS LAMBDA</b><br/>1-30s<br/>512MB<br/>Serverless<br/>Per-invoke cost"]

        FARGATE["<b>AWS FARGATE</b><br/>30s-5min<br/>2GB<br/>Container<br/>Per-second cost"]

        K8S["<b>ETHOS K8s</b><br/>5min-1hr<br/>8GB+<br/>Container<br/>Long compute<br/>Sandboxing"]
    end

    CTRL["Control"]

    CTRL -->|"tier=instant"| IN
    CTRL -->|"tier=quick"| LAMBDA
    CTRL -->|"tier=medium"| FARGATE
    CTRL -->|"tier=long"| K8S

    style IN fill:#e8f5e9
    style LAMBDA fill:#fff3e0
    style FARGATE fill:#e1f5fe
    style K8S fill:#f3e5f5
```

## Environment Comparison

| Environment | Duration | Best For                                      | Trade-offs |
|-------------|----------|-----------------------------------------------|------------|
| **In-Process** | < 1s | Rule-based, lookups, transforms               | Fastest, but blocks if slow |
| **AWS Lambda** | 1-30s | Single LLM call, light processing             | Serverless, but 15min max |
| **AWS Fargate** | 30s-5min | Multi-step agents, batch LLM                  | Flexible, but ~30s cold start |
| **Ethos K8s Jobs** | 5min-1hr | Site-wide analysis, heavy compute, sandboxing | Most powerful, slowest to start |

---

# Slide 9c: Thinkers - Developer Experience (PLANNED)

> **Implementation Status:** `@compute_profile` decorator does **not exist yet**. All producers run in-process. This slide describes the target DX once compute tiers are implemented.

## Developers Declare Tier at Design Time -> Control Routes Automatically

```mermaid
flowchart TB
    subgraph Developer["Developer Declares"]
        CODE["@compute_profile(<br/>tier='long',<br/>timeout_minutes=30,<br/>memory_mb=4096<br/>)"]
    end

    subgraph Control["Control Routes"]
        ROUTER["Producer<br/>Registry"]
    end

    subgraph Infra["Infrastructure"]
        IN["In-Process"]
        LAMBDA["Lambda"]
        FARGATE["Fargate"]
        K8S["K8s Job"]
    end

    CODE --> ROUTER
    ROUTER -->|"instant"| IN
    ROUTER -->|"quick"| LAMBDA
    ROUTER -->|"medium"| FARGATE
    ROUTER -->|"long"| K8S

    style CODE fill:#e8f5e9
    style ROUTER fill:#f3e5f5
```

## Control Routing Table

| Declaration | Routes To |
|-------------|-----------|
| `@compute_profile(tier="instant")` | Direct function call (same process) |
| `@compute_profile(tier="quick")` | SQS -> AWS Lambda |
| `@compute_profile(tier="medium")` | SQS -> AWS Fargate |
| `@compute_profile(tier="long")` | SQS -> Ethos K8s Job |

## Real-World Mappings

| Reasoning Task               | Tier | Environment |
|------------------------------|------|-------------|
| Page type classifier         | `instant` | In-process |
| Single guidance (1 LLM call) | `quick` | Lambda |
| HotLCTR multi-step agent     | `medium` | Fargate |
| Site-wide keyword analysis   | `long` | K8s Job |

**Key principle:** The team owning the reasoner decides the tier, not Control at runtime.

---

# Slide 10: Control - High Availability & Scaling

## Distributed Plan Execution

```mermaid
flowchart TB
    subgraph Scheduling["Scheduling (Leaderless)"]
        direction LR
        W1["Worker-1"]
        W2["Worker-2"]
        W3["Worker-3"]
    end

    subgraph TaskQueue["PostgreSQL Task Queue"]
        direction TB
        TQ[(control_task_queue)]
        T1["compute_fact(o_html)"]
        T2["compute_fact(o_screenshot)"]
        T3["compute_fact(d_page_class)<br/>deps: [T1, T2]"]
        T4["compute_fact(a_guidance)<br/>deps: [T3]"]
    end

    W1 -->|"claim site"| TQ
    W1 -->|"enqueue plan"| T1
    W1 -->|"enqueue plan"| T2
    W1 -->|"enqueue plan"| T3
    W1 -->|"enqueue plan"| T4

    W2 -->|"SKIP LOCKED"| T1
    W3 -->|"SKIP LOCKED"| T2
    W1 -->|"deps ready"| T3
    W2 -->|"deps ready"| T4

    style W1 fill:#f3e5f5
    style W2 fill:#f3e5f5
    style W3 fill:#f3e5f5
    style TQ fill:#fff3e0
```

## Why Leaderless?

| Aspect | Leader-Based | Leaderless (Chosen) |
|--------|--------------|---------------------|
| Failure mode | Leader crash → 30s gap | No single point of failure |
| Complexity | Leader election + task queue | Task queue only |
| Mental model | Leader schedules, workers execute | All workers equal |

## Worker Architecture

```
┌─────────────────────────────────────────┐
│         Worker Pod (1 process)          │
│                                         │
│  asyncio event loop                     │
│  ├── task_1 → await llm_call()          │
│  ├── task_2 → await llm_call()          │
│  └── ... (75 concurrent coroutines)     │
│                                         │
│  Memory: ~750MB per pod                 │
└─────────────────────────────────────────┘

4 pods × 75 concurrent = 300 capacity
```

## Sizing Summary

| Component | Spec | Cost |
|-----------|------|------|
| **Worker pods** | 4 × 750MB, 75 coroutines each | K8s resources |
| **Aurora Writer** | db.r6g.xlarge (4 vCPU, 32GB) | ~$320/mo |
| **Aurora Reader** | db.r6g.large (2 vCPU, 16GB) | ~$160/mo |
| **PgBouncer** | Transaction mode, 50 pool size | Sidecar |

## Key Patterns

| Pattern | Purpose |
|---------|---------|
| `SKIP LOCKED` | Contention-free task claiming |
| `LISTEN/NOTIFY` | Reduced polling (wake on new tasks) |
| DAG `depends_on` | Parallel execution respecting dependencies |
| Idempotency keys | Safe retries, no duplicate work |

> **Implementation Status:** Task queue, SKIP LOCKED, DAG depends_on, 75 coroutines per pod - all ✅ implemented. LISTEN/NOTIFY designed but uses polling fallback (1s interval).

> See [ha-architecture.md](../decisions/ha-architecture.md) for full details.

---

# Presentation Summary

| # | Slide | Content |
|---|-------|---------|
| 1 | **Overview** | 4 services at a glance |
| 2 | **DRS <-> Blackboard** | Notify + Pointer pattern |
| 3 | **DRS <-> Control** | Refresh commands, observation events |
| 4 | **TierScheduler** | Main computation path (95%+ of work) |
| 4b | **Cascade Policies** | Secondary event-driven mechanism |
| 5 | **Blackboard <-> Reasoning** | SDK consume/store |
| 6 | **Control <-> Reasoning** | Compute commands, HA task queue execution |
| 7 | **Complete Flow** | End-to-end cascade example (event-driven) |
| 7b | **HA Task Queue Flow** | TierScheduler + distributed workers |
| 8 | **Control Tiers** | Customer tier configuration |
| 9a | **Compute Challenge** | Why we need multiple environments |
| 9b | **Compute Environments** | The 4 supported infrastructures |
| 9c | **Compute DX** | Developer declares, Control routes |
| 10 | **Control HA** | Distributed execution, worker scaling |

---

# Related Documents

- [architecture.md](../01-architecture/architecture.md) - Primary architecture reference
- [data-flow-map.md](../01-architecture/data-flow-map.md) - Data flow diagrams
- [service-commands-events.md](../01-architecture/service-commands-events.md) - Full API reference
- [design-compute-flavours.md](../future/design-compute-flavours.md) - Compute tier exploration (PLANNED)
- [requirements-control-features.md](../future/requirements-control-features.md) - Tier requirements
- [ha-architecture.md](../decisions/ha-architecture.md) - HA infrastructure design
