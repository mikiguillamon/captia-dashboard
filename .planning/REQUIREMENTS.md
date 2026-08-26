# Requirements: Captia Dashboard

**Defined:** 2026-08-24
**Core Value:** Que el cliente pueda entender y supervisar de forma clara qué servicios tiene contratados, su estado actual, actividad, volumen, resultados, evaluaciones e incidencias —sin acceder a las herramientas técnicas que los ejecutan— mientras el proveedor conserva control, trazabilidad y capacidad de intervención.

Fuente: `docs/product/PRD.md` (§7 FRs, §8 NFRs, §10 ACs). Cada requisito conserva su referencia FR/NFR para trazabilidad inversa.

## v1 Requirements

### Tenancy: cuentas, organizaciones y usuarios

- [x] **TEN-01**: Crear y gestionar cuentas comerciales (FR-001)
- [x] **TEN-02**: Una cuenta contiene una o más organizaciones (FR-002)
- [x] **TEN-03**: Usuarios con acceso nivel cuenta y usuarios limitados a organizaciones concretas (FR-003)
- [x] **TEN-04**: Un usuario accede a varias organizaciones si sus permisos lo autorizan (FR-004)
- [x] **TEN-05**: Acceso a una organización no concede acceso automático a otras de la misma cuenta (FR-005)
- [x] **TEN-06**: Roles internos base: Superadmin, Dirección/Administrador global, Comercial, Account Manager, Técnico (FR-006)
- [x] **TEN-07**: Roles cliente base: Administrador de cuenta, Administrador de organización, Usuario operativo (FR-007)
- [x] **TEN-08**: Roles como plantillas de permisos con capacidades y excepciones (FR-008)
- [x] **TEN-09**: Permisos heredables desde niveles superiores con sobrescritura por excepciones explícitas (FR-009)
- [x] **TEN-10**: Usuarios internos restringibles a cuentas/organizaciones/servicios asignados (FR-010)
- [x] **TEN-11**: Administradores cliente autorizados pueden invitar usuarios según autogestión habilitada (FR-011)

### Autenticación e impersonación

- [x] **AUTH-01**: Todos los usuarios usan cuentas individuales (FR-012)
- [x] **AUTH-02**: MFA obligatorio para usuarios internos (FR-013)
- [x] **AUTH-03**: Una organización cliente puede exigir MFA a sus usuarios (FR-014)
- [x] **AUTH-04**: Perfiles internos autorizados pueden impersonar usuarios cliente (FR-015)
- [x] **AUTH-05**: La sesión de impersonación permite exactamente las operaciones del usuario impersonado (FR-016)
- [x] **AUTH-06**: Registro del actor interno real en todas las acciones durante impersonación (FR-017)
- [x] **AUTH-07**: Notificación al cliente sobre impersonaciones configurable por organización (FR-018)

### Servicios e instancias

- [ ] **SERV-01**: Tipos de servicio predefinidos desarrollados específicamente (FR-019)
- [ ] **SERV-02**: El MVP incluye al menos Email Assistant, Chatbot y Voice Assistant (FR-020)
- [ ] **SERV-03**: Una organización puede tener varias instancias del mismo tipo (FR-021)
- [ ] **SERV-04**: Configuración independiente por instancia cuando el tipo lo permita (FR-022)
- [ ] **SERV-05**: Crear nuevas instancias depende de capacidades habilitadas de cuenta/servicio (FR-023)
- [ ] **SERV-06**: Estado contractual separado del estado operativo (FR-024)
- [ ] **SERV-07**: Estado de salud por instancia (FR-025)
- [ ] **SERV-08**: Salud derivada de señales automáticas + intervención manual interna (FR-026)
- [ ] **SERV-09**: Finalización de servicio inmediata o programada con fecha efectiva (FR-027)
- [ ] **SERV-10**: Visibilidad histórica post-finalización configurable por servicio (FR-028)

### Acciones supervisadas

- [ ] **SUP-01**: Instancia en modo autónomo o supervisado cuando el tipo lo soporte (FR-029)
- [ ] **SUP-02**: Capacidades ver/editar/aprobar/rechazar configurables por permisos en modo supervisado (FR-030)
- [ ] **SUP-03**: Fecha límite de revisión en acciones supervisadas (FR-031)
- [ ] **SUP-04**: Acción vencida nunca se ejecuta automáticamente (FR-032)
- [ ] **SUP-05**: Acción vencida identificada como expirada o requiriendo atención (FR-033)

