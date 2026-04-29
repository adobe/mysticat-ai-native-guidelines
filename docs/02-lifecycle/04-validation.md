# Phase 4: Validation

## Purpose

The Validation phase ensures the implementation is correct, complete, and ready for production. This phase catches issues before they reach main branch and verifies the implementation meets the spec.

## Validation Layers

### 1. Local Testing

Run tests before pushing:

```bash
# Run unit tests
npm test           # JavaScript
pytest             # Python
go test ./...      # Go

# Run linting
npm run lint       # JavaScript
ruff check .       # Python
golangci-lint run  # Go

# Run type checking
npm run typecheck  # TypeScript
mypy .             # Python
```

### 2. CI/CD Pipeline

Monitor automated checks:

**Typical Pipeline**:
```
Push → Lint → Unit Tests → Integration Tests → Build → Deploy (staging)
```

**Common CI Failures**:
| Failure | Cause | Fix |
|---------|-------|-----|
| Lint errors | Style violations | Run linter locally, fix issues |
| Test failures | Broken functionality | Debug and fix the test or code |
| Build failures | Missing dependencies, syntax errors | Check logs, resolve issues |
| Type errors | Type mismatches | Fix type annotations |
| Security scan | Vulnerable dependencies | Update packages |

### 3. Code Review

PR review should verify:

- **Correctness**: Does it do what the spec says?
- **Completeness**: Are all requirements addressed?
- **Quality**: Does it follow team patterns?
- **Testing**: Are tests adequate?
- **Security**: Any security concerns?

**Requesting AI Review**:
```
Review this PR against the spec at docs/specs/dashboard.md.
Check for:
- Missing requirements
- Edge cases not handled
- Security issues
- Test coverage gaps
```

### 4. Deployed Resource Verification

For infrastructure or backend changes:

**AWS Resources**:
```bash
# Verify resources exist
aws cloudformation describe-stacks --stack-name my-stack

# Check resource status
aws ecs describe-services --cluster my-cluster --services my-service

# Verify configuration
aws lambda get-function-configuration --function-name my-function
```

**Database Migrations**:
```bash
# Verify migration applied
SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;

# Check table structure
\d+ table_name  # PostgreSQL
DESCRIBE table_name;  # MySQL
```

**API Endpoints**:
```bash
# Test endpoint directly
curl -X GET https://staging.example.com/api/dashboard \
  -H "Authorization: Bearer $TOKEN"
```

### 5. Integration Testing

Verify components work together:

**API + Database**:
```bash
# Run integration tests
pytest tests/integration/ -v

# Or manual verification
curl http://localhost:8000/api/health
```

**Frontend + Backend**:
- Load staging environment
- Test key user flows manually
- Verify data displays correctly

**Cross-Service**:
- Test service-to-service communication
- Verify event propagation
- Check data consistency

## Validation Checklist

### Automated Checks

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Linting passes (no warnings)
- [ ] Type checking passes
- [ ] Security scan passes
- [ ] Build succeeds
- [ ] Deploy to staging succeeds

### Manual Verification

- [ ] Key user flows tested manually
- [ ] Edge cases verified
- [ ] Error states display correctly
- [ ] Performance acceptable
- [ ] No console errors (frontend)
- [ ] Logs look normal (backend)

### Review Verification

- [ ] Code reviewed by peer
- [ ] All review comments addressed
- [ ] Spec requirements traced to implementation
- [ ] No regression in existing functionality

## Handling Failures

### Test Failures

1. **Read the failure message** carefully
2. **Reproduce locally** if possible
3. **Fix the issue** - either code or test
4. **Push the fix** - new commit, not amend
5. **Verify CI** passes with fix

### CI Pipeline Failures

1. **Check the logs** for specific error
2. **Common causes**:
   - Flaky tests (retry first)
   - Environment differences
   - Missing dependencies
   - Timeout issues
3. **Fix and push** new commit

### Review Feedback

1. **Understand the feedback** - ask for clarification if needed
2. **Categorize**:
   - Must fix (blocking)
   - Should fix (important)
   - Could fix (nice to have)
3. **Address blocking issues first**
4. **Push fixes** as new commits
5. **Re-request review** when ready

## AI-Assisted Validation

### Reviewing Test Coverage

```
Analyze the test coverage for the dashboard feature.
What edge cases are not covered?
What integration scenarios should we test?
```

### Debugging Failures

```
This test is failing with error: [paste error]
The relevant code is in src/services/dashboard.py.
Help me understand why it's failing.
```

### Verifying Against Spec

```
Compare the implementation in this PR against the spec at
docs/specs/dashboard.md. Create a checklist showing which
requirements are met and which might be missing.
```

## Validation Patterns

### Staging Environment Testing

Before production:
1. Deploy to staging
2. Run smoke tests
3. Manual exploratory testing
4. Performance spot-check
5. Sign-off from QA (if applicable)

### Feature Flag Validation

If using feature flags:
1. Test with flag OFF (existing behavior unchanged)
2. Test with flag ON (new behavior correct)
3. Test flag toggle (no errors on switch)

### Rollback Testing

For critical changes:
1. Deploy new version
2. Verify functionality
3. Practice rollback
4. Verify rollback works
5. Re-deploy new version

## Checklist

Before moving to Closure:

- [ ] All automated tests pass (local and CI)
- [ ] All manual testing complete
- [ ] PR approved by reviewer
- [ ] Staging deployment verified (if applicable)
- [ ] No blocking issues remain
- [ ] Performance is acceptable
- [ ] Security review passed

## See Also

- [Closure Phase](05-closure.md)
- [Baseline Alignment](baseline-alignment.md) - Detecting drift between spec, plan, and implementation across review cycles
- [MUST Rules](../05-guardrails/must-rules.md) - Critical validation requirements
