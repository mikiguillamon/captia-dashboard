---
phase: 02-crm-aprovisionamiento-y-cat-logo-de-servicios
plan: 02
subsystem: database
tags: [rails, postgres, rls, authorization, tenancy]

requires:
  - phase: 01
    provides: Tenancy::Context, patrón RLS NULLIF-safe
  - phase: 02-01
    provides: tablas CRM y de servicios a proteger
provides:
  - Políticas RLS deny-by-default para CRM y service_instances
  - Capacidades CRM/servicios por rol (ROLE_TEMPLATES)
affects: [03, 04, 05, 06, 08]

tech-stack:
  added: []
  patterns: [RLS vía organization→account para service_instances]

key-files:
  created:
    - db/migrate/20260828000004_add_rls_to_crm_and_service_models.rb
    - db/policies/crm_service_rls.sql
    - test/integration/tenancy/crm_service_rls_test.rb
  modified:
    - app/models/tenancy/role_assignment.rb
    - test/models/tenancy/role_assignment_test.rb
    - test/test_helper.rb

key-decisions:
  - "service_instances aisla por scope de organización → subconsulta a organizations.account_id (sin exigir GUC app.organization_id)."
  - "El catálogo atómico definitivo de capacidades sigue pendiente (OD-008); esta ampliación es provisional y se escalará antes de Fase 3."

patterns-established:
  - "RLS con USING/WITH CHECK NULLIF-safe igual que accounts_rls/organizations_rls."

requirements-completed: [CRM-01, CRM-02, CRM-03, CRM-04, CRM-05, CRM-06, SERV-01, SERV-02, SERV-03]

duration: ~20min
completed: 2026-08-28
---

# Plan 02: Aislamiento RLS + capacidades por rol

**Políticas RLS deny-by-default para CRM y service_instances, y ampliación de ROLE_TEMPLATES con capacidades CRM/servicios.**

## Performance
- **Tasks:** 3
- **Files modified:** 3 creados + 3 modificados

## Accomplishments
- RLS `FORCE` sobre crm_leads/contacts/opportunities, pipeline_stages y service_instances.
- Aislamiento cross-account verificado (test confirma que una cuenta no ve filas de otra).
- Capacidades por rol: comercial gestiona leads/contacts/opportunities/pipeline y desencadena conversión, pero NO el catálogo de servicios (AC-003); tecnico gestiona instancias; cliente gestiona instancias de su organización sin CRM.

## Decisions Made
- Ampliación provisional de ROLE_TEMPLATES (OD-008 sigue abierto; no se resuelve el catálogo atómico en esta fase).

## Deviations from Plan
None - plan ejecutado según lo escrito (los archivos previstos en el plan — `tenancy_scoping.rb`, `role_templates.rb`, `permission_engine.rb` — ya estaban consolidados en `role_assignment.rb` y `Tenancy::Context` en Fase 1).

## Issues Encountered
None.

## Next Phase Readiness
- Catálogo protegido; listo para validación de configuración (02-03) y UI (02-04+).

---
*Phase: 02-crm-aprovisionamiento-y-cat-logo-de-servicios*
*Completed: 2026-08-28*