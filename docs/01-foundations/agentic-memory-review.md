# Review: Agentic Memory Architecture (MIRIX & Simulation)

**Status:** Review / Pragmatic Assessment
**Last Updated:** 2025-01-19
**Reviewer:** Infrastructure team

> A pragmatic engineer's review of the MIRIX-inspired memory architecture and agent simulation proposals. The research is valuable inspiration, but we need to separate what's actionable now from what's speculative research.

---

## Executive Summary

The [mirix-layered-memory-analysis.md](mirix-layered-memory-analysis.md) and [agent-simulation-environment.md](agent-simulation-environment.md) documents propose sophisticated agentic memory systems inspired by academic research. While conceptually sound, they mix:

1. **Immediately useful** - Memory layers, fact authority
2. **Needs more design** - Workflow engine integration
3. **Research/deferred** - RL training, simulation environment

Given current priorities (DRS scaling for AEM page scanning, PLG for CS/AMS customers) and the need for system stabilization, we should extract the practical pieces and defer the speculative ones.

---

## What the Documents Propose

### MIRIX Memory Layers

A 7-layer memory architecture for organizing facts:

| Layer | Purpose | Always in context? |
|-------|---------|-------------------|
| Core | Brand identity, tenant preferences | Yes |
| Working | Current task facts | Task-dependent |
| Episodic | Historical events, outcomes | Selective |
| Semantic | Domain knowledge (WCAG, SEO rules) | On-demand |
| Workflow | Human-defined processes | Step-dependent |
| Procedural | Agent-learned patterns | Suggestive |
| Resource | References (URLs, docs) | Pointers only |

### Agent Simulation Environment

A PettingZoo-compatible simulation for:
- Testing agents against pre-configured memory states
- Learning patterns from human behavior traces
- RL-style training with reward shaping

---

## Key Clarifications Needed

### 1. Memory Layers vs DAG vs Scopes

**Concern:** Will this create an uncontrollable mixture of concepts?

**Clarification:** These are orthogonal dimensions, not competing structures:

| Dimension | What it is | Example |
|-----------|------------|---------|
| **Scope** | Multi-tenancy hierarchy | `site:acme.com/page:/products` |
| **DAG dependencies** | What triggers recomputation | `seo_analysis depends_on page_content` |
| **Memory layer** | Context budget allocation | "This fact goes in the 'core' bucket" |
| **Authority** | Override priority | "Human assertion beats agent-derived" |

The existing DAG remains unchanged. Memory layer is just a **tag on facts** that tells the context builder how to prioritize inclusion in agent prompts.

```python
class Fact:
    # Existing
    key: str
    value: Any
    scope: FactScope
    depends_on: list[str]  # DAG edges

    # New (just metadata)
    memory_layer: MemoryLayer = MemoryLayer.WORKING
    authority: FactAuthority = FactAuthority.AGENT
```

### 2. Workflow Engine vs Blackboard State Machine

**Concern:** The blackboard already has event-driven cascades. Why another workflow engine?

**Clarification:** They serve different purposes:

| Aspect | Blackboard DAG | Workflow Engine (MIRIX) |
|--------|----------------|-------------------------|
| **Nodes** | Facts (data) | Steps (activities) |
| **Edges** | Derived-from (dependency) | Next-step (sequence) |
| **Triggers** | Data change events | Step completion |
| **Blocking** | No (async cascade) | Yes (approval gates) |
| **Purpose** | React to data changes and explicit touches | Coordinate human + agent |

**However:** ASO already integrates with **WorkFront** for human approval workflows.

### 3. WorkFront: Delegate for Human Surfacing Only

**Important context:** WorkFront is a **3rd-party tool** (Adobe-owned, but separate product/team). It should **only** be used to surface decision points to customers - not to orchestrate workflows.

**Why we must own the workflow engine (not WorkFront):**

| Concern | Why WorkFront Can't Own It |
|---------|---------------------------|
| **Fact dependencies** | Workflow steps trigger based on fact changes (`seo_analysis` ready → proceed to review). WorkFront has no visibility into blackboard. |
| **Control Service integration** | Control owns scheduling, compute budgets, coalescing. Workflow progression is a control decision. |
| **Memory layer semantics** | Our concepts (procedural memory, authority hierarchy, episodic learning) don't exist in WorkFront's model. |
| **Context building** | Agent context depends on current workflow step + memory layers. Only our engine understands this. |
| **Release independence** | Different teams, different roadmaps. Tight coupling = cross-team dependency for every change. |

**Recommendation: WorkFront should be a notification delegate only**

*Note: This is a recommendation to be discussed with other architects.*

