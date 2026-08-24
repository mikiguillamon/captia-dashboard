# State: Captia Dashboard

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-08-24)

**Core value:** Que el cliente pueda entender y supervisar de forma clara sus servicios contratados —estado, actividad, resultados, evaluaciones e incidencias— mientras el proveedor conserva control, trazabilidad y capacidad de intervención.
**Sources of truth precedence:** ver `AGENTS.md`.

## Milestone

**Milestone:** v1 MVP (según PRD)
**Started:** 2026-08-24
**Status:** Initialized — pendiente planificación de Fase 1

## Phases

| # | Name | Status | Plans |
|---|------|--------|-------|
| 1 | Fundación e identidad segura | ○ Not planned | 0/0 |
| 2 | CRM, aprovisionamiento y catálogo de servicios | ○ Not planned | 0/0 |
| 3 | Núcleo de eventos, API privada y actividad | ○ Not planned | 0/0 |
| 4 | Tipos de servicio (Email, Chatbot, Voice) | ○ Not planned | 0/0 |
| 5 | Dashboards, métricas y frescura | ○ Not planned | 0/0 |
| 6 | Acciones supervisadas, feedback, tareas e incidencias | ○ Not planned | 0/0 |
| 7 | Documentación, conocimiento y sincronización | ○ Not planned | 0/0 |
| 8 | Retención, notificaciones, exportaciones y cierre | ○ Not planned | 0/0 |

## Current Position

**Phase:** 1 (not planned)
**Next:** `/gsd-discuss-phase 1`

## Blockers / Gates

- ⚠ **Stack framework sin aprobar** (research/STACK.md): Rails 8.1 recomendado; decisión del usuario requerida antes de scaffold de Fase 1 (AUTONOMY_POLICY #11).
- GSD agents no instalados en este runtime (`~/.claude/agents`): research/roadmap generados inline. Instalables con `npx get-shit-done-cc@latest --global` si se desea orchestration completa.
- Decisiones abiertas PRD OD-001..OD-015: no resolverlas durante desarrollo sin escalar al usuario.

## Recent Decisions Log

| # | Decision | Date | Phase Impact |
|---|----------|------|--------------|
| 1 | Inicialización GSD sobre repo existente captia-dashboard/ (bootstrap) | 2026-08-24 | all |
| 2 | Granularidad standard (8 fases mvp verticales) por volumen de 155 reqs y RISK-001 | 2026-08-24 | roadmap |

---
*Last updated: 2026-08-24 after project initialization*
