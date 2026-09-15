# AI Assisted Coding for Mysticat — Video Recording Plan

A walkthrough of this repo showing how we built the blackboard architecture 100% with AI.

---

## Video Structure

13 sections. For each: what to say, what to show on screen.

Estimated runtime: ~28-32 min.

---

## 1. DOCS, LOTS OF DOCS (~3 min)

**Say:** "The single biggest investment in vibecoding isn't prompting — it's documentation. Not one big doc, but a taxonomy of doc types, each with a clear purpose."

**Show on screen:**

1. Open `docs/blackboard/CLAUDE.md` — the master index
   - Show the table: concepts / mechanisms / decisions / guides / reference / design / migrations
   - Highlight the column: *"Start here when..."*

2. Open `docs/blackboard/concepts/CLAUDE.md` — a sub-index
   - Show the 17 concept files listed with descriptions
   - Point out: "Every folder has its own CLAUDE.md — the AI reads the index, picks the right folder, reads the sub-index, finds the doc. Two hops, not twenty grep attempts."

3. Quick tour of doc types (open one example of each):

| Type | File to open | What to show |
|------|-------------|--------------|
| **ADR** | `docs/blackboard/decisions/architectural-tradeoffs.md` | Tradeoff analysis: scalability, latency, COGS |
| **Spec** | `docs/blackboard/design/design-control-service.md` | Service design with architecture diagram |
| **Impl plan** | `docs/blackboard/guides/implementation-plan.md` | Phase 0-7 with checkboxes (✅/☐) |
| **Integration** | `docs/blackboard/mechanisms/drs-integration.md` | External system contract (DRS API) |
| **Vertical** | `docs/blackboard/migrations/oppies/alttext/strategy.md` | Single feature across systems (fact flow diagram) |
| **Ops helper** | `docs/blackboard/load-testing/LOAD_TESTING.md` | Perf testing with scaling guidelines |
| **Concepts** | `docs/blackboard/concepts/fact.md` | Definition of fact types (o_/d_/a_) |
| **Mental models** | `docs/blackboard/concepts/mental-models.md` | 6 analogies for the same architecture |

**Key point:** "Each doc type answers a different question. Specs say what to build. ADRs say why we chose this. Guides say how to do it. The AI navigates by intent, not by search."

---

## 2. SPEC-DRIVEN DEVELOPMENT (~2 min)

**Say:** "We practice Spec-Driven Development. Markdown specs are the source of truth. Code serves specs, not the other way around."

**Show on screen:**

1. Open `docs/blackboard/guides/collaboration-guide.md` — scroll to the SDD definition:
   ```
   Traditional:     Code → Documentation (docs rot)
   Spec-Driven:     Specification → AI-assisted Code → Specification validates Code
   ```

2. Show the loop:
   ```
   DRAFT (markdown) → REVIEW (PR + AI) → DECIDE (update TODO) → IMPLEMENT (AI from spec)
   ```

3. Open `docs/blackboard/ARCHITECTURE-TODO.md` — show decision status tracking:
   ```
   OPEN → LEANING → DECIDED → BLOCKED
   ```
   Scroll to a DECIDED entry — show how it links to source docs.

4. Show an example of the flow in action:
   - Open `docs/blackboard/migrations/oppies/alttext/` — show the 4-file structure:
     - `CLAUDE.md` — status + overview
     - `analysis.md` — what exists today
     - `strategy.md` — what to build (the SPEC)
     - `implementation.md` — progress checklist
   - "The strategy was written BEFORE any code. The spec is the implementation plan."

**Key point:** "The spec is the product. The code is a side effect."

---

## 3. THE FLYWHEEL (~2 min)

**Say:** "Docs compound. Every conversation produces artifacts that make the next conversation cheaper."

**Show on screen:**

1. Draw the flywheel (or show a diagram):
   ```
   prompt → docs
   prompt + docs → more docs
   prompt + docs → code
   code + tests → bugs → memory → better docs
   ```

2. Open `docs/blackboard/migrations/STATUS.md` — show the progression:
   - 4 complete, 2 strategy only, ~28 not started
   - Each completed migration PRODUCED docs that make the next one faster
   - Point at the "By Producer Type" table — patterns emerged from doing the first few

3. Show `.claude/skills/opportunity-creator/SKILL.md`:
   - "After migrating 4 opportunities, we captured the pattern as a SKILL"
   - Show Phase 0-7 workflow
   - Show the CRITICAL auto-discovery rules table
   - "Now creating a new opportunity is: `/opportunity-creator` — and the agent follows the pattern"

