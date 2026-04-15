# Operating Modes: From Collaborator to Director

## From Collaborator to Director

The guidelines describe AI as a "core collaborator." That framing is correct - and incomplete. As teams mature their harness and clarify their substrate boundaries, the human role shifts along a spectrum from hands-on collaborator to architectural director. Both modes are valid. What determines where you operate is not preference - it is the strength of your harness and the layer you are working in.

## The Spectrum

Two endpoints, not a binary:

### Collaborator Mode

This is the current default.

- Human writes specs, reviews diffs line-by-line, guides implementation step by step
- AI writes code with the human, not just for the human
- Appropriate when: harness is young, test coverage is partial, domain is unfamiliar, work touches durable substrate
- This is where most teams start and where the guidelines' existing advice applies directly

### Director Mode

This mode is emerging, validated by practitioners.

- Human defines intent via specs, tests, and architectural constraints
- AI executes autonomously - potentially for hours, potentially overnight
- Human reviews results and behavior, not every line of code
- Appropriate when: harness is mature, test coverage is comprehensive, mechanical enforcement is strong, work is in the fluid layer
- Practitioners have reported producing 9KLoC in 4 days with AI as primary implementer, reviewing results rather than lines

Most work falls somewhere between these endpoints. A single session might start in director mode (well-understood feature in the fluid layer) and shift to collaborator mode (unexpected edge case touching the durable layer).

## What Determines Your Operating Mode

Two axes determine where you operate on the spectrum.

### Substrate Layer

The [durable vs fluid substrate](substrate-model.md) is the first axis.

- **Fluid layer**: Director mode is viable when the harness supports it. Failures are contained, rollback is fast, domain experts can ship here.
- **Durable layer**: Collaborator mode is the default regardless of maturity. Failures cascade. Authentication, data storage, APIs, infrastructure demand human eyes on the diff.
- **Boundary work**: Changes that cross from fluid to durable (e.g., adding a database column to support a feature) require collaborator-mode rigor at the boundary, even if the feature itself is fluid.

### AI-Native Maturity

The [maturity model](../07-leadership/ai-native-engineering-phase1.md) is the second axis.

| Maturity | Collaborator Mode | Director Mode |
|----------|-------------------|---------------|
| L0-L1 (AI-Resistant/Assisted) | Required | Not viable - harness too weak |
| L2 (AI-Aware Services) | Default | Possible for isolated, well-tested fluid work |
| L3 (AI-Debuggable Systems) | For durable layer | Viable for fluid layer with strong harness |
| L4 (AI-Native Organization) | For durable layer | Natural mode for fluid layer; harness makes it safe by design |

No cell says "director mode mandatory." The spectrum is about what is available, not what is required. Teams and individuals choose based on context.

## Prerequisites for Director Mode

Director mode is not about trusting AI. It is about trusting your harness.

Before operating in director mode, verify these prerequisites:

**Comprehensive test suite.** Not just unit tests - contract tests that verify behavior, integration tests that catch cross-component failures, and end-to-end tests for critical paths. If you cannot verify correctness by running the test suite, you cannot verify it by reviewing results.

**Mechanical enforcement of guardrails.** The [MUST rules](../05-guardrails/must-rules.md) are enforced by automation, not by human vigilance. Pre-commit hooks, CI gates, secret scanning, type checking. If a guardrail depends on someone reading the diff to catch violations, it is not ready for director mode.

**Staging validation gates.** Changes deploy to staging before production. Staging is representative enough to catch real issues. No direct-to-production paths for director-mode work.

**Observability.** You can verify behavior post-deploy through metrics, logs, traces, or alerts. If the only way to know something is wrong is a customer report, director mode is premature.

**Rollback capability.** You can undo a bad change quickly - within minutes, not hours. Feature flags, blue-green deployments, or fast reverts. Director mode assumes some changes will be wrong; fast rollback limits the blast radius.

**Assessment**: If you are unsure whether your harness meets these prerequisites, it does not. Start in collaborator mode, invest in the harness, and transition gradually.

## Results-Based Review

The review practice evolves along the spectrum.

**Current default: Review the diff.** Read what changed, verify it matches intent, check for security and correctness issues. This is the starting point described in the [guardrails](../05-guardrails/must-rules.md) and the [experienced engineer's guide](../07-leadership/experienced-engineers-guide.md). It remains the right default.

**Emerging trajectory: Review the results.** Tests pass. Staging behaves correctly. Observability confirms expected patterns. The diff is available for spot-checking, but the primary verification is behavioral, not textual.

This trajectory is not yet the recommended default. It is an acknowledgment of where practices are heading as harnesses mature. Teams earn results-based review by building the prerequisites above - not by deciding they are too busy to read diffs.

The progression is gradual:

1. Review every diff (L0-L1, all layers)
2. Review diffs for durable, spot-check fluid with strong tests (L2-L3)
3. Review durable diffs, verify fluid results (L3-L4, prerequisites met)

## What Does Not Change

The shift from collaborator to director does not weaken these fundamentals - it strengthens them:

**Specs get more important, not less.** In collaborator mode, you can course-correct mid-implementation through conversation. In director mode, the spec IS your steering input. Vague specs produce vague results. Director mode demands better specs than collaborator mode, not fewer.

**Architecture decisions remain human.** Which services exist, how they communicate, what the data model looks like, where the substrate boundary falls. AI executes within boundaries that humans set. Director mode delegates implementation, not judgment.

**Guardrails get stronger, not weaker.** The more autonomous the AI, the more the harness must compensate. Mechanical enforcement, staging gates, observability - these are not bureaucracy. They are the infrastructure that makes director mode safe.

**Accountability stays with the director.** "The AI did it" is not an incident postmortem. The human who defined the spec, set the constraints, and reviewed the results owns the outcome. Director mode is a delegation of execution, not a delegation of responsibility.

## See Also

- [Philosophy](philosophy.md) - Core AI-first principles
- [Substrate Model](substrate-model.md) - Durable vs fluid layers
- [Harness Engineering](harness-engineering.md) - Why the harness matters more than the model
- [Experienced Engineers Guide](../07-leadership/experienced-engineers-guide.md) - The identity shift
- [AI-Native Maturity](../07-leadership/ai-native-engineering-phase1.md) - Maturity levels and scorecard
- [Mechanical Enforcement](../05-guardrails/mechanical-enforcement.md) - Automated guardrails
- [MUST Rules](../05-guardrails/must-rules.md) - Non-negotiable requirements
