# Architecture Research: Captia Dashboard

**Researched:** 2026-08-24 (inline; fuente principal: docs/architecture/ARCHITECTURE.md + ADRs 0001–0007)

## Componentes (módulos del monolito modular)

Módulos con límites explícitos; ninguno usa las tablas de otro como contrato (ADR-0001):

1. **Identidad y sesiones** — credenciales, recuperación, sesiones, MFA, impersonación auditada.
2. **Autorización y tenancy** — Cuenta→Organización→Servicio→Instancia, roles plantilla, herencia, excepciones, ámbito en cada registro.
3. **CRM y aprovisionamiento** — leads/contactos/cuentas/oportunidades/pipeline; conversión asistida que crea cuenta, organizaciones, servicios, instancias, permisos e invitaciones.
4. **Catálogo de servicios e instancias** — tipos Email Assistant/Chatbot/Voice Assistant; estados contractual/operativo/salud separados; finalización programada.
5. **Operación** — interacciones, actividad, acciones supervisadas, tareas, incidencias (info interna/pública).
6. **Eventos, proyecciones, métricas y frescura** — ingesta API, ledger inmutable, proyecciones a actividad legible/métricas/frescura/incidencias.
7. **Documentación, conocimiento y sincronización** — editor Markdown, versiones/aprobación, herencia, publicación ≠ sincronización, eventos hacia sistemas externos.
8. **Notificaciones, exportaciones y auditoría** — internas + email, preferencias por categoría, exportaciones que heredan permisos, auditoría solo interna.

## Flujo de datos canónico

```
Sistema externo ──(API privada, contrato versionado,
                  idempotency-key, ámbito, fecha origen)──▶
Ingesta valida ▸ ¿válido? ──▶ LEDGER (inmutable)
                    │                │
        inválido→rechazo             ▼ (outbox transaccional)
        incompleto→marcado    WORKERS (jobs PG)
                                     ├─▶ Proyección Actividad (legible, humana)
                                     ├─▶ Proyección Métricas (+frescura, cobertura)
                                     ├─▶ Acciones supervisadas (pendientes)
                                     └─▶ Incidencias automáticas (fallos persistentes)
Usuario ◀── Vistas (estado técnico | resultado operativo | evaluación humana)
Acción supervisada: revisar/editar/aprobar/rechazar ▸ evento ▸ sistema externo confirma
Documentación: borrador▸aprobación▸publicado ▸(≠)▸ sincronizado ▸ confirmación externa
```

Objetivo: evento aceptado visible ≤ 30 s (NFR-006). Distinguir siempre cero/ausente/incompleto/desactualizado/error.

## Fronteras de seguridad prioritarias (ARCHITECTURE.md)

Identidad · ámbito · API privada · contenido sensible · exportaciones · auditoría · impersonación. Doble barrera: autorización centralizada en app + RLS en PostgreSQL; workers establecen contexto de ámbito y no eluden políticas.

## Orden de construcción sugerido (dependencias)

1. **Fundación técnica** — scaffold monolito, CI, migraciones, PostgreSQL+RLS, esqueleto de módulos.
2. **Identidad + tenancy** — sin esto nada es seguro ni aislable; impersonación necesita sesiones.
3. **CRM y aprovisionamiento** — crea los datos maestros (cuenta/org/servicio/instancia) por conversión asistida.
4. **Núcleo de eventos** — API privada + ledger + outbox + proyección de actividad/históricos.
5. **Tipos de servicio** — vistas Email/Chatbot/Voice consumiendo proyecciones; interacciones evaluables.
6. **Métricas y frescura** — dashboards sobre proyecciones; drill-down a históricos.
7. **Feedback/tareas/incidencias + acciones supervisadas** — colaboración sobre interacciones.
8. **Documentación/conocimiento/sincronización** — flujo editorial completo.
9. **Retención, notificaciones, exportaciones, móvil, endurecimiento** — cierre transversal.

Las fases 2–3 pueden parcialmente paralelizarse tras la 1; la 4 bloquea 5–6; 7 depende de 5; 8 y 9 son mayormente independientes entre sí.

## Implicación para roadmap

Cada fase entrega capacidad observable end-to-end (modo mvp). La API privada y el ledger aparecen temprano porque los tres tipos de servicio dependen de ellos. El CRM precede al catálogo porque la conversión asistida es la vía de creación de instancias (journey 6.1), aunque el catálogo debe existir en forma mínima desde la fase 3.
