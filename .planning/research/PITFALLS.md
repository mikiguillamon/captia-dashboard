# Pitfalls Research: Captia Dashboard

**Researched:** 2026-08-24 (inline; derivado de RISK-001..010 del PRD, NFRs y ADRs)

| # | Pitfall | Señales tempranas | Prevención | Fase |
|---|---------|-------------------|------------|------|
| 1 | **Bypass del aislamiento multi-tenant** (RISK-009, AC-001/004): una consulta sin contexto de ámbito filtra datos de otro cliente | Queries con `account_id` opcional; tests de aislamiento añadidos tarde | RLS desde el primer esquema; helper obligatorio para `SET app.*`; suite de aislamiento como criterio de salida de la fase fundacional (QUALITY_BAR) | 2+ |
| 2 | **Mezclar dimensiones de resultado** (RISK-005, FR-064): un único campo "éxito" contamina métricas | Modelos con `status` único genérico | Modelar estado técnico / resultado operativo / evaluación humana como campos-tabla separados desde el diseño inicial | 5–6 |
| 3 | **Doble contabilización de eventos** (AC-025): reintentos de integración duplican métricas | Ingesta sin clave de idempotencia obligatoria | Unique constraint sobre (integración, idempotency_key) en el ledger; test AC-025 en ingesta | 4 |
| 4 | **Presentar ausencia como cero** (PRD §5.2, AC-027): dashboards inventan valores | Componentes que renderizan `0` ante `null` | Convención explícita null vs 0 vs incompleto vs desactualizado; componentes de UI con estados nulos diseñados | 6 |
| 5 | **Matriz de permisos explosiva** (RISK-003): excepciones heredadas imposibles de auditar | Permisos por-feature ad-hoc sin modelo | Roles plantilla + capacidades atómicas (resolver OD-008) + excepciones puntuales registradas; tests AC-003/004 permanentes | 2 |
| 6 | **Impersonación sin actor real** (FR-017, NFR-004, AC-007): auditoría irrecuperable si se añade tarde | Auditoría pensada "para después" | Actor real en el contexto de sesión desde el día 1; toda escritura registra actor efectivo y real | 2 |
| 7 | **Erosión de límites entre módulos** (ADR-0001): consultas cross-module vía tablas ajenas | JOINs entre schemas de módulos distintos en code review | Interfaces internas explícitas; revisión de límites en cada PR | todas |
| 8 | **CRM absorbiendo el producto** (RISK-002): features de marketing desplazan el portal | Pipeline pide campañas/scoring | Lista Out of Scope vinculante; CRM mínimo viable comercial (leads→conversión) | 3 |
| 9 | **Publicar = sincronizar** (FR-103, AC-019): un solo estado editorial rompe la confianza del sistema externo | Modelo Documento sin tabla de sincronizaciones | Dos estados independientes + eventos + confirmación externa + reintentos visibles | 8 |
| 10 | **Acción vencida autoejecutándose** (FR-032, AC-014): scheduler "ayuda" ejecutando lo expirado | Jobs con auto-approve al vencer | El vencimiento SOLO marca expirada/requiere atención; test negativo dedicado | 7 |
| 11 | **Frescura silenciosa** (NFR-007/012, AC-018): integración caída sin aviso, datos viejos como actuales | Métricas sin timestamp de última actualización | Health de integración + umbrales (OD-006) + advertencia UI + incidencia automática | 6 |
| 12 | **Criptografía/sesiones caseras** (ADR-0003 consecuencias): identidad nativa mal implementada | Implementaciones propias de hashing/reset/tokens | Primitivas del framework + gema/lib estándar para MFA; revisión de seguridad explícita obligatoria (QUALITY_BAR security-sensitive) | 2 |
| 13 | **Scope excesivo global** (RISK-001): intentar todo el PRD en una entrega | Fases sin capacidad observable propia | Roadmap mvp vertical: cada fase termina usable end-to-end; PRD rector intacto | roadmap |

## Antipatrones transversales

- Resolver decisiones abiertas (OD-001..015) "de paso" durante desarrollo — escalar al usuario según AUTONOMY_POLICY.
- Tests que verifican SQL en vez de comportamiento externo verificable (CONSTITUTION §5).
- Migraciones destructivas sin estrategia de rollback (CONSTITUTION §8).
