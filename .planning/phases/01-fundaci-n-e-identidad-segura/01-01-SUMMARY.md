---
phase: 01-fundaci-n-e-identidad-segura
plan: 01
subsystem: infra
tags: [rails-8-1, postgresql, rls, hotwire, turbo, solid-queue, cuprite, brakeman]

# Dependency graph
requires:
  - phase: bootstrap
    provides: ADRs 0001-0007, PRD, stack aprobado (research/STACK.md)
provides:
  - Scaffold Rails 8.1.3.1 operativo end-to-end (login → organizaciones → Turbo) sobre PostgreSQL 16 con RLS FORCE verificado por prueba negativa
  - Tenancy::Context único (D-07) con with() y provisioning(); patrón de políticas RLS NULLIF-safe en db/policies/
  - Auth::SessionsController server-side con rate_limit 10/min y copy anti-enumeración UI-SPEC
  - rake ci + workflow GitHub Actions ruby3.4/postgres16 (gates test+rubocop+brakeman)
  - ADR-0008 adopción Rails 8.1; entorno dev docker postgres:16-alpine + rol no-superusuario
affects: [01-02 identidad/MFA, 01-03 memberships/impersonación, fases 2+ (todo el monolito)]

# Tech tracking
tech-stack:
  added: [rotp, rqrcode, brakeman, cuprite]
  patterns: [tenancy-context-transaccional, rls-deny-by-default-force, provision-block, auth-namespacing-auth, turbo-stream-crud]

key-files:
  created:
    - lib/tenancy/context.rb
    - db/policies/accounts_rls.sql
    - db/policies/organizations_rls.sql
    - docker-compose.dev.yml
    - db/init/01-roles.sql
    - docs/architecture/adr/ADR-0008-rails-81.md
    - .github/workflows/ci.yml
    - lib/tasks/ci.rake
    - app/controllers/auth/sessions_controller.rb
    - app/controllers/organizations_controller.rb
    - test/system/organizations_flow_test.rb
    - test/integration/tenancy/rls_context_test.rb
  modified:
    - config/database.yml
    - config/routes.rb
    - app/models/user.rb
    - app/views/layouts/application.html.erb
    - db/seeds.rb
    - Gemfile

key-decisions:
  - "Rol BD único no-superusuario captia_app como owner de objetos con FORCE RLS: la separación estricta owner-migraciones/runtime se formaliza en despliegue"
  - "Provisión de cuentas vía Tenancy::Context.provisioning + política accounts_provision_read: INSERT..RETURNING exige visibilidad SELECT de la fila insertada"
  - "Políticas RLS con NULLIF(current_setting(...),'')::bigint: tras SET LOCAL revertido el placeholder es '' y el cast directo lanzaría error en vez de negar"
  - "schema.rb (no structure.sql): políticas RLS se reaplican idempotentemente en test_helper con advisory lock; pg_dump ausente en host y CI"
  - "Sin fixtures :all: el chequeo previo de FK de FixtureSet escribe en pg_catalog.pg_constraint, vedado al rol no-superusuario"
  - "cuprite (CDP directo a Chrome) en lugar de selenium/chromedriver: sin driver del sistema ni versionado cruzado"
  - "users.account_id como puente provisional del skeleton hasta memberships (01-03 lo sustituye y elimina)"

patterns-established:
  - "Tenancy::Context.with(account_id:, organization_id:) — ÚNICO acceso a datos tenant (D-07)"
  - "Baseline de sesión '' para GUCs app.* antes del valor local: pool-safe entre requests/tests"
  - "Copy de errores uniforme vía constantes del controlador (anti-enumeración T1-06)"
  - "System tests con cuprite headless; labels asociados y aria-live obligatorios (UI-SPEC)"

requirements-completed: [TEN-01, TEN-02, SEG-01]

# Metrics
duration: ~2 sesiones (2026-08-24T22:03Z → 2026-08-25T19:41Z; ~5h efectivas)
completed: 2026-08-25
---

# Phase 1 Plan 01: Walking Skeleton Summary

**Scaffold Rails 8.1.3.1 end-to-end con RLS PostgreSQL probada por prueba negativa, login rate-limited y CRUD de organizaciones vía Turbo — gates rake ci en verde**

## Performance

- **Duration:** ~5h efectivas en 2 sesiones
- **Started:** 2026-08-24T22:03:14Z
- **Completed:** 2026-08-25T19:41:13Z
- **Tasks:** 5
- **Files modified:** ~40 (scaffold completo + código propio)

## Accomplishments
- Monolito Rails 8.1.3.1/Ruby 3.4.10 arrancable (`docker compose up -d && bin/rails db:prepare && bin/dev`) con Solid Queue/Cache/Cable instalados
- Aislamiento D-07 demostrado: sin `Tenancy::Context` las tablas tenant devuelven 0 filas (FORCE RLS) y la escritura directa por SQL es rechazada por PostgreSQL
- Login/logout server-side con cookie HttpOnly, contraseñas ≥12, rate limit 10/min/IP y respuesta uniforme que no revela existencia de email
- E2E automatizado con navegador real: login → empty state exacto UI-SPEC → crear organización (Turbo Stream) → listada → logout

