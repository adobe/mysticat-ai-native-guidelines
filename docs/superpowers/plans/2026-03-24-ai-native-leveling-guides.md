# AI-Native Leveling Guides Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create three AI-native job leveling guide documents (IC, Manager, Domain Expert) and integrate them into the site navigation.

**Architecture:** Three standalone markdown documents in `docs/07-leadership/`, each following the same structure: header, how-to-use section, prose vignettes per level, matrix table with AI-native categories, and a glossary. Navigation updates in mkdocs.yml, README.md, and AGENTS.md.

**Tech Stack:** Markdown (MkDocs Material theme), git

**Spec:** `docs/superpowers/specs/2026-03-24-ai-native-leveling-guides-design.md`

---

### Task 1: Write IC Leveling Guide (ai-native-leveling-ic.md)

**Files:**
- Create: `docs/07-leadership/ai-native-leveling-ic.md`

This is the largest document - 6 levels (P10-P55), 5 categories, 6 vignettes.

- [ ] **Step 1: Write the header and how-to-use section**

Create `docs/07-leadership/ai-native-leveling-ic.md` with:

```markdown
# AI-Native Leveling: Individual Contributor (ESDEP)

**Last reviewed**: 2026-03-24 | Review quarterly as AI capabilities evolve
**Reference:** Adobe Job Code ESDEPXX

This guide complements - not replaces - the existing ESDEP Software Development Individual Contributor leveling guide. It defines the AI-native skills expected at each IC level, covering how engineers work with AI across the development lifecycle.

**Contents:**
- [How to Use This Guide](#how-to-use-this-guide)
- [Level Vignettes](#level-vignettes)
- [AI-Native Skills Matrix](#ai-native-skills-matrix)
- [Glossary](#glossary)
- [See Also](#see-also)

## How to Use This Guide

This guide serves three purposes:

1. **Performance evaluation** - Managers use it alongside the standard ESDEP guide during check-ins to assess the AI-native dimension of an engineer's work.
2. **Self-assessment and mentoring** - Engineers use it to understand what "good" looks like at their level and what to work toward. Frontier engineers use it to mentor others.
3. **Hiring bar** - Hiring managers use it to calibrate AI-native expectations when leveling candidates.

**Reading alongside the standard guide:** AI-native skills compound on existing role expectations. A P40 is still expected to meet all standard P40 criteria (design decisions, code quality, leadership). This guide adds the AI-native dimension on top.

**Cumulative progression:** Each level builds on the prior. The vignettes describe what someone at that level looks like holistically; the matrix cells focus on what is new or distinct at each level.

**Note on P60+:** Principal Scientists operate at a scope that transcends per-level AI-native prescriptions. P60+ engineers are expected to define and evolve the AI-native bar itself.
```

- [ ] **Step 2: Write the level vignettes section**

Add the Level Vignettes section with one prose paragraph per level (P10 through P55). Content is defined in the spec under "Sample Level Vignettes (IC)". Each vignette is 3-5 sentences describing what this person looks like in practice.

Use the exact vignette text from the spec for P10, P20, P30, P40 (revised version), P50, P55.

- [ ] **Step 3: Write the AI-Native Skills Matrix**

Add the matrix table section. The matrix has 6 columns (P10, P20, P30, P40, P50, P55) and 5 category rows:

1. **Harness Engineering** - cell content from spec section "1. Harness Engineering"
2. **AI-Directed Development** - cell content from spec section "2. AI-Directed Development"
3. **System Design for AI Effectiveness** - cell content from spec section "3. System Design for AI Effectiveness"
4. **Knowledge Encoding & Amplification** - cell content from spec section "4. Knowledge Encoding & Amplification"
5. **Ownership & Judgment** - cell content from spec section "5. Ownership & Judgment"

Format as one table per category (6-column table is too wide for markdown). Each category gets its own subsection heading, a one-line description of what the category covers, and a table with Level | Description columns. This matches how the spec already structures it.

