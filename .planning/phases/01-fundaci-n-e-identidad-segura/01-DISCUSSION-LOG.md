# Phase 1: Fundación e identidad segura - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-24
**Phase:** 1-Fundación e identidad segura
**Areas discussed:** Estructura del monolito, Factor MFA, Arquitectura de sesiones, Operativa de impersonación, Contexto multi-tenant RLS, Catálogo de permisos (OD-008)

> Ejecutado en modo `--auto` dentro de la cadena autónoma aprobada por el usuario
> (`/gsd-new-project --auto` + aprobación explícita del stack). Cada área se auto-seleccionó
> completa y se resolvió con la opción recomendada, según `modes/auto.md`.

## Estructura del monolito

| Option | Description | Selected |
|--------|-------------|----------|
| Namespaces + interfaces explícitas | Módulos como namespaces Ruby con contratos internos; engines diferidos | ✓ |
| Rails::Engine por módulo desde día 1 | Enforcement duro de límites desde el inicio | |

**User's choice:** [auto] Recomendada — namespaces primero (CONSTITUTION §2 simplicidad; ADR-0001 no exige engines).
**Notes:** Reversibility costly registrada en D-01.

## Factor MFA

| Option | Description | Selected |
|--------|-------------|----------|
| TOTP único (app autenticadora) | Autoalojado, sin SaaS de SMS; aditivo para factores futuros | ✓ |
| SMS/OTP por email | Menor fricción inicial pero requiere proveedor externo o SMTP OTP propio | |

**User's choice:** [auto] TOTP único en MVP.
**Notes:** ADR-0007 prohíbe SaaS salvo aprobación expresa.

## Arquitectura de sesiones

| Option | Description | Selected |
|--------|-------------|----------|
| Sesiones server-side persistidas | Store en PostgreSQL, cookie segura, revocables | ✓ |
| JWT stateless | Sin estado servidor pero revocación/impersonación complicadas | |

**User's choice:** [auto] Server-side persistidas.
**Notes:** Revocación requerida por re-auth MFA e impersonación.

## Operativa de impersonación

| Option | Description | Selected |
|--------|-------------|----------|
| Re-auth + 30 min + banner persistente | Parámetros conservadores por defecto | ✓ |
| Sin re-auth / duración larga | Más cómodo, mayor riesgo auditado | |

**User's choice:** [auto] Conservadora.
**Notes:** FR-015..018 fijan auditoría y notificación configurable; parámetros operativos son reversibles.

## Contexto multi-tenant RLS

| Option | Description | Selected |
|--------|-------------|----------|
| Helper transaccional obligatorio + tests gate de salida | `SET LOCAL app.*` centralizado; suite aislamiento AC-001..004 obligatoria | ✓ |
| Autorización solo en aplicación, RLS después | Más rápido al inicio, retrofit brutal | |

**User's choice:** [auto] Helper + tests desde el inicio.
**Notes:** D-07 marcada one-way (PITFALL #1); D-08 convierte los tests en criterio de salida de fase.

## Catálogo de permisos atómicos (OD-008)

| Option | Description | Selected |
|--------|-------------|----------|
| Motor genérico + catálogo mínimo de fase; escalar OD-008 antes de Fase 3 | Respeta decision abierta del PRD | ✓ |
| Definir catálogo completo ahora | Inventaría una decisión que el PRD reserva al usuario | |

**User's choice:** [auto] Motor genérico + escalación programada.
**Notes:** AUTONOMY_POLICY: auth/authz policy requiere implicación del usuario.

## the agent's Discretion

Gemas TOTP/hashing, estructura interna de carpetas, herramienta de CI (pendiente de hosting del repo), detalles de esquema dentro de ADR-0002.

## Deferred Ideas

Ninguna nueva. OD-008 queda como gate documentado en CONTEXT.md (D-09), no como idea diferida.
