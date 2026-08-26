---
phase: 01-fundaci-n-e-identidad-segura
plan: 02
subsystem: auth
tags: [mfa, totp, rotp, rqrcode, recovery-codes, password-reset, letter-opener, active-record-encryption]

# Dependency graph
requires:
  - phase: 01-01-walking-skeleton
    provides: User/Session/Auth:: base, rate_limit, vistas login, rake ci verde
provides:
  - MFA TOTP completo (AC-005): enrollment QR + confirmación, challenge post-password obligatorio con anti-replay por timestep, recovery codes un-solo-uso solo-digest
  - AC-006: organizations.require_mfa bloquea pre-sesión a usuarios sin enrollment; copy exacto UI-SPEC
  - D-05: reset por token efímero 30min un-uso solo-digest que revoca todas las sesiones e invalida enlaces previos
affects: [01-03 impersonación/memberships, fases 2+ (todo acceso interno exige MFA)]

# Tech tracking
tech-stack:
  added: [letter_opener]
  patterns: [pending-mfa-session-flag, token-solo-digest, drift-rotp-en-segundos, uniform-response-auth]

key-files:
  created:
    - app/models/identity/mfa_enrollment.rb
    - app/models/identity/recovery_code.rb
    - app/models/identity/password_reset_token.rb
    - app/controllers/auth/mfa/enrollments_controller.rb
    - app/controllers/auth/mfa/challenges_controller.rb
    - app/controllers/auth/passwords_controller.rb
    - app/mailers/auth_mailer.rb
    - db/policies/../db/migrate/*_create_{mfa_enrollments,recovery_codes,password_reset_tokens}.rb
    - test/integration/auth/{mfa_enrollment,mfa_challenge,org_required_mfa,password_reset}_test.rb
  modified:
    - app/controllers/concerns/authentication.rb
    - app/controllers/auth/sessions_controller.rb
    - app/models/user.rb
    - app/models/tenancy/organization.rb
    - config/routes.rb
    - config/credentials.yml.enc
    - config/environments/development.rb

key-decisions:
  - "rotp 6.x: drift_ahead/drift_behind son SEGUNDOS (30/paso), no pasos — sin esto la ventana de tolerancia era inexistente"
  - "Anti-replay por last_used_timestep estricto (>); confirmación consume su timestep para no reutilizarlo como primer challenge"
  - "AC-006 se aplica ANTES de crear Session (login devuelve 403 + pantalla explicativa): resuelve el chicken-and-egg del enrollment bloqueado dejando el alta para flujo administrativo/post-login"
  - "require_mfa togglable solo desde flujos administrativos internos hoy (consola/seeds); RBAC real llega con memberships en 01-03"
  - "Reset: validar nueva contraseña ANTES de consumir el token (un envío inválido no quema el enlace)"
  - "Secrets MFA cifrados con ActiveRecord Encryption (credenciales locales via master.key gitignored; CI necesitará RAILS_MASTER_KEY al publicar)"

patterns-established:
  - "Tokens sensibles SOLO como digest SHA256; valor claro únicamente en el canal de entrega"
  - "Respuestas uniformes vía constantes GENERIC_ERROR/UNIFORM_NOTICE compartidas entre controladores Auth::"
  - "Tests TOTP deterministas: confirmar en paso pasado (at(now-30)) para dejar libre la ventana actual"

requirements-completed: [AUTH-01, AUTH-02, AUTH-03, SEG-02, SEG-03]

# Metrics
duration: ~2h efectivas (misma sesión continua)
completed: 2026-08-25
---

# Phase 1 Plan 02: Identidad segura (MFA) Summary

**MFA TOTP end-to-end con anti-replay y recovery codes solo-digest, MFA exigible por organización pre-sesión (AC-005/006) y recuperación por token efímero que revoca sesiones**

## Performance

- **Duration:** ~2h
- **Started:** 2026-08-25T19:50Z aprox.
- **Completed:** 2026-08-25T22:05Z aprox.
- **Tasks:** 4
- **Files modified:** ~30

## Accomplishments
- Ningún usuario interno completa autenticación sin challenge TOTP exitoso; código repetido en ventana rechazado (probado negativamente)
- Organización con require_mfa=true impide sesión a quien carece de enrollment (403 + copy exacto), mientras quienes ya tienen MFA acceden tras challenge normal
- Reset de contraseña: token SHA256-digest de 30min un-solo-uso; al restablecer se invalidan enlaces previos y mueren TODAS las sesiones activas

## Task Commits

Each task was committed atomically:

1. **Task 1: Modelo MFA + enrollment con QR** - `feat(01-02)` modelo+controlador+vistas+cifrado
2. **Task 2: Challenge MFA post-password obligatorio** - `feat(01-02)` bifurcación login + challenges + anti-replay
3. **Task 3: MFA exigible por organización** - `feat(01-02)` require_mfa + enforcement 403
4. **Task 4: Recuperación por token efímero** - `feat(01-02)` PasswordResetToken + mailer + letter_opener

_(hashes individuales visibles en `git log --grep="01-02"`)_

## Files Created/Modified
Ver key-files. Destacados: `lib` de identidad bajo `Identity::`, rutas `/mfa/*` y `/password/*`, cuatro suites de integración nuevas.

## Decisions Made
Ver key-decisions en frontmatter (drift rotp en segundos, AC-006 pre-sesión, validate-before-consume en reset).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Ventana de tolerancia TOTP real**
- **Found during:** Task 2 (tests anti-replay flakes)
- **Issue:** rotp 6 usa drift_ahead/drift_behind en SEGUNDOS; con `1` la verificación solo aceptaba el paso exacto (sin tolerancia de reloj)
- **Fix:** STEP_SECONDS=30; verify con ±30s; confirmación en paso pasado en tests para determinismo
- **Files modified:** app/models/identity/mfa_enrollment.rb, tests
- **Verification:** suite ×3 estable
- **Committed in:** feat(01-02) challenge

**2. [Rule 3 - Blocking] Scope :valid invertido en PasswordResetToken**
- **Found during:** Task 4
- **Issue:** `expires_at: ..Time.current` seleccionaba EXPIRADOS; los vigentes daban nil
- **Fix:** `expires_at: Time.current..`
- **Files modified:** modelo + migración correctiva ya cubierta
- **Verification:** test expiración con travel 29/31min
- **Committed in:** feat(01-02) reset

**3. [Rule 3 - Blocking] Consumir token antes de validar contraseña quemaba el enlace ante un error tipográfico**
- **Found during:** Task 4 (test longitud mínima)
- **Fix:** find_valid (sin consumo) → update → consume! solo en éxito
- **Committed in:** feat(01-02) reset

---

**Total deviations:** 3 auto-fixed (1 missing critical, 2 blocking). **Impact:** correcciones de seguridad/corrección funcional dentro del alcance del plan.

## Issues Encountered
- Generador oficial de passwords eliminado (tokens firmados, sin digest ni revocación explícita): sustituido por implementación D-05 propia con tests
- Migración 194851 registrada vacía antes de rellenarse → columna añadida vía correctiva 201500 con guard column_exists?
- Active Record Encryption exigía credenciales: generadas con db:encryption:init y persistidas en credentials.yml.enc (master.key fuera de git)

## User Setup Required
None - letter_opener muestra los emails en navegador en desarrollo. En producción configurar SMTP_* (.env.example) — despliegue posterior.

## Next Phase Readiness
- Ready for 01-03: memberships sustituirán users.account_id (puente marcado para eliminar) y refinarán organization_requires_mfa? a nivel membership
- CI: al publicar repo, definir secret RAILS_MASTER_KEY para que las claves de cifrado estén disponibles

---
*Phase: 01-fundaci-n-e-identidad-segura*
*Completed: 2026-08-25*
