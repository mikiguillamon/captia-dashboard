# Phase 2: CRM, aprovisionamiento y catálogo de servicios - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-27
**Phase:** 02-CRM, aprovisionamiento y catálogo de servicios
**Areas discussed:** Pipeline UX, Assisted Conversion Wizard, Service Instance Configuration, Three-State Machine, CRM-Tenancy Relationship, Pipeline Stage Config

---

## Pipeline UX

| Option | Description | Selected |
|--------|-------------|----------|
| Kanban board | Columns per stage, drag-and-drop to advance, card shows key fields. Reuses Turbo Stream patterns from organizations. | ✓ |
| List view with inline stage selector | Table rows, dropdown per row to change stage. Simpler initial implementation, no drag-drop JS needed. | |
| Hybrid | Kanban on desktop, list on mobile (responsive switch). More complex, but best UX for mobile portal requirement (SEG-14). | |

**User's choice:** Kanban

| Option | Description | Selected |
|--------|-------------|----------|
| Drag-and-drop | Click and drag cards between columns; Turbo Stream updates on drop. Uses SortableJS or native HTML5 drag API with Stimulus controller. | ✓ |
| Click-to-advance only | Card has "Advance" button (→ next stage) or dropdown; simpler, no drag-drop library needed. | |
| Both | Drag-and-drop for power users, click-to-advance as fallback/accessible option. | |

**User's choice:** Drag and drop

| Option | Description | Selected |
|--------|-------------|----------|
| Modal per stage | Click stage header → modal to edit name, probability %, required fields, auto-actions. Keeps Kanban clean; reuses Turbo Frame/Modal patterns. | ✓ |
| Inline edit on header | Click stage name → inline edit; click probability → number input. More direct but clutters the board. | |
| Separate "Pipeline Settings" page | Full CRUD for stages in admin area; Kanban is read-only display. Simplest but adds navigation step. | |

**User's choice:** Modal per stage

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal | Name, company (Account/Contact), value, probability %, stage badge, expected close date. Fits card layout; click → full detail modal. | ✓ |
| Extended | Adds: owner avatar, last activity date, next action, tags, health indicator. More info at glance but cards get tall. | |
| Configurable per user | Each commercial user chooses their card fields. Flexible but adds preferences complexity. | |

**User's choice:** Minimal

---

## Assisted Conversion Wizard

| Option | Description | Selected |
|--------|-------------|----------|
| 5-step wizard | 1) Review/confirm Account → 2) Create/confirm Organizations → 3) Select Service Types → 4) Create Instances + configure → 5) Configure permissions + invite users → Activate Portal. Matches FR-126 exactly. | ✓ |
| 4-step (combine orgs + services) | 1) Account → 2) Orgs + Services together → 3) Instances + config → 4) Permissions + invites. Fewer steps but more complex screens. | |
| Flexible/skip-able | User can jump between steps, save draft, resume later. More UX work but handles real-world interruptions. | |

**User's choice:** 5-step

| Option | Description | Selected |
|--------|-------------|----------|
| Strict sequential | Must complete step N before N+1; validation on each submit; "Back" allowed, "Next" disabled until valid. Simple state machine, clear progress. | ✓ |
| Validated but flexible | Can navigate freely between completed steps; validation only on final submit. More complex (need to track dirty state per step). | |
| Auto-save draft | Each step auto-saves to session/DB; user can close browser and resume. Requires persistence layer for in-progress conversions. | |

**User's choice:** Strict sequential

| Option | Description | Selected |
|--------|-------------|----------|
| Full rollback | Delete created Organizations, ServiceInstances, Invitations, RoleAssignments on cancel. Clean but requires transactional wrapper or compensating deletions. | ✓ |
| Keep as draft | Mark Opportunity as `conversion_draft`; preserve all created records for resume. Safer for user but leaves orphaned data if never completed. | |
| Soft delete | Mark created records `status: abandoned`; exclude from normal queries; cleanup job runs later. Middle ground. | |

**User's choice:** Full rollback

| Option | Description | Selected |
|--------|-------------|----------|
| Immediate activation | Wizard completion = portal active. Simple, matches "activates the portal" in FR-126. | ✓ |
| Explicit "Go Live" button | After wizard, user reviews summary and clicks "Activate Portal". Adds safety but extra step. | |
| Scheduled activation | Choose activation date/time; background job flips the switch. Useful for coordinated launches. | |

**User's choice:** Immediate activation

---

## Service Instance Configuration

