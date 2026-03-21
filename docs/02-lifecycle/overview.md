# Development Lifecycle Overview

## The 5-Phase Cycle

AI-first development follows a structured lifecycle that emphasizes design, planning, and documentation alongside implementation.

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   ┌──────────┐    ┌──────────┐    ┌──────────────┐                 │
│   │  DESIGN  │───▶│ PLANNING │───▶│IMPLEMENTATION│                 │
│   │  & SPEC  │    │          │    │              │                 │
│   └──────────┘    └──────────┘    └──────────────┘                 │
│        │                                  │                         │
│        │                                  ▼                         │
│        │                          ┌──────────────┐                 │
│        │                          │  VALIDATION  │                 │
│        │                          │              │                 │
│        │                          └──────────────┘                 │
│        │                                  │                         │
│        │         Iterate                  ▼                         │
│        │◀─────────────────────────┌──────────────┐                 │
│        │                          │   CLOSURE    │                 │
│                                   │              │                 │
│                                   └──────────────┘                 │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Phase Summary

| Phase | Purpose | Key Activities | Outputs |
|-------|---------|----------------|---------|
| **1. Design & Spec** | Define what to build | Write spec, iterate with AI, review with team | Approved specification |
| **2. Planning** | Determine how to build | AI plan mode, identify files, sequence tasks | Implementation plan |
| **3. Implementation** | Build it | Create branch, write code, commit changes | Working code on branch |
| **4. Validation** | Verify it works | Run tests, check CI/CD, review deployed resources | Passing tests, green CI |
| **5. Closure** | Complete the work | Update docs, close tickets, merge PR | Merged PR, updated docs |

## Phase Details

### Phase 1: Design & Spec

**Goal**: Clearly define the problem and proposed solution before writing code.

**Activities**:
- Create specification document using [spec template](../03-templates/spec-proposal.md)
- Iterate with AI to refine requirements and approach
- Identify edge cases, constraints, and dependencies
- Review with team for feedback
- Mark spec as `Decided` when approved

**Outputs**:
- Specification document in `docs/specs/`
- Clear problem statement and success criteria
- Team alignment on approach

[Detailed Guide →](01-design-spec.md)

### Phase 2: Planning

**Goal**: Create a concrete implementation plan before coding.

**Activities**:
- Enter AI plan mode
- Identify all files that need changes
- Determine sequence of modifications
- Identify cross-repo dependencies
- Document the plan for review

**Outputs**:
- Implementation plan (in AI session or TODO.md)
- File change manifest
- Dependency order

[Detailed Guide →](02-planning.md)

### Phase 3: Implementation

**Goal**: Execute the plan with AI assistance.

**Activities**:
- Create feature branch
- Implement changes following the plan
- Commit incrementally with meaningful messages
- Push to remote for CI
- Create PR when ready for review

**Outputs**:
- Code changes on feature branch
- Passing local tests
- Pull request

[Detailed Guide →](03-implementation.md)

### Phase 4: Validation

**Goal**: Ensure the implementation is correct and complete.

**Activities**:
- Run full test suite
- Monitor CI/CD pipeline
- Verify deployed resources (if applicable)
- Test integration with dependent systems
- Address review feedback

**Outputs**:
- All tests passing
- CI pipeline green
- Review approval

[Detailed Guide →](04-validation.md)

### Phase 5: Closure

**Goal**: Complete the work and update all artifacts.

**Activities**:
- Update README.md if behavior changed
- Update spec status to `Implemented`
- Update CLAUDE.md if new patterns established
- Close Jira tickets (if applicable)
- Merge PR
- Clean up feature branch

**Outputs**:
- Merged code in main branch
- Updated documentation
- Closed tickets

[Detailed Guide →](05-closure.md)

## Iteration Patterns

### Within a Phase

Each phase may involve multiple iterations:

- **Design**: Multiple spec revisions based on feedback
- **Planning**: Refined plans as complexity is discovered
- **Implementation**: Incremental commits toward working solution
- **Validation**: Bug fixes based on test failures

### Across Phases

Sometimes you need to return to an earlier phase:

- **Validation → Implementation**: Tests reveal bugs to fix
- **Validation → Design**: Testing reveals fundamental design issues
- **Implementation → Planning**: Unexpected complexity requires re-planning
- **Closure → Design**: Document updates reveal spec gaps

The goal is forward progress, but don't hesitate to step back when needed.

## Phase Transitions

### Design → Planning

Transition when:
- ✅ Spec has status `Decided`
- ✅ Team has reviewed and approved
- ✅ Success criteria are clear
- ✅ Major questions are resolved

### Planning → Implementation

Transition when:
- ✅ All files to modify are identified
- ✅ Implementation sequence is clear
- ✅ Dependencies are mapped
- ✅ Plan is documented (AI session or TODO.md)

### Implementation → Validation

Transition when:
- ✅ Core functionality is complete
- ✅ Local tests pass
- ✅ Code is pushed to feature branch
- ✅ PR is created (or ready to create)

### Validation → Closure

Transition when:
- ✅ All tests pass (local and CI)
- ✅ PR is approved
- ✅ Integration tested (if applicable)
- ✅ No blocking issues remain

### Closure → Complete

Transition when:
- ✅ PR is merged
- ✅ Documentation is updated
- ✅ Tickets are closed
- ✅ Branch is cleaned up

## Multi-Session and Parallel Work

The lifecycle above assumes a single human-AI session. For features that span multiple sessions or involve multiple agents working in parallel, additional patterns apply:

- **State persistence** - Feature lists and progress files that carry context across sessions
- **Handoff protocols** - Git commits as session boundaries with structured start/end sequences
- **Worktree isolation** - One git worktree per agent to prevent interference
- **Work decomposition** - Breaking features into items that are independently completable and verifiable

[Multi-Session Patterns Guide →](multi-session-patterns.md)

## Adapting the Lifecycle

### Small Changes

For trivial changes (typo fixes, config tweaks):
- Skip formal spec—describe in commit message
- Planning phase may be a quick mental check
- Full validation still applies

### Urgent Fixes

For production issues:
- Start with Implementation (get the fix in)
- Do Validation rigorously
- Circle back to Design/Closure after resolution
- Create incident retrospective document

### Large Features

For complex features:
- Consider multiple cycles (one per major component)
- More formal specs with detailed alternatives analysis
- More comprehensive planning with explicit TODO.md
- Extended validation with staged rollout

## Beyond the Cycle

Your AI configuration (CLAUDE.md, .cursorrules) evolves alongside your project. As patterns emerge and tools change, your config should adapt.

- Add rules when you correct AI behavior three times for the same issue
- Promote SHOULD to MUST when violations cause real problems
- Restructure when the file becomes hard to scan
- Review quarterly to prune stale content

See [Configuration Evolution](06-config-evolution.md) for detailed guidance on maintaining your AI configuration over time.

## See Also

- [Design & Spec Phase](01-design-spec.md)
- [Planning Phase](02-planning.md)
- [Implementation Phase](03-implementation.md)
- [Validation Phase](04-validation.md)
- [Closure Phase](05-closure.md)
- [Multi-Session Patterns](multi-session-patterns.md)
- [Configuration Evolution](06-config-evolution.md)
- [Spec Template](../03-templates/spec-proposal.md)
- [TODO Template](../03-templates/TODO.md)
