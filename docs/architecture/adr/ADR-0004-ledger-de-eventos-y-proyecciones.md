# ADR 0004: Conservar un ledger canónico de eventos y proyecciones derivadas

## Status

Accepted

## Context

Las integraciones envían eventos granulares. Captia debe evitar duplicados, reconstruir actividad y reflejar eventos aceptados en las vistas en un objetivo de 30 segundos.

## Options considered

### Escritura directa en tablas funcionales

Simplifica la entrada, pero dificulta deduplicación, auditoría y reconstrucción.

### Event sourcing completo

Hace que los eventos sean la fuente de verdad de todo el dominio, con complejidad no justificada para el MVP.

### Ledger con proyecciones

Conserva eventos aceptados y construye vistas derivadas, manteniendo entidades de negocio para los comandos.

## Decision

Persistir un ledger canónico, inmutable, versionado e idempotente de eventos operativos aceptados, y derivar proyecciones para actividad, interacciones, métricas, frescura e incidencias.

## Rationale

Satisface trazabilidad, idempotencia y diagnóstico sin adoptar event sourcing completo.

## Consequences

Los contratos incluyen versión y clave de idempotencia cuando sea posible. Eventos inválidos no afectan proyecciones; los incompletos se identifican.

## Reversibility

Baja. Define integración, almacenamiento y cálculo de métricas.

## Follow-up

Definir contratos de evento y catálogo de métricas por servicio.

