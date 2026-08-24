# Stack Research: Captia Dashboard

**Researched:** 2026-08-24 (inline; versiones verificadas por búsqueda web ago-2026)

## Fijado por decisiones existentes (no negociable en esta fase)

| Componente | Decisión | Fuente |
|------------|----------|--------|
| Base de datos | PostgreSQL autoalojado, compartido, con RLS | ADR-0002 |
| Topología | Monolito modular desplegado como unidad | ADR-0001 |
| Identidad | Nativa autoalojada (credenciales, sesiones, MFA); sin IdP externo | ADR-0003 |
| Eventos | Ledger canónico inmutable + proyecciones (no ES completo) | ADR-0004 |
| Trabajo asíncrono | Outbox transaccional + jobs persistidos en PostgreSQL; sin broker externo | ADR-0005 |
| Infraestructura | Autoalojada; sin SaaS salvo aprobación expresa | ADR-0007 |

**Consecuencia directa:** el framework elegido debe convivir bien con PostgreSQL como único almacén (incluida cola de trabajos), permitir control fino de SQL (RLS, `SET app.*`), y soportar HTML server-rendered responsive + API privada versionada.

## ⚠ DECISIÓN ABIERTA — requiere aprobación del usuario

El lenguaje/framework NO está decidido por ningún ADR. Adoptar un framework principal exige involucrar al usuario (AUTONOMY_POLICY §"Decisions requiring user involvement" #11). Recomendación pendiente; no implementar hasta aprobar.

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