- [ ] **Step 4: Write the glossary and see-also sections**

Add the glossary table and see-also links. Glossary content is in the spec under "Glossary Terms". See Also should link to:
- `ai-first-leadership.md`
- `ai-native-engineering-phase1.md`
- `../01-foundations/harness-engineering.md`
- `../01-foundations/substrate-model.md`
- `../06-adoption/ai-readiness-checklist.md`
- `domain-experts.md`

- [ ] **Step 5: Review and commit**

Read the full document to verify:
- All 6 vignettes are present and distinguishable
- All 5 categories have complete tables with 6 levels each (30 cells total)
- No overlap with standard ESDEP content
- All cells describe observable behaviors
- Glossary links use correct relative paths

```bash
git add docs/07-leadership/ai-native-leveling-ic.md
git commit -m "docs: add AI-native leveling guide for IC (ESDEP)"
```

---

### Task 2: Write Manager Leveling Guide (ai-native-leveling-manager.md)

**Files:**
- Create: `docs/07-leadership/ai-native-leveling-manager.md`

Three bands (M2-M3, M4, M5-M6), 4 categories, 3 vignettes.

- [ ] **Step 1: Write the header and how-to-use section**

Create `docs/07-leadership/ai-native-leveling-manager.md` with:

```markdown
# AI-Native Leveling: Engineering Manager (ESDEM)

**Last reviewed**: 2026-03-24 | Review quarterly as AI capabilities evolve
**Reference:** Adobe Job Code ESDEMXX

This guide complements - not replaces - the existing ESDEM Software Development Manager leveling guide. It defines the AI-native skills expected at each management band, covering how managers enable AI-native engineering in their teams and systems.

**Contents:**
- [How to Use This Guide](#how-to-use-this-guide)
- [Band Vignettes](#band-vignettes)
- [AI-Native Skills Matrix](#ai-native-skills-matrix)
- [Glossary](#glossary)
- [See Also](#see-also)

## How to Use This Guide

This guide serves three purposes:

1. **Performance evaluation** - Senior leaders use it alongside the standard ESDEM guide during check-ins to assess the AI-native dimension of a manager's work.
2. **Self-assessment and mentoring** - Managers use it to understand what "good" looks like at their band and what to work toward.
3. **Hiring bar** - Hiring managers use it to calibrate AI-native expectations when leveling management candidates.

**Reading alongside the standard guide:** AI-native skills compound on existing role expectations. An M4 is still expected to meet all standard M4 criteria (people management, technical leadership, product delivery). This guide adds the AI-native dimension on top.

**Banded structure:** Manager AI-native skills scale primarily by scope and influence rather than technique. Levels are grouped into three bands: M2-M3 (team-level), M4 (cross-team), M5-M6 (org-level).

**Cumulative progression:** Each band builds on the prior. The vignettes describe what someone at that band looks like holistically; the matrix cells focus on what is new or distinct at each band.
```

- [ ] **Step 2: Write the band vignettes section**

Add the Band Vignettes section with one prose paragraph per band (M2-M3, M4, M5-M6). Content is defined in the spec under "Sample Level Vignettes (Manager)".

- [ ] **Step 3: Write the AI-Native Skills Matrix**

Add the matrix table section. The matrix has 3 columns (M2-M3, M4, M5-M6) and 4 category rows:

1. **AI Strategy & Maturity** - cell content from spec
2. **Team Enablement & Adoption** - cell content from spec
3. **Operational Excellence for AI** - cell content from spec
4. **Domain Expert Integration** - cell content from spec

Same format as IC: one table per category with Band | Description columns.

- [ ] **Step 4: Write the glossary and see-also sections**

Same glossary as IC. See Also should link to:
- `ai-first-leadership.md`
- `ai-native-engineering-phase1.md`
- `ai-native-leveling-ic.md`
- `ai-native-leveling-domain-expert.md`
- `../06-adoption/ai-readiness-checklist.md`

