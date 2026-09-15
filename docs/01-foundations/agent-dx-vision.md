# Speculative Developer Experience: POC-ing Baby Opportunities with Claude Agent SDK

> **STATUS: NOT READY FOR IMPLEMENTATION**
>
> This is a speculative vision document exploring how Claude Agent SDK + Skills could improve the developer experience for validating opportunity hypotheses. It requires prototyping, cost analysis, and team discussion before any implementation work begins.

## What is a "Baby Opportunity"?

A **baby opportunity** is an unvalidated hypothesis - an idea for a new insight that hasn't been proven yet:

| Question | Unknown Until Validated |
|----------|------------------------|
| **Is it a good idea?** | Does this detection find real, meaningful issues? |
| **Is it useful to customers?** | Do customers care about this? Will they act on it? |
| **Is it doable?** | Can we reliably detect this with available data? |

Baby opportunities need **fast, cheap validation** before investing in production code. The goal is to **fail fast** on bad ideas and **double down** on good ones.

## The Problem: High Investment Before Validation

Today, validating even a simple opportunity hypothesis requires building production infrastructure:

```
1. Define Pydantic schema          → fact_registry.py (30 lines)
2. Create Fact instance            → fact_registry.py (10 lines)
3. Create crew directory           → mkdir, __init__.py
4. Write agents.yaml               → config/agents.yaml (20 lines)
5. Write tasks.yaml                → config/tasks.yaml (30 lines)
6. Implement crew class            → my_crew.py (80 lines)
7. Wire decorators                 → @consumes, @produces
8. Add control policies            → control-service-config.json
9. Write tests                     → test_my_crew.py (50 lines)
10. Test locally                   → Multiple commands
```

**Total: ~250 lines of code across 8+ files, 30+ minutes minimum**

