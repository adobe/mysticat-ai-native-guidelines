# Anti-Patterns

## Overview

Anti-patterns are common mistakes that seem helpful but lead to problems. Recognizing these patterns helps you avoid them—and helps AI assistants suggest better alternatives.

## AI-Specific Anti-Patterns

### Blind Acceptance

**Pattern**: Accepting AI suggestions without review.

**Why It's Bad**:
- AI can generate plausible but incorrect code
- Security vulnerabilities may be subtle
- Context AI misses can cause bugs

**Better Approach**:
- Review every suggestion critically
- Test AI-generated code
- Understand before accepting

---

### The "Fix It" Loop

**Pattern**: Repeatedly asking AI to fix errors without understanding them.

```
User: This doesn't work
AI: *fixes*
User: Still broken
AI: *fixes*
User: Now something else broke
AI: *fixes*
...
```

**Why It's Bad**:
- Root cause never identified
- Creates fragile code
- Time wasted on symptoms

**Better Approach**:
- Ask AI to explain the error first
- Understand the root cause
- Fix systematically

---

### Over-Reliance on AI

**Pattern**: Using AI for everything, including tasks you should understand.

**Why It's Bad**:
- Skill atrophy
- Unable to debug AI mistakes
- Can't evaluate AI suggestions

**Better Approach**:
- Use AI to accelerate, not replace, understanding
- Learn the fundamentals
- Periodically code without AI

---

### Prompt Stuffing

**Pattern**: Giving AI massive context dumps instead of focused requests.

**Why It's Bad**:
- AI loses focus on actual task
- Important details get buried
- Slower responses

**Better Approach**:
- Provide relevant context only
- Break large tasks into steps
- Use CLAUDE.md for persistent context

---

## Code Anti-Patterns

### Premature Abstraction

**Pattern**: Creating abstractions before they're needed.

```typescript
// Bad: Generic factory for single use case
class WidgetFactoryBuilder {
  private strategies: Map<string, WidgetStrategy>;
  // 200 lines of abstraction for one widget type
}

// Good: Simple direct implementation
function createWidget(type: string): Widget {
  // 20 lines that does what's needed
}
```

**Why It's Bad**:
- Harder to understand
- Harder to change (ironic!)
- Often guesses wrong about future needs

**Better Approach**:
- Build concrete solutions first
- Refactor when patterns emerge (rule of three)

---

### Gold Plating

**Pattern**: Adding features not in requirements.

**Why It's Bad**:
- Delays delivery
- More code to maintain
- May not be what users want

**Better Approach**:
- Stick to spec
- Note ideas for future consideration
- Get feedback on actual requirements first

---

### Copy-Paste Programming

**Pattern**: Duplicating code instead of refactoring.

```typescript
// Bad: Same validation logic in 5 places
function validateUserForm() { /* 30 lines */ }
function validateAdminForm() { /* same 30 lines with 2 changes */ }
function validateGuestForm() { /* same 30 lines with 3 changes */ }
```

**Why It's Bad**:
- Bugs multiply
- Changes needed in multiple places
- Inconsistent behavior

**Better Approach**:
- Extract common logic
- Use composition or inheritance appropriately
- AI can help identify duplication

---

### Stringly Typed

**Pattern**: Using strings where enums or types would be safer.

```typescript
// Bad: Magic strings everywhere
function setStatus(status: string) {
  if (status === "actve") { // typo = runtime bug
    // ...
  }
}

// Good: Type-safe enum
type Status = "active" | "inactive" | "pending";
function setStatus(status: Status) {
  // TypeScript catches typos
}
```

**Why It's Bad**:
- Typos cause runtime errors
- No autocomplete
- Refactoring is risky

**Better Approach**:
- Use enums or union types
- Define constants for repeated values

---

### Exception Swallowing

**Pattern**: Catching exceptions without handling them.

```typescript
// Bad: Silent failure
try {
  await saveData(data);
} catch (e) {
  // Hope it works next time!
}

// Good: Proper handling
try {
  await saveData(data);
} catch (e) {
  logger.error("Failed to save data", { error: e, data });
  throw new DataSaveError("Save failed", { cause: e });
}
```

**Why It's Bad**:
- Bugs are hidden
- Data may be lost silently
- Debugging becomes impossible

**Better Approach**:
- Log errors with context
- Decide: retry, fail fast, or fallback
- Never silently ignore

---

## Process Anti-Patterns

### "It Works on My Machine"

**Pattern**: Not testing in environment matching production.

**Why It's Bad**:
- Environment differences cause bugs
- Discovered only in production
- Hard to reproduce and fix