### Eventos, actividad e históricos

- [ ] **ACT-01**: Las integraciones registran eventos operativos granulares (FR-034)
- [ ] **ACT-02**: Los eventos granulares se transforman en actividades comprensibles para humanos (FR-035)
- [ ] **ACT-03**: El portal no expone logs técnicos como actividad de cliente (FR-036)
- [ ] **ACT-04**: Detalle de actividad consulta la información subyacente según permisos (FR-037)
- [ ] **ACT-05**: Históricos cronológicos de actividad (FR-072)
- [ ] **ACT-06**: Búsqueda y filtros en el histórico (FR-073)
- [ ] **ACT-07**: Filtros comunes: periodo, organización, servicio, instancia, estado técnico, resultado operativo, evaluación humana, presencia de feedback/incidencia, texto o identificador (FR-074)
- [ ] **ACT-08**: Los tipos de servicio pueden añadir filtros específicos (FR-075)

### Email Assistant

- [ ] **EMAIL-01**: Histórico de emails procesados (FR-038)
- [ ] **EMAIL-02**: Detalle con el email entrante completo (FR-039)
- [ ] **EMAIL-03**: Indicación de decisión responder/no responder cuando la integración la proporcione (FR-040)
- [ ] **EMAIL-04**: Respuesta generada visible cuando exista (FR-041)
- [ ] **EMAIL-05**: Respuesta finalmente enviada visible cuando exista (FR-042)
- [ ] **EMAIL-06**: Estado técnico, resultado operativo y evaluación humana mostrados por separado (FR-043)

### Chatbot

- [ ] **CHAT-01**: Listado de conversaciones (FR-044)
- [ ] **CHAT-02**: Vista de conversación con sus mensajes (FR-045)
- [ ] **CHAT-03**: Respuestas generadas por el chatbot identificadas (FR-046)
- [ ] **CHAT-04**: Evaluación global y por respuestas concretas (FR-047)

### Voice Assistant

- [ ] **VOICE-01**: Listado de llamadas (FR-048)
- [ ] **VOICE-02**: Fecha, duración y datos básicos disponibles de cada llamada (FR-049)
- [ ] **VOICE-03**: Transcripción disponible (FR-050)
- [ ] **VOICE-04**: Transcripción dividida en turnos/segmentos identificables (FR-051)
- [ ] **VOICE-05**: Evaluación global y por segmentos concretos (FR-052)

### Dashboards y métricas

- [ ] **DASH-01**: Dashboards a nivel cuenta, organización, servicio e instancia cuando existan datos compatibles (FR-053)
- [ ] **DASH-02**: Dashboard principal combina estado operativo y elementos que requieren atención (FR-054)
- [ ] **DASH-03**: El proveedor configura qué widgets se muestran (FR-055)
- [ ] **DASH-04**: Cada tipo de servicio define configuración de dashboard por defecto (FR-056)
- [ ] **DASH-05**: Una instancia puede sobrescribir la configuración de su tipo (FR-057)
- [ ] **DASH-06**: El cliente no configura libremente los widgets en el MVP (FR-058)
- [ ] **DASH-07**: Selección de periodos temporales (FR-059)
- [ ] **DASH-08**: Comparación con el periodo anterior equivalente (FR-060)
- [ ] **DASH-09**: Variaciones de ratios distinguen % relativo de puntos porcentuales (FR-061)
- [ ] **DASH-10**: Drill-down de métrica hacia el histórico filtrado correspondiente (FR-062)
- [ ] **DASH-11**: Métricas agregadas combinan solo dimensiones semánticamente compatibles (FR-063)
- [ ] **DASH-12**: Distinción entre estado técnico, resultado operativo y evaluación humana (FR-064)
- [ ] **DASH-13**: Satisfacción humana calculada exclusivamente sobre elementos evaluados (FR-065)
- [ ] **DASH-14**: Cobertura de evaluación mostrada junto a la satisfacción (FR-066)

### Frescura de datos

