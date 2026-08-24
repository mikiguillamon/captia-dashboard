# Project Constitution

## 1. Product intent

Product requirements take precedence over implementation convenience.
Implementation must not silently redefine product behavior.

## 2. Simplicity

Use the simplest architecture that satisfies current verified requirements.
Do not introduce abstractions, infrastructure, or dependencies solely for hypothetical future requirements.

## 3. Maintainability

Prefer explicit, understandable, well-bounded code over clever or highly compressed solutions.
A component should have a clear responsibility and understandable dependencies.

## 4. Architecture

Significant architectural decisions must be documented.
Decisions that are expensive or difficult to reverse require user approval and an ADR.

## 5. Testing

Critical business rules require automated tests.
Regression fixes should include a test capable of reproducing the original failure when practical.
Tests should verify externally meaningful behavior rather than implementation trivia whenever possible.

## 6. Quality

A task is not complete merely because code was written.
Relevant validation must pass before work is considered complete.

## 7. Security

Apply least privilege.
Never commit secrets.
Do not expose sensitive values through logs.
Validate untrusted input at appropriate trust boundaries.
Security-sensitive changes require explicit review.

## 8. Data

Data integrity has priority over implementation convenience.
Destructive or difficult-to-reverse migrations require explicit approval and a recovery or rollback strategy.
Prefer compatible, additive migrations before destructive changes when practical.

## 9. Dependencies

Prefer mature and actively maintained dependencies.
A major new dependency, paid service, vendor commitment, or substantial lock-in requires explicit justification and user approval.

## 10. Observability

Important failures must be diagnosable.
Critical workflows require adequate error reporting and operational visibility.

## 11. User interfaces

Accessibility, responsive behavior, loading states, empty states, error states, and keyboard interaction are part of implementation quality when relevant.

## 12. Documentation

Durable product and architectural decisions must survive beyond the conversation that produced them.
Update the relevant source of truth when such a decision changes.

## 13. Autonomous decisions

The agent may make reversible local implementation decisions autonomously.
The agent must escalate decisions defined as significant by `AUTONOMY_POLICY.md`.

## 14. Definition of done

Work is complete when:

1. Agreed requirements are implemented.
2. Relevant tests pass.
3. Type checking and linting pass where configured.
4. The project builds successfully where applicable.
5. Significant review findings are resolved.
6. Relevant documentation is current.
7. No known blocker is hidden or deferred without being recorded.
