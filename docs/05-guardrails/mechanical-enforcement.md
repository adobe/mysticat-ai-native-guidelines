# Mechanical Enforcement

## The Principle

Human code review is a scarce resource. Agent-generated code arrives faster than humans can review it. When an agent produces 10 PRs in the time it takes a reviewer to finish one, the review queue becomes the bottleneck - and either quality drops (rubber-stamping) or throughput collapses (waiting).

The solution is not more reviewers. It is **mechanical enforcement**: automated checks that catch errors at the point of action, before the code reaches a reviewer. The goal is to make the review queue contain only code that has already passed every machine-verifiable check, so humans can focus on judgment calls that machines cannot make.

This is a harness design principle, not just a CI convenience. The faster the feedback loop, the better the agent performs - because it corrects mistakes immediately instead of compounding them across a session.

## Enforcement Points

Mechanical enforcement works at three levels, from fastest feedback to broadest coverage:

### 1. Edit-Time: Hooks and Linters

The fastest feedback loop. The agent gets an error message within seconds of making a mistake.

**Git pre-commit hooks** run before every commit. Use a standard git hook or a framework like husky/lint-staged:

```bash
#!/bin/bash
# .git/hooks/pre-commit (or via husky)
npm run lint -- --quiet
npm run typecheck
```

