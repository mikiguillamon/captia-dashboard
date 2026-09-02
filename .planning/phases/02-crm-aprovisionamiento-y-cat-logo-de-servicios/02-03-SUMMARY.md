---
phase: 02-crm-aprovisionamiento-y-cat-logo-de-servicios
plan: 03
subsystem: database
tags: [rails, json-schema, validation, sti]

requires:
  - phase: 02-01
    provides: service_instances con STI y CONFIG_SCHEMA
provides:
  - Validación JSON Schema de la configuración por tipo de instancia
affects: [04, 05, 10, 11]

tech-stack:
  added: []
  patterns: [validador custom sin gema externa]

key-files:
  created:
    - app/validators/json_schema_validator.rb
    - test/models/service_instance_test.rb
    - test/models/email_assistant_instance_test.rb
    - test/models/chatbot_instance_test.rb
    - test/models/voice_assistant_instance_test.rb
  modified: []

key-decisions:
  - "Validador custom (subconjunto Draft-07) en lugar de la gema activerecord-json_validator (decisión 02-CONTEXT.md: evitar dependencia externa)."
  - "Normalización de claves string/symbol entre esquema (símbolos) y valor JSONB (strings)."

patterns-established:
  - "store_accessor + CONFIG_SCHEMA por subclase STI."

requirements-completed: [SERV-01, SERV-02, SERV-03, SERV-04]

duration: ~25min
completed: 2026-08-28
---

# Plan 03: Validación de configuración por tipo de instancia

**JsonSchemaValidator custom que valida la configuración JSONB de cada subclase STI contra su CONFIG_SCHEMA.**

## Performance
- **Tasks:** 3
- **Files modified:** 5 creados

## Accomplishments
- Validador que cubre type/properties/required/items/enum/format con strict mode (propiedades no declaradas rechazadas).
- Las 3 subclases validan `configuration` contra su esquema.
- 18 tests cubren configuración válida, campos requeridos, strict mode, enum y format.

## Deviations from Plan

### Auto-fixed Issues

**1. Claves string vs símbolo**
- **Issue:** Los `CONFIG_SCHEMA` usan claves símbolo pero JSONB entrega claves string; el validador hacía `schema["properties"]` (string) sobre un hash con claves símbolo → todo era "no permitido".
- **Fix:** Deep-stringify del esquema y del valor en `validate_each`.
- **Files modified:** app/validators/json_schema_validator.rb

## Issues Encountered
None.

## Next Phase Readiness
- Configuración validada por tipo; listo para UI del catálogo (Wave 3).

---
*Phase: 02-crm-aprovisionamiento-y-cat-logo-de-servicios*
*Completed: 2026-08-28*