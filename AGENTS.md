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
7. `.planning/` for product reference material (PRD, ADRs, roadmap, requirements). This is read-only reference: the active development lifecycle is no longer driven by GSD.
8. Existing implementation and tests for factual current-state evidence.

Do not preload every document. Read only what is relevant to the current task.

## Workflow

Superpowers is the active development workflow.

Work moves through: brainstorming → writing-plans → subagent-driven-development → finishing-a-development-branch.

GSD is no longer used. `.planning/` is not deleted: it remains product reference material
(PRD, ADRs, roadmap, the 155 v1 requirements) that continues to serve as the source of truth
for product behavior and scope. The active lifecycle — design specs, plans, and execution — is
handled by Superpowers, with its artifacts kept under `docs/superpowers/`.

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

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Captia Dashboard**

Portal de clientes y herramienta operativa interna que centraliza los servicios prestados a cada cuenta —normalmente ejecutados por sistemas externos (agentes, n8n, telefonía, chatbots)— aportando gestión, observabilidad, colaboración, supervisión, feedback, documentación, control y trazabilidad. Incluye un CRM exclusivamente interno que cubre el ciclo desde lead hasta cliente y conecta la relación comercial con las cuentas, organizaciones y servicios del portal. Sirve simultáneamente a usuarios internos (Superadmin, Dirección, Comercial, Account Manager, Técnico) y clientes (Administrador de cuenta, Administrador de organización, Usuario operativo), mostrando capacidades según usuario, rol, organización, servicio y configuración de autogestión.

**Core Value:** Que el cliente pueda entender y supervisar de forma clara qué servicios tiene contratados, su estado actual, actividad, volumen, resultados, evaluaciones e incidencias —sin acceder a las herramientas técnicas que los ejecutan— mientras el proveedor conserva control, trazabilidad y capacidad de intervención.

### Constraints

- **Despliegue**: Infraestructura autoalojada; sin SaaS externos salvo necesidad extrema con aprobación expresa (ADR-0007) — independencia operativa y datos sensibles.
- **Persistencia**: PostgreSQL compartido con RLS; sin base/esquema por cliente (ADR-0002) — operación simple con aislamiento fuerte.
- **Identidad**: Nativa y autoalojada; MFA obligatorio interno; sin IdP externo en el MVP (ADR-0003).
- **Cola**: Outbox transaccional en PostgreSQL; sin broker externo en el MVP (ADR-0005) — reflejar eventos aceptados en vistas en ≤30s (NFR-006).
- **Rendimiento**: Evento recibido → visible en ≤30 segundos (NFR-006); RPO ≈ 1h; RTO ≤ 24h; sin SLA contractual (NFR-008/009/010).
- **Datos**: Distinguir siempre cero / ausente / incompleto / desactualizado / error; no inventar valores; no representar lo desactualizado como actual (PRD §5.2, NFR-007/013).
- **Seguridad**: Datos operativos sensibles (emails, chats, transcripciones); least privilege; auditoría de impersonación con actor real (NFR-001/004/011); cambios de seguridad requieren revisión explícita (QUALITY_BAR).
- **Uso inicial**: Equipo interno + clientes reales; no lanzamiento SaaS público (PRD §12.1).
- **Calidad**: Validación obligatoria antes de dar trabajo por completado (CONSTITUTION §6, QUALITY_BAR): types, lint, tests relevantes, build; pruebas críticas de aislamiento, autorización, MFA, impersonación, idempotencia.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Fijado por decisiones existentes (no negociable en esta fase)
| Componente | Decisión | Fuente |
|------------|----------|--------|
| Base de datos | PostgreSQL autoalojado, compartido, con RLS | ADR-0002 |
| Topología | Monolito modular desplegado como unidad | ADR-0001 |
| Identidad | Nativa autoalojada (credenciales, sesiones, MFA); sin IdP externo | ADR-0003 |
| Eventos | Ledger canónico inmutable + proyecciones (no ES completo) | ADR-0004 |
| Trabajo asíncrono | Outbox transaccional + jobs persistidos en PostgreSQL; sin broker externo | ADR-0005 |
| Infraestructura | Autoalojada; sin SaaS salvo aprobación expresa | ADR-0007 |
## ⚠ DECISIÓN ABIERTA — requiere aprobación del usuario
### Opción A — Ruby on Rails 8.1 + Hotwire (RECOMENDADA) · Confianza: alta en versión, media-alta en ajuste
- Rails **8.1.x** es la rama soportada actual (8.0 EOL nov-2026); Ruby 3.4 recomendado. *Verificado: rubyonrails.org/releases, endoflife.date/rails (ago-2026).*
- **Solid Queue/Cache/Cable** = outbox/jobs/caché/pubsub sobre PostgreSQL puro → encaja 1:1 con ADR-0005 sin componentes extra.
- Generador de autenticación integrado como base para identidad nativa (ADR-0003); MFA vía TOTP con gema mantenida.
- Hotwire (Turbo+Stimulus) cubre portal responsive server-rendered sin SPA.
- ActiveRecord permite SQL crudo donde RLS lo exija (`execute("SET app.account_id=...")`).
- Riesgo: dependes del ecosistema Ruby del equipo.
### Opción B — Django 5.2 LTS + HTMX (+ DRF para API) · Confianza: alta en versión, media en ajuste
- **5.2 LTS** soportada hasta abr-2028 (Python 3.10–3.14); 6.x activas pero no LTS. *Verificado: endoflife.date/django (ago-2026).*
- Admin integrado acelera vistas internas del CRM; authn extensible (django-otp) para MFA.
- Jobs: sin equivalente nativo al trío Solid — requeriría django-tasks/Celery-con-broker-PG (más montaje propio para el patrón outbox).
- ORM menos cómodo para RLS agresiva que SQL crudo, aunque viable.
### Opción C — Full TypeScript (Next.js/Nuxt + Prisma/Drift sobre PG) · Confianza: media
- Un solo lenguaje en todo el stack; UI rica.
- Contraindicado relativo: identidad, outbox, jobs y RLS serían casi todo artesanales; mayor superficie de error en seguridad (prioridad #1 aquí).
## Qué NO usar (y por qué)
- **Redis/Memcached como requisito** — ADR-0005 fija PG; añadir Redis viola minimalismo operativo sin necesidad demostrada.
- **IdP externo** (Keycloak/Auth0) — ADR-0003 excluye IdP en el MVP.
- **Microservicios / colas gestionadas** — ADR-0001/0005.
- **Constructores no-code / low-code** para tipos de servicio — PRD §11.
- **SaaS de email/notificaciones** sin aprobación expresa — ADR-0007 (evaluar SMTP autoalojado).
## Versiones base propuestas (a confirmar en fase de scaffold)
- PostgreSQL ≥ 16 (elegir minor vigente al instalar; verificar extensiones para RLS — nativas).
- Runtime según opción: Ruby 3.4 / Python 3.12+ / Node LTS.
- Despliegue autoalojado con backups que cumplan RPO≈1h y restauración probada ≤24h.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:Superpowers defaults -->
## Workflow Enforcement

Work is driven through the Superpowers workflow: brainstorming → writing-plans →
subagent-driven-development → finishing-a-development-branch. Design specs and plans live under
`docs/superpowers/specs/` and `docs/superpowers/plans/`.

Do not start implementation on `main` without explicit user consent.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
