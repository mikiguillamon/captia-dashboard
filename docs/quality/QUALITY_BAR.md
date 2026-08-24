# Quality Bar

## Normal development

Before completing a normal implementation phase:

1. Relevant type checking passes.
2. Relevant linting passes.
3. Relevant automated tests pass.
4. The application or package builds successfully when applicable.
5. Changed cross-component behavior has appropriate integration coverage.
6. Significant errors and edge cases are handled.
7. Documentation affected by the change is updated.
8. Code review has no unresolved high-impact finding.

## User interface work

In addition to normal development:

1. Loading state is considered.
2. Empty state is considered.
3. Error state is considered.
4. Responsive behavior is verified.
5. Keyboard interaction is verified where relevant.
6. Basic accessibility is verified.
7. Important visual states are reviewed by the user when design judgment is required.

## Data migrations

Before applying a significant migration:

1. Data impact is understood.
2. Compatibility during rollout is understood.
3. Recovery or rollback is defined when practical.
4. Destructive changes have explicit approval.
5. Relevant migration tests or verification exist.

## Security-sensitive changes

Require:

1. Explicit security review.
2. Authorization boundary verification.
3. Input validation review.
4. Secret handling review.
5. Logging review for sensitive information.
6. Relevant abuse cases or negative tests.

## Release or important milestone

Require:

1. Full relevant test suite.
2. Build verification.
3. Deep code review.
4. Security review where appropriate.
5. Migration review where applicable.
6. Documentation review.
7. Dependency review where significant changes occurred.
8. Human product acceptance for user-visible behavior.

## Coverage

Do not optimize for an arbitrary coverage percentage.
Coverage requirements should be derived from risk and critical behavior.
Critical business logic must have meaningful automated coverage.
