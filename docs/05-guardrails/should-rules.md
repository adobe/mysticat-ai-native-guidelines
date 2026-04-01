# SHOULD Rules

## Overview

SHOULD rules are **strong recommendations** with valid exceptions. Following them leads to better outcomes, but there are legitimate reasons to deviate. When deviating, document why.

Unlike MUST rules, AI assistants can help you deviate from SHOULD rules when you have good reason.

## Code Quality

### Style

- **SHOULD** follow existing code style in the project
- **SHOULD** use consistent naming conventions
- **SHOULD** keep functions under 50 lines
- **SHOULD** keep files under 500 lines

*Exception: Legacy code being gradually refactored*

### Simplicity

- **SHOULD** implement the simplest solution that works
- **SHOULD** avoid premature optimization
- **SHOULD** avoid premature abstraction
- **SHOULD NOT** add features not in requirements

*Exception: Known scaling requirements justify upfront complexity*

### Comments

- **SHOULD** add comments for complex business logic
- **SHOULD** use JSDoc/docstrings for public APIs
- **SHOULD NOT** comment obvious code
- **SHOULD** keep comments up-to-date with code changes

*Exception: Self-documenting code with clear naming needs fewer comments*

## Architecture

### Patterns

- **SHOULD** follow established patterns in the codebase
- **SHOULD** use dependency injection for testability
- **SHOULD** separate concerns (UI, business logic, data access)
- **SHOULD NOT** create "god classes" that do everything

*Exception: Small utilities may not need full architectural patterns*

### Dependencies

- **SHOULD** prefer well-maintained dependencies
- **SHOULD** minimize dependency count
- **SHOULD** use standard library when sufficient
- **SHOULD NOT** reinvent the wheel for common functionality

*Exception: Critical functionality may warrant custom implementation*

### APIs

- **SHOULD** design APIs for clarity over brevity
- **SHOULD** version APIs from the start
- **SHOULD** return consistent error formats
- **SHOULD** document all public endpoints

*Exception: Internal-only APIs may have simpler requirements*

## Testing

### Coverage

- **SHOULD** aim for 80%+ code coverage
- **SHOULD** focus coverage on business logic
- **SHOULD** test edge cases explicitly
- **SHOULD NOT** test trivial getters/setters

*Exception: Higher coverage for critical systems; lower for prototypes*

### Test Quality

- **SHOULD** write readable test names that describe behavior
- **SHOULD** use AAA pattern (Arrange, Act, Assert)
- **SHOULD** avoid testing implementation details
- **SHOULD** keep tests independent (no shared state)

*Exception: Integration tests may need some shared setup*

### Speed

- **SHOULD** keep unit tests fast (<100ms each)
- **SHOULD** separate fast and slow tests
- **SHOULD** mock external dependencies in unit tests
- **SHOULD NOT** require network for unit tests

*Exception: Integration tests intentionally test real connections*

## Git Workflow

### Commits

- **SHOULD** use conventional commit format
- **SHOULD** make atomic commits (one logical change)
- **SHOULD** write descriptive commit messages
- **SHOULD NOT** combine unrelated changes in one commit

*Exception: WIP commits on feature branches before squash merge*

### Branches

- **SHOULD** keep feature branches short-lived (<1 week)
- **SHOULD** rebase on main regularly
- **SHOULD** use descriptive branch names
- **SHOULD NOT** let branches diverge significantly from main

*Exception: Long-running feature branches with regular sync*

### Pull Requests

- **SHOULD** keep PRs small (<400 lines changed)
- **SHOULD** write clear PR descriptions
- **SHOULD** respond to review comments within 1 business day
- **SHOULD** squash commits when merging

*Exception: Large refactors may require bigger PRs*

## Documentation

### Content

- **SHOULD** document the "why" not just "what"
- **SHOULD** include examples in documentation
- **SHOULD** keep documentation close to code
- **SHOULD** use diagrams for complex systems

*Exception: Simple utilities need minimal documentation*

### Maintenance

- **SHOULD** review documentation quarterly
- **SHOULD** archive rather than delete old docs
- **SHOULD** link related documentation
- **SHOULD NOT** duplicate information across documents

*Exception: Some duplication acceptable for standalone guides*

## Error Handling

### Approach

- **SHOULD** fail fast on invalid input
- **SHOULD** provide actionable error messages
- **SHOULD** log errors with context
- **SHOULD NOT** catch and silence errors