- [ ] **Step 5: Review and commit**

Read the full document to verify:
- All 3 vignettes are present and distinguishable
- All 4 categories have complete tables with 3 bands each (12 cells total)
- No overlap with standard ESDEM content
- All cells describe observable behaviors

```bash
git add docs/07-leadership/ai-native-leveling-manager.md
git commit -m "docs: add AI-native leveling guide for managers (ESDEM)"
```

---

### Task 3: Write Domain Expert Leveling Guide (ai-native-leveling-domain-expert.md)

**Files:**
- Create: `docs/07-leadership/ai-native-leveling-domain-expert.md`

Four levels (D1-D4), 3 categories, 4 vignettes.

- [ ] **Step 1: Write the header and how-to-use section**

Create `docs/07-leadership/ai-native-leveling-domain-expert.md` with:

```markdown
# AI-Native Leveling: Domain Expert

**Last reviewed**: 2026-03-24 | Review quarterly as AI capabilities evolve

This guide defines the AI-native skills expected at each domain expert level. Domain experts are non-engineers who bring deep domain expertise (SEO, GEO, content strategy, paid traffic, etc.) and use AI tools to produce working software.

Unlike the IC and Manager guides, this does not complement an existing Adobe leveling guide - it establishes the AI-native progression for domain expert roles.

**Contents:**
- [How to Use This Guide](#how-to-use-this-guide)
- [Levels Overview](#levels-overview)
- [Level Vignettes](#level-vignettes)
- [AI-Native Skills Matrix](#ai-native-skills-matrix)
- [Glossary](#glossary)
- [See Also](#see-also)

## How to Use This Guide

This guide serves three purposes:

1. **Performance evaluation** - Managers use it during check-ins to assess a domain expert's AI-native progression.
2. **Self-assessment and mentoring** - Domain experts use it to understand where they are and what to work toward. Engineering buddies use it to calibrate their mentoring.
3. **Hiring bar** - Hiring managers use it to set expectations for domain expert roles that include AI-assisted production.

## Levels Overview

| Level | Name | Description |
|-------|------|-------------|
| D1 | Sandbox | Isolated prototypes, learning the tools |
| D2 | Guided Producer | Fluid layer with engineering review |
| D3 | Autonomous Producer | Fluid layer with ownership, PoC-to-production |
| D4 | Platform-Aware Leader | Durable-aware, shapes how domain expertise flows into product |

**Cumulative progression:** Each level builds on the prior. The vignettes describe what someone at that level looks like holistically; the matrix cells focus on what is new or distinct at each level.
```

- [ ] **Step 2: Write the level vignettes section**

Add the Level Vignettes section with one prose paragraph per level (D1 through D4). Content is defined in the spec under "Sample Level Vignettes (Domain Expert)".

- [ ] **Step 3: Write the AI-Native Skills Matrix**

Add the matrix table section. The matrix has 4 columns (D1, D2, D3, D4) and 3 category rows:

1. **AI-Assisted Production** - cell content from spec
2. **Domain-to-System Translation** - cell content from spec
3. **Production Awareness** - cell content from spec

Same format as IC/Manager: one table per category with Level | Description columns.

- [ ] **Step 4: Write the glossary and see-also sections**

Same glossary as IC/Manager. See Also should link to:
- `domain-experts.md` (the companion progression guide)
- `ai-native-engineering-phase1.md`
- `ai-native-leveling-ic.md` (for engineering buddies calibrating expectations)
- `ai-native-leveling-manager.md` (for managers integrating domain experts)
- `../01-foundations/substrate-model.md`

- [ ] **Step 5: Review and commit**

Read the full document to verify:
- All 4 vignettes are present and distinguishable
- All 3 categories have complete tables with 4 levels each (12 cells total)
- All cells describe observable behaviors
- Progression from D1 to D4 is clear and non-overlapping

