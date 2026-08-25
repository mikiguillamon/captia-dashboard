# ADR-0008: Adopción de Ruby on Rails 8.1 como framework de aplicación

## Status

Accepted

## Context

El proyecto Captia Dashboard requiere un monolito modular (ADR-0001) sobre PostgreSQL compartido con RLS (ADR-0002), identidad nativa autoalojada con MFA (ADR-0003) y trabajo asíncrono vía outbox transaccional en PostgreSQL sin broker externo (ADR-0005). La investigación de stack (`.planning/research/STACK.md`) comparó tres opciones y el usuario aprobó la Opción A el 2026-08-24.

## Options considered

### Option A

**Ruby on Rails 8.1 + Hotwire (Turbo + Stimulus) + Solid Queue/Cache/Cable.** Rails 8.1.x es la rama soportada vigente (8.0 EOL nov-2026; verificado ago-2026 en rubyonrails.org/releases y endoflife.date). El trío Solid opera sobre PostgreSQL puro, encajando 1:1 con ADR-0005 sin infraestructura adicional. El generador de autenticación integrado cubre sesiones server-side y hashing bcrypt como base de ADR-0003.

### Option B

**Django 5.2 LTS + HTMX + DRF.** Admin integrado útil para el CRM interno, pero sin equivalente nativo al patrón outbox/jobs-en-PG (requeriría Celery + broker o montaje propio), y el ORM es menos cómodo para el SQL crudo que exige la estrategia RLS (`SET LOCAL app.account_id`).

### Option C

Full TypeScript (Next.js/Nuxt + Prisma/Drizzle). Un solo lenguaje, pero identidad, outbox, jobs y RLS serían casi artesanales, ampliando la superficie de error en seguridad — prioridad #1 del proyecto.

## Decision

Adoptar **Ruby on Rails ~\> 8.1** (instalado: 8.1.x sobre Ruby 3.4.x) como framework único del monolito modular, con Hotwire para UI server-rendered y las gemas Solid (Queue/Cache/Cable) sobre PostgreSQL para jobs, caché y pub/sub. Los módulos se organizan como namespaces Ruby con contratos internos explícitos (D-01), sin Rails::Engine en la fundación. Gemas de apoyo aprobadas: `rotp` (TOTP RFC-6238), `rqrcode` (provisioning QR), `brakeman` (análisis estático de seguridad).

## Rationale

- Menor superficie propia en seguridad: hashing bcrypt probado, `rate_limit` integrado, sesiones seguras por defecto, generador de autenticación oficial.
- Solid Queue/Cache/Cable eliminan Redis/broker, coherente con minimalismo operativo de ADR-0005/0007.
- ActiveRecord permite SQL crudo donde la RLS lo exija, habilitando el contexto transaccional obligatorio D-07.
- Hotwire cubre el portal responsive server-rendered sin SPA ni Node en runtime.

## Consequences

- El equipo depende del ecosistema Ruby (riesgo aceptado por decisión de stack).
- Las versiones minor de gemas se fijan en el scaffold y se actualizan de forma controlada.
- CI debe ejecutar `test`, `rubocop` y `brakeman` en cada cambio (QUALITY_BAR).
- La separación estricta entre rol owner de migraciones y rol runtime de BD se formaliza en despliegue; en desarrollo ambos unifican en el rol no-superusuario `captia_app` cubierto por FORCE ROW LEVEL SECURITY.

## Reversibility

Costly — sustituir el framework reescribiría toda la capa de dominio, vistas y migraciones. La elección de namespaces (no engines) mantiene abierta la extracción futura de servicios si un límite lo exigiera.

## Follow-up

- Fijar versiones exactas en `Gemfile.lock` durante el scaffold.
- Documentar convenciones de módulos cuando existan ≥2 módulos (CONVENTIONS.md).
- Activar CI al disponer de remoto del repositorio (hoy solo git local).
