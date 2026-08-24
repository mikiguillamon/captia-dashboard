# Project operating rules

## Purpose

Build and maintain the product according to the project's documented sources of truth.

## Sources of truth

Use this precedence when sources conflict:

1. Direct decisions from the user in the current task.
2. `docs/product/PRD.md` for product behavior and scope.
3. `docs/governance/CONSTITUTION.md` for engineering principles.
4. Accepted ADRs in `docs/architecture/adr/` for architectural decisions.
5. `docs/architecture/ARCHITECTURE.md` for current architecture.
6. `docs/quality/QUALITY_BAR.md` for quality requirements.
7. `.planning/` for current GSD execution state and plans.
8. Existing implementation and tests for factual current-state evidence.

Do not preload every document. Read only what is relevant to the current task.

## Workflow

GSD Core is the primary project lifecycle orchestrator.

Do not automatically run Superpowers brainstorming, writing-plans, subagent-driven-development, or equivalent lifecycle workflows while executing a GSD-managed phase.

Superpowers may be used when explicitly requested or for a targeted problem where its specialized workflow is justified.

## Autonomy

Proceed autonomously for normal, reversible implementation decisions.

Do not ask for confirmation merely to continue working.

Ask the user before making a decision that materially affects:

1. User-visible product behavior.
2. UX or navigation.
3. Product scope.
4. Core domain or data models.
5. Public or external contracts.
6. Authentication, authorization, privacy, retention, or security policy.
7. Irreversible or difficult database migrations.
8. Major frameworks or architectural boundaries.
9. New paid vendors or significant vendor lock-in.
10. Production systems or destructive external actions.
11. Requirements that conflict with each other.
12. A reduction in the agreed quality bar.

When uncertain whether a decision is safely reversible, treat it as significant.

## Engineering

Prefer maintainability and clarity over cleverness.
Follow the existing architecture unless an approved decision changes it.
Do not add speculative abstractions for hypothetical future requirements.
Keep responsibilities bounded and interfaces explicit.
Do not silently change product behavior to simplify implementation.
Use existing project patterns before introducing new ones.

## Validation

Before declaring work complete, execute the validation appropriate for that change.

At minimum, use the project's configured:

1. Type checking.
2. Linting.
3. Relevant automated tests.
4. Build verification.

Use integration or end-to-end verification when the behavior crosses subsystem boundaries.
Never suppress or weaken a failing test merely to complete a task.

## Documentation

Update documentation when implementation changes a documented product, architectural, operational, or public behavior.
Create an ADR when a significant architecture decision is introduced or changed.

## Communication

Do not ask "should I continue?" during an approved phase.

If blocked by an important decision, provide:

1. The decision required.
2. Why it matters.
3. The viable options.
4. Tradeoffs.
5. Your recommendation.
6. The exact question the user needs to answer.

Keep routine progress concise.
