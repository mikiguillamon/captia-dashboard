# Phase 1: Fundación e identidad segura - Context

**Gathered:** 2026-08-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Monolito modular Ruby on Rails 8.1 operando con CI y PostgreSQL+RLS; identidad nativa completa (credenciales, recuperación, sesiones, MFA TOTP); modelo Cuenta→Organización→Usuario con roles plantilla, herencia y excepciones; impersonación auditada. Entrega los requisitos TEN-01..11, AUTH-01..07, SEG-01..05, SEG-11 verificables por AC-001..AC-007. No incluye CRM, servicios, eventos ni ninguna otra capacidad de fases posteriores.

Modo mvp: la fase termina con login/MFA/impersonación funcionando end-to-end sobre el esqueleto modular.

</domain>

<decisions>
## Implementation Decisions

> Capturadas en modo `--auto` (cadena autónoma aprobada): cada área se resolvió con la opción recomendada. El usuario puede revisar y corregir antes de ejecutar.

### Estructura del monolito
- **D-01:** Módulos como namespaces Ruby con contratos internos explícitos (sin usar tablas ajenas); NO extraer Rails::Engine por módulo en la fundación — engines solo cuando un límite necesite enforcement duro. — **Reversibility:** costly — migrar de namespaces planos a engines reescribe rutas/autoloads y dependencias cruzadas en todo el árbol.
- **D-02:** ADR-0008 (adopción de Rails 8.1) se redacta durante el scaffold conforme a CONSTITUTION §4.

### Autenticación y MFA
- **D-03:** Factor MFA único en MVP: TOTP (app autenticadora), sin SMS ni proveedor externo — coherente con ADR-0007 (autoalojado). Añadir factores futuros es cambio aditivo.
- **D-04:** Sesiones server-side persistidas (store en PostgreSQL) con cookie segura HttpOnly/SameSite; revocación explícita requerida por re-autenticación MFA, impersonación y cierre de sesión — no JWT stateless. — **Reversibility:** costly — sustituir el modelo de sesión toca login, MFA e impersonación completos.
- **D-05:** Recuperación de contraseña: token de un solo uso con expiración corta (≈30 min), enviado por SMTP autoalojado; todo token previo se invalida al restablecer.

### Impersonación
- **D-06:** Operativa: iniciar exige re-autenticación del interno; sesión de impersonación con expiración corta (≈30 min) y banner persistente en UI; auditoría registra actor real + impersonado + acción (FR-015..017). Notificación al cliente configurable por organización queda como setting (FR-018).

### Multi-tenancy y autorización
- **D-07:** Contexto de ámbito vía helper transaccional obligatorio (`SET LOCAL app.account_id / app.organization_id`) aplicado por capa central de persistencia; workers usan el mismo contexto; prohibido consultarlo eludiendo el helper. — **Reversibility:** one-way — omitirlo al inicio obliga a auditar/reescribir todas las consultas existentes para retrofit RLS (PITFALL #1).
- **D-08:** Suite de tests de aislamiento (AC-001..AC-004) es criterio de salida de la fase, no tarea posterior.
- **D-09:** Motor de permisos genérico (roles plantilla + herencia + excepciones puntuales registradas, FR-006..010) con catálogo inicial de capacidades mínimo derivado SOLO de los casos de uso de esta fase. ⚠ El catálogo definitivo de permisos atómicos es decisión abierta OD-008 del PRD: escalar al usuario antes de que la Fase 3 (API privada) dependa de permisos finos.

### Agent's Discretion
- Gemas concretas de TOTP/hashing y organización de carpetas interna dentro del namespace elegido.
- Herramienta de CI: diferida hasta confirmar dónde se hospeda el repositorio (hoy solo existe git local).
- Detalles de esquema de migraciones iniciales dentro de las fronteras ADR-0002.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Producto
- `docs/product/PRD.md` — §3 (roles y usuarios objetivo), §7 FR-001..FR-018 (alcance exacto de esta fase), §10 AC-001..AC-007 (aceptación), §15 glosario

### Arquitectura
- `docs/architecture/ARCHITECTURE.md` — identidad nativa, tenancy, persistencia compartida con RLS
- `docs/architecture/adr/ADR-0001-monolito-modular.md` — límites entre módulos, tablas nunca como contratos
- `docs/architecture/adr/ADR-0002-multitenancy-y-autorizacion.md` — ámbitos explícitos + RLS como segunda barrera
- `docs/architecture/adr/ADR-0003-identidad-nativa-autoalojada.md` — sin IdP externo; revisión de seguridad explícita obligatoria

### Gobernanza y calidad
- `docs/governance/CONSTITUTION.md` — §5 pruebas, §7 seguridad, §14 definición de done
- `docs/governance/AUTONOMY_POLICY.md` — qué decisiones requieren escalar al usuario
- `docs/quality/QUALITY_BAR.md` — sección "Security-sensitive changes" (obligatoria para identidad/MFA)
- `AGENTS.md` — precedencia de fuentes de verdad

### Planificación
- `.planning/research/STACK.md` — stack aprobado (Rails 8.1 + Hotwire + Solid) y versiones verificadas
- `.planning/research/PITFALLS.md` — pitfalls #1 (bypass tenant), #6 (impersonación sin actor real), #12 (crypto casero)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Ninguno — repositorio greenfield: solo documentación bootstrap (`docs/**`) y `.planning/`. No hay código, tests ni tooling previos.

### Established Patterns
- Convención de commits documental (`docs:`, `chore:`) ya establecida en historial.
- Estructura de fuentes de verdad bajo `docs/{product,architecture,governance,quality,operations}`.

### Integration Points
- El scaffold creará la app Rails en la raíz del repo junto a `docs/` y `.planning/`.
- `.gitignore` ya cubre `.env*`, claves y artefactos locales.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches (dentro del stack aprobado y los ADRs).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

Nota de gobierno: OD-008 (permisos atómicos definitivos) permanece abierto y se escala al usuario según AUTONOMY_POLICY antes de que otra fase dependa de él (ver D-09).

</deferred>

---

*Phase: 1-Fundación e identidad segura*
*Context gathered: 2026-08-24*