```bash
git add docs/07-leadership/ai-native-leveling-domain-expert.md
git commit -m "docs: add AI-native leveling guide for domain experts"
```

---

### Task 4: Update Navigation

**Files:**
- Modify: `mkdocs.yml` (add 3 entries under Leadership nav section)
- Modify: `README.md` (add 3 rows to Leadership table)
- Modify: `AGENTS.md` (update Leadership description)

- [ ] **Step 1: Update mkdocs.yml**

Add three entries after the existing `AI-Native Phase 1` entry in the Leadership nav section:

```yaml
    - AI-Native Leveling (IC): 07-leadership/ai-native-leveling-ic.md
    - AI-Native Leveling (Manager): 07-leadership/ai-native-leveling-manager.md
    - AI-Native Leveling (Domain Expert): 07-leadership/ai-native-leveling-domain-expert.md
```

Current Leadership section in mkdocs.yml (after Phase 1 addition):
```yaml
  - Leadership:
    - AI-First Leadership: 07-leadership/ai-first-leadership.md
    - For Junior Engineers: 07-leadership/junior-engineers.md
    - For Domain Experts: 07-leadership/domain-experts.md
    - For Experienced Engineers: 07-leadership/experienced-engineers-guide.md
    - AI-Native Phase 1: 07-leadership/ai-native-engineering-phase1.md
```

Add the three new entries after `AI-Native Phase 1`.

- [ ] **Step 2: Update README.md**

Add three rows to the Leadership table in README.md, after the existing `AI-Native Phase 1` row:

```markdown
| [AI-Native Leveling (IC)](docs/07-leadership/ai-native-leveling-ic.md) | AI-native skill expectations per IC level (P10-P55) |
| [AI-Native Leveling (Manager)](docs/07-leadership/ai-native-leveling-manager.md) | AI-native skill expectations per manager band (M2-M6) |
| [AI-Native Leveling (Domain Expert)](docs/07-leadership/ai-native-leveling-domain-expert.md) | AI-native skill expectations per domain expert level (D1-D4) |
```

- [ ] **Step 3: Update AGENTS.md**

Update the Leadership row in the Content Map table to mention the leveling guides:

```markdown
| [07 - Leadership](docs/07-leadership/) | For leaders, junior engineers, experienced engineers, domain experts, AI-native Phase 1, AI-native leveling guides (IC, Manager, Domain Expert) |
```

- [ ] **Step 4: Commit navigation updates**

```bash
git add mkdocs.yml README.md AGENTS.md
git commit -m "docs: add AI-native leveling guides to site navigation"
```

---

### Task 5: Final Verification

- [ ] **Step 1: Verify all files exist and render**

```bash
ls -la docs/07-leadership/ai-native-leveling-*.md
```

Expected: three files.

- [ ] **Step 2: Verify cross-references**

Check that all relative links in See Also sections resolve to existing files:

```bash
# From docs/07-leadership/, these should all exist:
ls docs/07-leadership/ai-first-leadership.md
ls docs/07-leadership/ai-native-engineering-phase1.md
ls docs/07-leadership/domain-experts.md
ls docs/01-foundations/harness-engineering.md
ls docs/01-foundations/substrate-model.md
ls docs/06-adoption/ai-readiness-checklist.md
```

- [ ] **Step 3: Verify navigation entries**

Check mkdocs.yml has all three new entries, README.md has all three new table rows, AGENTS.md mentions the leveling guides.

- [ ] **Step 4: Verify content completeness**

For each document, count the matrix cells:
- IC: 5 categories x 6 levels = 30 cells
- Manager: 4 categories x 3 bands = 12 cells
- Domain Expert: 3 categories x 4 levels = 12 cells

Total: 54 cells, each with 2-4 bullet points of observable behaviors.

- [ ] **Step 5: Push branch and create PR**

```bash
git push origin docs/ai-native-phase1-whitepaper
```

Then create a PR targeting main with title: "docs: add AI-native job leveling guides (IC, Manager, Domain Expert)"
