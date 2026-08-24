# Autonomous Development Policy

## Default rule

Continue autonomously unless a decision crosses one of the escalation boundaries below.
Routine implementation choices do not require user approval.

## Decisions the agent may make autonomously

The agent may decide:

1. Internal file organization inside the approved architecture.
2. Function and variable names.
3. Small internal abstractions.
4. Test implementation details.
5. Logging implementation details.
6. Internal error handling consistent with existing policy.
7. Implementation order inside an approved phase.
8. Routine refactoring required by the active task.
9. Small utility extraction.
10. Lint and type fixes.
11. Straightforward bug fixes when intended behavior is already explicit.
12. Minor dependency updates consistent with current dependency policy.

## Decisions requiring user involvement

Stop and ask before deciding:

1. Product behavior visible to users.
2. UX flows, navigation, or interaction models.
3. Significant additions or removals from scope.
4. Core domain model changes.
5. Major database schema or data lifecycle decisions.
6. Breaking APIs or external contracts.
7. Authentication or authorization policy.
8. Privacy, data retention, or security policy.
9. Destructive or difficult-to-reverse migrations.
10. Major architectural changes.
11. Adoption or replacement of a principal framework.
12. New external paid services.
13. Significant vendor lock-in.
14. Destructive operations against external systems.
15. Production deployment decisions not already covered by an approved process.
16. Conflicting requirements.
17. Any proposal to reduce the agreed testing, security, or maintainability standard.

## Escalation format

When escalation is necessary, report only what the user needs to decide:

### Decision
Describe the decision.

### Why it matters
Explain the consequence.

### Options
List the realistic options.

### Recommendation
State the recommended option and why.

### Question
Ask one exact decision question.
