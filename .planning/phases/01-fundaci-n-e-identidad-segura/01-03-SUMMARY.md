---
phase: 01-fundaci-n-e-identidad-segura
plan: 03
subsystem: tenancy
tags: [memberships, rbac, roles-plantilla, excepciones-auditadas, invitaciones, impersonacion, audit-log, solid-queue]

# Dependency graph
requires:
  - phase: 01-01-walking-skeleton
    provides: Tenancy::Context, organizations con RLS, login base
  - phase: 01-02-identidad-mfa
    provides: MFA TOTP confirmable, Current, sesiones server-side revocables
provides:
  - Motor de permisos D-09: 8 roles plantilla PRD §3, herencia account→org y excepciones puntuales SIEMPRE auditadas (can?)
  - AC-001 en app+RLS: memberships + scoping por organización con selector y 403 ante acceso ajeno
  - TEN-11/FR-011 invitaciones gobernadas por capability invite_users + autogestión; token un-uso 7 días solo-digest
  - D-06 impersonación auditada end-to-end (re-auth, 30 min, banner UI-SPEC, actor real≠effective, notificación configurable)
  - REQUIRED-GATE de fase: suite E2E AC-001/003/004 + SEG-05/11 en verde
affects: [fase 2 CRM (roles), fase 3 API privada (OD-008 pendiente), todas las fases (can?/audit)]

# Tech tracking
tech-stack:
  added: []
  patterns: [role-scope-chain, exception-deny-wins, audit-par-de-actores, pending-session-flag, required-gate-suite]

key-files:
  created:
    - app/models/tenancy/membership.rb
    - app/models/tenancy/role_assignment.rb
    - app/models/tenancy/invitation.rb
    - app/models/audit_log.rb
    - app/models/impersonation.rb
    - app/controllers/concerns/organization_scoping.rb
    - app/controllers/admin/{invitations,impersonations}_controller.rb
    - app/controllers/invitations_controller.rb
    - app/jobs/impersonation_notification_job.rb
    - test/system/tenancy/isolation_ac_test.rb   # REQUIRED-GATE D-08
    - test/integration/security/audit_visibility_test.rb
    - test/system/admin/impersonations_test.rb
  modified:
    - app/models/user.rb (associations + can?)
    - app/models/current.rb (actor_real/effective)
    - app/controllers/concerns/authentication.rb (expiración sesiones)
    - app/controllers/application_controller.rb (impersonación + auditoría mutaciones)
    - app/controllers/organizations_controller.rb (scoping + primera org)
    - db/seeds.rb (usuarios 8 roles demo)

key-decisions:
  - "AuditLog adelantado a Task 1 para que las excepciones ya nazcan auditadas (AC del plan lo exigía antes de Task 4)"
  - "Visibilidad por ORGANIZACIÓN es responsabilidad de la capa app sobre la barrera RLS a nivel cuenta — detectado y corregido gracias al propio test de leak"
  - "Current.actor_real = impersonation.initiator SIEMPRE; la sesión activa pertenece al objetivo"
  - "resolve_impersonation_state con prepend_before_action: expiración sale con gracia restaurando al empleado en vez de botar a login"
  - "Crear la PRIMERA organización de una cuenta requiere manage_organizations a nivel cuenta (sin org activa previa)"
  - "Rate limit entre suites: Rails.cache.clear global en TestCase.setup (memory store compartido por proceso provocaba fallos según orden)"
  - "System tests serializados (workers:1): Chrome headless paralelo provocaba crashes"

patterns-established:
  "ver key-decisions"

requirements-completed: [TEN-03, TEN-04, TEN-05, TEN-06, TEN-07, TEN-08, TEN-09, TEN-10, TEN-11, AUTH-04, AUTH-05, AUTH-06, AUTH-07, SEG-04, SEG-05, SEG-11]

# Metrics
duration: ~4h efectivas (misma sesión continua)
completed: 2026-08-26
---

# Phase 1 Plan 03: Tenancy completa Summary

**Motor de permisos con roles PRD §3 y excepciones auditadas, aislamiento AC-001..004 verificado E2E como gate de salida, invitaciones por autogestión e impersonación con actor real**

## Performance

- **Duration:** ~4h
- **Started:** 2026-08-25T22:10Z aprox.
- **Completed:** 2026-08-26T08:45Z
- **Tasks:** 5
- **Files modified:** ~35

## Accomplishments
- `User#can?` evalúa plantilla→herencia account→org→excepciones con deny-gana; toda alta/modificación de excepción escribe AuditLog con actor real
- Impersonación completa: re-auth obligatoria, 30 min, banner persistente copy exacto, auditoría par (real, effective) en start/end y en cada escritura durante suplantación, notificación configurable vía Solid Queue
- Suite REQUIRED-GATE verde: AC-001/003/004 en navegador real + SEG-05/SEG-11; `rake ci` completo 66 tests · rubocop 0 · brakeman 0

## Task Commits

1. **Task 1: Memberships + motor de roles** - `4011d23`
2. **Task 2: Scoping por organización + selector** - `3865a7c`
3. **Task 3: Invitaciones condicionadas** - `f07087a`
4. **Task 4: Impersonación auditada** - `0f824b2`
5. **Task 5: Suite aislamiento gate** - `c264442`

## Decisions Made
Ver key-decisions. Críticas: adelanto de AuditLog a T1, visibilidad por organización en capa app, actor_real desde Impersonation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Leak de organizaciones entre usuarios de la misma cuenta**
- **Found during:** Task 2 (security test)
- **Issue:** index listaba TODAS las orgs de la cuenta (contexto account) a usuarios con acceso parcial
- **Fix:** index usa lista de accesibles (membership/rol); RLS queda como segunda barrera a nivel cuenta
- **Verification:** security test + system AC-001 verdes
- **Committed in:** 3865a7c

**2. [Rule 3 - Blocking] Consumir token de invitación después de crear recursos**
- **Found during:** Task 3 (test reuso)
- **Issue:** token no se marcaba usado → ventana de replay
- **Fix:** update!(used_at) inmediatamente tras validar vigencia, antes de crear nada
- **Committed in:** f07087a

**3. [Rule 2 - Missing Critical] Actor real atribuido al cliente impersonado**
- **Found durante:** Task 4 (system banner mostraba 'petición de clientecito')
- **Issue:** Current.actor_real leía la sesión activa (=objetivo tras cambiar cookie)
- **Fix:** actor_real = Impersonation.initiator
- **Committed in:** 0f824b2

**4. [Rule 3 - Blocking] Rate-limit inter-suites y crashes de Chrome**
- **Found during:** Task 5 (rake ci intermitente)
- **Fix:** clear global de cache en setup + system tests serializados
- **Committed in:** c264442

---

**Total deviations:** 4 auto-fixed (1 missing critical, 3 blocking). **Impact:** seguridad/corrección; sin scope creep.

## Issues Encountered
- assert_text/assert_no_text de Capybara no aceptan mensaje como 2º arg (dos tests corregidos)
- Ferrum falla al visitar respuestas 4xx sin cuerpo → guards devuelven render plain
- rotp drift ya documentado en 01-02 reutilizado aquí sin coste

## User Setup Required
None.

## Next Phase Readiness
- FASE COMPLETA salvo verificación formal: ejecutar verifier
- OD-008 (catálogo atómico de permisos) sigue ABIERTO — escalar al usuario ANTES de Fase 3 (D-09)
- Puente users.account_id aún vivo (usado por current_account_id); migrar a memberships-only en Fase 2 junto al CRM

---
*Phase: 01-fundaci-n-e-identidad-segura*
*Completed: 2026-08-26*
