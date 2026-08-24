# Roadmap: Captia Dashboard

**Vision:** Portal de clientes y herramienta operativa que centraliza servicios ejecutados por sistemas externos —observabilidad, colaboración, supervisión, feedback, documentación y trazabilidad— con CRM interno integrado desde lead hasta operación.

**Requirements:** `.planning/REQUIREMENTS.md` (155 requisitos v1)
**Project:** `.planning/PROJECT.md`
**Research:** `.planning/research/SUMMARY.md`

⚠ **Gate previo a ejecución de Fase 1:** aprobar stack framework/lenguaje (ver `research/STACK.md`; AUTONOMY_POLICY exige decisión del usuario).

## Phases

### Phase 1: Fundación e identidad segura
**Goal:** Monolito modular operando con CI, PostgreSQL+RLS, identidad nativa completa (credenciales, sesiones, MFA), modelo Cuenta→Organización→Usuario con roles plantilla/herencia/excepciones e impersonación auditada.
**Mode:** mvp
**UI hint**: yes
**Requirements:** TEN-01..11, AUTH-01..07, SEG-01..05, SEG-11
**Success Criteria**:
1. Usuario nivel cuenta accede a sus 3 organizaciones mientras un usuario de organización solo ve la asignada (AC-001)
2. Un Comercial sin excepciones no puede acceder a emails, chats ni transcripciones de clientes (AC-003); un Técnico asignado a una cuenta no consulta operativa de otra (AC-004)
3. Ningún usuario interno autentica sin completar MFA (AC-005) y una organización con MFA obligatorio bloquea a sus usuarios hasta completarlo (AC-006)
4. Toda acción realizada durante impersonación registra al empleado interno como actor real (AC-007)

### Phase 2: CRM, aprovisionamiento y catálogo de servicios
**Goal:** Ciclo comercial completo (leads→oportunidades→pipeline→conversión asistida) que crea cuenta, organizaciones, servicios, instancias, permisos y activa el portal; catálogo con tipos Email Assistant/Chatbot/Voice Assistant, múltiples instancias configurables y estados contractual/operativo/salud separados.
**Mode:** mvp
**UI hint**: yes
**Requirements:** CRM-01..10, SERV-01..10
**Success Criteria**:
1. Marcar oportunidad ganada inicia conversión asistida; el portal no se activa hasta completar el flujo (AC-028)
2. Una organización mantiene dos instancias del mismo tipo con actividad, métricas y configuración separadas (AC-002)
3. Un servicio programado para finalizar sigue operando hasta la fecha efectiva (AC-029) y su visibilidad histórica posterior depende de la configuración elegida (AC-030)

### Phase 3: Núcleo de eventos, API privada y actividad
**Goal:** API privada versionada con idempotencia y validación de entrada; ledger inmutable + outbox/workers en PostgreSQL; proyección de actividad comprensible; históricos con búsqueda y filtros comunes.
**Mode:** mvp
**Requirements:** ACT-01..08, API-01..10, SEG-06
**Success Criteria**:
1. Evento duplicado con identificador inequívoco no incrementa dos veces las métricas asociadas (AC-025); inválido rechazado no modifica métricas normales (AC-026); incompleto utilizable se registra sin presentar ausentes como valores reales (AC-027)
2. Un evento aceptado es visible en las vistas operativas en ≤30 segundos objetivo (NFR-006)
3. El histórico filtra correctamente por periodo, organización, servicio, instancia, estados técnico/operativo/evaluación, presencia de feedback/incidencia y texto/identificador (FR-074)

### Phase 4: Tipos de servicio — Email Assistant, Chatbot y Voice Assistant
**Goal:** Vistas de interacciones evaluables por servicio: histórico y detalle completo del email procesado; conversaciones con respuestas identificadas; llamadas con transcripción segmentada; evaluación global y por partes.
**Mode:** mvp
**UI hint**: yes
**Requirements:** EMAIL-01..06, CHAT-01..04, VOICE-01..05, SEG-15
**Success Criteria**:
1. Un Email Assistant permite consultar email entrante, decisión del agente, respuesta generada y respuesta enviada cuando existan (AC-008)
2. Una conversación permite evaluar tanto la conversación completa como una respuesta concreta (AC-009)
3. Una llamada permite evaluar globalmente la llamada y un segmento identificable de la transcripción (AC-010)
4. Añadir un cuarto tipo de servicio no exige rediseñar cuentas/organizaciones/servicios/instancias (NFR-015)