4. Show the 6 skills:
   ```
   .claude/skills/
   ├── opportunity-creator/    # Create new pipelines
   ├── opportunity-migrator/   # Migrate legacy crews
   ├── evaluate-agent-offline/ # Run evals
   ├── auto-improve-agent/     # Fix eval failures
   ├── optimize-agent/         # Optimize prompts
   └── skill-creator/          # Create new skills (meta!)
   ```

**Key point:** "Early on, 80% docs, 20% code. Later it flips. The docs become the codebase's immune system."

---

## 4. VIBE-PROOFING A REPO (~2 min)

**Say:** "The litmus test: if a fresh Claude session starts with zero memory, can it orient itself? Can it implement a feature from just the repo contents?"

**Show on screen:**

1. Show the CLAUDE.md loading order:
   - Root `CLAUDE.md` (project rules, how to run, how to test)
   - `docs/blackboard/CLAUDE.md` (architecture index)
   - Folder-level `CLAUDE.md` files (sub-indexes)

2. Count the CLAUDE.md files in the repo:
   ```
   CLAUDE.md                                          # root
   docs/blackboard/CLAUDE.md                          # architecture
   docs/blackboard/concepts/CLAUDE.md                 # concepts index
   docs/blackboard/mechanisms/CLAUDE.md               # mechanisms index
   docs/blackboard/decisions/CLAUDE.md                # decisions index
   docs/blackboard/guides/CLAUDE.md                   # guides index
   docs/blackboard/reference/CLAUDE.md                # reference index
   docs/blackboard/design/CLAUDE.md                   # design index
   docs/blackboard/migrations/CLAUDE.md               # migrations index
   docs/blackboard/migrations/oppies/alttext/CLAUDE.md
   docs/blackboard/migrations/oppies/broken-backlinks/CLAUDE.md
   app/agents/facts/CLAUDE.md                         # producer index
   app/public/blackboard-visualization/CLAUDE.md      # UI index
   ```
   "13+ CLAUDE.md files. That's the routing table for the entire codebase."

3. Show the contrast:
   ```
   ❌  "please implement JIRA-XXXX, we use AWS, tests are in app/tests,
       don't break the cascade flow, use @consumes/@produces decorators,
       the deploy repo is at ../mystique-deploy..."

   ✅  "please implement JIRA-XXXX"
   ```
   "If you need the first form, your repo isn't vibe-proofed."

**Key point:** "The prompt should be the delta, not the baseline. Most of the prompting is already in the repo."

---

## 5. SELF-DOCUMENTING CODE + STRONG TYPING (~3 min)

**Say:** "The code itself minimizes the need for external docs. When every function, every model, every fact has a typed contract, the AI doesn't need to guess — it reads the type and knows."

**Show on screen:**

1. Open a real producer and its fact definition:
   ```python
   PAGE_CLASSIFICATION = Fact(
       key="d_page_classification",
       scope="page",
       max_staleness_hours=168,
       schema=PageClassification,
   )

   @consumes(HTML_CONTENT)
   @produces(PAGE_CLASSIFICATION, schema=PageClassification)
   class PageClassificationProducer(FactProducer):
       fact = PAGE_CLASSIFICATION
   ```
   "Without reading any docs, the AI knows: input is HTML, output is page classification, schema is enforced, and the fact becomes eligible for recomputation when touched after 7 days."

2. Show the naming convention:
   ```
   o_  = Observation (raw external data)
   d_  = Derived (computed from other facts)
   a_  = Assertion (final recommendations)
   ```
   "The prefix IS the metadata. The agent can reason about data flow from names alone."

3. Open `app/agents/facts/producers/base.py` — the generic base class:
   ```python
   class TypedFactProducer(FactProducer, Generic[OutputT]):
       @abstractmethod
       async def compute_typed(self, scope: FactScope, context: dict[str, Any]) -> OutputT | None:
           pass
   ```
   "`TypedFactProducer[MarkdownOutput]` — you know the return schema before reading any implementation."

4. Open a schema file — `app/opportunities/alt_text/schemas.py`:
   ```python
   class ImageWithoutAlt(BaseModel):
       image_url: str = Field(..., description="Absolute URL of the image")
       xpath: str = Field(..., description="XPath to the img element in the DOM")
       images_count: int = Field(0, ge=0, description="Number of images without alt text")
   ```
   "Every field has a type, a default, a description, and constraints like `ge=0`. This IS the contract."