- [ ] **FRESH-01**: Vistas operativas muestran última actualización cuando sea relevante (FR-067)
- [ ] **FRESH-02**: Indicación de integración sincronizada / desactualizada / sin datos recientes (FR-068)
- [ ] **FRESH-03**: Advertencia en métricas cuando la frescura pueda ser insuficiente (FR-069)
- [ ] **FRESH-04**: Umbrales de frescura definibles por tipo de servicio (FR-070)
- [ ] **FRESH-05**: Sobrescribible el umbral por instancia (FR-071)

### Feedback y mejora

- [ ] **FB-01**: Evaluación global de una interacción (FR-076)
- [ ] **FB-02**: Evaluación individual de partes identificables cuando el tipo lo permita (FR-077)
- [ ] **FB-03**: Evaluación marcada como correcta o incorrecta (FR-078)
- [ ] **FB-04**: Corrección propuesta en evaluación incorrecta (FR-079)
- [ ] **FB-05**: Comentarios en evaluaciones (FR-080)
- [ ] **FB-06**: Una evaluación puede generar una tarea (FR-081)
- [ ] **FB-07**: Workflow de mejora posterior al feedback (FR-082)
- [ ] **FB-08**: Sin modificación directa de prompts/modelos/workflows de agentes en el MVP (FR-083)

### Tareas

- [ ] **TASK-01**: Tareas operativas básicas (FR-084)
- [ ] **TASK-02**: Título, descripción, origen, responsable, estado, comentarios y fechas básicas (FR-085)
- [ ] **TASK-03**: Origen desde feedback, incidencias u otras acciones operativas soportadas (FR-086)

### Incidencias

- [ ] **INC-01**: Creación manual de incidencias (FR-087)
- [ ] **INC-02**: Creación/actualización automática por integraciones (FR-088)
- [ ] **INC-03**: Información interna diferenciada de la visible al cliente (FR-089)
- [ ] **INC-04**: Equipo interno decide qué información se expone (FR-090)
- [ ] **INC-05**: Estado y resolución de incidencias (FR-091)

### Documentación y conocimiento

- [ ] **DOC-01**: Editor visual con contenido representable en Markdown (FR-092)
- [ ] **DOC-02**: Distinción documentación-humanos vs conocimiento-servicios (FR-093)
- [ ] **DOC-03**: Documentación en diferentes niveles de la jerarquía (FR-094)
- [ ] **DOC-04**: Instancias heredan documentación de niveles superiores (FR-095)
- [ ] **DOC-05**: Un documento específico puede declarar que sustituye a un heredado (FR-096)
- [ ] **DOC-06**: Sin inferencia automática de contradicciones semánticas (FR-097)
- [ ] **DOC-07**: Versiones publicadas de documentos (FR-098)
- [ ] **DOC-08**: Historial de versiones con autor y fecha (FR-099)
- [ ] **DOC-09**: Restauración de una versión publicada anterior (FR-100)
- [ ] **DOC-10**: Un borrador no sustituye a la versión publicada hasta su aprobación (FR-101)
- [ ] **DOC-11**: Workflows de aprobación configurables por organización o servicio (FR-102)
- [ ] **DOC-12**: Publicación y sincronización externa como estados diferentes (FR-103)
- [ ] **DOC-13**: Publicación de conocimiento emite evento consumible por integraciones (FR-104)
- [ ] **DOC-14**: Confirmación externa del resultado de sincronización (FR-105)
- [ ] **DOC-15**: Reintento automático de sincronización fallida (FR-106)
- [ ] **DOC-16**: Fallo persistente de sincronización visible y generador de incidencia (FR-107)

### Retención y borrado

- [ ] **RET-01**: Políticas de retención configurables (FR-108)
- [ ] **RET-02**: Política por defecto con posibilidad de excepciones (FR-109)
- [ ] **RET-03**: Eliminación solicitada por clientes vía workflow solicitud-revisión-resolución (FR-110)
- [ ] **RET-04**: Solicitud de eliminación aprobable o rechazable (FR-111)
- [ ] **RET-05**: Auditoría conserva constancia de eliminación sin necesariamente conservar contenido (FR-112)

### Notificaciones

- [ ] **NOTIF-01**: Notificaciones internas (FR-113)
- [ ] **NOTIF-02**: Notificaciones por email (FR-114)
- [ ] **NOTIF-03**: Preferencias por usuario y categoría dentro de límites de plataforma (FR-115)
- [ ] **NOTIF-04**: Categorías obligatorias no desactivables (FR-116)

