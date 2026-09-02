# Phase 2: CRM, aprovisionamiento y catálogo de servicios - Research

**Researched:** 2026-08-28
**Status:** Complete

---

## 1. Domain Understanding

### Phase Scope
Ciclo comercial completo (leads → oportunidades → pipeline → conversión asistida) que crea cuenta, organizaciones, servicios, instancias, permisos y activa el portal; catálogo con tipos Email Assistant/Chatbot/Voice Assistant, múltiples instancias configurables y tres máquinas de estado operativas.

### Requirements Mapping
| Requirement | Description | Key Considerations |
|-------------|-------------|-------------------|
| CRM-01 | Gestión de leads | CRUD + source tracking + conversion to contact/account |
| CRM-02 | Gestión de contactos | Belongs to Account, multiple per account |
| CRM-03 | Gestión de cuentas comerciales | Unified with Tenancy::Account, adds CRM fields |
| CRM-04 | Gestión de oportunidades | Pipeline stages, value, probability, owner, expected close |
| CRM-05 | Pipeline con etapas configurables | Per-account stages, drag-and-drop Kanban |
| CRM-06 | Oportunidad con responsable, importe, probabilidad, fecha | Standard fields + custom per-stage probability |
| CRM-07 | Notas, actividades y tareas comerciales | Activity log linked to opportunity |
| CRM-08 | Histórico de actividad comercial | Timeline of all interactions |
| CRM-09 | Oportunidad ganada inicia conversión asistida | Wizard 5-step: Account → Orgs → Services → Instances → Permissions |
| CRM-10 | Conversión asistida completa | Creates account, orgs, service instances, invites users, activates portal |
| SERV-01 | Tipos de servicio predefinidos | Email Assistant, Chatbot, Voice Assistant (code-defined) |
| SERV-02 | MVP incluye 3 tipos | Hardcoded types, extensible via STI |
| SERV-03 | Múltiples instancias del mismo tipo | Per organization, independent config/metrics |
| SERV-04 | Configuración independiente por instancia | JSONB column + schema validation per type |
| SERV-05 | Crear instancias depende de capacidades | Permission-gated creation |
| SERV-06 | Estado contractual separado del operativo | 3-state machine: contractual, operational, health |
| SERV-07 | Estado de salud por instancia | Auto-derived + manual override |
| SERV-08 | Salud: señales automáticas + intervención manual | Heartbeat, error rate, latency → healthy/warning/critical/unknown |
| SERV-09 | Finalización inmediata o programada | contractual_end_date + scheduled job |
| SERV-10 | Visibilidad histórica post-finalización | historical_access_until per instance |

---

## 2. Technical Architecture Research

### 2.1 Rails 8.1 + Hotwire + Solid Stack Patterns (from Phase 1)

**Existing Patterns to Reuse:**
- `Tenancy::Context.with(account_id:, organization_id:)` — MANDATORY for all tenant queries
- `User#can?(capability, scope:)` — permission evaluation (deny-wins)
- `Tenancy::RoleAssignment::ROLE_TEMPLATES` — 8 roles with capabilities
- `OrganizationScoping` concern — resolves active organization from signed cookie
- `Current` model — `actor_real`, `actor_effective` for impersonation audit
- `AuditLog` — immutable audit trail
- Turbo Streams + Turbo Frames — `OrganizationsController` patterns
- RLS FORCE policies on `accounts`, `organizations` — NULLIF-safe pattern
- Solid Queue installed — recurring tasks for daily jobs
- Multi-step forms via Turbo Frames with `data-turbo-action="advance"`
- `Admin::` namespace for internal-only controllers
- System tests with Cuprite headless Chrome

### 2.2 Database Schema Design

