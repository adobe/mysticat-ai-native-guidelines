# Agent Orchestration

Choosing how to split work across contexts, and the contract that makes delegated work
come back.

[Token Efficiency](../04-configuration/token-efficiency.md#1-main-context-as-command-center)
establishes the principle: the main conversation should be thin on raw data and rich in
decisions, with heavy lifting delegated. This document covers the mechanics of doing
that: which primitive to reach for, what each one costs, and the delivery contract every
one of them needs.

## Why this matters

Delegation is usually adopted for cost. The stronger reason is that a long-running main
context degrades in three specific ways, and none of them announce themselves:

- **It stops finishing.** Work is declared done after partial progress, with no signal
  that coverage was partial.
- **It prefers its own output.** A context that produced an implementation is the wrong
  context to judge it. The bias is structural, not a lapse.
- **It drifts from the goal.** Compaction is lossy, and what it drops first is
  edge-case requirements and "do not do X" constraints.

A measurement from a real multi-day session in this workspace shows the shape. The main
thread ran 1,661 turns and accounted for 59% of the session's cost, against 56
subagents. Its tool histogram was 989 `Bash`, 385 `Edit`, 139 `Read`, 90 `Write`, and 55
`Agent` spawns: it was the primary implementer, and the subagents were an addition to its
work rather than a substitute for it. Its context peaked at 525,814 tokens, and
`cache_read` alone accounted for 74% of its cost. That last figure is the one to
internalise: past a certain size, most of what a session spends is not doing work, it is
carrying context across turns.

An orchestrator that edits files is not an orchestrator. The test is the tool histogram,
not the intent.

## Choose the primitive

Four ways to run work in parallel, and they are not interchangeable. Pick by who
coordinates and whether the workers must talk to each other.

| Primitive | Fits | Avoid when |
|---|---|---|
| [Subagents](https://code.claude.com/docs/en/sub-agents) | A side task whose result is all you need. Results return to the caller. | Workers need to talk to each other. |
| [Agent teams](https://code.claude.com/docs/en/agent-teams) | Workers that must share findings, challenge each other, and self-coordinate through a shared task list. | Pure fan-out, or anything needing worktree isolation or headless parity. Experimental, off by default. |
| [Cross-session messaging](https://code.claude.com/docs/en/cross-session-messaging) | Independent sessions you drive yourself, passing a finding or a status across. | Anything you want one agent to coordinate. Unavailable on Bedrock. |
| [Dynamic workflows](https://code.claude.com/docs/en/workflows) | Work too large for one conversation to coordinate, or needing findings adversarially verified before they are reported. The plan lives in a script rather than in a context. | Small tasks. Runs cost meaningfully more, and the orchestration has to be worth codifying. |

Three rules that follow:

- **Pure fan-out wants subagents, not a team.** If no worker has anything to say to
  another, a team buys coordination overhead and a higher token bill for a capability
  the design does not use.
- **Nesting is the orchestrator pattern.** A subagent that dispatches its own subagents
  keeps the intermediate output out of the main conversation entirely: only the
  top-level summary returns. This is the documented shape for a delegated task that
  itself splits into parallel subtasks, and it is what a per-repo or per-area agent
  should be.
- **Isolate by worktree when workers write.** Two agents editing one file overwrite each
  other. Subagents and separate sessions can each take a worktree; agent teams do not
  isolate teammates, so their work has to be partitioned by file instead. See
  [Multi-Session Patterns](../02-lifecycle/multi-session-patterns.md#git-worktree-isolation).

## The delivery contract

Every dispatched agent needs an explicit instruction about how its work comes back.
Without one, an agent that has finished and an agent that has stalled look identical
from the outside, and the orchestrator cannot tell them apart.

Which contract depends on how the agent was spawned, and the deciding factor is whether
it has a `name`.

**Unnamed, foreground: single channel.** The spawn returns the agent's output as the
tool result. The harness guarantees the channel, so the instruction only has to secure
the content:

```
When your analysis is complete, return your full findings as your completion message.
```

That still earns its place. An agent that ends on "I reviewed it and it looks
reasonable" has completed and delivered nothing usable.

**Named: two channels.** A `name` promotes the spawn to a teammate, which is
asynchronous. Findings arrive by mailbox, later, or not at all:

```
When your review is complete you MUST deliver it two ways. First, CALL
SendMessage with your full formatted findings as the message body, addressed
to: "team-lead" if you were spawned into a team and to: "main" otherwise.
Second, emit those same findings as your final response text.
```

Both halves are load-bearing, because which one reaches the orchestrator depends on the
runtime. Where the messaging layer is absent the completion message is the only
delivery; where it is present a plain response that skips the tool call is invisible.

Add a line telling the agent how to reach the tool. With tool search enabled,
`SendMessage` is deferred inside a subagent: the name is known, the schema is not, and
calling it before loading it fails. An agent that does not work this out falls back to
plain text, which is the exact silence the contract exists to prevent.

**Naming is opt-in, and so is the failure mode.** The silence problem belongs to
asynchronous teammates. Name an agent only when something must address it: because it
escalates a question only a human can answer, or because another agent needs to reach
it. A fan-out that just collects results should not pay for it.

**When you do name, add a per-run discriminator.** Names are the only namespace.
Duplicate names resolve to the newest holder, so two concurrent runs sharing a roster
name misdeliver silently, while an unknown name fails loudly. Reuse the discriminator
when matching an agent's transcript and when scoping any shutdown.

**Recovering an undelivered agent.** Treat idle-with-no-content as an undelivered
completion rather than a stall. Re-request by the agent's full name, naming both the
tool and a valid recipient: a bare "send me your findings" reproduces the original
silence. Read the send's return value, since a failed send is not a nudge. Cap the
rounds, then do the work directly rather than waiting.

Do not pre-check existence with `ListAgents`. It does not list team teammates by design,
so a live, reachable teammate is absent from it every time. The send is the check.

## Runtime facts that decide designs

Verified against Claude Code 2.1.227 on 2026-08-11. These change; re-check before
relying on one.

- **Background is the default.** Subagents run in the background unless the caller needs
  the result before continuing. A background subagent returns by notification rather
  than inline, and runs with a reduced built-in tool set that drops `ListAgents`. Ask
  for the foreground explicitly when the return semantics matter.
- **Subagents cannot ask the user.** `AskUserQuestion` is not available to them. Every
  gate where a human decides is therefore structurally main-thread work, and a delegated
  agent can only escalate.
- **Subagents can invoke skills and spawn subagents.** Both `Skill` and `Agent` are
  available, so a delegated agent can load a skill's whole body into its own context
  rather than the orchestrator's. This is the largest single context saving available in
  most designs.
- **Workflows are main-thread only.** Subagents do not have the tool, so fan-out inside
  a workflow is expressed in the script rather than as a workflow per worker.
- **A teammate honours its definition's `tools` allowlist**, except that the team
  coordination tools remain available to it regardless.
- **Delivery behaviour varies by model.** Given no delivery instruction, an opus agent
  loaded the messaging tool and delivered unprompted while a haiku agent emitted plain
  text and idled twice. A design cannot assume the tier it gets, which is why the
  contract is written rather than left implicit.

## Runtime parity

A skill that runs both interactively and headless has to work in the poorer environment.
Check what the headless runtime actually offers before depending on a mechanism, because
the failure is silent: the interactive path works, and only the automated one degrades.

The pattern to expect is a stricter environment than the local one. A headless worker
typically pins an explicit `--allowedTools` list, may run on a provider where some
features are unavailable, and may set `CLAUDE_CODE_FORK_SUBAGENT=1`, which forces every
subagent into the background. Any of those alone is enough to remove a mechanism that
works locally. Where a capability is missing, the design must degrade to something the
poorer runtime has, which is the reasoning behind the two-channel contract above.

## Cost discipline

Every one of these primitives multiplies token usage, and the multiplier is not the
point of adopting them. The point is context headroom and work that finishes.

Establish a baseline before restructuring, and state what the change must achieve
against it: peak context, the orchestrator's share of spend, its edit and write counts,
and duplicated work across agents. "Some improvement" is not a result. A restructuring
that halves peak context while costing somewhat more is usually a good trade; one that
costs more and moves nothing is the common outcome of adopting a mechanism on the
strength of its description.

Start small. Three focused workers usually beat five scattered ones, and a run on one
directory tells you what the same design costs on the whole repository.