**Post-edit hooks** run after every file write, giving immediate feedback:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "./scripts/lint-changed.sh",
        "description": "Lint after editing"
      }
    ]
  }
}
```

See [ACI Design](../04-configuration/aci-design.md#3-integrate-feedback-at-the-point-of-action) for a complete lint-changed.sh script example that extracts the file path from `$CLAUDE_TOOL_INPUT`.

For structural boundary enforcement, tools like **dependency-cruiser** (Node.js) and **import-linter** (Python) let you declare architectural rules as config — each layer specifying what it may import. The **allowlist pattern** means new modules are blocked by default without requiring config updates:

```javascript
// .dependency-cruiser.cjs
module.exports = {
  forbidden: [
    {
      name: 'no-domain-imports-in-framework',
      from: { path: '^src/framework/' },
      to: {
        path: '^src/',
        pathNot: ['^src/framework/', '^src/event/', '^src/types\\.ts$'],
      },
    },
  ],
};
```

Chain them into the existing lint command so they run at every enforcement point:

```json
"scripts": {
  "lint:boundaries": "depcruise src",
  "lint": "eslint . && npm run lint:boundaries"
}
```

Both tools emit structured violations — file, rule, dependency path — satisfying the agent-friendly error message requirements without custom formatting.

**Why edit-time matters for agents**: An agent that gets a lint error immediately after writing a file can fix it in the same turn. An agent that discovers the error 10 commits later has to unwind significant work - or worse, builds more code on top of the broken foundation.

### 2. Commit-Time: Structural Tests

Structural tests verify architectural invariants - not just behavior, but the *shape* of the code. These catch mistakes that linters miss.

**Examples of structural tests:**

```typescript
// No direct database imports outside the data layer
test('data layer isolation', () => {
  const files = glob.sync('src/**/*.ts', { ignore: 'src/data/**' });
  for (const file of files) {
    const content = fs.readFileSync(file, 'utf-8');
    expect(content).not.toMatch(/import.*from ['"].*prisma/);
    expect(content).not.toMatch(/import.*from ['"].*knex/);
  }
});

// All API endpoints have corresponding test files
test('API test coverage completeness', () => {
  const endpoints = glob.sync('src/api/**/*.ts');
  for (const endpoint of endpoints) {
    const testFile = endpoint.replace('src/', 'test/').replace('.ts', '.test.ts');
    expect(fs.existsSync(testFile)).toBe(true);
  }
});

// No files exceed the maximum line count
test('file size limits', () => {
  const files = glob.sync('src/**/*.ts');
  for (const file of files) {
    const lines = fs.readFileSync(file, 'utf-8').split('\n').length;
    expect(lines).toBeLessThan(500);
  }
});
```

**Why structural tests work for agents**: Agents follow instructions well but lack architectural awareness. They will happily import a database client into a UI component if nothing stops them. Structural tests encode architectural boundaries as executable assertions - the agent cannot violate them without failing the test suite.

### 3. CI-Time: Pipeline Gates

CI gates catch everything that escaped edit-time and commit-time checks. They run the full test suite, security scans, and integration tests.

**Effective CI gates for agent workflows:**

- **MUST** run the full test suite (unit + integration)
- **MUST** run security scanning (dependency audit, secret detection)
- **SHOULD** run structural tests as a separate CI step (fast feedback)
- **SHOULD** enforce coverage thresholds on changed files
- **SHOULD** run performance benchmarks for performance-sensitive paths

The key design constraint: CI gates MUST be fast enough for agent-speed development. If CI takes 45 minutes, an agent's throughput drops to one PR per hour regardless of how fast it writes code.

**Target CI times:**
- Lint + typecheck: < 2 minutes
- Unit tests: < 5 minutes
- Integration tests: < 10 minutes
- Full pipeline: < 15 minutes

## Agent-Friendly Error Messages

When a check fails, the error message is the agent's only guidance for fixing the problem. Vague or human-oriented error messages cause agents to guess - often incorrectly.

### What Makes an Error Message Agent-Friendly

| Property | Bad | Good |
|----------|-----|------|
| **Specificity** | "Style violation" | "File src/api/users.ts line 42: function exceeds 50-line limit (current: 73 lines)" |
| **Actionability** | "Fix the imports" | "Move database import from src/ui/Dashboard.tsx to src/data/dashboard-service.ts - UI components must not import database modules directly" |
| **Format** | Free-form paragraph | Structured: file, line, rule, suggestion |
| **Scope** | "27 errors found" | Show the first 5 with full context, summarize the rest |

### Designing Custom Linter Rules

When you write custom lint rules or structural tests, write the error messages for agent consumption:

```typescript
// Bad: human-oriented error
throw new Error('Invalid import detected');

// Good: agent-oriented error
throw new Error(
  `Architecture violation in ${file}:${line}\n` +
  `Rule: data-layer-isolation\n` +
  `Found: import of '${importPath}' (database module)\n` +
  `Location: ${file} is in the UI layer (src/ui/)\n` +
  `Fix: Move the database call to a service in src/data/ and import the service instead\n` +
  `See: docs/architecture/layer-boundaries.md`
);
```

### Rules for Error Messages

- **MUST** include the file path and line number
- **MUST** name the rule or check that failed
- **SHOULD** include a concrete fix suggestion
- **SHOULD** reference documentation when available
- **SHOULD NOT** include more than 20 lines of output per error (agents lose context in long output)
- **MUST NOT** rely on color coding or terminal formatting (agents read plain text)

## Enforcing Invariants, Not Implementations

Mechanical enforcement works best when it checks *what must be true* rather than *how to do it*. This distinction matters for agent workflows:

**Invariant (good):** "Every API endpoint must return a JSON response with a `status` field"
- The agent can implement this any way it chooses
- The test verifies the outcome, not the approach

**Implementation detail (bad):** "Every API endpoint must use the `respondWithStatus()` helper"
- Forces a specific approach that may not fit every case
- The agent will use the helper even when a different approach would be better

### Examples

| Invariant | Implementation Detail |
|-----------|----------------------|
| "All exports are tested" | "Use describe/it blocks" |
| "No secrets in source" | "Use the SecretManager class" |
| "API responses have consistent shape" | "Use the ResponseBuilder" |
| "Errors include request IDs" | "Call addRequestId() in catch blocks" |

Enforce the invariant. Let the agent choose the implementation. If the agent consistently chooses a bad implementation, add a SHOULD rule in CLAUDE.md rather than a mechanical check.

## Throughput-Aware Merge Philosophy

Traditional merge discipline assumes human-speed development: a few PRs per day, each carefully reviewed. Agent-speed development can produce 10-30 PRs per day. The math changes.

### The Tradeoff

| Approach | Cost of Review | Cost of Bugs | Best For |
|----------|---------------|--------------|----------|
| **Traditional** (human review required) | High - blocks throughput | Low - bugs caught before merge | Durable substrate (auth, data, infra) |
| **Automated gates** (merge when CI passes) | Low - no queue | Medium - bugs caught after merge | Fluid substrate (features, experiments, UI) |

### When to Use Each

**Traditional review gates - MUST for durable substrate:**
- Authentication and authorization changes
- Data model and migration changes
- Infrastructure and deployment changes
- Security-sensitive code paths
- Changes to the CI/CD pipeline itself

These are the areas where the [2 AM test](ai-task-boundaries.md) applies: if a bug would wake someone up, a human must review it before merge.

**Automated gates with fast correction - SHOULD consider for fluid substrate:**
- Feature implementations behind feature flags
- UI component additions and modifications
- Test additions and improvements
- Documentation updates
- Dev tooling changes

For fluid substrate work, the cost equation favors speed: an agent produces a PR, CI validates it automatically, and if something breaks, a revert takes minutes. The cost of a 2-hour review queue is higher than the cost of an occasional revert.

### Designing for Fast Correction

To make automated merging safe, invest in:

1. **Comprehensive CI gates** - the more the pipeline catches, the less humans need to review
2. **Feature flags** - new features are dark-launched and enabled gradually
3. **Fast rollback** - one-command revert with confidence that it actually fixes the issue
4. **Monitoring and alerting** - detect regressions before users report them
5. **Small PRs** - each PR changes one thing, making reverts surgical

### Rules

- **MUST** maintain human review for durable substrate changes regardless of throughput
- **SHOULD** consider automated merge for fluid substrate work when CI coverage is comprehensive
- **SHOULD** track revert rate - if it exceeds 10%, tighten the automated gates
- **MUST NOT** auto-merge without a passing CI pipeline
- **MUST NOT** auto-merge changes that touch both durable and fluid substrate in the same PR

## Integrated Feedback Loops

The principle behind all mechanical enforcement: **the faster the feedback, the better the agent performs**. Every enforcement point is a feedback loop. Design them for speed.

### Feedback Loop Speed

| Feedback Point | Latency | Agent Impact |
|----------------|---------|-------------|
| Post-edit lint hook | ~1 second | Agent fixes in the same turn |
| Pre-commit check | ~5 seconds | Agent fixes before the commit |
| CI unit tests | ~2-5 minutes | Agent waits, then fixes |
| CI integration tests | ~10-15 minutes | Agent may have moved on; context switch to fix |
| Human review | ~2-24 hours | Agent session has ended; new session needed to address |

The goal is to push as many checks as possible toward the top of this table. Every check that moves from "CI-time" to "edit-time" reduces the cost of fixing a mistake by an order of magnitude.

### Practical Setup

**Minimum viable enforcement** (start here):
- Pre-commit hook: lint + typecheck
- CI: full test suite + security scan
- CLAUDE.md: rules for the top 5 mistakes agents make in your codebase

**Comprehensive enforcement** (grow toward this):
- Post-edit hooks: lint on every file write
- Pre-commit hooks: lint + typecheck + structural tests
- CI: full tests + security + coverage + performance benchmarks
- Custom lint rules with agent-friendly error messages
- Structural tests for architectural boundaries
- Automated merge for fluid substrate with monitoring

## See Also

- [MUST Rules](must-rules.md) - Non-negotiable requirements
- [SHOULD Rules](should-rules.md) - Strong recommendations
- [AI Task Boundaries](ai-task-boundaries.md) - Durable vs fluid substrate classification
- [Anti-Patterns](anti-patterns.md) - Common mistakes to avoid
- [Harness Engineering](../01-foundations/harness-engineering.md) - Environment audit mindset and feedback loop design
- [ACI Design](../04-configuration/aci-design.md) - Agent-friendly error messages and interface design
- [Multi-Session Patterns](../02-lifecycle/multi-session-patterns.md) - State persistence and handoff for agent workflows
