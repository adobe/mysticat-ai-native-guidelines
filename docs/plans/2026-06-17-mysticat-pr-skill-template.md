# Mysticat Pull Request Template

This is the canonical Mysticat PR body template — the companion artifact to the [PR skill design spec](2026-06-17-mysticat-pr-skill-design.md). Its purpose is to give every Mysticat PR one consistent, human-readable structure that the `create-pr` skill fills automatically from the current session.

**How it is used.** At implementation, the content **between the two `---` markers** below is copied verbatim into the `create-pr` skill's `assets/pr_template.md` (in `experience-success-skills`, `mysticat-dev` plugin). Everything outside the markers (this title, introduction, and example) is documentation and is NOT part of the PR body. When rendering a PR, the skill: replaces every `{{TOKEN}}`, strips every `AGENT:` instruction comment, and fills-or-drops each `[CONDITIONAL]` section. When a placeholder resolves to empty/null the skill removes the **entire line or bullet** (not just the token), so no dangling `- Spec:` remains. A `{{TOKEN}}` the skill cannot resolve at all (as opposed to a deliberately empty optional) is a bug — the skill fails rather than open a PR with raw placeholders. The fixed `🤖 Generated with Claude Code` footer at the end is static (lightweight AI-usage disclosure) and is part of the body. See the spec for the full fill-guide and the hard exclusions (no code snippets, no passing-test counts, no lint-success statements).

**Example (filled-in).** The body of PR adobe/mysticat-ai-native-guidelines#37 is a manually authored instance following this template's structure (the skill does not exist yet): abstract, reasoning, high-level overview, required-information links, affected workspace projects, and test plan, with the conditional sections (5, 6, 8) present or dropped according to what applied.

---

## 1. Abstract
<!-- AGENT: One or two sentences — what is this PR about, at a glance. No "why" here (that is section 2), just what it is. -->
{{ABSTRACT}}

## 2. Reasoning
<!-- AGENT: Why was this changed? The problem, motivation, or trigger. Reference the bug/incident/request that prompted it. Source: Jira/issue description, session context, commit messages. -->
{{REASONING}}

## 3. High-level overview of the changes
<!-- AGENT: Explain to a person who understands the system (not necessarily this code) WHAT this changes and HOW it changes the behaviour of the application. Prose + bullets. Describe behaviour deltas (before -> after), not a file-by-file diff. Call out anything user-visible or operationally visible. -->
{{OVERVIEW}}

## 4. Required information
<!-- AGENT: Links to supporting material. Include only the ones that exist; when a value is empty, remove the ENTIRE bullet line (do not leave a dangling "- Spec:"). Jira: workspace convention key (e.g. SITES-1234 / LLMO-1234). Look for spec/plan/ADR under docs/ in the touched repos and in session context. -->
- Jira / issue: {{JIRA_LINK}}
- Spec: {{SPEC_LINK}}
- Implementation plan: {{PLAN_LINK}}
- ADR(s): {{ADR_LINK}}
- Other: {{OTHER_LINKS}}

<!-- [CONDITIONAL] Include section 5 ONLY if the change affects or relies on other mysticat-workspace projects. Otherwise remove the whole section. -->
## 5. Affected / used mysticat-workspace projects
<!-- AGENT: List ONLY mysticat-workspace projects this change touches OR depends on at runtime. Example: this PR changes an API request shape -> list spacecat-api-service because it must serve it. For each, one line on the nature of the dependency (changed / consumed / contract). Do not list the repo the PR is in unless cross-repo coordination is needed. -->
{{AFFECTED_PROJECTS}}

<!-- [CONDITIONAL] Include section 6 ONLY if validation/verification outside the code was actually done. Otherwise remove the whole section. -->
## 6. Additional information outside the code
<!-- AGENT: Evidence gathered outside the code itself, ONLY if performed this session. Manual or agent validation/verification (what was checked and the result), and infrastructure observations (logs, queues, DynamoDB, S3, dashboards) with the concrete query or location. Do not fabricate; if nothing was done, the section is omitted. -->
{{OUTSIDE_CODE_INFO}}

## 7. Test plan
<!-- AGENT: End-to-end verification, NOT automated unit tests (CI runs those). Two parts:
  (a) What was tested locally beyond unit tests (manual e2e, local stack, through-API checks) and the result.
  (b) How to verify on each relevant environment: eph / dev / stage / prod — concrete steps, commands, or checks. Include only the environments that apply.
  Do NOT state how many tests pass or that static analysis/linting succeeded — CI owns that. -->
{{TEST_PLAN}}

<!-- [CONDITIONAL] Include section 8 ONLY if this PR depends on, or is related to, other PRs. Otherwise remove the whole section. -->
## 8. Deployment & merge order
<!-- AGENT: If this change depends on other PRs (must merge/deploy after them) or is related to other PRs (e.g. a coordinated cross-repo change), list them and state the required order to merge and deploy safely. One line per PR: link + relationship (depends-on / blocks / related) + why. End with the explicit ordered sequence. Omit the section entirely if this PR is independent. -->
{{DEPLOYMENT_ORDER}}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---
