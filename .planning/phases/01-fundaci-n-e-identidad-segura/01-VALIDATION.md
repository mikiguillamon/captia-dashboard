---
phase: 1
slug: fundaci-n-e-identidad-segura
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-24
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | minitest (Rails default) + Capybara system tests |
| **Config file** | `test/test_helper.rb` (creado por scaffold Wave 0) |
| **Quick run command** | `bin/rails test` |
| **Full suite command** | `bin/rails test:all && bundle exec brakeman --no-pager && bundle exec rubocop` |
| **Estimated runtime** | ~60–120 s full |

## Sampling Rate

- **After every task commit:** `bin/rails test`
- **After every plan wave:** full suite command
- **Before `/gsd-verify-work`:** Full suite green
- **Max feedback latency:** ~120 s

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-T2 | 01 | 1 | SEG-01 / TEN-01..02 | T1-01 (bypass RLS) | Consulta sin contexto → 0 filas cross-tenant | integration+SQL | `bin/rails test test/integration/tenancy/rls_context_test.rb` | ❌ W0 | ⬜ pending |
| 01-01-T3 | 01 | 1 | AUTH-01 | — | Login password-only del skeleton | request | `bin/rails test test/integration/auth/` | ❌ W0 | ⬜ pending |
| 01-02-T* | 02 | 2 | AUTH-02..03, SEG-02..03 | T1-02 (replay TOTP) | Sin MFA no hay sesión interna; código usado se rechaza | request/system | `bin/rails test test/integration/auth/mfa_challenge_test.rb` | ❌ W0 | ⬜ pending |
| 01-02-T* | 02 | 2 | AUTH (recuperación) | — | Token un-solo-uso 30 min invalida previos | request | `bin/rails test test/integration/auth/password_reset_test.rb` | ❌ W0 | ⬜ pending |
| 01-03-T* | 03 | 3 | TEN-03..11 | — | Roles plantilla+excepciones restringen acceso | system | `bin/rails test test/system/tenancy/` | ❌ W0 | ⬜ pending |
| 01-03-T* | 03 | 3 | AUTH-04..07, SEG-04..05, SEG-11 | T1-03 (impersonación sin actor real) | audit_log registra actor real siempre | system | `bin/rails test test/system/admin/impersonations_test.rb` | ❌ W0 | ⬜ pending |
| 01-03-T* | 03 | 3 | D-08 / AC-001..004 | T1-01 | Suite aislamiento E2E completa verde | system | `bin/rails test test/system/tenancy/isolation_ac_test.rb` | ❌ W0 | ⬜ pending |

## Wave 0 Requirements

- [ ] Scaffold crea `test/` infrastructure (minitest+Capybara) — Plan 01-01 T1
- [ ] `test/integration/tenancy/rls_context_test.rb` stub negativo desde primera tabla tenant
- [ ] `bin/rails db:test:prepare` con políticas RLS aplicadas en entorno test

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| QR TOTP escaneable con app autenticadora | AUTH-02 | Requiere dispositivo físico | Escanear QR de enrollment con Google Authenticator/Aegis y validar código aceptado |
| Banner de impersonación visible y legible | AUTH-06/AC-007 (UI) | Juicio visual | Iniciar impersonación y verificar banner persistente en cada página |

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120 s
- [ ] `nyquist_compliant: true` set after Wave 0

**Approval:** pending