5. Open a fact definition — `app/agents/facts/cwv_observation_facts.py`:
   ```python
   O_CWV_METRICS = Observation(
       key="o_cwv_metrics",
       scope="page",
       max_staleness_hours=24,
       source=PSI,
       schema=CWVMetricsOutput,
       default_change_detection=ChangeDetection(
           algorithm=ChangeAlgorithm.JSON_SEMANTIC,
           threshold=0.90,
       ),
   )
   ```
   "Key, scope, max staleness, schema, change detection — all typed. Enums, not strings. No magic values."

   "`Fact.max_staleness_hours` is a lazy threshold: positive `N` becomes eligible only when touched after `N` hours, `0` is always eligible, and `None` is force-or-signal-only. It does not delete facts or trigger autonomous refresh. `ttl_hours` is only a deprecated compatibility alias."

6. Show the live DAG at `http://localhost:8080/bb/live-code.html`:
   "The DAG is auto-generated from the decorators. This is how we verify code matches spec — the visualization IS the validation."

**The stack — from bottom to top:**
```
Enums           → valid values (no magic strings)
Pydantic models → field types, defaults, constraints, descriptions
Generics        → TypedFactProducer[T] enforces return type
Fact defs       → scope, max staleness, schema, change detection — all typed
Decorators      → @consumes/@produces on top of it all
```

**Key point:** "Strong typing turns code into a queryable knowledge base. The agent doesn't ask 'what does this return?' — it reads the type. Types are docs that can't go stale."

---

## 6. WHERE CONTEXT LIVES (~2 min)

**Say:** "Not all context sources are equal for AI agents. Here's how we think about it."

**Show on screen:**

Show a tiered diagram:

```
AVOID (low discoverability for agents)
├── Wikis / Confluence — agent won't know to look there
├── Slack — ephemeral, fragile browser access
├── Meetings / verbal — doesn't exist for agents
└── Personal notes — not in repo = not in context

TOLERATE (accessible, can drift)
├── Jira — via MCP + links from repo docs
└── ArgoCD / k8s dashboards — via CLI

PREFER (always in context, zero friction)
├── Repo markdown (.md files)
├── CLAUDE.md files (auto-loaded)
├── .claude/skills/ (reusable workflows)
├── .claude/memory/ (persistent bug fixes)
├── Code conventions (decorators, naming)
└── Test files (document behavior)
```

**Show concrete examples:**

1. Open `.mcp.json` — show Jira MCP configured
2. Open root `CLAUDE.md` — show Jira field quirks documented:
   ```
   Epic Link field is customfield_11800 (not customfield_10008)
   ```
   "We could rely on the agent discovering this every time, or we can document it once."
3. Show the ArgoCD section in `CLAUDE.md` — exact cluster names, contexts, namespaces documented
   "The agent can `kubectl` into the right pod without asking."

**Key point:** "If you find yourself saying the same thing to the agent across sessions, it belongs in the repo, not in your prompt."

---

## 7. NEARBY REPOS (~1 min)

**Say:** "Real work rarely lives in one repo. The agent needs cross-repo context."

**Show on screen:**

1. Open `.claude/settings.json`:
   ```json
   "additionalDirectories": [
       "../llmo-data-retrieval-service",
       "../spacecat",
       "../mystique-deploy"
   ]
   ```

2. Explain each:
   - `mystique-deploy` — Helm charts, ArgoCD config, ephemeral environments
   - `llmo-data-retrieval-service` — DRS API, scraping service
   - `spacecat` — legacy system being migrated

3. Show root `CLAUDE.md` — the "Paired PR workflow":
   ```
   Adding/changing a column:
   1. Write dbmate migration in ../mysticat-data-service/
   2. Update SQLAlchemy model in app/db/blackboard_models.py
   3. Test application code
   4. Commit both repos (paired PRs)
   ```
   "A schema change touches both repos. The agent sees both."

**Key point:** "The agent understands inter-repo dependencies because it can see all of them."

---

## 8. AI ACCESS — REMOVE THE HUMAN FROM THE LOOP (~2 min)

**Say:** "Spend time making sure the agent has access. A human in the loop means you're on-call for your agent. The agent works for you, not the other way around."

**Show on screen:**

Show the priority stack:

