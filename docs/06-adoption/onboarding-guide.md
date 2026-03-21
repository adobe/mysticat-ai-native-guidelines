# Onboarding to an AI-First Team

## Purpose

This guide helps new engineers get productive on a team that practices AI-first development. Whether you are a recent hire, a transfer from another team, or an experienced engineer encountering AI-first workflows for the first time, the steps below give you a structured path from day one to independent contribution.

## What is Different About AI-First

Before diving into the steps, it helps to name the things that will feel unfamiliar:

- **Docs are working memory, not afterthoughts.** Specifications, CLAUDE.md files, and decision records are living artifacts that the team - and AI assistants - rely on daily. If a doc is out of date, the AI gives bad advice. Keeping docs current is part of the work, not a chore that follows it.
- **AI is a pair programmer, not a search engine.** You will work with AI assistants in long, context-rich sessions - not one-off queries. The quality of the output depends on the quality of the context you provide.
- **Async-first communication.** Design happens in specs and PRs, not hallway conversations. This means decisions have a paper trail, and you can catch up by reading rather than asking around.
- **Rules are encoded, not tribal.** Critical rules live in configuration files (CLAUDE.md, .cursorrules) where AI assistants enforce them automatically. Read these files early - they tell you more about how the team works than most onboarding decks.

## Step 1: Understand the Philosophy

Start by reading the team's foundational documents:

1. **Read the AI-first philosophy.** Understand the core principles: spec-driven development, conversation as context, guardrails over guidelines, documentation as code, and multi-agent consistency. See [AI-First Development Philosophy](../01-foundations/philosophy.md).
2. **Read the development lifecycle.** Understand the 5-phase cycle (Design, Planning, Implementation, Validation, Closure) and how each phase uses AI differently. See [Development Lifecycle Overview](../02-lifecycle/overview.md).
3. **Understand roles.** AI handles generation, exploration, and enforcement. Humans own decisions, review, and accountability. The AI writes code with you, not for you - you are responsible for everything that ships.

Do not rush this step. The philosophy shapes every practice that follows.

## Step 2: Learn the Rules

Every AI-first team encodes its standards in configuration files. Find and read yours:

1. **Read CLAUDE.md** (or equivalent). Start at the workspace level, then check the project level. These files contain the MUST and SHOULD rules that govern how both humans and AI assistants work on the codebase. If your team uses a workspace repository, these files are provided automatically when you run `init.sh` - but you still need to read and understand them.
2. **Understand the rule hierarchy.** MUST rules are non-negotiable - violations cause real problems (security breaches, broken builds, data loss). SHOULD rules are strong recommendations with valid exceptions. See [MUST Rules](../05-guardrails/must-rules.md) and [SHOULD Rules](../05-guardrails/should-rules.md).
3. **Check for tool-specific configs.** If the team uses Cursor, look for `.cursorrules`. If the team uses Copilot, check for `.github/copilot-instructions.md`. These extend the base rules for specific editors.
4. **Read the anti-patterns.** Knowing what not to do is as valuable as knowing the workflow. See [Anti-Patterns](../05-guardrails/anti-patterns.md).

You do not need to memorize every rule. The AI assistant reads these files and enforces them during your sessions. But you need to understand them well enough to recognize when AI output violates the spirit of a rule, even if it satisfies the letter.

## Step 3: Explore the Codebase with AI

This is where AI-first onboarding diverges from traditional onboarding. Instead of reading code in isolation, use your AI assistant as a guide:

1. **Ask the AI to explain the architecture.** Point it at the codebase and ask high-level questions: "What are the main components?", "How does data flow from the API to the database?", "Where does authentication happen?" If your workspace includes agent definitions (role-based or service-specific), these give the AI deep context about individual components - use them to get more targeted explanations.
2. **Walk through a recent PR.** Pick a merged PR from the last sprint and ask the AI to explain each change - what it does, why it was needed, and how it fits into the broader system.
3. **Trace a feature end-to-end.** Pick a user-facing feature and follow it through the stack with AI help. This builds a mental model faster than reading files in isolation.
4. **Read the specs.** If the team keeps design specs in the repo, read a few recent ones. They capture not just what was built, but why certain alternatives were rejected.

