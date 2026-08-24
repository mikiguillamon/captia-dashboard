# Research Summary: Captia Dashboard

**Synthesized:** 2026-08-24 (síntesis inline de STACK/FEATURES/ARCHITECTURE/PITFALLS)

## Stack

**Decidido por ADRs:** PostgreSQL autoalojado compartido con RLS · monolito modular · identidad nativa sin IdP · ledger de eventos + proyecciones (no ES completo) · outbox/jobs en PostgreSQL · infraestructura 100% autoalojada.

**Abierto (bloquea scaffold, requiere aprobación del usuario — AUTONOMY_POLICY #11):** lenguaje/framework.
- Recomendación: **Rails 8.1 + Hotwire + Solid Queue/Cache/Cable** (encaje directo con outbox-en-PG y server-rendered; versiones verificadas ago-2026)
- Alternativa sólida: Django 5.2 LTS + HTMX (+DRF) — admin nativo ayuda al CRM, pero jobs/outbox requieren más montaje
- Descartada por ahora: full TypeScript monolito — demasiada seguridad artesanal (identidad+RLS+outbox)

## Table Stakes (núcleo v1)

17 categorías funcionales / 140 FRs del PRD: tenancy y permisos, auth+MFA+impersonación, servicios e instancias (Email Assistant/Chatbot/Voice Assistant), acciones supervisadas, eventos→actividad→históricos, dashboards multidimensionales con frescura, feedback→tareas→incidencias, documentación/conocimiento con publicación≠sincronización, retención, notificaciones, CRM con conversión asistida, API privada idempotente, exportaciones.

## Watch Out For (top pitfalls)

1. Bypass multi-tenant → RLS desde fase fundacional + suite de aislamiento
2. Dimensiones métricas mezcladas → modelar técnico/operativo/humano separados desde el esquema
3. Duplicación de eventos → idempotencia en ingesta (constraint, no convención)
4. Impersonación sin actor real → contexto de sesión desde el día 1
5. Vencidas autoejecutándose → prohibición explícita + test negativo
6. CRM scope creep → Out of Scope vinculante
7. Publicar≠sincronizar → dos estados independientes

## Decisiones abiertas que condicionan planificación (PRD OD-001..015)

Estados contractuales/operativos/salud (OD-1..3), retención por defecto (OD-4), reintentos (OD-5), umbrales frescura (OD-6), KPIs por servicio (OD-7), permisos atómicos (OD-8), notificaciones obligatorias (OD-9), auditoría no-impersonación (OD-10), campos por servicio (OD-11), nomenclatura UI (OD-12), KPIs producto (OD-13), tratamiento eliminado (OD-14), activación portal (OD-15). **No resolverlas durante desarrollo sin escalar.**

## Implicaciones para roadmap

- Granularidad standard: ~7 fases verticales mvp (fundación → identidad/tenancy → CRM/provisioning → eventos/API → tipos de servicio → métricas → colaboración → docs → cierre transversal).
- Fase 0 implícita: aprobación de stack antes del scaffold.
- Las 35 ACs del PRD son la base de los success criteria verificables.
