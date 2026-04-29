# Baseline Alignment: Detecting Drift Across Review Cycles

## The Problem

Larger features go through multiple rounds of review and revision at every phase: the spec gets reviewed and refined, the implementation plan gets reviewed and adjusted, and the implementation itself goes through PR review cycles with fixes and changes. Each individual revision makes sense in isolation — a reviewer catches an edge case, a constraint surfaces during planning, a test failure prompts a code change.

But without periodically checking back against the **baseline** — the artifact from the previous phase — these incremental changes compound into **drift**. The implementation no longer matches the plan. The plan no longer matches the spec. The spec may have evolved away from the original problem statement.

```
Original Intent
     │
     ▼
  Spec v1 ──review──▶ Spec v2 ──review──▶ Spec v3 ──review──▶ Spec v4
                                                                  │
                                                                  ▼
                                            Plan v1 ──review──▶ Plan v2 ──review──▶ Plan v3
                                                                                      │
                                                                                      ▼
                                                                   Impl v1 ──review──▶ Impl v2 ──review──▶ Impl v3
                                                                                                              │
                                                                                                         ❓ Still aligned
                                                                                                            with Spec v4?
```

Each arrow is a well-intentioned revision. The danger is that no one checks the diagonal — whether the final implementation still serves the original spec.

## Why This Happens

### Narrowing Focus During Reviews

Reviewers naturally focus on the artifact in front of them. A PR reviewer reads the code diff, not the spec. A plan reviewer reads the plan, not the original problem statement. This is efficient for catching local issues but blind to global drift.

### Accumulation of Small Deviations

No single review comment causes drift. But a series of reasonable changes can:

1. A spec reviewer suggests simplifying a requirement ("we don't need X for v1")
2. The plan accommodates the simplification but also drops a related requirement Y that was tightly coupled
3. The implementation skips Y's test coverage since it's "not in the plan"
4. A PR reviewer asks for a refactor that subtly changes the behavior of Z, which depended on Y

Each step is locally correct. The result is an implementation that has silently dropped a requirement.

### Context Loss Across Sessions

When work spans multiple sessions or days, the human and AI both lose context about upstream decisions. The PR reviewer in session 5 wasn't present for the spec discussion in session 1. The AI agent implementing a fix in response to review feedback has no memory of why the plan chose a particular approach.

## The Baseline Alignment Practice

The fix is simple: **periodically check the current artifact against its baseline**.

| Current Phase | Baseline to Check Against |
|---------------|--------------------------|
| Spec revision | Original problem statement / requirements |
| Plan revision | Approved spec |
| Implementation (PR review cycles) | Approved implementation plan |
| Post-merge validation | Approved spec (full circle) |

### When to Check

- **After every 3rd review cycle** on the same artifact — if a PR has gone through 3+ rounds of review/fix, it's time to check the plan
- **Before phase transitions** — before moving from planning to implementation, verify the plan still covers the spec
- **When a reviewer requests a significant change** — if a review comment leads to more than a localized fix (architectural change, dropped feature, new dependency), check the baseline
- **When resuming after a break** — if days have passed since the last session, re-read the baseline before continuing

### How to Check

#### Manual Check

Re-read the baseline document and compare it against the current state of the artifact. Create a simple alignment checklist:

```markdown
## Baseline Alignment Check

**Artifact**: PR #42 (implementation)
**Baseline**: Implementation plan at docs/plans/feature-x.md
**Trigger**: 4th round of PR review

### Requirements from plan:
- [ ] REST endpoint with pagination — still present, matches plan
- [ ] Redis caching with 5-min TTL — changed to 10-min during review, **intentional** (reviewer flagged perf concern)
- [ ] Error handling with retry — **missing**, dropped during refactor in review round 3
- [ ] Integration test for cache invalidation — **missing**, not written after cache TTL change

### Verdict: 2 items drifted. Error handling needs to be restored. Integration test needs updating for new TTL.
```

#### AI-Assisted Check

Ask the AI to perform the comparison explicitly:

```
Compare the current implementation on this branch against the plan
at docs/plans/feature-x.md. For each item in the plan, verify whether
the implementation still addresses it. Flag any items that were dropped,
changed, or only partially implemented. For changes, note whether they
were intentional (documented in review comments) or accidental.
```