### CRM interno

- [ ] **CRM-01**: Gestión de leads (FR-117)
- [ ] **CRM-02**: Gestión de contactos (FR-118)
- [ ] **CRM-03**: Gestión de cuentas comerciales (FR-119)
- [ ] **CRM-04**: Gestión de oportunidades (FR-120)
- [ ] **CRM-05**: Pipeline con etapas configurables (FR-121)
- [ ] **CRM-06**: Oportunidad con responsable, importe estimado, probabilidad y fecha estimada de cierre (FR-122)
- [ ] **CRM-07**: Notas, actividades y tareas comerciales (FR-123)
- [ ] **CRM-08**: Histórico de actividad comercial (FR-124)
- [ ] **CRM-09**: Oportunidad ganada inicia conversión asistida (FR-125)
- [ ] **CRM-10**: Conversión asistida: revisar cuenta, crear/confirmar organizaciones, seleccionar servicios, crear instancias, configurar permisos e invitar usuarios antes de activar el portal (FR-126)

### API e integraciones

- [ ] **API-01**: API privada para integraciones del equipo técnico (FR-127)
- [ ] **API-02**: Operaciones principales del dominio expuestas vía API (FR-128)
- [ ] **API-03**: Sin API pública para clientes en el MVP (FR-129)
- [ ] **API-04**: Conservación de eventos fundamentales recibidos para reconstruir actividad (FR-130)
- [ ] **API-05**: Cálculo de métricas comunes a partir de eventos (FR-131)
- [ ] **API-06**: Métricas específicas proporcionadas por integraciones por tipo de servicio (FR-132)
- [ ] **API-07**: Evitar doble contabilización de duplicados inequívocos (FR-133)
- [ ] **API-08**: Datos incompletos pero utilizables registrados marcando lo afectado como incompleto (FR-134)
- [ ] **API-09**: Datos inválidos no contaminan métricas ni históricos normales (FR-135)
- [ ] **API-10**: Errores persistentes de integración pueden generar incidencias (FR-136)

### Exportaciones

- [ ] **EXP-01**: Exportación solo de información ya accesible para el usuario (FR-137)
- [ ] **EXP-02**: Interacciones y métricas exportables en formatos tabulares (CSV) donde sea compatible (FR-138)
- [ ] **EXP-03**: Documentación exportable en Markdown (FR-139)
- [ ] **EXP-04**: Sin exportación integral de toda la cuenta en el MVP (FR-140)

### Transversales (seguridad y calidad)

- [x] **SEG-01**: Aislamiento: ningún usuario accede a cuentas/organizaciones sin permiso (NFR-001)
- [x] **SEG-02**: MFA obligatorio para todos los usuarios internos (NFR-002)
- [x] **SEG-03**: Posibilidad de exigir MFA a todos los usuarios de una organización cliente (NFR-003)
- [x] **SEG-04**: Sesiones de impersonación registran actor real, impersonado y acciones (NFR-004)
- [x] **SEG-05**: Auditoría de seguridad/administración visible solo a internos autorizados (NFR-005)
- [ ] **SEG-06**: Evento aceptado visible en vistas operativas en ≤30 segundos objetivo (NFR-006)
- [ ] **SEG-07**: Datos desactualizados nunca presentados como actuales conociendo el problema de sync (NFR-007)
- [ ] **SEG-08**: Mecanismos de recuperación con RPO objetivo ≈1 hora (NFR-008)
- [ ] **SEG-09**: RTO aceptado hasta 24 horas ante recuperación completa (NFR-009)
- [ ] **SEG-10**: Sin SLA contractual formal de disponibilidad en el MVP (NFR-010)
- [x] **SEG-11**: Trazabilidad suficiente para diferenciar acción directa de acción por impersonación (NFR-011)
- [ ] **SEG-12**: Fallos persistentes de sincronización no quedan silenciosos (NFR-012)
- [ ] **SEG-13**: Tratamiento diferenciado de cero/ausente/incompleto/desactualizado/error (NFR-013)
- [ ] **SEG-14**: Portal móvil para supervisión y acciones rápidas definidas en UX, sin paridad administrativa total (NFR-014)
- [ ] **SEG-15**: Nuevos tipos de servicio por desarrollo específico sin rediseñar el modelo base (NFR-015)

