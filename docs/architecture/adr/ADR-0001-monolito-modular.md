# ADR 0001: Adoptar un monolito modular para el MVP

## Status

Accepted

## Context

El MVP combina portal, CRM, permisos, documentación e integraciones, se usará inicialmente de forma controlada y no tiene SLA contractual.

## Options considered

### Microservicios por dominio

Aíslan despliegues, pero introducen contratos distribuidos, operación y observabilidad desproporcionados para el MVP.

### Monolito modular

Una unidad desplegable con límites explícitos entre dominios.

## Decision

Usar un monolito modular con módulos de dominio explícitos y contratos internos acotados.

## Rationale

Minimiza complejidad operativa sin cerrar una extracción futura sustentada por necesidad real.

## Consequences

Los módulos no comparten tablas como interfaces y sus dependencias se mantienen explícitas.

## Reversibility

Media. Extraer módulos será viable si se respetan los límites, pero no se hará preventivamente.

## Follow-up

Definir la estructura interna al planificar implementación.