**Better Approach**:
- Use Docker/containers for consistency
- Test in staging environment
- Document environment requirements

---

### Big Bang Deployment

**Pattern**: Deploying all changes at once after long development.

**Why It's Bad**:
- Hard to isolate issues
- Rollback is all or nothing
- High risk, high stress

**Better Approach**:
- Deploy incrementally
- Use feature flags
- Keep deployments small and frequent

---

### Documentation as Afterthought

**Pattern**: Writing documentation only when "done."

**Why It's Bad**:
- Often never gets written
- Missing context and decisions
- Already moved on mentally

**Better Approach**:
- Document as you go
- Update specs as implementation evolves
- Treat docs as part of "done"

---

### Meeting-Driven Development

**Pattern**: Requiring meetings for every decision.

**Why It's Bad**:
- Slows down progress
- Not everyone needs to be involved
- Decisions often unclear afterward

**Better Approach**:
- Use async communication (specs, PRs)
- Document decisions in writing
- Reserve meetings for complex discussions

---

### Cowboy Coding

**Pattern**: Skipping process because "it's just a small change."

**Why It's Bad**:
- Small changes cause production outages
- No review catches mistakes
- Bad habits spread

**Better Approach**:
- Follow process for all changes
- Keep process lightweight enough to always use
- "Small changes" are where bugs hide

---

## Git Anti-Patterns

### The Mega-Commit

**Pattern**: One commit with all changes after days of work.

```
commit abc123
Author: developer
Date: Friday

    Implement feature X, fix bug Y, refactor Z, update deps, fix tests

    1,847 files changed, 23,451 insertions(+), 12,038 deletions(-)
```

**Why It's Bad**:
- Impossible to review
- Can't revert partial changes
- History is useless

**Better Approach**:
- Commit frequently
- One logical change per commit
- Squash before merge if needed

---

### Branch Hoarding

**Pattern**: Keeping branches open for weeks/months.

**Why It's Bad**:
- Massive merge conflicts
- Code reviews are overwhelming
- Features rot before merging

**Better Approach**:
- Merge within a week
- Break large features into smaller PRs
- Use feature flags for incomplete work

---

### Force Push to Shared Branches

**Pattern**: `git push --force` on branches others use.

**Why It's Bad**:
- Destroys others' work
- Creates confusion
- Can't recover easily

**Better Approach**:
- Never force push to main or shared branches
- Create new commits instead of amending and force-pushing
- If history is messy, clean it up through a squash merge at PR time

---

## Database Anti-Patterns

### The God Table

**Pattern**: One table with columns for everything.

```sql
-- Bad: Everything in one table
CREATE TABLE data (
  id, type, name, value1, value2, value3, value4, value5,
  metadata, created_at, updated_at, deleted_at, ...
);
```

**Why It's Bad**:
- No data integrity
- Impossible to query efficiently
- Schema changes affect everything

**Better Approach**:
- Normalize appropriately
- Create domain-specific tables
- Use proper relationships

---

### N+1 Queries

**Pattern**: Querying in a loop instead of batching.

```typescript
// Bad: N+1 queries
const users = await getUsers();
for (const user of users) {
  user.posts = await getPostsForUser(user.id); // Query per user!
}

// Good: Batch query
const users = await getUsers();
const userIds = users.map(u => u.id);
const posts = await getPostsForUsers(userIds); // Single query
// ... associate posts with users
```

**Why It's Bad**:
- Performance degrades with data size
- Database overloaded
- Latency multiplied

**Better Approach**:
- Use JOINs or batch queries
- Use ORMs with eager loading
- Monitor query counts

---

## Recognizing Anti-Patterns

### Signs You're in an Anti-Pattern

- "We've always done it this way"
- "It's faster to skip [process step]"
- "I'll fix it properly later"
- "It's too complicated to explain"
- "No one will notice"

### What To Do

1. **Recognize** - Acknowledge the pattern
2. **Understand** - Why does it seem attractive?
3. **Alternatives** - What's the better approach?
4. **Refactor** - Fix it when practical
5. **Prevent** - Add guardrails (CLAUDE.md, linting, etc.)

## See Also

- [MUST Rules](must-rules.md) - Non-negotiable requirements
- [SHOULD Rules](should-rules.md) - Strong recommendations
- [Mechanical Enforcement](mechanical-enforcement.md) - Prevent anti-patterns with automated gates
- [Multi-Session Patterns](../02-lifecycle/multi-session-patterns.md) - Avoid amnesia loops and shared worktree problems
