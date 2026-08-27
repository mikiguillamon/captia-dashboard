# Phase 2: CRM, aprovisionamiento y catálogo de servicios - Context

**Gathered:** 2026-08-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Ciclo comercial completo (leads → oportunidades → pipeline → conversión asistida) que crea cuenta, organizaciones, servicios, instancias, permisos y activa el portal; catálogo con tipos Email Assistant/Chatbot/Voice Assistant, múltiples instancias configurables por tipo, y estados contractual/operativo/salud separados.

Modo mvp: la fase termina con CRM funcional, wizard de conversión end-to-end, catálogo de 3 tipos de servicio con instancias, y tres máquinas de estado operativas.

Requisitos: CRM-01..10, SERV-01..10. Criterios de éxito: AC-028 (conversión asistida), AC-002 (múltiples instancias mismo tipo), AC-029/030 (finalización programada + visibilidad histórica).
</domain>

<decisions>
## Implementation Decisions

### Pipeline UX
- **Kanban board** — Columns per stage, drag-and-drop to advance cards (SortableJS or native HTML5 drag API + Stimulus controller). Reuses Turbo Stream patterns from Phase 1 organizations CRUD.
- **Modal per stage** — Click stage header → modal to edit name, probability %, order, color. Keeps board clean; uses Turbo Frame/Modal patterns established in Phase 1.
- **Minimal card fields** — Name, company (Account/Contact), value, probability %, stage badge, expected close date. Click card → full detail modal.

### Assisted Conversion Wizard
- **5-step sequential wizard** — 1) Review/confirm Account → 2) Create/confirm Organizations → 3) Select Service Types → 4) Create Instances + configure → 5) Configure permissions + invite users → **Immediate portal activation**.
- **Strict sequential validation** — Must complete step N before N+1; validation on each submit; "Back" allowed, "Next" disabled until valid. Simple state machine.
- **Full rollback on cancel** — Delete created Organizations, ServiceInstances, Invitations, RoleAssignments in reverse order. No draft persistence.
- **Immediate activation** — Wizard completion = portal active. Emits `PortalActivated` event for Phase 3 outbox.

### Service Instance Configuration
- **JSONB column** — `ServiceInstance.configuration jsonb` single field; each service type defines schema via `store_accessor` + ActiveModel validations.
- **JSON schema validation in model** — `validates :configuration, json_schema: { ... }` per type using `activerecord-json_validator` gem (lightweight) or custom validator.
- **STI hierarchy** — `ServiceInstance` base (enum `type: { email_assistant, chatbot, voice_assistant }`); subclasses `EmailAssistantInstance`, `ChatbotInstance`, `VoiceAssistantInstance` each define `CONFIG_SCHEMA` constant and validations.
- **Display name + identifier** — User gives each instance a name (e.g., "Soporte Ventas"); system generates slug/identifier for API/dropdowns.

### Three-State Machine (per ServiceInstance)
| Dimension | States | Control |
|-----------|--------|---------|
| **Contractual** | `active` \| `pending_start` \| `scheduled_end` \| `ended` \| `cancelled` | Internal users with `manage_services` capability only |
| **Operational** | `running` \| `degraded` \| `stopped` \| `maintenance` \| `error` | Auto from health signals + manual override by `tecnico`/`account_manager` |
| **Health** | `healthy` \| `warning` \| `critical` \| `unknown` | Fully automatic (derived from latency, error rate, last heartbeat) |

- **Scheduled end transition** — `EndScheduledServicesJob` (Solid Queue recurring daily) finds instances where `contractual_end_date <= Date.current` and transitions `scheduled_end → ended`; emits event for Phase 3.
- **Post-termination visibility (AC-030)** — Per-instance `historical_access_until` date (set on `ended` = `ended_at + configured_retention_days`). Queries filter: `where("historical_access_until IS NULL OR historical_access_until >= ?", Date.current)`. Configurable per service type default, override per instance.

### CRM-Tenancy Relationship
- **Unified Account** — Single `Tenancy::Account` serves both commercial and operational contexts. CRM adds fields (`status`, `source`, `industry`, `assigned_to`) to existing model. Conversion wizard "activates" the account for portal access.
- **Separate Lead/Contact models** — `CRM::Lead`, `CRM::Contact`, `Tenancy::Account` (unified). Lead converts to Contact + Account (or links to existing Account). Matches standard B2B CRM.
- **Won Opportunity creates new Account** — Conversion Wizard creates new `Tenancy::Account` + Organizations + ServiceInstances. Clean separation; each deal = new tenant.
- **Opportunity ownership via permission engine** — Opportunity has `user_id` (owner); permissions via `can?(:manage_opportunities, scope: account)`. Reuses Phase 1 `RoleAssignment` engine. Add `manage_opportunities` to capability list.

### Pipeline Stage Config
- **Configurable per stage:** `name`, `position` (order), `probability` (0-100), `color` (hex for Kanban badge). Minimal for MVP.
- **Per-Account scope** — Each `Tenancy::Account` has its own pipeline stages (`PipelineStage` model `belongs_to :account`). Commercial teams customize per client/account. RLS enforces isolation.
- **System defaults for new accounts** — Seed: `Prospecting (10%) → Qualified (25%) → Proposal (50%) → Negotiation (75%) → Won (100%) / Lost (0%)`. User can customize via modal per stage.

