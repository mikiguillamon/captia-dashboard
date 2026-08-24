# ADR 0002: Aislamiento lógico compartido con defensa en profundidad

## Status

Accepted

## Context

Usuarios y servicios tienen ámbitos de Cuenta, Organización y Servicio. El aislamiento entre clientes es crítico.

## Options considered

### Autorización solo en aplicación

Es simple, pero una omisión en una consulta puede filtrar datos de otro cliente.

### Base compartida con autorización y seguridad por fila

Combina control centralizado del dominio y una barrera adicional en la base de datos.

### Base o esquema por cliente

Ofrece mayor separación física, pero complica operación, migraciones y agregados.

## Decision

Usar PostgreSQL autoalojado y compartido, con ámbitos explícitos, autorización centralizada en la aplicación y políticas de seguridad por fila en PostgreSQL.

## Rationale

Ofrece aislamiento fuerte para el MVP sin operar una base por cliente.

## Consequences

Las entidades de cliente llevan ámbito. Workers e integraciones establecen el contexto de autorización y no eluden políticas.

## Reversibility

Baja. Afecta modelo de datos, consultas y procesos desde el inicio.

## Follow-up

Definir permisos atómicos y revisar políticas antes de cambios sensibles.

