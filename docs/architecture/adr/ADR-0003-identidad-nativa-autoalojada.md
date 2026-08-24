# ADR 0003: Implementar identidad nativa autoalojada

## Status

Accepted

## Context

Captia exige cuentas individuales, MFA interno obligatorio, MFA configurable por organización e impersonación auditada. No se desean servicios externos ni un gestor de identidad separado.

## Options considered

### Proveedor gestionado

Reduce trabajo de seguridad, pero crea dependencia externa y coste.

### IdP autoalojado separado

Evita SaaS, pero añade infraestructura y complejidad no necesarias para el MVP.

### Identidad nativa

Captia gestiona credenciales, recuperación, sesiones y MFA en su propia infraestructura.

## Decision

Implementar identidad nativa y autoalojada en Captia. La autorización de ámbitos y permisos permanece separada.

## Rationale

Cumple la independencia operativa requerida sin introducir un gestor de identidad complejo.

## Consequences

Captia asume la responsabilidad de proteger credenciales, recuperación, sesiones y MFA. La implementación requerirá revisión de seguridad explícita.

## Reversibility

Baja. Migrar identidades y factores MFA a un IdP futuro exige una migración segura.

## Follow-up

Definir mecanismos concretos de MFA, recuperación y protección de credenciales en un diseño de seguridad aprobado.

