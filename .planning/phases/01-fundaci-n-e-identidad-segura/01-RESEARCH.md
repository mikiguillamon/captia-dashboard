# Phase 1: Fundación e identidad segura - Research

**Researched:** 2026-08-24
**Domain:** Rails 8.1 monolito modular · PostgreSQL RLS multi-tenancy · auth nativa TOTP + impersonación auditada
**Confidence:** HIGH (versiones framework verificadas ago-2026; minors de gemas se confirman al instalar)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Módulos = namespaces Ruby con contratos internos; sin Rails::Engine en fundación
- D-02: ADR-0008 (adopción Rails 8.1) durante scaffold
- D-03: MFA único factor MVP = TOTP; sin SMS/SaaS
- D-04: Sesiones server-side persistidas en PostgreSQL; NO JWT
- D-05: Recuperación por token un-solo-uso ≈30 min vía SMTP autoalojado
- D-06: Impersonación con re-auth interno, expiración ≈30 min, banner persistente, auditoría actor real
- D-07: Contexto de ámbito vía helper transaccional obligatorio (`SET LOCAL app.account_id/app.organization_id`), workers incluidos
- D-08: Suite de aislamiento AC-001..004 como criterio de salida de fase
- D-09: Motor de permisos genérico con catálogo mínimo; escalar OD-008 antes de Fase 3

### the agent's Discretion
Gemas TOTP/QR concretas, estructura interna de carpetas, herramienta CI (pendiente hosting), esquema de migraciones dentro de ADR-0002.

### Deferred Ideas (OUT OF SCOPE)
CRM/servicios/eventos/dashboards/docs/notificaciones (fases 2–8); catálogo definitivo OD-008.
</user_constraints>

<architectural_responsibility_map>
## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Autenticación/sesiones/MFA | API/Backend (Rails) | Browser (formularios Hotwire) | Identidad nativa ADR-0003 |
| Autorización y tenancy | Backend + Database (RLS) | — | Doble barrera ADR-0002 |
| Impersonación auditada | Backend | Browser (banner) | Auditoría en servidor |
| UI login/MFA/admin básico | Frontend Server (ERB+Turbo) | — | Server-rendered responsive |
</architectural_responsibility_map>

<research_summary>
## Summary

Investigado el stack Rails 8.1 para identidad multi-tenant con RLS. Enfoque estándar 2026: generador de autenticación integrado de Rails 8 como base (sesiones server-side, password_digest bcrypt) ampliado con TOTP vía gema mantenida; Solid Queue para jobs en PostgreSQL (encaje 1:1 con ADR-0005); políticas RLS por migraciones y contexto de ámbito por transacción.

Hallazgo clave: Rails 8 trae `rate_limit`, sesiones seguras y generator de auth — no se necesita Devise. La doble barrera (app+RLS) exige UN helper transaccional; cualquier consulta cliente fuera de él es bug de seguridad.

**Primary recommendation:** Scaffold mínimo Rails 8.1+PostgreSQL+Tailwind, helper RLS transaccional desde la primera tabla, auth generada extendida con rotp para TOTP, suite system tests de aislamiento como gate de salida.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ruby / rails | 3.4.x / ~> 8.1 | Runtime/framework | Rama soportada actual (verificado ago-2026); 8.0 EOL nov-2026 |
| postgresql | >= 16 | Persistencia + RLS + cola | Único almacén (ADR-0002/0005) |
| solid_queue | bundled Rails 8 | Jobs/outbox en PG | Sin Redis/broker (ADR-0005) |
| turbo-rails + stimulus | bundled Rails 8 | Interactividad sin SPA | Hotwire estándar |
| bcrypt | default Rails | Hashing contraseñas | Primitiva probada; no rodar crypto propio |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| rotp | latest | TOTP RFC-6238 | MFA interno/exigible por org |
| rqrcode | latest | QR provisión TOTP | Enrollment |
| brakeman | latest | Análisis estático seguridad | Gate QUALITY_BAR security-sensitive |

**Installation:**
```bash
rails new . --database=postgresql -j importmap -c tailwind --skip-action-mailbox --skip-action-text --skip-action-cable
bundle add rotp rqrcode brakeman
```

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| rotp | devise-two-factor | Acopla a Devise; no usamos Devise |
| minitest (default) | rspec | Más expresivo pero añade dependencia; default basta |
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### System Architecture Diagram
```
Browser ──(cookie sesión segura)──▶ Rails Router
   │                    ┌────────────┴─────────────┐
   │                    │ Auth:: (Identity ns)      │
   │                    │ credencial bcrypt →       │
   │                    │ challenge TOTP si aplica  │
   │                    └────────────┬─────────────┘
   │                    ┌────────────▼─────────────┐
   └── Turbo/Stimulus ◀── Tenancy::Context (D-07)    │
        (UI reactiva)      BEGIN; SET LOCAL app.*    │
                           └────────────┬────────────┘
                     PostgreSQL ▶ RLS policies por tenant
                     Admin::Impersonations → audit_log(actor_real, impersonado, acción)
```

