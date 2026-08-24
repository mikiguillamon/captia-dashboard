# ADR 0007: Priorizar infraestructura y dependencias operativas autoalojadas

## Status

Accepted

## Context

El producto debe evitar dependencias de servicios externos. Si una capacidad adicional es imprescindible, debe poder operarla el propio equipo.

## Options considered

### Servicios SaaS gestionados

Reducen operación inicial, pero crean dependencia de proveedor, coste recurrente y restricciones potenciales sobre datos sensibles.

### Componentes autoalojados

Mantienen control de datos y operación, a costa de desplegar, actualizar, respaldar y monitorizar cada componente.

## Decision

Priorizar infraestructura y dependencias operativas autoalojadas. No se adoptará un SaaS o servicio externo salvo necesidad extrema, justificación documentada y aprobación expresa. Cuando exista una alternativa, deberá poder autoalojarse.

## Rationale

Respeta la independencia operativa requerida y reduce lock-in de terceros.

## Consequences

El equipo asume operación, copias de seguridad, actualizaciones, seguridad y recuperación de cada componente elegido.

## Reversibility

Media. Cambiar componentes requiere planificar migración de datos y operación.

## Follow-up

Toda nueva dependencia operativa documentará necesidad, operación, backup y recuperación antes de adoptarse.

