# Features Research: Captia Dashboard

**Researched:** 2026-08-24 (inline, fundamentado en PRD §4/§7 y ADRs)
**Nota:** El PRD ya define el alcance v1 con precisión (140 FRs + 35 ACs). Esta investigación clasifica complejidad y dependencias para la roadmap, no redefiniendo alcance.

## Categorías y complejidad

### 1. Tenancy: cuentas, organizaciones, usuarios (FR-001..011)
- **Table stakes:** jerarquía Cuenta→Organización, acceso por organización, roles plantilla con herencia y excepciones, invitaciones cliente condicionadas a autogestión.
- **Complejidad:** ALTA (modelo de permisos es RISK-003).
- **Depende de:** nada (fundación).

### 2. Autenticación e impersonación (FR-012..018)
- **Table stakes:** cuentas individuales, MFA interno obligatorio, MFA exigible por organización, impersonación con auditoría del actor real, notificación configurable.
- **Complejidad:** ALTA (seguridad crítica; ADR-0003).
- **Depende de:** categoría 1.

### 3. Servicios e instancias (FR-019..028)
- **Table stakes:** tipos Email Assistant/Chatbot/Voice Assistant, múltiples instancias por organización, configuración por instancia, estado contractual ≠ operativo ≠ salud, finalización inmediata/programada, visibilidad histórica configurable.
- **Complejidad:** MEDIA-ALTA.

### 4. Acciones supervisadas (FR-029..033)
- **Differentiators:** modo autónomo/supervisado, capacidades ver/editar/aprobar/rechazar por permisos, fecha límite, vencida nunca se autoejecuta.
- **Complejidad:** MEDIA-ALTA (flujo 6.5 del PRD).

### 5. Eventos, actividad e históricos (FR-034..037, FR-072..075)
- **Table stakes:** ingesta de eventos granulares por API, transformación a actividad comprensible, históricos con búsqueda y filtros comunes.
- **Complejidad:** ALTA (ledger ADR-0004 + proyecciones).

### 6. Interfaces de servicio (FR-038..052)
- **Email Assistant:** histórico de emails, detalle completo (entrante, decisión, respuesta generada, respuesta enviada), tres dimensiones separadas.
- **Chatbot:** conversaciones, mensajes, respuestas identificadas, evaluación global y por respuesta.
- **Voice Assistant:** llamadas, metadatos, transcripción segmentada, evaluación global y por segmento.
- **Complejidad:** MEDIA (x3 servicios).

### 7. Dashboards y métricas (FR-053..066)
- **Table stakes:** dashboards cuenta/org/servicio/instancia, widgets configurados por proveedor (no cliente), periodos y comparación, drill-down, separación de dimensiones, satisfacción con cobertura (AC-016).
- **Complejidad:** ALTA (semántica de métricas es RISK-005/006).

### 8. Frescura de datos (FR-067..071)
- **Differentiators:** indicadores sincronizada/desactualizada/sin datos recientes, umbrales por tipo sobrescribibles por instancia.
- **Complejidad:** MEDIA.

### 9. Feedback y mejora (FR-076..083)
- **Differentiators:** evaluación global y por partes, correcto/incorrecto, corrección propuesta, comentarios, conversión a tarea. SIN modificar agentes (FR-083).
- **Complejidad:** MEDIA.

### 10. Tareas (FR-084..086) — BAJA. 11. Incidencias (FR-087..091) — MEDIA (info interna/pública separada).

### 12. Documentación y conocimiento (FR-092..107)
- **Table stakes:** editor Markdown, docs vs conocimiento, herencia con sustitución explícita, versiones con autor/fecha, restauración, aprobación configurable, publicación ≠ sincronización, evento de sincronización, reintentos, fallo visible/incidencia.
- **Complejidad:** ALTA (flujo editorial completo).

### 13. Retención y borrado (FR-108..112) — MEDIA (workflow de solicitud; resolver OD-004/OD-014 antes).

### 14. Notificaciones (FR-113..116) — MEDIA-BJA. Preferencias por categoría con obligatorias.

### 15. CRM (FR-117..126)
- **Table stakes:** leads, contactos, cuentas, oportunidades, pipeline con etapas configurables, notas/actividades/tareas, histórico, conversión asistida completa (AC-028).
- **Complejidad:** MEDIA-ALTA (conversión asistida cruza CRM→portal).

### 16. API e integraciones (FR-127..136) — ALTA. Contratos versionados, idempotencia, inválidos/incompletos/duplicados (AC-025..027).

### 17. Exportaciones (FR-137..140) — BAJA-MEDIA.

## Anti-features (NO construir — PRD §11)

Constructor visual de tipos/agentes, edición de prompts/modelos/workflows n8n, SSO empresarial, API pública, white-label, registro público, facturación/pagos, marketing automation/campañas/lead scoring, BI avanzado, constructor de dashboards cliente, gestor de proyectos completo, Gantt/sprints, motor de alertas avanzado, edición colaborativa tipo Google Docs, reproducción de audio, análisis emocional, exportación integral, SLA contractual, canal alterno de aprobación en caída, modificación automática de agentes por feedback, sincronización directa portal→agente.

## Implicación para requisitos

Las 35 ACs del PRD son el criterio de aceptación verificable por categoría; cada REQ del REQUIREMENTS.md conserva su referencia FR/AC para trazabilidad.