### Agent's Discretion
- Exact Stimulus controller structure for Kanban drag-drop.
- `activerecord-json_validator` gem vs custom validator for JSONB schema.
- Background job scheduling details (Solid Queue recurring task config).
- Migration ordering for new models (Account fields, Lead, Contact, Opportunity, PipelineStage, ServiceType, ServiceInstance, etc.).
- UI copy for wizard steps, state badges, empty states.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Producto
- `docs/product/PRD.md` — §3 (roles y usuarios objetivo), §7 FR-117..FR-126 (CRM), FR-019..FR-028 (Servicios), §10 AC-002, AC-028, AC-029, AC-030
- `.planning/REQUIREMENTS.md` — CRM-01..10, SERV-01..10 traceability

### Arquitectura (Phase 1 decisions carried forward)
- `docs/architecture/adr/ADR-0001-monolito-modular.md` — límites entre módulos
- `docs/architecture/adr/ADR-0002-multitenancy-y-autorizacion.md` — ámbitos explícitos + RLS
- `docs/architecture/adr/ADR-0005-outbox-y-trabajos-asincronos.md` — Solid Queue para jobs
- `.planning/phases/01-fundaci-n-e-identidad-segura/01-CONTEXT.md` — D-07 (Tenancy::Context), D-09 (permission engine), D-06 (impersonation audit)

### Gobernanza y calidad
- `docs/governance/CONSTITUTION.md` — §5 pruebas, §7 seguridad
- `docs/quality/QUALITY_BAR.md` — security-sensitive changes
- `AGENTS.md` — precedencia de fuentes de verdad

### Planificación
- `.planning/ROADMAP.md` — Phase 2 goal, success criteria, requirements mapping
- `.planning/research/STACK.md` — Rails 8.1 + Hotwire + Solid stack approved
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (Phase 1)
- `Tenancy::Context.with(account_id:, organization_id:)` — **MANDATORY** for all tenant queries
- `User#can?(capability, scope:)` — permission evaluation (template → inheritance → exceptions, deny-wins)
- `Tenancy::RoleAssignment::ROLE_TEMPLATES` — 8 roles with capabilities; `set_exception!` audits changes
- `OrganizationScoping` concern — resolves active organization from signed cookie, validates membership access
- `Current` model — `actor_real`, `actor_effective` for impersonation audit
- `AuditLog` — immutable audit trail; `actor_real` ≠ `actor_effective` during impersonation
- `Solid Queue` installed — `config/solid_queue.yml` pending; recurring tasks for daily jobs
- Turbo Streams + Turbo Frames patterns — `OrganizationsController` create/append/remove, modals via `turbo_frame_tag`
- RLS FORCE policies on `accounts`, `organizations` — NULLIF-safe `current_setting` pattern

### Established Patterns
- Server-side sessions with HttpOnly cookies, MFA challenge post-password
- Token digest-only storage (SHA256) for invitations, recovery codes, password resets
- Multi-step forms via Turbo Frames with `data-turbo-action="advance"`
- `Admin::` namespace for internal-only controllers (invitations, impersonations)
- System tests with Cuprite headless Chrome; isolation AC tests as phase gate

### Integration Points
- Phase 3 will consume `PortalActivated` event from wizard completion
- Phase 3 API privada will expose ServiceInstance configuration/state
- Phase 4 service types will inherit `ServiceInstance` STI hierarchy
- Phase 5 dashboards will query ServiceInstance states and configuration
</code_context>

<specifics>
## Specific Ideas

- Wizard step 3 (Select Service Types): show cards for Email/Chatbot/Voice with brief description; user adds multiple instances per type inline before proceeding.
- Kanban: empty column state shows "No opportunities in this stage. Drag here or click +".
- ServiceInstance health: `unknown` when no events received in > 2× freshness threshold (links to Phase 3 FRESH-04).
- PipelineStage `color` hex used for Kanban column header badge and opportunity card stage badge.
- Conversion Wizard uses same `Turbo Frame` modal pattern as Phase 1 organization create.
</specifics>

<deferred>
## Deferred Ideas

- **Team-based opportunity ownership** — Opportunity belongs to `Team`; users inherit via team membership. Not in PRD; would be Phase 2+ enhancement.
- **Flexible wizard navigation** — Jump between completed steps, auto-save draft. Current decision: strict sequential only.
- **Global pipeline templates** — "SaaS Sales", "Services", "Enterprise" templates for new accounts. Current: single system default.
- **SLA days per stage** — Entry/exit conditions, approval gates. Current: minimal config only.
- **Organization-level retention policy** — Each org sets retention for all its instances. Current: per-instance override of service-type default.
</deferred>

---

*Phase: 02-crm-aprovisionamiento-y-cat-logo-de-servicios*
*Context gathered: 2026-08-27*