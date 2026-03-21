# MUST Rules

## Overview

MUST rules are **non-negotiable requirements**. Violations cause real problems: security breaches, data loss, broken builds, or significant rework. These rules have no exceptions.

AI assistants should treat MUST rules as hard constraints that cannot be overridden by user requests.

## Security

> Leaked credentials are the #1 cause of breaches. Input validation prevents injection attacks. Auth checks prevent unauthorized access.

### Secrets

- **MUST NOT** commit secrets (API keys, passwords, tokens) to version control
- **MUST NOT** hardcode secrets in source code
- **MUST NOT** paste secrets into AI chat sessions
- **MUST NOT** log secrets or sensitive data
- **MUST** use environment variables or secret managers for all credentials

### Input Validation

- **MUST** validate and sanitize all user input
- **MUST** use parameterized queries (never string concatenation for SQL)
- **MUST** escape output to prevent XSS
- **MUST** validate file uploads (type, size, content)

### Authentication/Authorization

- **MUST** verify authorization on every protected endpoint
- **MUST NOT** expose internal IDs that allow enumeration attacks
- **MUST** use secure password hashing (bcrypt, argon2)
- **MUST** implement rate limiting on authentication endpoints

## Version Control

> Force pushes destroy history and others' work. Direct commits bypass review. Stale branches cause merge conflicts and confusion.

### Commits

- **MUST NOT** force push to main/master branches
- **MUST NOT** commit directly to main/master (use PRs)
- **MUST** have passing CI before merging PRs
- **MUST NOT** commit generated files that should be built (node_modules, dist/, etc.)

### Branches

- **MUST** create feature branches for all changes
- **MUST** delete branches after merging
- **MUST NOT** reuse branches from unrelated work

### Code Review

- **MUST** have at least one approval before merging
- **MUST** address all blocking review comments
- **MUST NOT** self-merge without review (except trivial fixes with team agreement)

## Testing

> Broken tests caught locally cost minutes to fix. Broken tests caught in production cost hours or days. CI is the last line of defense.

### Before Committing

- **MUST** run tests locally before pushing
- **MUST** ensure linting passes
- **MUST** verify build succeeds

### Test Coverage

- **MUST** write tests for new functionality
- **MUST** update tests when modifying existing functionality
- **MUST NOT** commit code that breaks existing tests

### CI/CD

- **MUST** fix CI failures before continuing
- **MUST NOT** merge with failing CI
- **MUST** monitor deployments for errors

## Data

> Data loss is often irrecoverable. Schema changes without migrations cause deployment failures. Production data changes without backups are gambling.

### Migrations

- **MUST** create migration files for all schema changes
- **MUST** test migrations in non-production first
- **MUST** have rollback plan for data migrations
- **MUST NOT** modify production data without backup

### Backups

- **MUST** verify backup restoration works
- **MUST NOT** delete production data without confirmation
- **MUST** document data retention policies

## Documentation

> Outdated docs are worse than no docs - they actively mislead. AI assistants rely on CLAUDE.md being accurate to give correct guidance.

### Updates

- **MUST** update README when behavior changes
- **MUST** update API documentation when endpoints change
- **MUST** update spec status when implementation completes
- **MUST** keep CLAUDE.md current with project changes

### Accuracy

- **MUST NOT** leave outdated documentation
- **MUST** remove documentation for deleted features
- **MUST** mark deprecated features clearly

## Dependencies

> Every dependency is a liability - it can introduce vulnerabilities, break on updates, or become unmaintained. Unpinned versions cause "works on my machine" failures.

### Adding Dependencies