### Phase 5: Dashboards, métricas y frescura
**Goal:** Dashboards a 4 niveles con widgets por defecto por tipo y override por instancia (sin configuración cliente), periodos/comparativas, drill-down, separación técnica/operativo/humano, satisfacción+cobertura e indicadores de frescura con umbrales.
**Mode:** mvp
**UI hint**: yes
**Requirements:** DASH-01..14, FRESH-01..05, SEG-07, SEG-13
**Success Criteria**:
1. El dashboard distingue éxito técnico, resultado operativo y evaluación humana cuando las tres dimensiones existen (AC-015)
2. Con 100 de 1.000 interacciones evaluadas y 90 satisfactorias se muestra 90 % de satisfacción y 10 % de cobertura, sin clasificar las 900 restantes (AC-016)
3. Seleccionar una métrica con drill-down abre el histórico con los filtros que explican la cifra (AC-017)
4. Si una integración supera su umbral sin datos, el portal indica posible desactualización (AC-018)
5. Una instancia sobrescribe los widgets definidos por su tipo (AC-034) pero el cliente no puede reorganizarlos libremente (AC-035)

### Phase 6: Acciones supervisadas, feedback, tareas e incidencias
**Goal:** Flujo de intervención humana sobre acciones pendientes (ver/editar/aprobar/rechazar con caducidad sin autoejecución), evaluaciones con correcciones/comentarios convertibles en tareas, workflow de mejora, y incidencias con información interna/pública diferenciada.
**Mode:** mvp
**UI hint**: yes
**Requirements:** SUP-01..05, FB-01..08, TASK-01..03, INC-01..05
**Success Criteria**:
1. Una acción supervisada puede ser editada, aprobada o rechazada según capacidades del usuario (AC-013) y una vencida nunca se ejecuta automáticamente (AC-014)
2. Una evaluación incorrecta admite corrección propuesta y comentario (AC-011)
3. Un feedback convertido en tarea conserva referencia a su origen (AC-012)
4. Una incidencia contiene información interna separada de la visible al cliente (AC-023)

### Phase 7: Documentación, conocimiento y sincronización
**Goal:** Editor Markdown con documentos/conocimiento en todos los niveles, herencia con sustitución explícita, versiones con autoría/restauración/aprobación configurable, y ciclo publicación ≠ sincronización con eventos, confirmación externa y reintentos.
**Mode:** mvp
**UI hint**: yes
**Requirements:** DOC-01..16
**Success Criteria**:
1. Un documento publicado aún no sincronizado muestra estados diferentes de publicación y sincronización (AC-019)
2. Un documento heredado puede ser sustituido explícitamente en un nivel inferior (AC-020)
3. Restaurar una versión anterior no elimina el historial de versiones (AC-021)
4. Un fallo persistente de sincronización produce una incidencia visible para el equipo interno (AC-022)

### Phase 8: Retención, notificaciones, exportaciones y cierre transversal
**Goal:** Políticas de retención con workflow de borrado solicitado por clientes, notificaciones internas/email con preferencias por categoría y obligatorias, exportaciones autorizadas CSV/Markdown, experiencia móvil de supervisión y verificación transversal (backups RPO/RTO, auditoría sin fallos silenciosos).
**Mode:** mvp
**UI hint**: yes
**Requirements:** RET-01..05, NOTIF-01..04, EXP-01..04, SEG-08, SEG-09, SEG-10, SEG-12, SEG-14
**Success Criteria**:
1. Una solicitud de eliminación de cliente no borra contenido sin pasar por el workflow configurado (AC-024)
2. Preferencias de email configurables por categoría sin poder desactivar obligatorias (AC-031)
3. Solo se exporta información ya accesible en el portal (AC-032)
4. Desde móvil un usuario autorizado consulta estado, actividad, incidencias y ejecuta acciones rápidas soportadas (AC-033)
5. Backup restaurado cumple RPO ≈1h / RTO ≤24h en prueba de recuperación (SEG-08/09)

## Coverage

155/155 requisitos v1 mapeados · 35/35 ACs del PRD usados como criterios de éxito ✓

---
*Roadmap created: 2026-08-24*