```
1. CLI       git, gh, kubectl, argocd, aws, vault    Scriptable, fast, composable
2. MCP       Jira, Confluence                        Structured API, discoverable
3. Browser   Chrome MCP                              Last resort — UIs without APIs
4. Human     Ask the user                            The fallback, not the default
```

**Show concrete examples:**

1. Terminal: `gh pr create ...` — agent creates PRs
2. Terminal: `argocd app list --grpc-web | grep mystique` — agent checks deploys
3. Terminal: `kubectl logs <pod>` — agent reads production logs
4. Show `.mcp.json` — Jira MCP lets the agent create tickets, read epics

**Show the CLAUDE.md ArgoCD setup section:**
- Exact `brew install` commands
- Exact kubectl/kubelogin versions
- Login command
- "The agent can set up its own environment."

**Key point:** "Watch where the agent asks you for help, then eliminate that bottleneck. Over time, the list of things only you can do shrinks to near-zero."

---

## 9. AUTONOMOUS OPERATION — TESTING, TROUBLESHOOTING, MEMORY (~4 min)

**Say:** "The agent has to be able to test, debug, and learn — all by itself. If it can't iterate without you, you're the bottleneck."

**Show on screen — Part A: Testing**

1. Open root `CLAUDE.md` — scroll to "Running Tests":
   ```bash
   # FAST: Run specific test file (use this during development)
   uv run pytest app/tests/services/drs/

   # FULL: Run all tests (~1 hour - only for PR prep)
   uv run pytest app/tests/
   ```
   "FAST vs FULL — the agent knows when to use each."

2. Show the "Dear Future Claude" note:
   ```
   > Dear Future Claude: On 2026-01-27, we wasted an entire day fixing
   > CI test failures because we kept pushing to CI and waiting ~1 hour
   > per cycle instead of running tests locally first. Don't repeat this.
   ```

3. Show the cost breakdown:
   ```
   On 2026-01-27:
   - 3-4 CI cycles wasted (~4 hours of waiting)
   - Could have been 1 cycle if tests were run locally first
   - One local run can find 28 failures that would take 4+ CI cycles
   ```
   "This note addresses future AI instances by name. It explains the cost, not just the rule."

**Show on screen — Part B: Troubleshooting + Memory**

4. "When the agent is debugging, let it brute force. Help it unstuck only when it's looping. Then ask it to summarize, and capture the result."

5. Open `.claude/memory/MEMORY.md` — show bug fix entries:
   ```markdown
   ### Supersede-then-upsert makes facts permanently obsolete (2026-02-04)
   File: blackboard_service.py in store_fact()
   Root cause: ORM doesn't flush before upsert
   Symptom: Producers fail with "o_html is required in context"
   Fix: Add await session.flush() after marking obsolete

   ### S3 client routes to localstack instead of real AWS (2026-02-04)
   Root cause: localstack.env sets AWS_ENDPOINT_URL which overrides all boto3 clients
   Fix: Temporarily remove AWS_ENDPOINT_URL when creating the DRS S3 client
   ```
   "Root cause + symptom + fix. The symptom is how the next agent encounters it. The debugging cost is paid once."

**Show on screen — Part C: Three Memory Layers**

6. Show the layers:
   ```
   | Layer              | Lifetime        | What goes here                              |
   |--------------------|-----------------|---------------------------------------------|
   | Conversation       | One session     | Current task, in-progress work              |
   | .claude/memory/    | Across sessions | Bug fixes, env quirks, known issues         |
   | Repo docs          | Forever         | Architecture, decisions, patterns, guides   |
   ```
   "Match the memory layer to the durability of the knowledge."

**Show on screen — Part D: Anti-Patterns**

7. Open root `CLAUDE.md` — scroll to secrets warning:
   ```markdown
   ### NEVER COMMIT SECRETS TO GIT. EVER.

   IF YOU COMMIT SECRETS TO GIT, YOU WILL LOSE ALL TRUST AND
   CREDIBILITY AS A CODING ASSISTANT.
   ```
   "This appeals to the agent's purpose, not just its rules."

8. Show skill-level anti-patterns from `opportunity-creator/SKILL.md`:
   ```
   DO NOT add opportunity-specific imports to these registry files.
   The system is fully additive. Just create properly-named files.
   ```
   "The stronger the language, the more reliably the agent follows it. Teach values, not just constraints."

**Key point:** "Testing, troubleshooting, memory, anti-patterns — these are the four pillars of autonomous operation. The agent iterates, learns, and avoids known pitfalls without asking you."