**New Models Required:**
```ruby
# CRM Module
class CRM::Lead < ApplicationRecord
  # email, name, company, source, status, assigned_to, converted_at
  # converts to Contact + Account (or links existing Account)
end

class CRM::Contact < ApplicationRecord
  # account_id, first_name, last_name, email, phone, role
  # belongs_to :account (Tenancy::Account)
end

class CRM::Opportunity < ApplicationRecord
  # account_id, name, value_cents, probability, stage_id, user_id (owner)
  # expected_close_date, source, notes
  # belongs_to :pipeline_stage, :account, :user
end

class PipelineStage < ApplicationRecord
  # account_id, name, position, probability, color (hex)
  # system defaults seeded per new account
  # belongs_to :account
end

# Service Catalog Module
class ServiceType < ApplicationRecord
  # name (email_assistant, chatbot, voice_assistant), description
  # config_schema (JSONB), default_config, default_retention_days
  # icon, display_order
end

class ServiceInstance < ApplicationRecord
  # organization_id, service_type_id, name, slug
  # configuration (JSONB), contractual_state, operational_state, health_state
  # contractual_start_date, contractual_end_date, historical_access_until
  # last_heartbeat_at, error_rate, latency_ms
  # STI: type column for EmailAssistantInstance, ChatbotInstance, VoiceAssistantInstance
end
```

### 2.3 Three-State Machine Implementation

**Contractual States:** `active` | `pending_start` | `scheduled_end` | `ended` | `cancelled`
- Controlled by: internal users with `manage_services` capability
- Transition: `scheduled_end` → `ended` via daily Solid Queue job

**Operational States:** `running` | `degraded` | `stopped` | `maintenance` | `error`
- Controlled by: auto from health signals + manual override by `tecnico`/`account_manager`
- Auto-transition based on heartbeat, error rate, latency

**Health States:** `healthy` | `warning` | `critical` | `unknown`
- Fully automatic (derived from metrics)
- `unknown` when no events in > 2× freshness threshold

### 2.4 Service Instance Configuration (JSONB + STI)

**Pattern from Context:**
- `ServiceInstance.configuration jsonb` single field
- Each service type defines schema via `store_accessor` + ActiveModel validations
- JSON schema validation: `activerecord-json_validator` gem or custom validator
- STI hierarchy: base `ServiceInstance` with enum `type`, subclasses define `CONFIG_SCHEMA`

**Service Type Configurations:**
```ruby
# Email Assistant
CONFIG_SCHEMA = {
  type: "object",
  properties: {
    inbound_email_domain: { type: "string" },
    auto_reply_enabled: { type: "boolean" },
    escalation_rules: { type: "array", items: { type: "object" } },
    forwarding_addresses: { type: "array", items: { type: "string" } }
  },
  required: ["inbound_email_domain"]
}

# Chatbot
CONFIG_SCHEMA = {
  type: "object",
  properties: {
    widget_theme: { type: "string", enum: ["light", "dark", "auto"] },
    welcome_message: { type: "string" },
    escalation_trigger: { type: "string", enum: ["keyword", "sentiment", "manual"] },
    integration_webhook: { type: "string", format: "uri" }
  },
  required: ["welcome_message"]
}

# Voice Assistant
CONFIG_SCHEMA = {
  type: "object",
  properties: {
    phone_number: { type: "string" },
    language: { type: "string" },
    voice_id: { type: "string" },
    recording_enabled: { type: "boolean" },
    transcription_provider: { type: "string", enum: ["whisper", "deepgram", "assemblyai"] }
  },
  required: ["phone_number", "language"]
}
```

### 2.5 Assisted Conversion Wizard (5-Step)

**Flow:**
1. **Review/Confirm Account** — Show lead details, allow edits, confirm or link existing account
2. **Create/Confirm Organizations** — Add one or more organizations under the account
3. **Select Service Types** — Cards for Email/Chatbot/Voice; add multiple instances per type inline
4. **Create Instances + Configure** — For each instance: name, configuration per schema
5. **Configure Permissions + Invite Users** — Role assignments, invitations, then **Immediate portal activation**

**Technical Implementation:**
- Turbo Frame modal pattern (reuse Phase 1 organization create)
- Strict sequential validation: must complete step N before N+1
- Full rollback on cancel: delete Organizations, ServiceInstances, Invitations, RoleAssignments in reverse
- Emits `PortalActivated` event for Phase 3 outbox consumption

### 2.6 Pipeline Kanban Board