*Exception: Resilient systems may intentionally swallow some errors*

### User Experience

- **SHOULD** show user-friendly error messages
- **SHOULD** hide technical details from end users
- **SHOULD** provide recovery suggestions when possible
- **SHOULD NOT** expose stack traces in production

*Exception: Admin/debug modes may show more detail*

## Performance

### General

- **SHOULD** measure before optimizing
- **SHOULD** optimize for common case first
- **SHOULD** set performance budgets
- **SHOULD NOT** optimize prematurely

*Exception: Known bottlenecks can be addressed proactively*

### Database

- **SHOULD** add indexes for columns in WHERE clauses
- **SHOULD** paginate large result sets
- **SHOULD** use connection pooling
- **SHOULD NOT** query in loops (N+1 problem)

*Exception: Small datasets may not need pagination*

### Frontend

- **SHOULD** lazy load non-critical components
- **SHOULD** optimize images
- **SHOULD** minimize bundle size
- **SHOULD** use caching appropriately

*Exception: Simple internal tools may not need optimization*

## Communication

### Async

- **SHOULD** document decisions in writing
- **SHOULD** use issue trackers for task management
- **SHOULD** summarize meetings with action items
- **SHOULD** over-communicate on remote teams

*Exception: Urgent issues may require synchronous communication*

### Code Review

- **SHOULD** review within 1 business day
- **SHOULD** be constructive and specific
- **SHOULD** approve when concerns are minor
- **SHOULD NOT** nitpick style when linters exist

*Exception: Junior reviewers may need more time*

## AI Collaboration

### Working with AI Assistants

- **SHOULD** provide a spec or design before asking AI to implement
- **SHOULD** review AI-generated code diff-style rather than accepting whole files
- **SHOULD** break large tasks into phases rather than requesting everything at once
- **SHOULD** verify AI-generated tests independently confirm correctness (not just mirror the implementation)
- **SHOULD NOT** accept AI output without reading and understanding it

*Exception: Trivial changes (formatting, renaming) need less scrutiny*

### AI Configuration

- **SHOULD** maintain a CLAUDE.md (or equivalent) with project context and rules
- **SHOULD** keep AI configuration rules actionable and specific
- **SHOULD** review and prune AI configuration quarterly
- **SHOULD NOT** duplicate the same rules across multiple configuration files

*Exception: Some duplication between CLAUDE.md and .cursorrules may be needed for cross-tool support*

### AI-Generated Artifacts

- **SHOULD** capture plans and designs in persistent files, not just AI chat sessions
- **SHOULD** attribute AI-assisted work the same way as human work (ownership stays with the developer)
- **SHOULD** use AI to assist code review, not replace human judgment
- **SHOULD NOT** rely on AI sessions as documentation (sessions are ephemeral)

*Exception: Exploratory conversations that don't produce decisions need not be captured*

### Token Efficiency

- **SHOULD** default to Sonnet for routine tasks, reserving Opus for complex reasoning
- **SHOULD** set effort to medium for Sonnet-based agentic work, escalating to high only for complex tasks
- **SHOULD** audit MCP servers quarterly and disable those not used weekly
- **SHOULD** delegate data-heavy operations (bulk reads, searches, test runs) to subagents
- **SHOULD** check `/cost` or `/stats` at natural breakpoints (after features, before agent spawns)
- **SHOULD NOT** spawn multi-agent review panels for small PRs (scale review depth to PR size)

*Exception: Opus on high effort is justified for architecture decisions, complex debugging, or when Sonnet output quality is noticeably insufficient*

See [Token Efficiency](../04-configuration/token-efficiency.md) for the full guide.

## When to Deviate

### Document the Reason

When deviating from a SHOULD rule, add a comment:

```typescript
// DEVIATION: Using callback pattern instead of async/await
// Reason: Legacy API doesn't support promises, refactor planned in Q2
function legacyOperation(callback) {
  // ...
}
```

### Get Team Buy-In

For significant deviations:
1. Discuss with team
2. Document in decision record
3. Plan to address technical debt if appropriate

### Review Periodically

- Track deviations in tech debt backlog
- Revisit quarterly to see if exceptions still apply
- Refactor when feasible

## See Also

- [MUST Rules](must-rules.md) - Non-negotiable requirements
- [Mechanical Enforcement](mechanical-enforcement.md) - Automated gates and throughput-aware merge philosophy
- [Anti-Patterns](anti-patterns.md) - Common mistakes
