# Walking Skeleton — Captia Dashboard

**Phase:** 1
**Generated:** 2026-08-24

## Capability Proven End-to-End

> Un usuario interno autenticado (email+contraseña) ve las organizaciones de su cuenta en una página Rails y crea una mediante interacción UI real, persistida en PostgreSQL bajo políticas RLS activas.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Ruby on Rails 8.1 (Ruby 3.4) | Aprobado por usuario; monolito modular ADR-0001; ADR-0008 en scaffold |
| Data layer | PostgreSQL ≥16 compartido + RLS por transacción | ADR-0002; doble barrera app+BD |
| Jobs | Solid Queue en PostgreSQL | ADR-0005 sin broker externo |
| Auth | Generador auth Rails 8 (sesiones server-side, bcrypt) | Base de identidad nativa ADR-0003; D-04 |
| UI | ERB + Hotwire (Turbo/Stimulus) + Tailwind | Server-rendered responsive; NFR-014 |
| Deployment target | Entorno dev local (`bin/dev` + docker compose para PG) | MVP sin SLA; hosting producción decisión posterior |

## Stack Touched in Phase 1

- [x] Project scaffold (rails new, propshaft/importmap/tailwind, minitest, rubocop-omakase)
- [x] Routing — rutas reales login/dashboard/organizaciones
- [x] Database — lectura Y escritura reales (organizations) con RLS FORCE
- [x] UI — formulario Turbo crea organización y la lista se actualiza
- [x] Deployment — comando de ejecución full-stack documentado (README)

## Out of Scope (Deferred to Later Slices)

MFA TOTP (01-02) · recuperación de contraseña (01-02) · roles plantilla/herencia/excepciones (01-03) · invitaciones cliente (01-03) · impersonación auditada (01-03) · CRM/servicios/eventos/dashboards/docs/notificaciones (fases 2–8) · hosting productivo y dominio.

## Subsequent Slice Plan

Cada fase añade un slice vertical sobre este skeleton sin alterar sus decisiones arquitectónicas:

- Phase 1 (resto): identidad completa → tenancy/roles → impersonación
- Phase 2: CRM + conversión asistida + catálogo servicios
- Phase 3: API privada + ledger eventos + históricos
- Phases 4–8: tipos de servicio, métricas, colaboración, documentación, cierre
