# Information Lookup

When an agent needs context - a ticket's details, how a subsystem works, what a past decision was - it can either ask you or look it up. A good agent looks it up. This guide is the routing logic that makes that reliable: which source to reach for given what you have, and how to research across sources without drowning the main context.

It is the read-side companion to your documentation hierarchy. Where you decide to *write* a doc is where an agent should *read* it, so this guide mirrors whatever "where things live" map your workspace already has.

**Who this is for:** anyone wiring tool-routing rules into a `CLAUDE.md` / `AGENTS.md`, and anyone deciding where team knowledge should live so agents can find it.

## The Principle

> Don't ask the human for context you can look up yourself.

The human is the fallback, not the first resort. An agent that asks "which ticket?" or "where is that documented?" when the answer is one tool call away is spending your attention instead of its own tokens. Encode the routing once (below) and the agent stops asking.

This is not a license to guess. Looking it up means using the right tool to fetch the real source, not inventing a plausible answer. The [trust model](#the-trust-model-for-discovery-search) further down draws that line.

## Local Docs First

The cheapest, most authoritative source is almost always the repos already on disk.

- **Local** - reading a file costs no network round-trip and no external-service auth.
- **Authoritative** - your own architecture docs and ADRs are the canonical decision record; an external wiki or chat thread is often a stale secondary copy.
- **Discoverable** - well-run repos expose an `AGENTS.md` (or `CLAUDE.md`) entry point that indexes the rest, so an agent can follow a progressive-discovery chain (repo -> architecture index -> specific doc) instead of grepping blind.

So for any conceptual question - "how does X work", "is there a decision about Y", "what's our standard for Z" - **check local docs before reaching for external search.** Follow the `AGENTS.md` chain, and consult the documentation hierarchy map (for example a `DOCUMENTATION-GUIDE.md`) to know which tier owns the answer. External discovery is the fallback when the answer is not captured locally, and what it returns is secondary, to be cross-checked (see the trust model).

This mirrors the source-discoverability tiering in [vibecoding best practices](../05-guardrails/vibecoding-best-practices.md): prefer durable, agent-discoverable repo docs; treat ephemeral wikis and chat as a lower tier.

## The Decision Tree

Keep this short and concrete in your `CLAUDE.md` so the agent follows it without being told which tool to use each time. Wording matters more than completeness - "Have a ticket number? -> tracker tool" fires because it is specific. "Use the right tool" means nothing.

```text
1. Specific artifact with an ID/URL?  ->  go straight to its tool
   - ticket ID / tracker URL       -> issue-tracker tool (e.g. Jira)
   - wiki / docs URL               -> wiki fetch tool (e.g. Confluence get-page)
   - chat URL / thread             -> chat tool for that workspace (e.g. Slack)
   - code-host PR / repo URL       -> code-host tool, chosen by host
   - log / metric / data question  -> the matching telemetry or database tool

2. Conceptual? ("how does X work", "is there a decision about Y", "what's our standard for Z")
   ->  LOCAL DOCS FIRST: follow the AGENTS.md progressive-discovery chain
       (repo -> architecture/platform index -> specific doc);
       org-wide standards in the org RFC repo; process in the methodology repo;
       one service's detail in that service's repo.
   ->  only if not found locally: fan out to external search (wiki + chat + tracker),
       treated as secondary and cross-checked.

3. Don't know where it lives? ("has anyone discussed X?")
   ->  local docs first (grep + AGENTS.md indexes), then a parallel fan-out
       across external sources. See Fan-Out Research below.
```

### Worked example (generic)

A request like "give me the full picture on the `acme/checkout` rate-limit work":

- Start local: grep `acme/checkout`, read its `AGENTS.md`, and check the architecture repo's index for a rate-limit decision.
- Then the artifact tools: the linked `PROJ-481` ticket, the PR, the design wiki page.
- Synthesize, and cite each fact to its source.

## Fan-Out Research

For "deep dive / full context / everything we know about X" requests, do not serialize a dozen lookups - fan out and cache.

1. **Check the cache first.** Look for a prior synthesis on this topic in your research cache (a gitignored scratch path). If found and fresh (say, under ~2 weeks old), offer to reuse it; if stale, re-run. Skip the cache on an explicit "fresh" / "from scratch".
2. **Fan out in parallel** across the sources that could hold the answer: local repos (grep + `AGENTS.md` indexes) **first**, then per-source external tools (wiki search, chat search, tracker search, code-host search). Delegate heavy searches to subagents so their raw output never lands in the main context.
3. **Synthesize** into one summary, with every fact cited to its source (URL, ticket key, PR number, file path).
4. **Cache the synthesis** (not the raw search output) to the scratch path with a header recording the date and the sources consulted. Next session, reading that file is one fast read; re-fanning costs minutes and many tokens.

This pairs with the [`deep-research`](skills/overview.md) and parallel-agent skills if your setup has them. The value comes from doing it on a real deliverable, not as a drill.

## The Trust Model for Discovery Search

AI-powered discovery and search (semantic search, RAG assistants) is excellent at one thing and unreliable at another:

- **Good for:** finding *where* something lives - the channel, the page, the ticket, the file.
- **Unreliable for:** the exact quote, name, date, or number. A confident summary can be built on the wrong snippet, or fill a gap with a plausible invention. You cannot tell from the answer which happened.

> **Rule:** Trust the pointer, verify the quote. Use discovery search to find the thread or page; then open the real source with the direct tool before citing any specific name, date, number, or decision.

Calibrate it once: ask a discovery tool something you already know, and watch where it confidently diverges. That tells you what to double-check going forward.

## Follow Linked Resources First

When you open a ticket, chat thread, or PR to do work, the linked resources are part of the context, not optional extras. Before starting, follow the links - the design doc the ticket references, the thread the PR description links, the ADR a comment points to - using the matching tool for each link type. Half the misunderstandings in agentic work come from acting on a ticket title without reading the doc it linked.

## See Also

- [Token Efficiency](token-efficiency.md) - subagent delegation and `/context`; the cost side of "look it up vs ask"
- [Cross-Tool Setup](cross-tool-setup.md) - wiring the same routing across Claude Code, Cursor, Codex, Gemini, Copilot
- [MCP Overview](mcp/overview.md) - MCP-vs-CLI routing and server setup
- [Vibecoding Best Practices](../05-guardrails/vibecoding-best-practices.md) - source-discoverability tiering (where to put knowledge so agents find it)