This works well because the AI can read both artifacts and do a systematic cross-reference — exactly the kind of tedious-but-important work that humans skip under time pressure.

#### Spec Compliance Review

For the final check (implementation vs. spec), use a structured review:

```
Compare the implementation in this PR against the spec at
docs/specs/feature-x.md. Create a table with three columns:
1. Spec requirement
2. Implementation status (met / partially met / not met / changed)
3. Evidence (file:line or test name)

Flag any requirement that is "changed" or "not met" so we can
decide whether the deviation is intentional.
```

## Intentional vs. Accidental Drift

Not all drift is bad. Sometimes a review cycle reveals that the spec was wrong, or the plan was over-engineered, or a simpler approach emerged during implementation. The point of baseline alignment is not to rigidly enforce the original plan — it's to make drift **visible and intentional**.

When you detect drift:

1. **If intentional**: Document the deviation and update the baseline. If the implementation intentionally diverges from the plan, update the plan (or add a note explaining the divergence). If the plan diverges from the spec, update the spec.
2. **If accidental**: Restore the original intent. Re-implement the dropped requirement, restore the removed test, or fix the behavioral change.

The worst outcome is **undocumented intentional drift** — where everyone informally agrees the spec is outdated but nobody updates it. This creates a documentation debt that compounds over time and misleads future AI sessions and new team members.

## Integrating Into Your Workflow

### CLAUDE.md Rule

Add a baseline alignment reminder to your project's CLAUDE.md:

```markdown
## Review Cycle Discipline

- SHOULD perform a baseline alignment check after 3+ review rounds on the same PR
- SHOULD compare implementation against the plan before requesting final review approval
- MUST update the plan/spec when intentional deviations are identified during alignment checks
```

### PR Template Addition

Add a section to your PR template for larger features:

```markdown
## Baseline Alignment

- [ ] Implementation matches the plan at [link to plan]
- [ ] Any intentional deviations are documented below
- [ ] Plan/spec updated to reflect intentional changes

### Deviations from Plan
<!-- List any intentional changes from the original plan, with rationale -->
```

### Multi-Session Features

For features spanning multiple sessions, baseline alignment is especially important. Add it to the [start-of-session protocol](multi-session-patterns.md):

1. Read the progress file
2. Read the feature list
3. **Re-read the plan and verify the last session's work still aligns**
4. Run baseline tests
5. Continue work

### Review Skills / Automation

If your team uses AI-assisted PR reviews, configure the review to include a baseline check. A review skill can automatically compare the PR diff against a linked spec or plan and flag potential drift in its review output.

## Signs You Need a Baseline Check

- A PR has been open for more than a week with active review cycles
- You can't remember why a particular approach was chosen
- A reviewer asks "was this in the spec?" and you're not sure
- The PR description no longer accurately describes the changes
- Test coverage has decreased during review-driven refactors
- The implementation "works" but you've lost track of whether it covers all original requirements

## Anti-Pattern: The Telephone Game

**Pattern**: Spec is reviewed and changed. Plan is written from the changed spec, then reviewed and changed. Implementation is written from the changed plan, then reviewed and changed. At no point does anyone check whether the final implementation still satisfies the original spec.

**Why it's bad**: Like the children's game of telephone, the message degrades with each retransmission. Requirements get dropped, simplified, or subtly altered at each phase transition and within each review cycle. By the end, the feature may technically "work" but miss the original business need.

**Better approach**: Treat baseline alignment as a hygiene practice — quick, routine, and non-negotiable for larger features. The cost of a 10-minute alignment check is trivial compared to discovering post-merge that a key requirement was silently dropped three review cycles ago.

## See Also

- [Development Lifecycle Overview](overview.md) — the 5-phase cycle and phase transitions
- [Phase 4: Validation](04-validation.md) — verification patterns including spec traceability
- [Multi-Session Patterns](multi-session-patterns.md) — state persistence across sessions
- [Anti-Patterns](../05-guardrails/anti-patterns.md) — common process mistakes
- [MUST Rules](../05-guardrails/must-rules.md) — non-negotiable requirements
