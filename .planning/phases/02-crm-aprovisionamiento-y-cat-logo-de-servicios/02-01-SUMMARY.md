---
phase: 02-crm-aprovisionamiento-y-cat-logo-de-servicios
plan: 01
subsystem: database
tags: [rails, postgres, activerecord, sti, crm, service-catalog]

requires:
  - phase: 01
    provides: patrón Tenancy::Context, cuenta/organización, RLS base
provides:
  - Esquema CRM (leads, contacts, opportunities, pipeline_stages)
  - Catálogo de servicios (service_types, service_instances con STI)
  - Campos CRM en accounts
  - Semilla de tipos de servicio y pipeline stages
affects: [02, 03, 04, 05, 06, fases de CRM y servicios]

tech-stack:
  added: []
  patterns: [STI para tipos de servicio, JSONB para configuración]

key-files:
  created:
    - db/migrate/20260828000001_create_crm_models.rb
    - db/migrate/20260828000002_create_service_catalog_models.rb
    - db/migrate/20260828000003_add_crm_fields_to_accounts.rb
    - app/models/crm/lead.rb
    - app/models/crm/contact.rb
    - app/models/crm/opportunity.rb
    - app/models/pipeline_stage.rb
    - app/models/service_type.rb
    - app/models/service_instance.rb
    - app/models/email_assistant_instance.rb
    - app/models/chatbot_instance.rb
    - app/models/voice_assistant_instance.rb
  modified:
    - app/models/tenancy/account.rb
    - app/models/tenancy/organization.rb
    - config/initializers/inflections.rb
    - db/seeds.rb

key-decisions:
  - "El slug (índice único [:organization_id, :slug]) es el identificador estable; el nombre es etiqueta repetible (AC-002). Se retiró la validación de unicidad del nombre."
  - "Registrar 'CRM' como acrónimo en inflections para que Zeitwerk resuelva app/models/crm/ → CRM::*."

patterns-established:
  - "STI sobre service_instances con CONFIG_SCHEMA por subclase (validación en 02-03)."
  - "Campos de cuenta (status/source/industry/assigned_to) amplían Tenancy::Account con scope :active."

requirements-completed: [CRM-01, CRM-02, CRM-03, CRM-04, CRM-05, CRM-06, SERV-01, SERV-02, SERV-03]

duration: ~30min
completed: 2026-08-28
---

# Plan 01: Database Schema + Models + Migrations (Foundation)

**Esquema y modelos base del CRM y del catálogo de servicios, incluyendo STI y seeds.**

## Performance
- **Duration:** se estimaron ~30 min de cierre/validación (el código ya estaba escrito sin validar)
- **Tasks:** 4 (migraciones CRM, catálogo, campos en accounts, seeds)
- **Files modified:** 17 (creados) + 4 (modificados)

## Accomplishments
- 3 migraciones aplicadas y `db:migrate` ejecutado sin errores.
- Modelos CRM y de servicio con STI cargando correctamente.
- Inflection `CRM` registrado para autocarga Zeitwerk.
- Seeds de 3 ServiceType + 6 pipeline stages para la cuenta demo.

## Deviations from Plan

### Auto-fixed Issues

**1. Zeitwerk no resuelve el namespace `CRM`**
- **Issue:** `app/models/crm/*.rb` define `module CRM` pero Zeitwerk cameliza `crm/` → `Crm`, provocando `uninitialized constant CRM` / "expected file to define constant Crm::Contact".
- **Fix:** Registro `inflect.acronym "CRM"` en `config/initializers/inflections.rb`.
- **Files modified:** config/initializers/inflections.rb

**2. Falta asociación inversa `Organization#service_instances`**
- **Issue:** `ServiceInstance#generate_slug` consulta `organization.service_instances` pero `Tenancy::Organization` no declaraba esa asociación → `NoMethodError`.
- **Fix:** Añadido `has_many :service_instances, dependent: :destroy`.
- **Files modified:** app/models/tenancy/organization.rb

**3. Unicidad de nombre vs. slug**
- **Issue:** El modelo validaba `uniqueness` sobre `name` a la vez que generaba slugs únicos, contradiciendo AC-002 (múltiples instancias del mismo tipo) y el índice único `[:organization_id, :slug]`.
- **Fix:** Retirada la unicidad del nombre; el slug queda como identificador único.
- **Files modified:** app/models/service_instance.rb

**4. Referencias a modelos aún inexistentes**
- **Issue:** `CRM::Opportunity` declaraba `has_many :notes/:activities/:tasks` hacia `CRM::Note/Activity/Task` (Fase 6), que no existen.
- **Fix:** Retiradas esas asociaciones (se reintroducirán con sus modelos en Fase 6).
- **Files modified:** app/models/crm/opportunity.rb

## Issues Encountered
- Docker/PostgreSQL caído al iniciar; se levantó el entorno para migrar y validar.

## Next Phase Readiness
- Fundación de datos lista para RLS (02-02) y validación de configuración (02-03).

---
*Phase: 02-crm-aprovisionamiento-y-cat-logo-de-servicios*
*Completed: 2026-08-28*