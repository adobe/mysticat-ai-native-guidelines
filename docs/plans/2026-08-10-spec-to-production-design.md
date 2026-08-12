# Spec to Production: carrying a change past the PR

| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Author** | Rainer Friederich |
| **Created** | 2026-08-10 |
| **Updated** | 2026-08-10 |
| **Decided** | N/A |
| **Approvers** | TBD |
| **Jira** | N/A |

> Spec only — no implementation in this document. Cross-repo references use
> repo-relative paths anchored at each repo root (e.g.
> `experience-success-skills/skills/...`, `mysticat-ci/.github/workflows/...`).

## Summary

An existing chain of four skills carries work from a spec reference to a reviewed,
CI-green, runtime-validated pull request. It stops there, and everything after it —
merging, watching the deploy, confirming the change actually runs in each
environment, and promoting it onward — is manual, undocumented, and done differently
by each engineer.

This proposes extending that chain to the last environment the change is meant to
reach, with the deployment topology of each repo made explicit, an evidence trail
left on the PR at every environment boundary, and named human gates where an agent
must not decide alone.

## Problem Statement

### Current State

`/implement` (feature-delivery) resolves a spec to a pinned commit and opens a
worktree session on `feature-delivery:ship-feature`, which explores, designs,
implements, reviews, verifies locally, commits, and opens a PR through
`review-kit:create-pr`. `review-kit:pr-review-cycle` then drives the bot review loop,
gates on every CI check being green, and hands the runtime half to
`review-kit:pr-validate`, which exercises the change on whatever environment already
serves the branch and posts the result as a PR comment. That chain is in review
( https://github.com/adobe/experience-success-skills/pull/160 ); every contract
reference to it in this document tracks that branch and MUST be re-verified against
the merged state before this procedure is implemented. The chain's contracts are
recorded in the middle-stage design of record
( https://github.com/adobe/mysticat-ai-native-guidelines/pull/48 ).

That chain ends at a PR that is reviewed, green, and validated **pre-merge**. What
happens next is not modelled anywhere:

- **Merging is not the same action on every repo.** On the spacecat services a merge
  to `main` *is* the production deploy. On `mysticat-data-service` it deploys dev and
  opens a promotion PR. On DRS it deploys dev and leaves two more branch merges
  before production.
- **Nobody watches the deploy.** A merge that triggers a failing production deploy
  looks identical, on the PR, to one that succeeded.
- **Post-deploy validation is inconsistent.** The pre-merge validation
  `pr-validate` performs has no post-merge counterpart, so the environment the change
  was actually built for is frequently the one environment nobody exercises.
- **Promotion is invisible.** A `mysticat-data-service` change is not live in
  production until two further PRs merge; nothing links those back to the PR that
  introduced the change, and nothing records whether migrations ran.
- **Multi-PR changes have no ordering discipline.** A cross-repo change carries its
  merge order in section 9 of the PR body as prose. Nothing enforces it.

### Desired State

A change reaches its target environment through a procedure that is the same shape
everywhere, parameterised by the repo's real topology, and that leaves the same
evidence at every boundary: what was deployed, whether it ran, and what the logs
said.

### Gap Analysis

- No model of "what does merging this actually do" per repo.
- No post-merge deploy watch, and no defined behaviour when a deploy fails.
- No production validation contract, including the cases where production must not
  be written to at all.
- No promotion procedure for the repos where production is two or three merges away.
- No risk assessment, no on-call notification, and no rollback path.
- No merge-order execution for a set of related PRs.

## Goals and Non-Goals

### Goals

- Model each repo's path to production as one of a small number of **topology
  shapes**, so the procedure is written once per shape rather than once per repo.
- Extend the chain past the PR with an explicit evidence trail per environment.
- Define what an agent may do unattended, and where a human must decide.
- Define failure and escalation behaviour at every stage, including rollback.
- Support a set of PRs merged in a stated order.

### Non-Goals

- Replacing the deploy pipelines. This orchestrates and observes them; it does not
  reimplement them.
- Automating production deploys on repos where production is gated behind a human
  decision today. Those gates stay, and this spec names them.
- Removing the pre-merge review and validation. This starts where that ends.

## Proposed Solution

### The three topology shapes

Every repo in the workspace falls into one of three shapes, and the shape — not the
repo name — determines the procedure.

#### Shape A — merge is the production deploy

A push to `main` deploys to production directly, with no gate in between.

Verified in `mysticat-ci/.github/workflows/service-ci.yaml`: on
`github.event_name == 'push' && github.ref == 'refs/heads/main'`, the
`semantic-release` job runs under `environment: prod` and the `deploy-stage` job runs
under `environment: stage`. Both depend only on `build` and `it-postgres`, so they run
**in parallel** — stage does not precede prod, and there is no approval between them.

The consequence that governs the whole procedure: **the merge button is the deploy
button.** Everything that should be true of a production release must be true before
the merge, because there is nothing after it.

#### Shape B — merge deploys dev, promotion is a pull request

A push to `main` deploys to dev and opens a promotion PR; merging that PR deploys the
next environment.

Verified in `mysticat-data-service/.github/workflows/cd.yml`, whose own header reads
*PR: CI only | Main: CI → Release → Build once → Deploy dev → Promote*. Deploy jobs
are gated on a push to `main` and on `semantic-release` having cut a release. The run
applies `dbmate` migrations, deploys dev, writes the released version into
`environments.yml`, and opens a stage promotion PR.
`promote.yml` — *"Dev is auto-updated by cd.yml; stage/prod are updated via PRs"* —
deploys stage or prod when that file's pinned version changes on `main`.

Two properties follow. Promotion is **a PR, so it is reviewable and revertible**. And
a promotion PR may carry **more than one change**, because it pins a version rather
than a commit — so merging it ships everything released since the last promotion, not
only your change.

#### Shape C — merge deploys dev, promotion is a branch merge

Long-lived branches map to environments.

Verified in `llmo-data-retrieval-service/.github/workflows/ENVIRONMENTS.md` and
`deploy.yml`: `main` → `drs-dev`, `stage` → `drs-stage`, `prod` → `drs-v2-prod`,
plus ephemeral per-PR environments. A separate `deploy-to-production.yml` is
`workflow_dispatch` only, taking a commit SHA from `main` and an explicit
`allow_rollback` flag for deploying a commit older than what is live.

Promotion is a merge from one environment branch to the next, and production has an
additional manual, SHA-pinned path used for hotfixes and rollbacks.

### Repo to shape

| Repo | Shape | Basis |
|---|---|---|
| `spacecat-api-service` | A | `service-ci.yaml@v3`, `it-postgres: true` |
| `spacecat-audit-worker` | A | `service-ci.yaml@v2` |
| `spacecat-auth-service` | A | `service-ci.yaml@v3` |
| `spacecat-jobs-dispatcher` | A | `service-ci.yaml@v2` |
| `spacecat-import-worker` | A | `service-ci.yaml@v2` |
| `mysticat-projector-service` | A | `service-ci.yaml@v2` |
| `mysticat-data-service` | B | `cd.yml` + `promote.yml` |
| `llmo-data-retrieval-service` | C | branch-per-environment + manual prod dispatch |
| `spacecat-content-scraper` | **unverified** | does not use the shared workflow; its CI is bespoke |
| `spacecat-shared` | **unverified** | no `ci.yaml`; publishes npm packages rather than deploying |

**The unverified rows are deliberately unverified, not assumed.** Placing a repo in a
shape it does not belong to is the most expensive error this spec can make: it would
tell an agent that a merge is safe when it is a production deploy, or that a promotion
step exists when it does not. A repo enters the table only after its workflows have
been read, and the procedure refuses to run on a repo with no verified row.

### The procedure

The chain gains a fifth skill, provisionally `review-kit:ship-to-production`, invoked
after `pr-validate` reports `validated`. It is a loop over environment boundaries; the
shape decides how many boundaries there are.

#### Stage 0 — preconditions (all shapes)

Refuse to proceed unless every one holds, and say which failed:

1. The PR's base branch is merged into it and CI is green **on the merge result**,
   not on an older commit. On these repos every push is a deploy, so a branch behind
   its base deploys stale code while reading green.
2. The review loop is closed: every declared finding has a recorded decision.
3. `pr-validate` has recorded `validated`, or an explicitly recorded skip whose
   reason is a property of the pipeline rather than an unavailable environment.
4. The repo has a verified row in the shape table.
5. `autoMergeRequest` is null. An armed auto-merge means the merge fires when the
   last check clears, which removes the ordering this procedure depends on.

#### Stage 1 — merge

The merge is performed by the procedure only when the shape's **merge gate** is
satisfied (below). Record the merge commit SHA; every later stage is anchored to it,
not to the PR's head, because a squash merge produces a different commit.

#### Stage 2 — watch the deploy

Follow the workflow run triggered by the merge to completion. A deploy is not
"probably fine" because CI was green; the deploy jobs run *after* the checks the PR
gated on. Capture the run URL and the job conclusions.

For Shape B this stage additionally watches the **migration** task: `dbmate` runs
inside the deploy, and its logs are a Splunk blind spot, so read them from CloudWatch
(`/ecs/mysticat-data-service`, container `app`, task ID echoed by the deploy step).
CI's own log-dump prints `(no logs available)` when it cannot fetch them, which reads
like an empty migration rather than a failed read.

#### Stage 3 — validate in the environment

Reuse `pr-validate`'s four outcomes — validated, defect found, could not validate,
skipped, defined normatively in the middle-stage design of record — against the environment just deployed, with one addition: **production is
read-only by default.** A production validation may exercise a read path, inspect
logs, and query state; it may not seed data, mutate a customer record, or leave
anything behind. Where a change can only be proven by a write, the outcome is
`could not validate` with that reason stated, not a write performed anyway.

#### Stage 4 — read the logs

After every deploy, and before declaring the environment good: check the service's
error rate against its baseline for the window since the deploy, and look for
new error signatures rather than absolute counts. A service with a steady background
error rate will always show errors; what matters is what changed.

Anything new is escalated immediately: a new error signature in the logs or Splunk,
an error reported in the team Slack channels, or an uptime-monitoring alert after a
production deploy **alerts a human as soon as possible** — the alert is not deferred
to the Stage 5 comment.

#### Stage 5 — comment on the PR

One comment per environment boundary, naming the environment, the deploy run, the
validation outcome, and what the logs showed. The comment is the deliverable: a
validation that exists only in an agent's reply to its operator leaves no record for
the next reader, which is the same rule `pr-validate` already applies.

#### Stage 6 — promote (Shapes B and C only)

Return to Stage 1 for the next boundary, with the promotion PR or branch merge as the
subject. Production is the last boundary, and it has its own gate.

### Merge gates: what an agent may decide alone

This is the part of the spec that matters most, because the procedure holds
credentials that can deploy to production.

| Boundary | Gate |
|---|---|
| Shape A merge to `main` | **Human authorization required.** The merge is the production deploy. |
| Shape B/C merge to `main` (deploys dev) | Agent may merge once Stage 0 holds. |
| Shape B/C promotion to stage | Agent may merge once dev is validated and its comment is posted. |
| Shape B/C promotion to production | **Human authorization required**, after a risk assessment (below). |

An agent never merges to production. It prepares the merge, states the risk, notifies
on-call, and asks. The authorization is per promotion, not standing. It is human
whenever the deploy risk is high or the promotion carries more than the single change
— a batched promotion is always authorized by a person. A low-risk single-change
promotion is the only candidate for ever delegating this gate, and until a flip
criterion is decided, every promotion asks.

Every gate in this table is main-thread work per the agent orchestration guide
( https://github.com/adobe/mysticat-ai-native-guidelines/pull/46 ): sub-agents cannot
ask the user, so the procedure runs its gates in the invoking session, and a
delegated agent can only escalate to it.

### Risk assessment before a production promotion

Before asking for production authorization, the procedure establishes and states:

- **Is this the only change in the promotion?** A Shape B promotion PR pins a version
  and therefore carries everything released since the last promotion. Enumerate the
  commits it actually ships, not the one that prompted it.
- **Does it contain a migration?** A schema change is a different risk class, and on
  Shape B the rollback story differs from the code rollback story.
- **Is it reversible?** State the rollback path concretely: revert-and-repromote for
  Shape B, `deploy-to-production.yml` with an earlier SHA and `allow_rollback` for
  Shape C, revert-and-merge for Shape A.
- **What is the blast radius?** Which customers or orgs are affected if it is wrong.
- **What was validated, and where?** Carry forward the dev and stage evidence.

**Notify Skyline on-call before a production promotion**, with the assessment above,
and record that the notification was sent. On-call being told after a production
incident starts is the failure this exists to prevent.

### Failure handling and escalation

| Failure | Response |
|---|---|
| Deploy job fails | Stop. Do not promote. Post the failing job and its log excerpt on the PR. A failed deploy may leave the environment partially updated — say so rather than assuming it rolled back. |
| Migration fails | Stop, and escalate immediately. A partially applied migration is the highest-severity state in this document: the code and the schema disagree, and the next deploy will not fix it. |
| Validation finds a defect | Stop promoting. On dev or stage, return the change to the fix loop. In production, escalate and state the rollback path. |
| Validation cannot run | Not a pass. Record `could not validate` with the reason and stop at that boundary; do not promote past an environment that was never exercised. |
| Logs show a new error signature | Treat as a defect found, even if the deploy and validation both succeeded, and alert a human as soon as possible. |
| Promotion PR carries changes that are not yours | Not a failure, but it removes your authority to promote alone. Name the other changes and their authors in the authorization request. |
| Anything unrecognised | Stop and report. An unattended procedure holding deploy credentials must not improvise past a state it has no rule for. |

Every stop is reported **on the PR**, not only to the operator, and names the
environment reached, the environment not reached, and what would have to be true to
continue.

### Multiple PRs in a stated order

A set of related PRs is driven as an ordered list, and the order is the one stated in
section 9 of the PR bodies (deployment and merge order). Section 9 may be hand-written
or rendered from the spec's work-package edges; the procedure reads it the same way
either way. The procedure:

1. Resolves the set and reads the stated order. Refuses to guess: a set whose order
   is not stated anywhere is an input error, not something to infer from timestamps.
2. Runs Stage 0 across **all** of them before merging any. A set where the second PR
   is not ready is not a set that should have its first PR merged, because the
   intermediate state is one nobody designed.
3. Then, per PR in order, runs Stages 1 to 5 to completion before starting the next.
   Parallelism across a merge order is the thing the order exists to prevent.
4. Halts the whole set on the first failure, and reports which PRs are merged, which
   are not, and what state that leaves the system in.

A cross-repo set may mix shapes. The gates are per boundary, so a set containing one
Shape A repo requires human authorization at that repo's merge, even if the others do
not.

## Open Questions

- Should the fifth skill be one skill with a shape parameter, or one per shape? One
  skill keeps the sequential state together; three keep each procedure short. The
  same trade-off was decided in favour of one skill for `pr-review-cycle`.
- Where does the shape table live so it is single-sourced? It is operational fact
  about repos, and duplicating it into each skill is how it will drift.
- What is the production log baseline per service, and who owns it? Stage 4 is
  unimplementable without one, and "look for new signatures" is judgement until it
  exists.
- Do the two unverified repos need to be in the table before this ships, or does the
  procedure simply refuse to run on them until someone reads their workflows?

## Risks

- **This automates the path to production.** The mitigation is that it does not: it
  automates the path *to the production gate*. Every high-risk or batched promotion
  is authorized by a person, and no delegation of the low-risk single-change case
  happens before an explicit flip criterion is decided. That boundary is the security
  property of the whole design and is not relaxed for convenience.
- **Contract drift against the in-review chain.** The four skills this document
  builds on track a moving branch; every contract reference is re-verified against
  the merged state before implementation.
- **A wrong shape assignment is worse than no assignment.** Hence the unverified rows
  and the refusal to run without one.
- **Evidence can look more complete than it is.** `could not validate` posts a comment
  like every other outcome. The procedure must read the outcome a comment states, not
  the fact that a comment exists — the same trap `pr-validate` documents.

## References

- `experience-success-skills/skills/feature-delivery/skills/implement-spec/SKILL.md`
- `experience-success-skills/skills/feature-delivery/skills/ship-feature/SKILL.md`
- `experience-success-skills/skills/review-kit/skills/pr-review-cycle/SKILL.md`
- `experience-success-skills/skills/review-kit/skills/pr-validate/SKILL.md`
- https://github.com/adobe/mysticat-ai-native-guidelines/pull/48 — middle-stage design of record and delivery-pipeline overview (verdict vocabulary, hand-off contract, human gates)
- https://github.com/adobe/mysticat-ai-native-guidelines/pull/46 — agent orchestration guide (main-thread human gates, spawn shapes)
- `mysticat-ci/.github/workflows/service-ci.yaml`
- `mysticat-data-service/.github/workflows/cd.yml`, `promote.yml`
- `llmo-data-retrieval-service/.github/workflows/ENVIRONMENTS.md`, `deploy.yml`,
  `deploy-to-production.yml`
