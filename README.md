# Captia Dashboard

Portal de clientes y herramienta operativa interna que centraliza los servicios prestados a cada cuenta —gestión, observabilidad, colaboración, supervisión y trazabilidad— con CRM interno. Monolito modular Ruby on Rails 8.1 + Hotwire sobre PostgreSQL 16 con RLS (ADR-0001..0008).

Requisitos: Ruby 3.4 (recomendado vía rbenv), Docker, Rails ~> 8.1.

## Arranque rápido (desarrollo)

```bash
# 1. PostgreSQL 16 local + rol de aplicación no-superusuario (captia_app)
docker compose up -d   # usa docker-compose.dev.yml por defecto

# 2. Dependencias y base de datos
bin/bundle install
bin/rails db:prepare

# 3. App + Tailwind watcher
bin/dev
```

La app queda en http://localhost:3000. Credenciales locales por defecto: `captia_app`/`captia` (solo contenedor desechable; ver `db/init/01-roles.sql`).

## Calidad (gate obligatorio antes de dar trabajo por completado)

```bash
bin/rails test          # suite completa (incluye aislamiento RLS)
bin/rubocop             # estilo
bin/brakeman --no-pager # análisis estático de seguridad
rake ci                 # todo lo anterior
```

## Notas de operación

- **CI**: el workflow `.github/workflows/ci.yml` se activa automáticamente al publicar el repo en un remoto (hoy solo git local).
- **Fuentes de verdad**: `docs/product/PRD.md`, `docs/architecture/`, `.planning/`. Precedencia completa en `AGENTS.md`.
- Estado de ejecución GSD: `.planning/STATE.md`.