```
┌─────────────────────────────────────────────────────────────────┐
│           OUR WORKFLOW ENGINE (Blackboard + Control)             │
│                    (We own this completely)                      │
│                                                                  │
│  Owns:                                                          │
│  • Workflow state machine, step definitions, transitions        │
│  • Fact dependencies & cascade triggers                         │
│  • Memory layer integration & authority rules                   │
│  • Business logic: when/what needs human decision               │
│  • Integration with Control Service policies                    │
└─────────────────────────────────────────────────────────────────┘
                    │                         ▲
                    │ "surface this to human" │ "human decided X"
                    ▼                         │
┌─────────────────────────────────────────────────────────────────┐
│                 WORKFRONT (Notification Delegate)                │
│              (Only surfaces tasks - does NOT orchestrate)        │
│                                                                  │
│  Does:                                                          │
│  • Show task to user with description we provide                │
│  • Send notifications, reminders                                │
│  • Return decision (approved/rejected/edited) via callback      │
│                                                                  │
│  Does NOT:                                                      │
│  • Own workflow state                                           │
│  • Make routing decisions                                       │
│  • Know about facts, memory layers, or cascades                 │
└─────────────────────────────────────────────────────────────────┘
```

**Benefits:**
- We control all workflow semantics and can innovate independently
- WorkFront does what it's good at (human-facing UX, notifications)
- Loose coupling: WorkFront is swappable for Slack, email, custom UI
- No cross-team dependencies for workflow changes

### 4. RL Training and Simulation

**Concern:** If an RL agent runs every 5 minutes, where's the human in the loop?

**Clarification:** The simulation is for **offline training**, not production:

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRAINING (Offline, separate env)              │
│                                                                  │
│  • Load pre-configured scenarios                                │
│  • Replay human traces                                          │
│  • Train policies via RL                                        │
│  • No real consequences                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ trained policies (artifacts)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PRODUCTION                                    │
│                                                                  │
│  • Agents execute with frozen policies                          │
│  • Human-in-the-loop via WorkFront                              │
│  • No live learning                                             │
└─────────────────────────────────────────────────────────────────┘
```

The "5-minute loop" is the **Control Service** scheduling touches. It is deterministic, not RL, and distinct from `Fact.max_staleness_hours`, which only determines lazy recomputation eligibility when a fact is touched.

---

## Practical Assessment

### What's Immediately Useful

| Component | Value | Effort | Recommendation |
|-----------|-------|--------|----------------|
| Memory layer field on facts | Better context selection | Low | **Implement** |
| Authority field (human/agent) | Respect human assertions | Low | **Implement** |
| MetaMemoryManager | Smarter context building | Medium | **Implement** |

These are just metadata additions and a context builder. No new infrastructure.

### What Needs Design Refinement

| Component | Blocker | Recommendation |
|-----------|---------|----------------|
| Workflow Engine | Needs design integrated with Blackboard + Control | **Build as part of Blackboard, Control triggers transitions** |
| Notification Delegate Interface | Need contract definition | **Design simple interface: surface task → receive decision** |
| Procedural Memory (patterns) | How are patterns discovered? | **Design pattern lifecycle** |

### What's Research / Deferred

| Component | Why Defer | Prerequisites |
|-----------|-----------|---------------|
| RL training loop | No training data, no reward definition | Observability, human traces |
| PettingZoo simulation | Heavy for what may be integration tests | Stable prod to test against |
| Pattern learner | "Learn from human traces" assumes traces exist | Logging infrastructure |

---

## Recommended Architecture

### Separation of Concerns

**Key recommendation:** We should own the workflow engine completely. WorkFront (and other tools) would be **notification delegates only**.

*Note: This is a recommendation to be discussed with other architects.*

```
┌─────────────────────────────────────────────────────────────────┐
│                        CONTROL SERVICE                           │
│              (Scheduling, policies, compute budgets)             │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                 BLACKBOARD + WORKFLOW ENGINE                     │
│                    (We own this completely)                      │
│                                                                  │
│  Facts & DAG:                                                   │
│  • Fact storage, dependencies, cascade                          │
│  • Memory layers (core, working, episodic, semantic, etc.)      │
│  • Authority tracking (human vs agent)                          │
│                                                                  │
│  Workflow Engine:                                               │
│  • Step definitions, state machine, transitions                 │
│  • Gates that check fact conditions                             │
│  • Triggers based on fact changes                               │
│                                                                  │
│  When human decision needed:                                    │
│    → workflow_state = "blocked_on_human"                        │
│    → emit event to notification delegate                        │
│                                                                  │
│  When decision received:                                        │
│    → update workflow state                                      │
│    → store decision as fact (authority=human)                   │
│    → trigger downstream cascades                                │
└─────────────────────────────────────────────────────────────────┘
                    │                         ▲
                    │ "surface to human"      │ callback
                    ▼                         │