**UX Decisions from Context:**
- Columns per stage, drag-and-drop to advance (SortableJS or native HTML5 drag API + Stimulus)
- Modal per stage: click header → edit name, probability %, order, color
- Minimal card fields: name, company, value, probability %, stage badge, expected close date
- Click card → full detail modal
- Empty column state: "No opportunities in this stage. Drag here or click +"

**Implementation:**
- Stimulus controller for drag-and-drop
- Turbo Streams for real-time updates
- Per-account pipeline stages (RLS isolation)

---

## 3. Integration Points

### 3.1 Phase 1 Dependencies (Already Built)
- `Tenancy::Context` — mandatory for all queries
- Permission engine (`User#can?`, `RoleAssignment`, capabilities)
- Impersonation audit (`Current.actor_real`, `Current.actor_effective`)
- RLS policies on accounts/organizations
- Solid Queue infrastructure
- Turbo patterns for modals, forms, lists

### 3.2 Phase 3 Consumption
- `PortalActivated` event from wizard completion
- ServiceInstance configuration/state exposed via API privada
- Event ledger + outbox for all state changes

### 3.3 Phase 4 Inheritance
- ServiceInstance STI hierarchy extended by service types
- Configuration schemas used by Email/Chatbot/Voice views

---

## 4. Security Considerations

### 4.1 Authorization (RLS + Application-Level)
- All new models must have RLS policies matching `accounts`/`organizations` pattern
- `PipelineStage` scoped to `account_id`
- `CRM::Lead`, `CRM::Contact`, `CRM::Opportunity` scoped to `account_id`
- `ServiceInstance` scoped to `organization_id` (via account)
- `ServiceType` global (no tenancy) — reference data

### 4.2 Capability Additions
Add to `RoleAssignment::ROLE_TEMPLATES`:
- `manage_leads`, `manage_contacts`, `manage_opportunities`
- `manage_pipeline_stages`
- `manage_service_types`, `manage_service_instances`
- `convert_opportunity` (triggers wizard)
- `manage_service_config` (instance configuration)

### 4.3 Data Sensitivity
- ServiceInstance configuration may contain sensitive data (webhooks, API keys)
- Encrypt sensitive JSONB fields at rest if needed
- Audit all configuration changes

---

## 5. Testing Strategy

### 5.1 Unit Tests
- State machine transitions (contractual, operational, health)
- JSONB schema validation per service type
- Conversion wizard rollback logic
- Pipeline stage CRUD + reordering
- RLS policy isolation tests

### 5.2 Integration/System Tests (Cuprite)
- Full conversion wizard flow (5 steps)
- Kanban drag-and-drop
- Multi-instance creation per organization
- Permission-gated access to CRM/Service features
- Impersonation during CRM operations

### 5.3 Acceptance Criteria Mapping
| AC | Test Approach |
|----|---------------|
| AC-028 (conversión asistida) | System test: win opportunity → wizard → portal active |
| AC-002 (múltiples instancias mismo tipo) | Create 2 EmailAssistantInstance in same org, verify separate config/metrics |
| AC-029 (finalización programada) | Set contractual_end_date tomorrow, run job, verify state transition |
| AC-030 (visibilidad histórica) | End service, set historical_access_until, query with/without date filter |

---

## 6. Migration Strategy

### 6.1 Migration Order (Dependencies)
1. `service_types` (reference data, no FKs)
2. `pipeline_stages` (FK to accounts)
3. `crm_leads`, `crm_contacts` (FK to accounts)
4. `crm_opportunities` (FK to accounts, pipeline_stages, users)
5. `service_instances` (FK to organizations, service_types)
6. Add columns to `accounts` (CRM fields: status, source, industry, assigned_to)
7. Add `capabilities` to role templates

### 6.2 Seed Data
- ServiceType records for 3 MVP types with default configs
- Default pipeline stages per new account (callback on account creation)

---

## 7. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| JSONB schema validation complexity | Medium | High | Use `activerecord-json_validator` gem; thorough test coverage |
| STI with configuration differences | Medium | Medium | Clear base class + schema constants per subclass |
| Wizard rollback on partial failure | High | High | Transaction wrapping; idempotent deletion order |
| RLS policy complexity on new models | Medium | High | Copy exact pattern from Phase 1 accounts/organizations |
| Solid Queue recurring job reliability | Low | Medium | Test job scheduling; monitoring alert on failure |
| Drag-and-drop UX edge cases | Medium | Low | SortableJS with Turbo Stream fallback |

