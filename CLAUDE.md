# AI-First Guidelines Repository

Read [AGENTS.md](AGENTS.md) for the content map and navigation. This file covers contribution rules for AI-assisted editing.

This is a **documentation-only** repository. All content is markdown files organized in numbered folders.

## Content Standards

### Writing Style

- **Mixed audience**: Team members, broader org, new hires
- **Strong guardrails**: Use MUST/MUST NOT for critical rules
- **Advisory tone**: Use SHOULD/SHOULD NOT for preferences
- **Concrete examples**: Every concept needs a practical example
- **Cross-linking**: Link related documents using relative paths

### Document Structure

All documents MUST include:
1. **Clear title** as H1
2. **Brief introduction** explaining the document's purpose
3. **Structured content** with logical headings
4. **Examples** where applicable

### Template Status Fields

Templates MUST use these status values:
- `Draft` - Initial creation, not reviewed
- `Review` - Ready for team review
- `Decided` - Approved and active
- `Implemented` - Fully executed
- `Superseded` - Replaced by newer document (link to replacement)

## File Organization

```
docs/
├── 01-foundations/     # Core concepts and setup
├── 02-lifecycle/       # Development phases
├── 03-templates/       # Copy-paste ready templates
├── 04-configuration/   # Tool-specific configs
├── 05-guardrails/      # Rules and anti-patterns
├── 06-adoption/        # Team adoption case studies
├── 07-leadership/      # Guidance for engineering leaders
├── examples/           # Concrete examples
├── plans/              # Design documents and RFCs
└── presentations/      # Marp slide decks
```

## Editing Guidelines

### Adding New Content

1. Determine the correct folder based on content type
2. Use consistent naming: `lowercase-with-dashes.md`
3. Add navigation entry to README.md, mkdocs.yml, and AGENTS.md (if it's a new section)
4. Cross-link from related documents

### Modifying Existing Content

1. Read the full document before editing
2. Maintain existing structure and style
3. Update any cross-references if needed
4. Verify relative links still work

### Templates

When editing templates in `03-templates/`:
- Keep placeholders in `[BRACKETS]` or `{CURLY_BRACES}`
- Include usage instructions at the top
- Provide a filled-in example section

## Multi-Persona Review Process

Opinion pieces and leadership documents SHOULD use a panel of persona reviewers that matches the document's audience. This produces stronger prose than single-pass editing.

### Personas

Define reviewers from the document's Reading Guide or target audience. For leadership docs, the standard panel is:

| Persona | Angle |
|---------|-------|
| VP of Engineering | Organizational impact, strategic framing |
| Director of Engineering | Middle-management reality, coalition building |
| Senior Staff Engineer | Technical credibility, peer-to-peer voice |
| Junior Engineer (2-3 yrs) | Downstream impact, authenticity check |
| Domain Expert (non-engineer) | Inclusivity, gatekeeping dynamics |
| Senior Technical Writer | Structure, voice, line-level craft |
| Author (DJ) | Voice consistency, final authority |

### Modes

**Brainstorm mode** - Use when creating new content. Each persona responds independently to brainstorm questions (e.g., "where should this section go, what voice, what to include"). Synthesize convergent ideas into an implementation plan.

**Review mode** - Use after content is written. Each persona provides: (1) Ship / Ship with changes / Needs work, (2) Grade, (3) What works, (4) What doesn't with specifics, (5) Exact text edits. Require unanimous "ship" before committing opinion pieces.

### Synthesis Rules

- Implement feedback where 3+ personas converge
- Decline outlier suggestions unless they identify a clear defect
- Always use the full panel (all 7) - partial panels miss perspectives
- After implementing changes, run another review round until unanimous ship

## Verification Checklist

Before committing changes:

- [ ] Document renders correctly in markdown preview
- [ ] All relative links work
- [ ] README.md and docs/index.md navigation updated if new file added
- [ ] Consistent with existing document style
- [ ] Examples are realistic and helpful
- [ ] No broken cross-references

## Git Workflow

- Create feature branches for changes
- PR titles should describe the content change
- Self-review markdown rendering before merging
