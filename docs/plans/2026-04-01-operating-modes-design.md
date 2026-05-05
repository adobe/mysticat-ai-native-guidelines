# Design: Operating Modes - From Collaborator to Director

**Date:** 2026-04-01
**Status:** Approved
**Scope:** mysticat-ai-native-guidelines

## Summary

Evolve the guidelines' stance on the human role from a single mode ("AI as collaborator") to a spectrum determined by two axes: substrate layer (durable vs fluid) and AI-native maturity (L0-L4). Acknowledge "human as director" as a valid operating mode when the harness supports it. Add AI-aware technology selection as a design criterion.

## Motivation

Practitioners are operating in director mode today - defining intent via specs and tests, delegating execution to AI, reviewing results rather than every line of code. The guidelines should acknowledge this trajectory honestly rather than prescribing a single collaboration style that doesn't match reality at higher maturity levels.

Source: Chris Wellons' blog post (2026-03-29) documenting 9KLoC in 4 days with AI as primary implementer, plus cross-Adobe discussions on AI-native practices.

## Changes

### New: `01-foundations/operating-modes.md`

Core document defining the collaborator-to-director spectrum:

1. **The Spectrum** - Two endpoints: collaborator mode (current default) and director mode (emerging). Not binary - a continuum.
2. **The 2D Matrix** - Layer (durable/fluid) x maturity (L0-L4) determines where you can operate. Fluid + high maturity = director mode viable. Durable + low maturity = collaborator mode required.
3. **Prerequisites for Director Mode** - What the harness must provide: comprehensive tests, mechanical enforcement, staging gates, observability, rollback. "Director mode isn't about trusting AI. It's about trusting your harness."
4. **Results-Based Review** - Acknowledge as trajectory. Current default: review the diff. Emerging: review the results. Gated by prerequisites. Not yet recommended default, but named honestly.
5. **What Doesn't Change** - Specs first (better specs, not fewer). Architecture decisions stay human. Guardrails get more important. Accountability stays with the director.

### New section in `01-foundations/harness-engineering.md`: "AI-Effective Technology Selection"

After "Application Legibility" section:

- AI agent effectiveness as a weighted design criterion (not the deciding factor, but a factor)
- What makes a technology AI-effective: training corpus size, type systems, ecosystem, standard structures, error messages
- Practical examples: Node.js vs Python (AEM Architecture Council discussion), well-known frameworks over bespoke, Wellons' C++ over C
- Caveat: criterion ages as models improve; weight it, don't let it veto

### Update: `01-foundations/philosophy.md`

Add forward reference after "AI as collaborator" definition acknowledging the spectrum exists, linking to operating-modes.md.

### Update: `01-foundations/substrate-model.md`

Add short section connecting substrate layers to operating modes. Fluid + strong harness = director mode viable. Durable = closer collaboration regardless.

### Update: `07-leadership/experienced-engineers-guide.md`

Add paragraph in "shift in practice" section acknowledging results-based review as a trajectory gated by harness maturity.

### Update: `07-leadership/ai-native-engineering-phase1.md`

Add note connecting L3/L4 maturity to director-mode viability.

### Update: `mkdocs.yml`

Add operating-modes.md to Foundations nav.

## Out of Scope

- Rewriting existing philosophy or principles
- Changing MUST rules around code review (those remain as the default)
- Endorsing director mode as the recommended default
- CLI vs MCP discussion (separate topic)
