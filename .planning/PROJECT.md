# Captia Dashboard

## What This Is

Portal de clientes y herramienta operativa interna que centraliza los servicios prestados a cada cuenta —normalmente ejecutados por sistemas externos (agentes, n8n, telefonía, chatbots)— aportando gestión, observabilidad, colaboración, supervisión, feedback, documentación, control y trazabilidad. Incluye un CRM exclusivamente interno que cubre el ciclo desde lead hasta cliente y conecta la relación comercial con las cuentas, organizaciones y servicios del portal. Sirve simultáneamente a usuarios internos (Superadmin, Dirección, Comercial, Account Manager, Técnico) y clientes (Administrador de cuenta, Administrador de organización, Usuario operativo), mostrando capacidades según usuario, rol, organización, servicio y configuración de autogestión.

## Core Value

Que el cliente pueda entender y supervisar de forma clara qué servicios tiene contratados, su estado actual, actividad, volumen, resultados, evaluaciones e incidencias —sin acceder a las herramientas técnicas que los ejecutan— mientras el proveedor conserva control, trazabilidad y capacidad de intervención.

## Requirements

### Validated

(None yet — ship to validate)

### Active

<!-- Current scope. Building toward these. Detalle completo en .planning/REQUIREMENTS.md -->

- [ ] Jerarquía multi-tenant Cuenta → Organización → Servicio → Instancia con aislamiento por defecto
- [ ] Autenticación individual, MFA obligatorio interno y exigible por organización, impersonación auditada
- [ ] Tipos de servicio Email Assistant, Chatbot y Voice Assistant con instancias configurables
- [ ] Acciones supervisadas (ver/editar/aprobar/rechazar) con caducidad sin autoejecución
- [ ] Actividad comprensible a partir de eventos granulares vía API privada
- [ ] Dashboards con separación estado técnico / resultado operativo / evaluación humana, drill-down y frescura
- [ ] Feedback con correcciones y comentarios convertible en tareas
- [ ] Tareas operativas e incidencias con información interna/pública diferenciada
- [ ] Documentación y conocimiento con versiones, aprobación, herencia y sincronización externa
- [ ] CRM interno (leads, contactos, cuentas, oportunidades, pipeline) con conversión asistida
- [ ] Notificaciones internas y email, exportaciones autorizadas, políticas de retención
- [ ] Portal móvil para supervisión y acciones rápidas (responsive)

### Out of Scope

<!-- Lista completa y razonada en .planning/REQUIREMENTS.md ## Out of Scope -->

- Constructor visual/no-code de tipos de servicio ni de agentes — los tipos se desarrollan explícitamente (PRD §5.5)
- Edición de prompts, modelos LLM o workflows n8n — la plataforma no modifica sistemas externos (FR-083)
- SSO empresarial, API pública para clientes, white-label, registro público — fuera del MVP (PRD §11)
- Facturación, pagos, suscripciones, presupuestos — no es objetivo del producto (PRD §11)
- Marketing automation, campañas, lead scoring avanzado, forecasting — el CRM no es generalista (PRD §11, RISK-002)
- BI avanzado ni constructor de dashboards para clientes (FR-058) — widgets configurados por el proveedor
- Gestor de proyectos completo, subtareas complejas, Gantt, sprints (PRD §11)
- Reproducción de audio de llamadas y análisis emocional (PRD §11)
- SLA contractual formal (NFR-010) y canal alternativo de aprobación durante caídas (PRD §11)
- Exportación integral de toda la cuenta (FR-140)
- Sincronización directa del conocimiento por el propio portal con cada agente externo (PRD §11)

## Context

**Origen:** El repositorio fue inicializado mediante bootstrap determinista (docs + gobernanza) sin código. Las fuentes de verdad con precedencia están definidas en `AGENTS.md`: decisiones directas del usuario > `docs/product/PRD.md` > `docs/governance/CONSTITUTION.md` > ADRs aceptados > `docs/architecture/ARCHITECTURE.md` > `docs/quality/QUALITY_BAR.md` > `.planning/` > implementación existente.

**Usuarios objetivo:** Equipo interno (Superadmin, Dirección/Administrador global, Comercial, Account Manager, Técnico), usuarios cliente (Administrador de cuenta, Administrador de organización, Usuario operativo) y sistemas externos como consumidores no humanos de la API privada.

**Frontera clave:** La plataforma NO ejecuta los servicios que representa; actúa como capa común sobre sistemas externos que intercambian información mediante la API privada. No se garantiza que una acción externa se haya ejecutado hasta recibir confirmación.