┌─────────────────────────────────────────────────────────────────┐
│                   NOTIFICATION DELEGATES                         │
│         (Interchangeable - customer's choice)                    │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  WorkFront  │  │    Slack    │  │  ASO UI     │             │
│  │             │  │             │  │  (inline)   │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                  │
│  All delegates:                                                 │
│  • Receive: task description, options, deadline                 │
│  • Return: decision (approved/rejected/edited)                  │
│  • Do NOT own workflow state or routing logic                   │
└─────────────────────────────────────────────────────────────────┘
```

**Why this architecture:**

| Principle | Rationale |
|-----------|-----------|
| **We own workflow state** | Steps depend on facts, memory layers, Control policies - only we have this context |
| **WorkFront = notification only** | 3rd-party tool, separate team/roadmap. Use it for what it's good at (surfacing to humans) |
| **Delegate interface** | Allows customer choice: WorkFront, Slack, email, custom UI. No lock-in. |
| **Decision = fact** | Human decisions stored as facts with `authority=human`, enabling cascade and audit trail |

### If RL/Training is Needed Later

Use deployment separation, not architectural mixing:

```
┌─────────────────────────────────────────────────────────────────┐
│  PRODUCTION                                                      │
│  • Blackboard (Postgres, production data)                       │
│  • Agents with frozen policies                                  │
│  • Logs actions and outcomes                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ logs, traces (observability)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  ANALYTICS                                                       │
│  • What facts accessed                                          │
│  • What decisions made                                          │
│  • Outcomes (success/failure)                                   │
│  • Human feedback                                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ training data export
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TRAINING (Separate deployment, ephemeral)                       │
│  • SimulatedMemory (in-memory, isolated)                        │
│  • Scenario replay                                              │
│  • Policy training                                              │
│  • Output: policy artifacts                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ new policies (code review, testing)
                              ▼
                         PRODUCTION (updated)
```

**Key principle:** Training never writes to production. Cross-pollination is explicit and reviewed.

---

## Terminology Updates Needed

The MIRIX docs use stale terminology:

| Document Says | Should Say | Why |
|---------------|------------|-----|
| "audit runs" | "fact refresh cycles" | Audits migrated to blackboard |
| "audit_history" | "episodic events" | General term, not audit-specific |
| "audit.*.result" | "refresh.*.outcome" | Consistent with new model |

---

## Implementation Priority

Given current priorities (alpha goals, stabilization):

### Phase 1: Metadata (Do Now) - Concrete Steps

**1. Add fields to Fact model** (`app/models/blackboard/fact.py`):

```python
class MemoryLayer(str, Enum):
    CORE = "core"           # Brand identity, tenant prefs - always in context
    WORKING = "working"     # Current task facts - task-dependent
    EPISODIC = "episodic"   # Historical events - selective
    SEMANTIC = "semantic"   # Domain knowledge (WCAG, SEO rules) - on-demand
    WORKFLOW = "workflow"   # Human-defined processes - step-dependent
    PROCEDURAL = "procedural"  # Agent-learned patterns - suggestive
    RESOURCE = "resource"   # References (URLs, docs) - pointers only

class FactAuthority(str, Enum):
    HUMAN = "human"    # Explicitly stated by human - AUTHORITATIVE
    AGENT = "agent"    # Derived by agent - SUGGESTIVE
    SYSTEM = "system"  # System config - REFERENCE

class Fact(Base):
    # ... existing fields ...
    memory_layer: MemoryLayer = MemoryLayer.WORKING
    authority: FactAuthority = FactAuthority.AGENT
```

**2. Classify existing fact types** (config or code):

```python
# Initial mapping - refine based on actual usage
FACT_KEY_TO_LAYER = {
    "brand.*": MemoryLayer.CORE,
    "tenant.*": MemoryLayer.CORE,
    "guidance.*": MemoryLayer.CORE,

    "page.*": MemoryLayer.WORKING,
    "seo.*": MemoryLayer.WORKING,
    "a11y.*": MemoryLayer.WORKING,

    "wcag.*": MemoryLayer.SEMANTIC,
    "schema.org.*": MemoryLayer.SEMANTIC,

    "workflow.*": MemoryLayer.WORKFLOW,
    "pattern.*": MemoryLayer.PROCEDURAL,
}
```

**3. Build MetaMemoryManager** (`app/services/blackboard/meta_memory_manager.py`):

```python
class MetaMemoryManager:
    """Builds agent context with token budgets per memory layer."""

    TOKEN_BUDGETS = {
        MemoryLayer.CORE: 2000,      # Always included
        MemoryLayer.WORKING: 3500,   # Main task context
        MemoryLayer.SEMANTIC: 1500,  # Domain knowledge
        MemoryLayer.EPISODIC: 1000,  # Historical hints
        MemoryLayer.WORKFLOW: 1000,  # Process context
        MemoryLayer.PROCEDURAL: 500, # Learned patterns
    }

    async def build_context(
        self,
        agent_type: str,
        task: Task,
        scope: FactScope,
    ) -> AgentContext:
        """
        Build context for an agent, respecting:
        - Token budgets per layer
        - Authority hierarchy (human > agent > system)
        - Task relevance
        """
        context = AgentContext()

        # 1. Always include CORE (brand, tenant, guidance)
        core_facts = await self.blackboard.get_facts(
            scope=scope,
            memory_layer=MemoryLayer.CORE,
        )
        context.add(core_facts, budget=self.TOKEN_BUDGETS[MemoryLayer.CORE])

        # 2. Include WORKING facts relevant to task
        working_facts = await self.blackboard.get_facts(
            scope=scope,
            memory_layer=MemoryLayer.WORKING,
            key_patterns=self._patterns_for_task(task),
        )
        context.add(working_facts, budget=self.TOKEN_BUDGETS[MemoryLayer.WORKING])

        # 3. Authority: human facts override agent facts
        context.apply_authority_priority()

        return context
```

**4. Example: How this affects agent behavior**

Before (current): Agent gets ALL facts for scope, may hit token limits, no prioritization.

After:
```
SEOOptimizer agent runs for page:/products/widget

MetaMemoryManager builds context:
├── CORE (2000 tokens max)
│   └── brand.voice: "Professional but friendly"
│   └── tenant.seo_preferences: {...}
├── WORKING (3500 tokens max)
│   └── page.content: "..." (truncated to fit)
│   └── page.seo_analysis: {...}
│   └── page.priority: "high" [authority=HUMAN, overrides agent-derived]
├── SEMANTIC (1500 tokens max)
│   └── seo.title_best_practices: {...}
└── Total: ~8000 tokens, fits in context window
```

### Phase 2: Workflow Engine (Needs Architect Discussion)

1. Inventory existing approval flows (Suggestions → AutoFix, etc.)
2. Design workflow engine as part of Blackboard
3. Define notification delegate interface
4. Implement WorkFront as first delegate

### Phase 3: Observability (Foundation for Future)

1. Log fact accesses during agent execution
2. Log decisions and outcomes
3. Capture human feedback (approvals, rejections, edits)

### Phase 4: RL/Simulation (Deferred)

1. Only after stable production + observability
2. Requires concrete scenarios worth simulating
3. Requires defined reward signals
4. Can be separate deployment unit

---

## Open Questions

### For Product/Architecture

1. **Current WorkFront usage:** What's the current integration? We need to understand if migrating to delegate-only model requires changes.

2. **Approval flows inventory:** What approval flows exist today? Suggestions → AutoFix? Content → Publish? Others? (Need to model these in our workflow engine.)

3. **Customer notification preferences:** Do some customers not use WorkFront? What alternatives exist? (Validates the delegate pattern.)

4. **Delegate contract:** What information does WorkFront need to surface a task? What does it return? (Design the minimal interface.)

### For Implementation

4. **Memory layer classification:** Who decides which fact type goes in which layer? Hard-coded mapping or configurable?

5. **Authority override:** When a human assertion is superseded or explicitly invalidated, does agent-derived automatically take over, or require confirmation?

6. **Cross-pollination governance:** If training produces new policies, what's the review/deploy process?

---

## Conclusion

The MIRIX research provides valuable direction for how agentic memory could evolve. However:

1. **Memory layers and authority** are practical additions we can implement now
2. **Workflow engine** should be owned by us (not WorkFront) - needs design discussion with architects
3. **RL/Simulation** is research-grade and should be deferred until we have stable production, observability, and clear training data

The ivory tower inspiration is welcome and needed. Now we need to get practical and pragmatic given timelines.

---

## Related Documents

### Architecture
- [mirix-layered-memory-analysis.md](mirix-layered-memory-analysis.md) - Original MIRIX analysis (research/inspiration)
- [agent-simulation-environment.md](agent-simulation-environment.md) - Simulation proposal (deferred)
- [executive-summary.md](executive-summary.md) - Overall architecture context
- [ARCHITECTURE-TODO.md](ARCHITECTURE-TODO.md) - Open decisions and action items

### Existing Code (for Phase 1 implementation)
- `app/models/blackboard/` - Fact model lives here
- `app/services/blackboard/` - BlackboardService, add MetaMemoryManager here
- `app/agents/tools/facts_tool.py` - How agents currently access facts (needs to use MetaMemoryManager)