**The problem:** You invest 30-80 minutes building production code before you even know if the opportunity hypothesis is valid. If it turns out to be:
- A bad idea (too many false positives)
- Not useful (customers don't care)
- Not doable (detection is unreliable)

...you've wasted significant engineering time. This discourages experimentation.

---

## The Vision: Conversational Fact POC-ing

### What If...

```
Developer: I want to detect pages where the hero image is missing alt text.

Claude: I'll create a quick skill to detect this. Let me:
1. Check what facts we already have... ✓ WEBPAGE_CONTEXT has the HTML
2. Create a minimal skill for alt-text detection
3. Run it on 5 pages from site "adobe.com" to validate

[Creates skill, runs, shows results]

Found 2/5 pages with missing hero alt text:
- /products/photoshop → <img src="hero.jpg" alt="">
- /solutions/creative → <img src="banner.png"> (no alt attribute)

Developer: That looks right! But also flag images with generic alt like "image" or "photo"

Claude: Updated the skill to catch generic alts. Running again...

Now 3/5 pages flagged:
- /products/photoshop → alt=""
- /solutions/creative → no alt
- /about → alt="photo"  ← newly caught

Developer: Perfect. Can you make this a real fact producer now?

Claude: Done. Created:
- HERO_IMAGE_ALT_STATUS fact (d_hero_image_alt_status)
- HeroImageAltProducer class
- Added to visualization DAG

Ready for production runs.
```

**Total time: 5 minutes. Zero boilerplate written by developer.**

---

## How It Would Work

### Phase 1: Skill-First Prototyping

Instead of writing code, developers describe what they want:

```python
# The developer never writes this directly.
# Claude generates it from natural language.

# .claude/skills/hero-alt-detector/SKILL.md
---
name: hero-alt-detector
description: Detects missing or poor alt text on hero/banner images.
  Use when analyzing page accessibility for primary images.
---

# Hero Image Alt Text Detector

Analyze the provided HTML to find hero/banner images and evaluate their alt text.

## Input
- `html`: Raw HTML of the page
- `page_url`: The page URL for context

## Detection Rules
1. Find images in hero sections (header, .hero, .banner, first large image)
2. Flag if: no alt attribute, empty alt, or generic alt (image, photo, banner, picture)
3. Return severity: critical (no alt), warning (generic alt), ok

## Output Format
```json
{
  "has_issues": true,
  "hero_images": [
    {
      "src": "hero.jpg",
      "alt": "",
      "issue": "empty_alt",
      "severity": "critical"
    }
  ],
  "recommendation": "Add descriptive alt text..."
}
```
```

### Phase 2: Immediate Validation

The skill runs instantly on real data:

```
┌─────────────────────────────────────────────────────────────────┐
│  Claude Agent SDK Execution                                     │
│                                                                  │
│  1. Load skill: hero-alt-detector                               │
│  2. Query blackboard: Get WEBPAGE_CONTEXT for 5 pages           │
│  3. Run skill on each page                                      │
│  4. Stream results to developer                                 │
│                                                                  │
│  Page 1: /products/photoshop                                    │
│    → Found 1 hero image, alt="" (critical)                     │
│                                                                  │
│  Page 2: /solutions/creative                                    │
│    → Found 1 hero image, no alt attr (critical)                │
│                                                                  │
│  Page 3: /about                                                 │
│    → Found 1 hero image, alt="photo" (warning)                 │
│                                                                  │
│  Page 4: /pricing                                               │
│    → Found 1 hero image, alt="Pricing plans..." (ok)           │
│                                                                  │
│  Page 5: /contact                                               │
│    → No hero image found                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Phase 3: Conversational Iteration

The developer refines via conversation:

```
Developer: The /contact page does have a hero - it's in a <section class="page-header">

Claude: Ah, I'll update the detection to also look for .page-header sections.
[Updates SKILL.md]

Re-running...

Page 5: /contact
  → Found 1 hero image in .page-header, alt="Get in touch" (ok)

Developer: Better! But "Get in touch" is not great for a background image...

Claude: Good catch. I'll add a rule: alt text that matches the page
heading/title is likely decorative and should use alt="" instead.

[Updates detection logic, re-runs, shows nuanced results]
```

### Phase 4: Graduation to Production Fact

When the skill is validated, Claude generates the full production setup:

```
Developer: This is working well. Let's make it a real fact.

Claude: Creating production fact producer...

Generated:
├── app/agents/facts/fact_registry.py (added HERO_IMAGE_ALT_STATUS)
├── app/agents/facts/producers/hero_image_alt.py (HeroImageAltProducer)
├── app/agents/facts/schemas/accessibility.py (HeroImageAltOutput)
└── app/tests/agents/facts/test_hero_image_alt.py

The skill logic is now embedded in the producer, but I'm keeping the
SKILL.md as reference documentation.

DAG updated - HERO_IMAGE_ALT_STATUS now consumes WEBPAGE_CONTEXT.
```

---

## The Developer Experience Delta

### Before (CrewAI-based)

| Step | Time | Files | Lines |
|------|------|-------|-------|
| Understand blackboard facts | 10 min | - | - |
| Design schema | 5 min | 1 | 30 |
| Create fact definition | 5 min | 1 | 15 |
| Write crew class | 15 min | 4 | 100+ |
| Write YAML configs | 10 min | 2 | 50 |
| Add control policies | 5 min | 1 | 20 |
| Write tests | 10 min | 1 | 50 |
| Debug & iterate | 20 min | - | - |
| **Total** | **80 min** | **10 files** | **265+ lines** |

### After (Agent SDK + Skills)

| Step | Time | Files | Lines |
|------|------|-------|-------|
| Describe what you want | 1 min | 0 | 0 |
| Claude generates skill | 1 min | 1 | 30 |
| Validate on real data | 2 min | 0 | 0 |
| Iterate via conversation | 5 min | 0 | 0 |
| Graduate to production | 1 min | auto | auto |
| **Total** | **10 min** | **1 (+auto)** | **30 (+auto)** |

**8x faster. Zero boilerplate written by developer.**

---

## Technical Architecture

### The "Baby Fact Lab" Service

```
┌─────────────────────────────────────────────────────────────────┐
│                       BABY FACT LAB                              │
│                    (Development Environment)                      │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  CLAUDE CONVERSATION                       │   │
│  │                                                            │   │
│  │  Developer ←→ Claude Code with Blackboard Skills           │   │
│  │                                                            │   │
│  └───────────────────────────┬──────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    SKILL SANDBOX                           │   │
│  │                                                            │   │
│  │  - Ephemeral skill storage (.claude/skills/sandbox/)       │   │
│  │  - Claude Agent SDK runtime                                │   │
│  │  - Read-only access to Blackboard facts                   │   │
│  │  - Safe execution (no writes until graduation)            │   │
│  │                                                            │   │
│  └───────────────────────────┬──────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    SAMPLE DATA PICKER                      │   │
│  │                                                            │   │
│  │  - Pull N pages matching criteria from Blackboard          │   │
│  │  - Stratified sampling (different page types, sites)       │   │
│  │  - Cached fact values for fast iteration                  │   │
│  │                                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    GRADUATION ENGINE                       │   │
│  │                                                            │   │
│  │  - Convert validated skill → Python producer class         │   │
│  │  - Generate Pydantic schemas from output examples          │   │
│  │  - Wire @consumes/@produces decorators                     │   │
│  │  - Generate tests from validation runs                     │   │
│  │  - Update DAG visualization                                │   │
│  │                                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Components

#### 1. Blackboard Skills for Claude Code

Custom skills that give Claude deep knowledge of Mystique:

```markdown
# .claude/skills/mystique-blackboard/SKILL.md
---
name: mystique-blackboard
description: Create and manage blackboard facts for Mystique. Use when
  asked to create new insights, opportunities, or fact producers.
---

# Mystique Blackboard Skill

You are helping develop facts for the Mystique blackboard architecture.

## Available Facts (Query from /api/blackboard/facts/metadata)
[Dynamic list of all registered facts with their schemas and scopes]

## Creating New Facts

### Step 1: Discovery
Query existing facts to see what's already available:
- WEBPAGE_CONTEXT - Page HTML, text, links
- PAGE_CLASSIFICATION - Page type, industry, intent
- VISUAL_ANALYSIS_DESKTOP - Above-fold visual analysis
[... etc]

### Step 2: Skill Prototyping
Create a SKILL.md in .claude/skills/sandbox/ with:
- Clear input/output specification
- Detection/analysis logic
- JSON output format

### Step 3: Validation
Run the skill on sample pages to validate accuracy.

### Step 4: Graduation
Generate production code:
- fact_registry.py entry
- Producer class
- Pydantic schema
- Test file
```

#### 2. Sample Data Picker

Pull representative data for validation:

```python
class SampleDataPicker:
    """Picks representative sample data from blackboard for skill testing."""

    async def pick_pages(
        self,
        count: int = 5,
        site_filter: str | None = None,
        page_type_filter: str | None = None,
        require_facts: list[str] | None = None,
        stratify_by: str | None = None,  # "site", "page_type", "industry"
    ) -> list[SamplePage]:
        """
        Returns sample pages with their associated facts for testing.

        Example:
            pages = await picker.pick_pages(
                count=10,
                page_type_filter="homepage",
                require_facts=["WEBPAGE_CONTEXT", "PAGE_CLASSIFICATION"],
                stratify_by="industry"
            )
        """
        ...
```

#### 3. Graduation Engine

Converts validated skills to production code:

```python
class GraduationEngine:
    """Converts validated skills to production fact producers."""

    async def graduate_skill(
        self,
        skill_name: str,
        fact_key: str,
        scope: FactScope,
        max_staleness_hours: int | None,
        validation_results: list[ValidationResult],
    ) -> GraduationResult:
        """
        Generates production code from a validated skill.

        Returns:
            GraduationResult with paths to:
            - fact_registry.py changes
            - New producer class
            - Generated schema
            - Generated tests (from validation examples)
        """
        ...
```

---

## Example Session: Missing Sitemap Detection

```
Developer: I want to find sites that don't have a sitemap.xml

Claude: Good one. Let me check what we have...

Available facts:
- SITE_STRUCTURE (site scope) - has robots.txt, sitemap info
- WEBPAGE_CONTEXT (page scope) - individual pages

SITE_STRUCTURE already has sitemap info! Let me query a few sites...

Checking 5 sites:
- adobe.com: ✓ sitemap.xml found (1,234 URLs)
- example-client.com: ✗ no sitemap found
- another-client.com: ✓ sitemap.xml found (456 URLs)
- test-site.com: ✗ no sitemap found (but has sitemap in robots.txt!)
- demo-shop.com: ✓ sitemap.xml found (89 URLs)

Interesting - 2 sites missing, and one claims to have a sitemap in
robots.txt but it 404s.

Developer: Ooh, that broken sitemap case is important. Can you detect that?

Claude: Yes! I'll create a skill that:
1. Checks if robots.txt mentions sitemap
2. Verifies the sitemap URL actually works
3. Flags: missing, broken_reference, empty, or ok

[Creates skill, runs]

Updated results:
- adobe.com: ok (1,234 URLs)
- example-client.com: missing (no reference anywhere)
- another-client.com: ok (456 URLs)
- test-site.com: broken_reference (robots.txt points to 404)
- demo-shop.com: ok (89 URLs)

Developer: Perfect. The broken_reference case should be higher severity.

Claude: Agreed. Updating severity levels...
- missing: medium (many sites legitimately don't have sitemaps)
- broken_reference: high (they intended to have one but it's broken)
- empty: medium (sitemap exists but has no URLs)

Developer: Make it a fact!

Claude: Done.
Created: SITEMAP_STATUS (s_sitemap_status) at site scope
Producer: SitemapStatusProducer
Consumes: SITE_STRUCTURE
Fact.max_staleness_hours: 168 (eligible when touched after 7 days)

It's in the DAG now. Run `uv run python -m scripts.validate_sitemap --limit 100`
to validate on more sites.
```

---

## Implications for Opportunity Development

### The "Baby Opportunity" Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│   HYPOTHESIS                                                     │
│     │                                                            │
│     │ "I think X is a problem customers have"                   │
│     ▼                                                            │
│   SKILL PROTOTYPE (5 min)                          ┌──────────┐ │
│     │                                              │          │ │
│     │ SKILL.md in sandbox                          │  KILLED  │ │
│     │ Test on 5-10 real pages                      │          │ │
│     │                                              │ Bad idea │ │
│     │──── Too many false positives? ──────────────►│ Not      │ │
│     │──── Can't reliably detect? ─────────────────►│ doable   │ │
│     ▼                                              └──────────┘ │
│   VALIDATED PROTOTYPE (10 min)                                  │
│     │                                                            │
│     │ Works on 50+ pages                                        │
│     │ Precision/recall acceptable                               │
│     │                                                            │
│     │──── Show to customer / PM ────────┐                       │
│     │                                    ▼                       │
│     │                              ┌──────────┐                 │
│     │                              │  PARKED  │                 │
│     │◄── Customers care! ──────────│          │                 │
│     │                              │ Not now  │                 │
│     ▼                              └──────────┘                 │
│   GRADUATED FACT (auto-generated)                               │
│     │                                                            │
│     │ Production code, tests, in DAG                            │
│     ▼                                                            │
│   PRODUCTION OPPORTUNITY                                         │
│     │                                                            │
│     │ Wire to UI, add guidance crew, docs                       │
│     ▼                                                            │
│   SHIPPED                                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Validation Gates

| Gate | Question | How to Validate | Outcome if Fails |
|------|----------|-----------------|------------------|
| **Doable?** | Can we detect this reliably? | Run skill on 10 pages, check precision | KILL - not technically feasible |
| **Real problem?** | Does this find actual issues? | Check if detections are true positives | KILL - false positive factory |
| **Useful?** | Do customers care? | Show prototype output to PM/customer | PARK - maybe later |
| **Worth it?** | ROI of production investment? | Compare effort vs customer value | PARK or GRADUATE |

### The Math: Hypothesis Testing Velocity

**Today (CrewAI):**
- 1 hour to build + test one opportunity hypothesis
- If 70% of hypotheses fail validation → 70% of engineering time wasted
- Team can test ~8 hypotheses per week → ~2-3 make it to production

**With Agent SDK + Skills:**
- 10 minutes to prototype + validate one hypothesis
- Kill bad ideas in 5 minutes before investing
- Team can test ~40 hypotheses per week → same 2-3 make it to production
- But: You found the BEST 2-3 ideas out of 40, not out of 8

**The insight:** The goal isn't to ship more opportunities faster. It's to **find better opportunities** by testing more hypotheses cheaply.

### What This Enables

| Capability | Impact |
|------------|--------|
| **Rapid Experimentation** | Try 10 ideas in an hour instead of 1 |
| **Domain Expert Involvement** | Non-coders can describe opportunities, Claude builds |
| **Reduced Boilerplate** | Focus on detection logic, not scaffolding |
| **Built-in Validation** | Every skill tested on real data before graduating |
| **Automatic Documentation** | SKILL.md becomes the fact's documentation |
| **Test Generation** | Validation runs become test cases |

---

## Open Questions

1. **Skill vs Producer Parity**: How to ensure graduated code behaves identically to skill?
2. **Complex Multi-Step Logic**: Can skills handle multi-agent workflows?
3. **State Management**: How do skills handle stateful detection (e.g., comparing to historical)?
4. **Cost Control**: How to limit Agent SDK costs during experimentation?
5. **Rollback**: If a graduated fact is wrong, how to revert?

---

## Next Steps

1. **Build "Baby Fact Lab" prototype** - Sandbox environment for skill experimentation
2. **Create Mystique-specific skills** - Blackboard awareness, sample data picker
3. **Implement Graduation Engine** - Skill → Production code conversion
4. **Test with real opportunity ideas** - Validate the 8x speedup claim
5. **Document the workflow** - For onboarding new developers

---

*Created: 2026-01-11*
*Status: Speculative Vision*
*Author: Claude*