**Arquitectura aprobada (ADRs 0001–0007):**
- Monolito modular desplegado como unidad, con módulos explícitos (identidad, autorización/tenancy, CRM, catálogo de servicios, operación, eventos/proyecciones, documentación, notificaciones/exportaciones/auditoría) que no comparten tablas como contratos (ADR-0001)
- PostgreSQL autoalojado compartido con ámbitos explícitos, autorización centralizada en aplicación y seguridad por fila (RLS) como segunda barrera (ADR-0002)
- Identidad nativa autoalojada: credenciales, recuperación, sesiones y MFA; sin IdP externo en el MVP (ADR-0003)
- Ledger canónico de eventos inmutable/versionado/idempotente + proyecciones; no event sourcing completo (ADR-0004)
- Outbox transaccional y trabajos persistidos en PostgreSQL; objetivo <30s evento→vista; interfaz interna sustituible (ADR-0005)
- Captia custodia el contenido sensible (emails, conversaciones, transcripciones, documentos); datos operativos y objetos de contenido separados (ADR-0006)
- Infraestructura autoalojada prioritaria; ningún SaaS salvo necesidad extrema + aprobación expresa (ADR-0007)

**Decisiones abiertas del PRD (no inventar durante desarrollo):** OD-001 estados contractuales, OD-002 estados operativos, OD-003 estados de salud, OD-004 retención por defecto, OD-005 reintentos de sincronización, OD-006 umbrales de frescura, OD-007 KPIs por servicio, OD-008 permisos atómicos, OD-009 notificaciones obligatorias, OD-010 auditoría fuera de impersonación, OD-011 campos por servicio, OD-012 nomenclatura de interfaz, OD-013 KPIs de éxito, OD-014 tratamiento del contenido eliminado, OD-015 política de activación del portal.

**Stack tecnológico:** Pendiente de decisión. Los ADRs fijan PostgreSQL, autoalojamiento y monolito modular, pero no lenguaje/framework. Ver `.planning/research/STACK.md`.

## Constraints

- **Despliegue**: Infraestructura autoalojada; sin SaaS externos salvo necesidad extrema con aprobación expresa (ADR-0007) — independencia operativa y datos sensibles.
- **Persistencia**: PostgreSQL compartido con RLS; sin base/esquema por cliente (ADR-0002) — operación simple con aislamiento fuerte.
- **Identidad**: Nativa y autoalojada; MFA obligatorio interno; sin IdP externo en el MVP (ADR-0003).
- **Cola**: Outbox transaccional en PostgreSQL; sin broker externo en el MVP (ADR-0005) — reflejar eventos aceptados en vistas en ≤30s (NFR-006).
- **Rendimiento**: Evento recibido → visible en ≤30 segundos (NFR-006); RPO ≈ 1h; RTO ≤ 24h; sin SLA contractual (NFR-008/009/010).
- **Datos**: Distinguir siempre cero / ausente / incompleto / desactualizado / error; no inventar valores; no representar lo desactualizado como actual (PRD §5.2, NFR-007/013).
- **Seguridad**: Datos operativos sensibles (emails, chats, transcripciones); least privilege; auditoría de impersonación con actor real (NFR-001/004/011); cambios de seguridad requieren revisión explícita (QUALITY_BAR).
- **Uso inicial**: Equipo interno + clientes reales; no lanzamiento SaaS público (PRD §12.1).
- **Calidad**: Validación obligatoria antes de dar trabajo por completado (CONSTITUTION §6, QUALITY_BAR): types, lint, tests relevantes, build; pruebas críticas de aislamiento, autorización, MFA, impersonación, idempotencia.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Monolito modular (ADR-0001) | Minimiza complejidad operativa del MVP sin cerrar extracción futura | — Pending |
| PostgreSQL compartido + RLS (ADR-0002) | Aislamiento fuerte sin base por cliente | — Pending |
| Identidad nativa autoalojada (ADR-0003) | Independencia operativa; MFA e impersonación bajo control | ⚠️ Revisar seguridad explícitamente |
| Ledger de eventos + proyecciones, no ES completo (ADR-0004) | Trazabilidad canónica sin sobrecargar módulos de comando | — Pending |
| Outbox + trabajos en PostgreSQL (ADR-0005) | Menor dependencia operativa; consistencia transaccional | — Pending |
| Custodia de contenido sensible en Captia (ADR-0006) | Vistas, históricos y exportación consistentes | ⚠️ Requiere diseño privacidad/retención |
| Infraestructura autoalojada (ADR-0007) | Control de datos y reducción de lock-in | — Pending |
| Stack framework/lenguaje | ADRs fijan persistencia y topología pero no framework | ⚠️ Pendiente aprobación — ver research/STACK.md |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-08-24 after initialization*
