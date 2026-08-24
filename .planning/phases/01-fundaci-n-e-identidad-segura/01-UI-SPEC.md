---
phase: 1
slug: fundaci-n-e-identidad-segura
status: draft
shadcn_initialized: false
preset: none
created: 2026-08-24
---

# Phase 1 — UI Design Contract

> Generado inline (desviación por presupuesto; normalmente gsd-ui-researcher/ui-checker). Superficies UI de esta fase: login, challenge MFA, enrollment TOTP, recuperación, selector/admin básico de organizaciones, banner de impersonación.

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Hotwire + Tailwind CSS vía scaffold Rails) |
| Preset | not applicable |
| Component library | none (partials ERB) |
| Icon library | ninguno en Fase 1 |
| Font | system-ui stack (sin webfonts externas — autoalojado ADR-0007) |

## Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | gaps de iconos/inline |
| sm | 8px | spacing compacto formularios |
| md | 16px | default elementos |
| lg | 24px | padding secciones |
| xl | 32px | gaps layout |
| 2xl | 48px | separación mayor |
| 3xl | 64px | spacing página |

Exceptions: none

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.5 |
| Label | 14px | 500 | 1.4 |
| Heading | 20px | 600 | 1.3 |
| Display | 28px | 700 | 1.2 |

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | #FFFFFF | fondo, superficies |
| Secondary (30%) | #F3F4F6 / slate-100 | tarjetas, sidebar, nav |
| Accent (10%) | #2563EB (blue-600) | CTA primario, links, foco |
| Destructive | #DC2626 (red-600) | solo acciones destructivas (revocar sesión, rechazar) |

Accent reservado para: botón primario "Iniciar sesión", enlaces activos, anillo de foco de inputs.

Estados obligatorios (QUALITY_BAR UI): loading (spinner/deshabilitar submit), empty ("Sin organizaciones todavía"), error (mensaje bajo campo), responsive (mobile-first: formularios full-width <640px), teclado (orden de tabulación nativo, foco visible), accesibilidad (labels asociados, aria-live para errores de MFA).

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | Iniciar sesión |
| Empty state heading | Sin organizaciones todavía |
| Empty state body | Tu cuenta aún no tiene organizaciones. Contacta con el equipo de Captia para configurarlas. |
| Error estado (login/MFA) | Credenciales o código incorrectos. Compruébalos e inténtalo de nuevo. |
| Banner impersonación | Estás operando como {usuario} a petición de {empleado}. Todas las acciones quedan registradas. — Salir |
| Destructive confirmation | Revocar sesión: Esta acción cerrará la sesión en ese dispositivo. ¿Continuar? |

Idioma de interfaz: español (idioma del PRD y clientes iniciales).

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| third-party | none | n/a |

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending (revisar antes de ejecutar Plan 01-01 T3+; visual states clave requieren revisión humana según QUALITY_BAR)
