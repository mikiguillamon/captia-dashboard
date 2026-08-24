# ADR 0005: Usar outbox transaccional y trabajos persistidos en PostgreSQL

## Status

Accepted

## Context

Captia necesita ejecutar proyecciones, reintentos, notificaciones e incidencias sin un servicio externo.

## Options considered

### Broker o cola gestionada

Escala de forma independiente, pero introduce un servicio externo.

### Broker autoalojado

Evita SaaS, pero añade una pieza operativa no necesaria para el MVP.

### Outbox y trabajos en PostgreSQL

Usa la misma persistencia autoalojada y permite consistencia transaccional entre cambios y trabajo desencadenado.

## Decision

Usar outbox transaccional y trabajos persistidos en PostgreSQL autoalojado. Los productores y consumidores dependen de una interfaz interna, no de la tabla.

## Rationale

Es la solución con menor dependencia operativa que satisface las necesidades conocidas del MVP.

## Consequences

Se observarán capacidad y latencia. Si no se cumple el objetivo de 30 segundos, se evaluará un broker autoalojado mediante ADR nuevo.

## Reversibility

Media. Una interfaz interna permite sustituir el mecanismo de cola con planificación.

## Follow-up

Definir política de reintentos y criterios de fallo persistente.