---

## 8. Validation Architecture (for Nyquist)

### 8.1 Dimension 1: Requirements Coverage
All CRM-01..10, SERV-01..10 mapped to specific plan tasks with acceptance criteria.

### 8.2 Dimension 2: Architecture Compliance
- Modular boundaries: CRM module, ServiceCatalog module
- No cross-module table sharing
- RLS on all tenant-scoped tables

### 8.3 Dimension 3: Security
- Threat model for: wizard data exposure, configuration injection, privilege escalation via conversion
- Capability-gated all mutating operations

### 8.4 Dimension 4: Performance
- Kanban: paginated/infinite scroll for opportunities
- ServiceInstance queries indexed on organization_id + states
- Health state computation: cached, updated async

### 8.5 Dimension 5: Data Integrity
- Wizard transactional rollback
- State machine invalid transition prevention
- JSONB schema validation on write

### 8.6 Dimension 6: Observability
- AuditLog entries for all CRM mutations
- Event emission for: lead_converted, opportunity_won, portal_activated, instance_created, state_changed

### 8.7 Dimension 7: Operational Readiness
- Database migrations reversible
- Seed data idempotent
- Health check endpoints for service instances

### 8.8 Dimension 8: Validation Requirements (from Research)
- **Schema validation tests** for each service type CONFIG_SCHEMA
- **State machine transition tests** covering all valid/invalid transitions
- **Wizard integration test** covering all 5 steps + rollback
- **RLS isolation tests** for all new models
- **Permission matrix tests** for new capabilities

---

## 9. Implementation Sequence (Suggested Plan Breakdown)

### Wave 1: Foundation (Sequential)
1. **Plan 01**: Database schema + models + migrations (CRM + ServiceCatalog)
2. **Plan 02**: RLS policies + permissions + capabilities
3. **Plan 03**: ServiceType seed data + STI hierarchy + JSONB validation

### Wave 2: CRM Core (Parallel after Wave 1)
4. **Plan 04**: Lead/Contact/Account management (CRUD + conversion)
5. **Plan 05**: Opportunity + PipelineStage management
6. **Plan 06**: Kanban board UI (drag-drop, modals, Turbo Streams)

### Wave 3: Conversion Wizard (Sequential)
7. **Plan 07**: Wizard steps 1-3 (Account → Organizations → Service Selection)
8. **Plan 08**: Wizard steps 4-5 (Instances → Permissions/Invitations → Activation)
9. **Plan 09**: Wizard rollback + event emission + integration tests

### Wave 4: Service Instance Management (Parallel)
10. **Plan 10**: ServiceInstance CRUD + configuration UI (per-type forms)
11. **Plan 11**: Three-state machine implementation + health computation
12. **Plan 12**: Scheduled end job + historical visibility

### Wave 5: Polish & Verification
13. **Plan 13**: System tests + acceptance criteria verification
14. **Plan 14**: Documentation + edge case handling

---

## 10. Agent's Discretion Areas

- Exact Stimulus controller structure for Kanban drag-drop
- `activerecord-json_validator` gem vs custom validator
- Background job scheduling details (Solid Queue recurring task config)
- Migration ordering for new models
- UI copy for wizard steps, state badges, empty states
- Health computation algorithm thresholds (warning/critical boundaries)

---

## 11. Deferred / Out of Scope

- Team-based opportunity ownership (Phase 2+ enhancement)
- Flexible wizard navigation / auto-save draft
- Global pipeline templates
- SLA days per stage / approval gates
- Organization-level retention policy (current: per-instance override)

---

## 12. Canonical References (MUST READ)

### Producto
- `docs/product/PRD.md` — §3 (roles), §7 FR-117..126 (CRM), FR-019..028 (Servicios), §10 AC-002, AC-028, AC-029, AC-030
- `.planning/REQUIREMENTS.md` — CRM-01..10, SERV-01..10 traceability

### Arquitectura (Phase 1 decisions)
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

---

## RESEARCH COMPLETE