Resist the urge to skim. The goal of this step is building a mental model of the codebase, not shipping code. Time invested here pays off in every task that follows.

## Step 4: Start Small

Pick a small bug fix or minor enhancement for your first contribution. Use it to practice the full workflow:

1. **Write a spec or contract.** Even for small changes, practice writing down what you intend to change and why. See [Spec/Proposal Template](../03-templates/spec-proposal.md) for project-level specs and [Contract Template](../03-templates/contract.md) for component-level contracts.
2. **Use AI to generate tests first.** Describe the expected behavior and let the AI write the test cases. Review them carefully - this is where you learn what the AI understands about the codebase and where it gets confused.
3. **Implement with AI assistance.** Let the AI draft the implementation, but review every line. Ask it to explain anything you do not understand. Do not accept code you cannot explain to a teammate.
4. **Follow the PR process.** Create a feature branch, commit incrementally, push for CI, and open a PR. If your team requires AI disclosure in PRs, include it.
5. **Respond to review feedback.** Your first PR will likely get comments. This is normal and valuable - it teaches you the team's unwritten standards that configuration files do not capture.

## Step 5: Graduate to Larger Work

As you build codebase familiarity and workflow confidence, take on progressively larger tasks:

- **Bug fixes** - Build confidence with the PR and review process
- **Small features** - Practice the full lifecycle: spec, plan, implement, validate, close
- **Cross-component work** - Learn how different parts of the system interact
- **Design work** - Write specs for others to implement, using AI to explore trade-offs

Each step up requires more judgment about when to trust AI output and when to push back. That judgment comes from the mental model you built in Steps 3 and 4.

## Common New-Joiner Mistakes

### Over-relying on AI without learning the codebase

AI can generate plausible code for a codebase it has never seen. If you accept that code without understanding the system, you will ship changes that technically work but violate architectural assumptions. Step 3 exists to prevent this. Do it thoroughly.

### Accepting AI output without review

AI writes confident-sounding code that is sometimes wrong. It hallucinates APIs, invents config options, and misunderstands business logic. You are the reviewer. If you cannot explain what a line does and why it belongs, do not commit it.

### Skipping contracts for "simple" changes

Small changes have a way of becoming large ones. Writing down your intent - even in a few sentences - forces you to think before you code. It also gives reviewers context they would otherwise have to guess at.

### Treating AI sessions as throwaway

Long AI sessions build context. If you start a new session for every question, you lose the accumulated understanding from the previous conversation. Treat sessions as working sessions, not search queries.

### Ignoring the configuration files

CLAUDE.md and related files are not bureaucracy - they are the team's collective memory of what matters. Ignoring them means the AI gives you generic advice instead of team-specific guidance.

## See Also

- [AI-First Development Philosophy](../01-foundations/philosophy.md) - Core principles
- [Development Lifecycle Overview](../02-lifecycle/overview.md) - The 5-phase workflow
- [Workspace Setup](../01-foundations/workspace-setup.md) - Directory structure and configuration
- [MUST Rules](../05-guardrails/must-rules.md) - Non-negotiable requirements
- [SHOULD Rules](../05-guardrails/should-rules.md) - Strong recommendations
- [Anti-Patterns](../05-guardrails/anti-patterns.md) - Common mistakes to avoid
- [Claude Code Configuration](../04-configuration/ai-tools/claude-code.md) - CLAUDE.md patterns
- [Spec/Proposal Template](../03-templates/spec-proposal.md) - Template for design documents
- [Contract Template](../03-templates/contract.md) - Component-level Design by Contract specs

---

*This onboarding guide is adapted from the ASO UI team's new engineer workflow (Abhinav Saraswat, OneAdobe/experience-success-studio-ui).*
