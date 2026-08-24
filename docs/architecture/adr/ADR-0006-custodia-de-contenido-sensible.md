# ADR 0006: Custodiar en Captia el contenido operativo necesario

## Status

Accepted

## Context

El portal debe mostrar emails, conversaciones, transcripciones, documentación, feedback e históricos, que pueden contener datos sensibles.

## Options considered

### Solo metadatos y enlaces externos

Reduce custodia, pero compromete trazabilidad, experiencia y disponibilidad.

### Custodia completa en Captia

Permite vistas e históricos independientes, a costa de obligaciones de privacidad, seguridad y retención.

### Modelo híbrido

Puede limitar algunos contenidos, pero añade complejidad de contratos y comportamiento.

## Decision

Captia custodia el contenido necesario para las vistas y trazabilidad. Datos operativos y objetos de contenido se separan para aplicar acceso, cifrado y retención adecuados.

## Rationale

Satisface de forma consistente histórico, detalle, feedback, documentación y exportación autorizada.

## Consequences

Retención, borrado, exportación y acceso requieren diseño de privacidad y seguridad. No se fijan plazos ni tratamiento de eliminación hasta resolver OD-004 y OD-014.

## Reversibility

Baja. Cambiar a referencias externas implica migraciones de datos e integraciones.

## Follow-up

Definir política de retención y tratamiento de contenido eliminado.