| Option | Description | Selected |
|--------|-------------|----------|
| JSONB column on ServiceInstance | Single `configuration jsonb` field; each service type defines its own schema via Rails `store_accessor` + validations. Flexible, single table, easy to query/filter. | ✓ |
| Separate config table per service type | `EmailAssistantConfig`, `ChatbotConfig`, `VoiceAssistantConfig` with typed columns. Strict schemas but more migrations, joins, and model complexity. | |
| Hybrid | JSONB for flexible fields, dedicated columns for frequently queried/validated fields (e.g., `webhook_url`, `api_key`). | |

**User's choice:** JSONB

| Option | Description | Selected |
|--------|-------------|----------|
| ActiveModel::Validations in ServiceInstance | `validates :configuration, json_schema: { type: "object", properties: { ... } }` per type using `activerecord-json_validator` gem or custom validator. Centralized in model. | ✓ |
| Per-type form objects | `EmailAssistantConfigForm`, `ChatbotConfigForm` with typed attributes + validations; ServiceInstance delegates to form object. Cleaner separation but more classes. | |
| JSON Schema files + validator | Store `.json` schemas in `config/service_schemas/`; validate on save. Versionable, shareable with API consumers, but adds file I/O. | |

**User's choice:** ActiveModel

| Option | Description | Selected |
|--------|-------------|----------|
| Rails enum + class hierarchy (STI) | `ServiceInstance.type` enum; `EmailAssistantInstance < ServiceInstance`, etc. Each subclass defines its `CONFIG_SCHEMA` constant and validations. STI pattern. | ✓ |
| ServiceType model (data-driven) | `ServiceType` record per type with `config_schema jsonb`; `ServiceInstance` belongs_to `:service_type`. Admin can add types without code (but PRD says types are explicitly developed, not no-code). | |
| Module-based | `ServiceTypes::EmailAssistant`, `ServiceTypes::Chatbot` modules mixed into instance. Flexible but less Rails-idiomatic. | |

**User's choice:** Rails (STI)

| Option | Description | Selected |
|--------|-------------|----------|
| Display name + optional identifier | User gives each instance a name (e.g., "Soporte Ventas", "Soporte Técnico"); system generates slug/identifier. Shows in dropdowns, dashboards, API. | ✓ |
| Auto-numbered suffix | "Email Assistant #1", "Email Assistant #2". Simple but not meaningful. | |
| Configuration-driven | Instances differentiated by key config field (e.g., different webhook URLs, different email domains). Works for some types but not all. | |

**User's choice:** 1 (Display name + optional identifier)

---

## Three-State Machine

| Option | Description | Selected |
|--------|-------------|----------|
| Contractual: `active` \| `pending_start` \| `scheduled_end` \| `ended` \| `cancelled` | Operational: `running` \| `degraded` \| `stopped` \| `maintenance` \| `error` | Health: `healthy` \| `warning` \| `critical` \| `unknown` | ✓ |

**User's choice:** OK (accepted proposed states)

| Option | Description | Selected |
|--------|-------------|----------|
| Contractual: Only internal users with `manage_services` capability. Operational: Automatic from health signals + manual override by `tecnico`/`account_manager`. Health: Fully automatic from signals. | ✓ |

**User's choice:** OK (accepted proposed control model)

| Option | Description | Selected |
|--------|-------------|----------|
| Background job | `EndScheduledServicesJob` runs daily via Solid Queue; finds instances where `contractual_end_date <= Date.current` and transitions `scheduled_end → ended`. Emits event for Phase 3. | ✓ |
| On-read evaluation | No job; `contractual_state` method computes effective state: if `scheduled_end` and date passed, return `ended`. Simpler but state not persisted; queries need to compute. | |
| Hybrid | Job persists the transition but on-read also handles edge cases (job missed, timezone issues). | |

**User's choice:** Background job

| Option | Description | Selected |
|--------|-------------|----------|
| Per-instance `historical_access_until` date | On `ended`, set `historical_access_until = ended_at + configured_retention_days`. Queries filter: `where("historical_access_until IS NULL OR historical_access_until >= ?", Date.current)`. Configurable per service type default, override per instance. | ✓ |
| Global setting per service type | Single `retention_days` on `ServiceType`; all instances of that type share it. Simpler but less flexible. | |
| Organization-level policy | Each organization sets its own retention for all its instances. More complex, matches multi-tenant but SERV-10 says "configurable por servicio". | |

**User's choice:** Per instance

---

## CRM-Tenancy Relationship

