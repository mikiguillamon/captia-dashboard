# Bootstrap next steps: Captia Dashboard

This repository has the deterministic autonomous-development boilerplate installed.

## Important boundary

The bootstrap script intentionally did **not** create `.planning/`.
GSD Core owns `.planning/` and should create it from inside Codex.

## 1. Define product

Use `docs/operations/prompts/greenfield-product.md` in normal ChatGPT.
When product decisions are stable, produce the final document as:

`docs/product/PRD.md`

Do not initialize GSD from `PRD_TEMPLATE.md`.

## 2. Design architecture with Codex

Use `docs/operations/prompts/greenfield-architecture.md`.
Create/update:

- `docs/architecture/ARCHITECTURE.md`
- `docs/architecture/adr/ADR_NNNN_*.md`

## 3. Initialize GSD from Codex

In Codex, from this repository root, run:

`$gsd-new-project --auto @docs/product/PRD.md`

## 4. Review roadmap before execution

Use `docs/operations/prompts/greenfield-roadmap-review.md` before approving autonomous execution.

## Recommended first autonomous loop

`$gsd-discuss-phase N --assumptions`
`$gsd-plan-phase N`
`$gsd-execute-phase N`
`$gsd-verify-work N`

Keep human approval focused on product, UX, architectural decisions and quality gates.