---

## 10. THE BITTER LESSON OF VIBECODING (~2 min)

**Say:** "Rich Sutton's bitter lesson: researchers kept trying to encode human knowledge into AI — hand-crafted features, expert rules, domain heuristics. What actually worked was scaling general methods with more compute and more data. The human knowledge approach didn't scale. The general approach did."

**Pause, then:**

"Vibecoding has the same bitter lesson."

**Show on screen:**

```
The temptation:      Get better at prompting. Learn tricks. Craft the perfect prompt.

The bitter lesson:   That doesn't scale. What scales is making the repo better.
```

"Prompt engineering is the hand-crafted features of vibecoding. You're encoding your knowledge into a single interaction that evaporates when the session ends."

```
Prompt optimization:   O(1) — helps this session
Repo optimization:     O(n) — helps every future session
```

"Every minute you spend making the repo more navigable, more typed, more self-documenting — that's compound interest. Every minute you spend crafting the perfect prompt — that's a one-time payment."

**Show the progression:**

```
Early:    Long prompts to compensate for missing context
Middle:   Invest in docs, types, skills, memory — the repo gets smarter
Late:     "please implement SITES-40592" — 5 words, the repo does the rest
```

**Say:** "You can't out-prompt a bad repo. And you don't need to prompt a good one."

**Final slide:**

```
The repo is the product. The code is a side effect.
```

---

## 11. THE PAYOFF — LIVE DEMO (~5-8 min)

**Say:** "Everything I showed you — the docs, the types, the skills, the memory, the access — it all converges here. Watch what happens when I give a fresh Claude session a single Jira ticket."

**Setup before recording:**
- Start a **fresh Claude session** (no prior conversation)
- Have the server running (`source localstack.env && cd app && uv run uvicorn asgi:app --port 8080`)
- Have `http://localhost:8080/bb/live-code.html` open in browser
- Optionally have `app/agents/facts/cwv_observation_facts.py` open in editor to show existing infra