| Option | Description | Selected |
|--------|-------------|----------|
| Unified | Single `Tenancy::Account` serves both commercial and operational contexts. CRM adds fields (`status`, `source`, `industry`, `assigned_to`) to existing model. Conversion wizard simply "activates" the account for portal access. | ✓ |
| Separate models with link | `CRM::Account` (lead/opportunity phase) → converts to → `Tenancy::Account` (operational). Cleaner separation but requires sync/migration on conversion. | |
| STI on Account | `Tenancy::Account` base; `CrmAccount < Tenancy::Account` with commercial fields. Shared table, but STI can get messy with tenancy scoping. | |

**User's choice:** Unified

| Option | Description | Selected |
|--------|-------------|----------|
| Lead/Contact as separate models | `CRM::Lead`, `CRM::Contact`, `CRM::Account` (unified with Tenancy). Lead converts to Contact + Account (or links to existing Account). Matches standard CRM patterns. | ✓ |
| Lead only, promotes to Account | Single `CRM::Lead` with `status` enum; on "won" becomes `Tenancy::Account`. Simpler but loses Contact distinction. | |
| Prospect model | Single `CRM::Prospect` with `type` (lead/contact/account) and state machine. Most flexible but complex. | |

**User's choice:** As separate models

| Option | Description | Selected |
|--------|-------------|----------|
| Creates new Tenancy::Account | Won Opportunity → Conversion Wizard → new `Tenancy::Account` + Organizations + ServiceInstances. Clean separation; each deal = new tenant. | ✓ |
| Links to existing Account | Won Opportunity selects existing `Tenancy::Account` (e.g., upsell/renewal). Wizard adds Organizations/Instances to existing tenant. | |
| Both options | Wizard asks: "New client?" → creates Account; "Existing client?" → selects Account. More flexible, matches real sales. | |

**User's choice:** 1 (Creates new)

| Option | Description | Selected |
|--------|-------------|----------|
| User owns via `role_assignment` | Opportunity has `user_id` (owner); permissions via `can?(:manage_opportunities, scope: account)`. Reuses Phase 1 permission engine. | ✓ |
| Team-based | Opportunity belongs to `Team` (new model); users inherit via team membership. More complex, not in PRD. | |
| Account-level only | All users with account role see all opportunities. Simpler but no individual ownership. | |

**User's choice:** 1 (User owns via role_assignment)

---

## Pipeline Stage Config

| Option | Description | Selected |
|--------|-------------|----------|
| Name, order, probability %, color | Minimal: `name`, `position`, `probability` (0-100), `color` (hex for Kanban badge). Matches standard pipelines. | ✓ |
| Plus: required fields, auto-actions | Add `required_fields` (array of field names that must be filled to enter stage), `auto_actions` (e.g., "create task", "send email", "notify owner"). More powerful but complex. | |
| Full workflow per stage | Entry/exit conditions, SLA days, approval gates. Overkill for MVP. | |

**User's choice:** 1 (Minimal)

| Option | Description | Selected |
|--------|-------------|----------|
| Per Account | Each `Tenancy::Account` has its own pipeline stages. Commercial teams can customize per client/account. Matches multi-tenant. | ✓ |
| Global default + per-account override | System provides default stages; Account can copy and modify. Best of both. | |
| Global only | Single pipeline for all accounts. Simplest but inflexible. | |

**User's choice:** Per account

| Option | Description | Selected |
|--------|-------------|----------|
| System defaults | New accounts get: `Prospecting (10%) → Qualified (25%) → Proposal (50%) → Negotiation (75%) → Won (100%) / Lost (0%)`. User can customize. | ✓ |
| Empty — user creates from scratch | No defaults; user builds pipeline in settings. More setup friction. | |
| Template selection | Choose from "SaaS Sales", "Services", "Enterprise" templates. Nice but more work. | |

**User's choice:** 1 (System defaults)

---

## the agent's Discretion

- Exact Stimulus controller structure for Kanban drag-drop.
- `activerecord-json_validator` gem vs custom validator for JSONB schema.
- Background job scheduling details (Solid Queue recurring task config).
- Migration ordering for new models.
- UI copy for wizard steps, state badges, empty states.

## Deferred Ideas

- **Team-based opportunity ownership** — Opportunity belongs to `Team`; users inherit via team membership. Not in PRD; would be Phase 2+ enhancement.
- **Flexible wizard navigation** — Jump between completed steps, auto-save draft. Current decision: strict sequential only.
- **Global pipeline templates** — "SaaS Sales", "Services", "Enterprise" templates for new accounts. Current: single system default.
- **SLA days per stage** — Entry/exit conditions, approval gates. Current: minimal config only.
- **Organization-level retention policy** — Each org sets retention for all its instances. Current: per-instance override of service-type default.