## Task Commits

Each task was committed atomically:

1. **Task 1: Scaffold Rails 8.1 + ADR-0008 + entorno dev** - `cb5259d` (feat)
2. **Task 2: Tenancy::Context + Account/Organization con RLS** - `9b78a5c` (feat)
3. **Task 3: Auth generador Rails 8 + rate limit login** - `bccd7ed` (feat)
4. **Task 4: Dashboard organizaciones con escritura Turbo** - `92074fe` (feat)
5. **Task 5: CI + gates de calidad** - `dca0886` (feat)

## Files Created/Modified
- `lib/tenancy/context.rb` — helper transaccional único `with()` / `provisioning()` con set_config local + baseline ''
- `db/policies/*.sql` — políticas RLS FORCE con USING/WITH CHECK NULLIF-safe
- `app/controllers/auth/sessions_controller.rb` — login bajo Auth:: con rate_limit y GENERIC_ERROR
- `app/controllers/organizations_controller.rb` — index/create dentro de Context, turbo_stream append/remove
- `test/integration/tenancy/rls_context_test.rb` — prueba negativa de aislamiento (4 tests)
- `test/system/organizations_flow_test.rb` — flujo E2E con cuprite
- `.github/workflows/ci.yml`, `lib/tasks/ci.rake` — gate de calidad replicable en CI
- Ver lista completa en commits `cb5259d..dca0886`

## Decisions Made
Ver key-decisions en frontmatter. Destacadas: rol no-superusuario único con FORCE RLS (separación de roles diferida a despliegue), bloque `provisioning` para altas de cuentas, NULLIF para placeholders de sesión, schema.rb + reaplicación idempotente de políticas en tests, cuprite como driver system.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] accounts_rls usa políticas SELECT/UPDATE/INSERT separadas (no "patrón idéntico" a organizations)**
- **Found during:** Task 2 (tests RLS)
- **Issue:** accounts carece de columna account_id (su id ES la clave de tenant) y ActiveRecord siempre emite INSERT..RETURNING, que exige visibilidad SELECT de la fila insertada
- **Fix:** policies por comando + bloque `Tenancy::Context.provisioning` con política de lectura restringida al flag de provisión
- **Files modified:** db/policies/accounts_rls.sql, lib/tenancy/context.rb
- **Verification:** rls_context_test verde incluyendo cross-tenant invisible
- **Committed in:** 9b78a5c

**2. [Rule 2 - Missing Critical] NULLIF(current_setting(...), '')::bigint en todas las USING/WITH CHECK**
- **Found during:** Task 2 (error PG::InvalidTextRepresentation '')
- **Issue:** tras un SET LOCAL revertido, current_setting devuelve '' (no NULL) en la misma conexión del pool → cast fallaba en vez de negar
- **Fix:** migración NullifRlsSettings reaplica políticas con NULLIF
- **Files modified:** db/policies/{accounts,organizations}_rls.sql, db/migrate/*_nullif_rls_settings.rb
- **Verification:** suite completa verde; deny-by-default estable entre requests
- **Committed in:** 9b78a5c

**3. [Rule 3 - Blocking] Políticas RLS ausentes en BD de tests (schema.rb no serializa políticas)**
- **Found during:** Task 2 (primera ejecución de rls_context_test)
- **Issue:** pg_dump no disponible en host ni en imagen CI ruby → structure.sql inviable sin dependencia extra
- **Fix:** reaplicación idempotente de db/policies en test_helper dentro de transacción con pg_advisory_xact_lock (paralelismo seguro)
- **Files modified:** test/test_helper.rb
- **Verification:** tests paralelos verdes de forma repetida
- **Committed in:** 9b78a5c

---

**Total deviations:** 3 auto-fixed (1 missing critical, 2 blocking). **Impact on plan:** correcciones necesarias para que la doble barrera (app+RLS) sea real y testeable con el rol no-superusuario; sin scope creep funcional.

## Issues Encountered
- Generador de migraciones falla con sintaxis de llaves en zsh → migraciones escritas a mano
- Test de passwords del generador oficial dependía de fixtures (rol no-superusuario impide su chequeo FK en pg_catalog) → eliminado; 01-02 Task 4 reconstruye el flujo completo con tests propios
- Tests transaccionales: SET LOCAL vive hasta el fin del test (savepoints) → helper clear_tenant_context! simula el estado real fuera de contexto; documentado en el test

## User Setup Required
None - no external service configuration required. (SMTP se configura en 01-02.)

## Next Phase Readiness
- Ready for 01-02 (MFA TOTP): User/Session/Auth:: base operativos, letter_opener pendiente de configurar ahí
- Pendiente conocido: users.account_id puente se sustituye por memberships en 01-03 Task 1
- OD-008 (catálogo definitivo de permisos) sigue abierto — escalar antes de Fase 3 según D-09

---
*Phase: 01-fundaci-n-e-identidad-segura*
*Completed: 2026-08-25*