**The ticket: [SITES-40592](https://jira.corp.adobe.com/browse/SITES-40592)**

*CWV Detection — identify CWV issues as Mysticat goals*

Why this ticket is perfect:
- Observation facts already exist (`o_cwv_metrics`, `o_lhs_scores`) — shows flywheel
- Schemas already typed (`cwv_models.py`) — shows strong typing payoff
- Deterministic logic (threshold checks, no LLM) — demo won't hang on API calls
- Clear acceptance criteria in the Jira description
- Result is visible in the DAG immediately

**Step 1: Show the Jira ticket** (30 seconds)

Open [SITES-40592](https://jira.corp.adobe.com/browse/SITES-40592) in browser. Scroll through the description:
- Existing infrastructure: `o_cwv_metrics`, `o_lhs_scores`, 39 tests
- Thresholds: LCP > 2.5s, CLS > 0.1, INP > 200ms, TTFB > 800ms
- Design: unified detection, separate goals per failing metric
- Acceptance criteria: 6 bullet points

**Say:** "This is a real ticket from our backlog. The description references facts that already exist in the codebase. Let's see what happens."

**Step 2: Type the prompt** (5 seconds)

In the fresh Claude session, type:

```
please implement SITES-40592
```

That's it. Nothing else.

**Step 3: Narrate what the agent does** (3-5 minutes, sped up in post)

As the agent works, narrate each step:

| Agent action | What it demonstrates |
|-------------|---------------------|
| Reads the Jira via MCP | **AI access** — Jira MCP configured in `.mcp.json` |
| Reads `CLAUDE.md` (auto-loaded) | **Vibe-proofed repo** — routing table, test protocol |
| Finds `cwv_observation_facts.py` | **Strong typing** — reads existing fact definitions, schemas |
| Reads migration guides / producer examples | **Docs** — follows the breadcrumbs |
| Creates schema (`schemas.py`) | **Pydantic contracts** — typed output with Field descriptions |
| Creates fact definitions | **Naming conventions** — `d_cwv_detection` with `d_` prefix |
| Creates producer with `@consumes/@produces` | **Self-documenting code** — decorators declare the contract |
| Runs `uv run pytest` | **Autonomous testing** — knows FAST vs FULL from CLAUDE.md |
| (Optionally) checks DAG endpoint | **Validation** — new fact appears in live DAG |

**Say during each step:**
- "It's reading the Jira — that's the MCP server we configured."
- "Now it found the existing CWV facts — these are the typed definitions we showed earlier."
- "It's creating a producer. Notice the `@consumes` and `@produces` — it learned that pattern from the codebase, not from my prompt."
- "It's running tests. It knows to run only the relevant tests first — that's the 'Dear Future Claude' protocol."

**Step 4: Show the result** (1 minute)

1. Open the created files in the editor — show the `@consumes/@produces` decorators
2. Refresh `http://localhost:8080/bb/live-code.html` — the new `d_cwv_detection` node appears in the DAG, connected to `o_cwv_metrics` and `o_lhs_scores`
3. Show test output — green

**Say:** "I typed 5 words. The agent read the Jira, found the existing infrastructure, followed the patterns in the codebase, created typed schemas, built the producer, ran tests. Everything it needed was already in the repo."

**Step 5: The closing line**

```
The prompt was 5 words.
The repo did the rest.
```

**Contingency plan:** If the agent makes a mistake or the demo goes sideways:
- "This is vibecoding in real life — sometimes the agent gets stuck. Watch how I help it unstuck and then ask it to summarize what it learned. That summary goes into memory for next time." (This actually demonstrates section 9 — autonomous operation.)

---

## Quick-Reference: Files to Have Open

Pre-open these tabs before recording:

| # | File | Section |
|---|------|---------|
| 1 | `CLAUDE.md` (root) | Secrets warning, test protocol, ArgoCD setup |
| 2 | `docs/blackboard/CLAUDE.md` | Master index with architecture diagram |
| 3 | `docs/blackboard/concepts/CLAUDE.md` | Sub-index example (17 files) |
| 4 | `docs/blackboard/decisions/architectural-tradeoffs.md` | ADR example |
| 5 | `docs/blackboard/guides/implementation-plan.md` | Phase tracking |
| 6 | `docs/blackboard/migrations/oppies/alttext/strategy.md` | Vertical doc (fact flow diagram) |
| 7 | `docs/blackboard/migrations/STATUS.md` | Migration progress |
| 8 | `docs/blackboard/guides/collaboration-guide.md` | SDD definition |
| 9 | `docs/blackboard/ARCHITECTURE-TODO.md` | Decision tracking |
| 10 | `docs/blackboard/concepts/mental-models.md` | 6 analogies |
| 11 | `.claude/skills/opportunity-creator/SKILL.md` | Skill example |
| 12 | `.claude/settings.json` | Nearby repos |
| 13 | `.mcp.json` | MCP servers |
| 14 | `.claude/memory/MEMORY.md` | Persistent memory (private — decide if showing) |
| 15 | `app/agents/facts/producers/page_classification.py` | @consumes/@produces |
| 16 | `app/agents/facts/producers/base.py` | TypedFactProducer[T] generic base |
| 17 | `app/opportunities/alt_text/schemas.py` | Pydantic schema with Field descriptions |
| 18 | `app/agents/facts/cwv_observation_facts.py` | Typed fact definitions + live demo context |

---

## Recording Tips

- **Pace:** Sections 1-10 at ~2.5 min avg = ~23 min. Section 11 (live demo) = ~5-8 min. Total ~28-32 min.
- **Show, don't tell:** Every section has a real file to open. Don't just describe — scroll through it.
- **Live demo is the climax:** Build toward section 11. Sections 1-10 explain the "why" — section 11 proves it works. Consider recording the live demo separately and editing it in (speed up the agent working, keep key moments at normal speed).
- **If the demo fails:** That's fine — it demonstrates autonomous operation (section 9). Help the agent unstuck, ask it to summarize, show the memory capture. Real vibecoding isn't perfect, it's iterative.
- **The closing shot:** Refresh the DAG visualization after the producer is created. The new node appearing in the graph is the most visual proof that the entire system works end-to-end.

---

## Time Budget

| Section | Topic | Est. |
|---------|-------|------|
| 1 | Docs taxonomy | 3 min |
| 2 | Spec-Driven Development | 2 min |
| 3 | Flywheel + skills | 2 min |
| 4 | Vibe-proofing | 2 min |
| 5 | Self-documenting code + strong typing | 3 min |
| 6 | Where context lives | 2 min |
| 7 | Nearby repos | 1 min |
| 8 | AI access | 2 min |
| 9 | Autonomous operation (test + debug + memory + anti-patterns) | 4 min |
| 10 | Bitter lesson | 2 min |
| 11 | Live demo | 5-8 min |
| | **Total** | **~28-32 min** |