### Recommended Project Structure
```
app/models/identity/     # User, Session, MfaEnrollment, RecoveryCode
app/models/tenancy/      # Account, Organization, Membership, RoleAssignment
app/controllers/auth/    # sessions, passwords, mfa challenges
app/controllers/admin/   # accounts, organizations, impersonations
lib/tenancy/context.rb   # helper transaccional SET LOCAL (único punto)
db/policies/             # SQL de políticas RLS aplicado por migraciones
test/system/tenancy/     # suite aislamiento AC-001..004 (D-08)
```

### Pattern 1: Contexto RLS transaccional (D-07)
**What:** Todo acceso a datos cliente viaja dentro de un bloque que fija `SET LOCAL app.account_id` y `app.organization_id`; RLS niega por defecto.
**When to use:** Siempre para tablas tenant; workers fijan contexto desde argumentos del job.
**Anti-patterns:** consultas cliente fuera del helper; superusuario de app (RLS no aplica a BYPASSRLS); olvidar FORCE ROW LEVEL SECURITY para owner.

### Pattern 2: Sesión como modelo (Rails 8 auth generator)
**What:** `sessions` tabla con token; cookie HttpOnly; revocación = borrado fila. Base para MFA step-up e impersonación.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hashing contraseñas | hash propio | bcrypt (ActiveModel::SecurePassword) | Parametrización, timing attacks |
| TOTP | implementación RFC propia | rotp | Ventanas, drift, replay |
| Rate limiting login | contador manual | Rails 8 rate_limit | Probado, por IP/ruta |
| CSRF/sesiones seguras | middleware custom | Rails built-ins | Estándares web cubiertos |
| QR provisioning | SVG manual | rqrcode | Encoding correcto otpauth:// |
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Bypass del contexto RLS
**What goes wrong:** consulta cliente sin SET LOCAL filtra datos cruzados.
**Why it happens:** atajo fuera del helper o worker sin scope.
**How to avoid:** helper único + revisión + tests AC-001/AC-004 desde primera tabla.
**Warning signs:** queries raw con account_id hardcodeado.

### Pitfall 2: Replay TOTP
**What goes wrong:** mismo código usado dos veces en su ventana.
**How to avoid:** guardar last_used_timestep y rechazar ≤ anterior.

### Pitfall 3: Impersonación sin actor real
**What goes wrong:** auditoría atribuye acciones al usuario impersonado.
**How to avoid:** actor real en Current.attributes desde el inicio; toda escritura registra par (real, efectivo).
**Warning signs:** audit_log sin columna actor_real_id.
</common_pitfalls>

<sota_updates>
## State of the Art (2024-2026)

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Devise + Devise-two-factor | Generator auth Rails 8 + rotp | Menos dependencias |
| Sidekiq+Redis | Solid Queue en PG | Cero infra extra (ADR-0005) |
| sprockets | propshaft/importmap | Default Rails 8 |
</sota_updates>

<open_questions>
## Open Questions
1. **Proveedor CI/hosting repo** — repo hoy solo local. Recomendación: GitHub Actions como YAML preparado; activar al publicar.
2. **SMTP autoalojado concreto** (postfix vs msmtprp relay) — diferir a ejecución; dev usa letter_opener.
</open_questions>

## Validation Architecture

Capas de verificación para la fase (base de VALIDATION.md):

| Layer | Tool | Scope |
|-------|------|-------|
| Lint/style | rubocop-rails-omakase | Todo commit |
| Security static | brakeman | Gate de fase (security-sensitive) |
| Unit/model | minitest | Modelos Identity/Tenancy, validaciones de ámbito NOT NULL |
| Request/auth flow | minitest request tests | login, MFA challenge, reset tokens, rate limit |
| System/E2E | Capybara (headless) | AC-001..AC-007 completos |
| DB isolation | minitest + SQL directo | RLS deny cross-tenant con y sin contexto; workers |

Elementos Nyquist: cada REQ de fase mapea ≥1 test automatizado; los 7 ACs son E2E observables; fallos de seguridad requieren prueba negativa explícita.

<sources>
## Sources
### Primary (HIGH)
- rubyonrails.org/releases + endoflife.date/rails — versiones 8.1.x/Ruby 3.4 (verificado 2026-08)
- endoflife.date/django, guides.rails 8.0 notes — comparativa y defaults Rails 8
### Secondary (MEDIUM)
- Docs oficiales Solid Queue/rotp — patrones de uso (confirmar API exacta al instalar)
</sources>

<metadata>
## Metadata
**Confidence breakdown:** stack HIGH (verificado) · arquitectura HIGH (ADRs+docs) · gemas menores MEDIUM (API confirmar al instalar) · validación HIGH
**Research date:** 2026-08-24 · **Valid until:** 2026-09-23
</metadata>

---
*Phase: 01-fundaci-n-e-identidad-segura*
*Research completed: 2026-08-24*
*Ready for planning: yes*