- **MUST** justify new dependencies (don't add for trivial functionality)
- **MUST** verify license compatibility
- **MUST** check for known vulnerabilities
- **MUST** pin versions for production dependencies

### Updates

- **MUST** review changelogs before major version updates
- **MUST** test after dependency updates
- **MUST NOT** blindly update all dependencies at once

## Infrastructure

> Infrastructure changes affect all users simultaneously. An unreviewed `terraform apply` can take down production. Staging catches issues before customers do.

### Terraform/IaC

- **MUST** run `terraform plan` before `apply`
- **MUST** review plan output for unexpected changes
- **MUST** use remote state with locking
- **MUST NOT** apply infrastructure changes without review

### Deployment

- **MUST** deploy to staging before production
- **MUST** have rollback procedure documented
- **MUST** monitor after deployment
- **MUST NOT** deploy on Fridays (or before holidays) without justification

## Communication

> Unlinked PRs lose context. Stale tickets mislead planning. Code without explanation becomes unmaintainable.

### Jira/Tickets

- **MUST** link PRs to relevant tickets
- **MUST** update ticket status when work starts/completes
- **MUST NOT** close tickets without verification

### Code Comments

- **MUST** explain "why" for non-obvious code
- **MUST NOT** leave TODO comments without ticket reference
- **MUST** remove commented-out code (use version control)

## Vibeproofing

**Vibeproofing** is the practice of protecting production systems from rapid, under-reviewed changes that feel productive but haven't been properly validated.

### The Problem

AI-accelerated development creates a new failure mode: code that "vibes well" in development but fails in production. The speed feels good, the code looks reasonable, but critical validation steps get skipped because everything flows so smoothly.

### Vibeproofing Principles

- **MUST** have automated gates that cannot be bypassed by enthusiasm
- **MUST** require tests before merge, regardless of how simple the change feels
- **MUST** deploy to staging before production, even for "obvious" fixes
- **MUST NOT** self-approve changes just because "AI wrote it correctly"
- **MUST NOT** skip review because the author is confident

### Vibeproofing Checklist

Before shipping any AI-assisted work:

- [ ] Tests pass (automated, not just "I ran it once")
- [ ] Another human reviewed the code (not just the AI)
- [ ] Deployed to staging and verified behavior
- [ ] Rollback procedure is documented and tested
- [ ] Monitoring alerts are in place for the new code paths

### Team Implementation

1. **Make gates automatic** — CI/CD should block, not warn
2. **Make review mandatory** — Branch protection requires approval
3. **Make staging required** — Production deploys require staging sign-off
4. **Make metrics visible** — Track time-to-production to catch rushing

The goal isn't to slow down—it's to ensure acceleration doesn't sacrifice reliability.

---

## Enforcement

### In CLAUDE.md

Include MUST rules in your CLAUDE.md:

```markdown
## MUST Rules

- MUST run `npm test` before committing
- MUST NOT commit to main directly
- MUST NOT hardcode credentials
```

### In settings.json

Use [deny rules](../04-configuration/ai-tools/permissions.md#deny-rules-as-defense-in-depth) to hard-block operations that violate MUST rules:

```json
{
  "permissions": {
    "deny": [
      "Bash(git push --force *)",
      "Bash(git push --force)",
      "Bash(git reset --hard *)",
      "Bash(rm -rf *)"
    ]
  }
}
```

CLAUDE.md rules are advisory - the AI follows them but can be overridden. Deny rules are enforced - the tool call is blocked regardless. Use both for critical rules.

### In Code Review

Reviewers should:
- Block PRs that violate MUST rules
- Not approve with "fix later" for MUST violations
- Escalate if MUST violations are being ignored

### In CI/CD

Automate where possible:
- Linting catches style violations
- Secret scanning catches committed secrets
- Branch protection enforces PR workflow
- Test requirements enforce coverage

## See Also

- [SHOULD Rules](should-rules.md) - Strong recommendations
- [Mechanical Enforcement](mechanical-enforcement.md) - Automated gates, structural tests, agent-friendly errors
- [Anti-Patterns](anti-patterns.md) - Common mistakes
- [Environment & Secrets](../04-configuration/env-secrets.md) - Secure secrets handling