## v2 Requirements

El PRD no difiere funcionalidad a v2: todo lo no incluido está explícitamente fuera de alcance (§11). Si surge una petición nueva, añadirla aquí tras validación del usuario.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Constructor visual/no-code de tipos de servicio | Los tipos se desarrollan explícitamente (PRD §5.5, §11) |
| Constructor de agentes / edición de prompts / modelos LLM / workflows n8n | La plataforma no modifica sistemas externos (FR-083, §11) |
| SSO empresarial | Fuera del MVP (§11) |
| API pública para clientes | Solo API privada de integraciones (FR-129, §11) |
| White-label | Fuera del MVP (§11) |
| Registro público / autoprovisionamiento | Alta gestionada por proveedor/conversión (§11) |
| Facturación, pagos, suscripciones, presupuestos, facturas | No es objetivo del producto (§11) |
| Marketing automation, campañas, newsletters | CRM no generalista (RISK-002, §11) |
| Lead scoring avanzado, secuencias comerciales, forecasting avanzado | Igual que anterior (§11) |
| BI avanzado | Fuera del MVP (§11) |
| Constructor de dashboards para clientes | Widgets configurados por el proveedor (FR-058, §11) |
| Gestor de proyectos completo, subtareas complejas, Gantt, sprints | Tareas operativas básicas bastan (§11) |
| Motor avanzado de reglas de alertas | Notificaciones básicas bastan (§11) |
| Edición documental colaborativa tipo Google Docs | Editor Markdown con versiones basta (§11) |
| Reproducción de audio de llamadas | Transcripción textual basta (§11) |
| Análisis emocional / IA adicional no definida | Fuera del MVP (§11) |
| Exportación integral de toda una cuenta | Solo exportaciones parciales autorizadas (FR-140, §11) |
| SLA contractual | Aceptado para MVP (NFR-010, §11) |
| Canal alternativo de aprobación con portal caído | Riesgo aceptado hasta RTO (PRD §12.10, §11) |
| Modificación automática de agentes por feedback | Solo workflow de mejora manual (FR-083, §11) |
| Sincronización directa portal→agente del conocimiento | Vía eventos consumibles por integraciones (FR-104, §11) |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TEN-01..TEN-11 | Phase 1 | Complete (2026-08-26) |
| AUTH-01..AUTH-07 | Phase 1 | Complete (2026-08-26) |
| SEG-01..SEG-05, SEG-11 | Phase 1 | Complete (2026-08-26) |
| CRM-01..CRM-10 | Phase 2 | Pending |
| SERV-01..SERV-10 | Phase 2 | Pending |
| ACT-01..ACT-08 | Phase 3 | Pending |
| API-01..API-10 | Phase 3 | Pending |
| SEG-06 | Phase 3 | Pending |
| EMAIL-01..EMAIL-06 | Phase 4 | Pending |
| CHAT-01..CHAT-04 | Phase 4 | Pending |
| VOICE-01..VOICE-05 | Phase 4 | Pending |
| SEG-15 | Phase 4 | Pending |
| DASH-01..DASH-14 | Phase 5 | Pending |
| FRESH-01..FRESH-05 | Phase 5 | Pending |
| SEG-07, SEG-13 | Phase 5 | Pending |
| SUP-01..SUP-05 | Phase 6 | Pending |
| FB-01..FB-08 | Phase 6 | Pending |
| TASK-01..TASK-03 | Phase 6 | Pending |
| INC-01..INC-05 | Phase 6 | Pending |
| DOC-01..DOC-16 | Phase 7 | Pending |
| RET-01..RET-05 | Phase 8 | Pending |
| NOTIF-01..NOTIF-04 | Phase 8 | Pending |
| EXP-01..EXP-04 | Phase 8 | Pending |
| SEG-08, SEG-09, SEG-10, SEG-12, SEG-14 | Phase 8 | Pending |

**Coverage:**
- v1 requirements: 155 total (140 FR + 15 NFR)
- Mapped to phases: 155
- Unmapped: 0 ✓

---
*Requirements defined: 2026-08-24*
*Last updated: 2026-08-24 after initial definition*
