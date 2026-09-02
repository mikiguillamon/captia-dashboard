---
wave: 1
depends_on: []
files_modified:
  - db/migrate/*_create_crm_models.rb
  - db/migrate/*_create_service_catalog_models.rb
  - db/migrate/*_add_crm_fields_to_accounts.rb
  - app/models/crm/lead.rb
  - app/models/crm/contact.rb
  - app/models/crm/opportunity.rb
  - app/models/pipeline_stage.rb
  - app/models/service_type.rb
  - app/models/service_instance.rb
  - app/models/email_assistant_instance.rb
  - app/models/chatbot_instance.rb
  - app/models/voice_assistant_instance.rb
  - config/initializers/activerecord_json_validator.rb
autonomous: true
---

# Phase 2 Plan: CRM, Aprovisionamiento y Catálogo de Servicios

**Goal:** Complete commercial cycle (leads→opportunities→pipeline→assisted conversion) creating account, organizations, services, instances, permissions and activating portal; catalog with Email Assistant/Chatbot/Voice Assistant types, multiple configurable instances per type, and three separate state machines (contractual/operational/health).

**MVP Mode:** Vertical slices — each plan delivers end-to-end functionality.

**Requirements:** CRM-01..10, SERV-01..10

**Success Criteria (must_haves):**
1. Won opportunity triggers assisted conversion wizard; portal activates only after wizard completion (AC-028)
2. Organization maintains multiple instances of same type with independent activity, metrics, config (AC-002)
3. Scheduled service end continues operating until effective date; post-termination historical visibility configurable (AC-029, AC-030)

---

## Wave 1: Foundation — Database, Models, RLS, Permissions (Sequential)

### Task 1.1: CRM Models + Migrations (Leads, Contacts, Opportunities, Pipeline Stages)
<read_first>
- db/schema.rb (current schema state)
- app/models/tenancy/account.rb (unified Account model pattern)
- app/models/tenancy/organization.rb (tenancy pattern)
- .planning/phases/01-fundaci-n-e-identidad-segura/01-CONTEXT.md (D-07 Tenancy::Context, D-09 permission engine)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-RESEARCH.md (§2.2 Database Schema Design, §6.1 Migration Order)
</read_first>
<action>
Create migrations and models for CRM module:
1. Migration: create crm_leads (email, name, company, source, status, assigned_to_id, converted_at, account_id)
2. Migration: create crm_contacts (account_id, first_name, last_name, email, phone, role)
3. Migration: create pipeline_stages (account_id, name, position, probability, color)
4. Migration: create crm_opportunities (account_id, name, value_cents, probability, stage_id, user_id, expected_close_date, source, notes)
5. Migration: add CRM fields to accounts (status, source, industry, assigned_to_id)
6. Models: CRM::Lead, CRM::Contact, CRM::Opportunity, PipelineStage with associations, validations, scopes
7. PipelineStage: default scope order by position; system default seed callback on Account creation
8. Opportunity: belongs_to :account, :pipeline_stage, :user (owner); delegate account to stage
</action>
<acceptance_criteria>
- `rails db:migrate` runs without errors
- `CRM::Lead.create!(email: "test@example.com", name: "Test", company: "Co", account: account)` persists
- `CRM::Contact` belongs to `Tenancy::Account`; `account.contacts` returns contacts
- `PipelineStage` scoped to account via RLS; `account.pipeline_stages` returns stages ordered by position
- `CRM::Opportunity` validates presence of name, account, stage, user; value_cents >= 0
- System default stages created on `Account.create!`: Prospecting(10%), Qualified(25%), Proposal(50%), Negotiation(75%), Won(100%), Lost(0%)
- RLS policies on all 4 new tables match accounts/organizations pattern (NULLIF-safe current_setting)
</acceptance_criteria>

### Task 1.2: Service Catalog Models + Migrations (ServiceType, ServiceInstance STI)
<read_first>
- db/schema.rb (post Task 1.1)
- app/models/tenancy/organization.rb (organization pattern)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-RESEARCH.md (§2.2 Database Schema Design, §2.4 JSONB+STI, §6.1 Migration Order)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-CONTEXT.md (Service Instance Configuration decisions)
</read_first>
<action>
Create migrations and models for Service Catalog:
1. Migration: create service_types (name, description, config_schema jsonb, default_config jsonb, default_retention_days, icon, display_order)
2. Migration: create service_instances (organization_id, service_type_id, type, name, slug, configuration jsonb, contractual_state, operational_state, health_state, contractual_start_date, contractual_end_date, historical_access_until, last_heartbeat_at, error_rate, latency_ms)
3. Add indexes: service_instances on [organization_id, service_type_id], [organization_id, contractual_state], [organization_id, health_state]
4. Models: ServiceType (global reference data, no tenancy), ServiceInstance (STI base with enum type), EmailAssistantInstance, ChatbotInstance, VoiceAssistantInstance subclasses
5. ServiceInstance: belongs_to :organization, :service_type; validates :name uniqueness per organization; slug auto-generated from name
6. STI hierarchy: type column stores class name; each subclass defines CONFIG_SCHEMA constant per RESEARCH.md §2.4
7. State enums: contractual (active, pending_start, scheduled_end, ended, cancelled), operational (running, degraded, stopped, maintenance, error), health (healthy, warning, critical, unknown)
</action>
<acceptance_criteria>
- `rails db:migrate` runs without errors
- `ServiceType.create!(name: "email_assistant", config_schema: {...}, default_config: {...})` persists
- `EmailAssistantInstance.create!(organization: org, service_type: type, name: "Support", configuration: {...})` creates instance with type="EmailAssistantInstance"
- `service_instance.contractual_state` returns enum value; `service_instance.operational_state` returns enum value; `service_instance.health_state` returns enum value
- `service_instance.slug` auto-generated from name (parameterized, unique per organization)
- JSONB configuration column accepts valid hash; invalid keys rejected by model validation (later task)
- RLS policy on service_instances via organization_id → account_id chain matches Phase 1 pattern
</acceptance_criteria>

### Task 1.3: RLS Policies + Permission Capabilities for New Models
<read_first>
- db/migrate/*_create_crm_models.rb (from Task 1.1)
- db/migrate/*_create_service_catalog_models.rb (from Task 1.2)
- db/migrate/*_enable_rls_on_new_tables.rb (to create)
- app/models/tenancy/role_assignment.rb (ROLE_TEMPLATES, capabilities pattern)
- .planning/phases/01-fundaci-n-e-identidad-segura/01-CONTEXT.md (D-09 permission engine, RLS FORCE policies)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-RESEARCH.md (§4.1 Authorization, §4.2 Capability Additions)
</read_first>
<action>
1. Create migration enabling RLS on crm_leads, crm_contacts, crm_opportunities, pipeline_stages, service_instances with FORCE policies using NULLIF-safe `current_setting('app.current_account_id')` and `current_setting('app.current_organization_id')` pattern from Phase 1
2. Add capabilities to `Tenancy::RoleAssignment::ROLE_TEMPLATES`:
   - `manage_leads`, `manage_contacts`, `manage_opportunities`
   - `manage_pipeline_stages`
   - `manage_service_types`, `manage_service_instances`, `manage_service_config`
   - `convert_opportunity` (triggers wizard)
3. Map capabilities to role templates per RESEARCH.md §4.2:
   - Superadmin/Dirección: all CRM + Service capabilities
   - Comercial: manage_leads, manage_contacts, manage_opportunities, convert_opportunity
   - Account Manager: manage_opportunities, manage_service_instances, manage_service_config
   - Técnico: manage_service_instances, manage_service_config (operational override)
4. ServiceType: no RLS (global reference), readable by all authenticated users
</action>
<acceptance_criteria>
- `rails db:migrate` runs without errors; RLS enabled on 5 tables with FORCE policies
- `User#can?(:manage_opportunities, scope: account)` returns true for Comercial role on assigned account
- `User#can?(:manage_service_instances, scope: organization)` returns true for Account Manager on assigned org
- `User#can?(:convert_opportunity, scope: account)` returns true only for Comercial, Account Manager, Superadmin, Dirección
- `ServiceType.all` accessible without tenancy context (no RLS)
- `CRM::Lead` queries filtered by `Tenancy::Context.current_account_id` automatically via RLS
- AuditLog entries created for capability assignment changes via `set_exception!`
</acceptance_criteria>

### Task 1.4: ServiceType Seed Data + JSONB Schema Validation
<read_first>
- db/migrate/*_create_service_catalog_models.rb (from Task 1.2)
- app/models/service_type.rb (from Task 1.2)
- app/models/service_instance.rb + subclasses (from Task 1.2)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-RESEARCH.md (§2.4 JSONB+STI, §2.5 CONFIG_SCHEMA definitions)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-CONTEXT.md (JSONB column + store_accessor + validations decision)
</read_first>
<action>
1. Add `activerecord-json_validator` gem to Gemfile (or implement custom validator if preferred)
2. Configure initializer for JSON schema validation
3. Define CONFIG_SCHEMA constants in each STI subclass per RESEARCH.md §2.4:
   - EmailAssistantInstance: inbound_email_domain (required), auto_reply_enabled, escalation_rules, forwarding_addresses
   - ChatbotInstance: welcome_message (required), widget_theme, escalation_trigger, integration_webhook
   - VoiceAssistantInstance: phone_number (required), language (required), voice_id, recording_enabled, transcription_provider
4. Add `validates :configuration, json_schema: { schema: ->(instance) { instance.class::CONFIG_SCHEMA } }` to ServiceInstance base
5. Seed 3 ServiceType records with default_config, config_schema, default_retention_days (Email: 90, Chatbot: 90, Voice: 180)
6. ServiceType `config_schema` matches subclass CONFIG_SCHEMA for UI form generation
</action>
<acceptance_criteria>
- `rails db:seed` creates 3 ServiceType records with correct schemas and defaults
- `EmailAssistantInstance.new(configuration: { inbound_email_domain: "example.com" }).valid?` → true
- `EmailAssistantInstance.new(configuration: { auto_reply_enabled: true }).valid?` → false (missing required inbound_email_domain)
- `ChatbotInstance.new(configuration: { welcome_message: "Hi" }).valid?` → true
- `VoiceAssistantInstance.new(configuration: { phone_number: "+123", language: "es" }).valid?` → true
- Invalid JSONB (wrong types, extra keys not in schema) rejected with validation error on `configuration` field
- `ServiceType.find_by(name: "email_assistant").config_schema` matches `EmailAssistantInstance::CONFIG_SCHEMA`
</acceptance_criteria>

---

## Wave 2: CRM Core — Lead/Contact/Account, Opportunity, Pipeline, Kanban (Parallel after Wave 1)

### Task 2.1: Lead/Contact/Account Management (CRUD + Conversion)
<read_first>
- app/models/crm/lead.rb, app/models/crm/contact.rb, app/models/tenancy/account.rb (from Task 1.1)
- app/controllers/concerns/tenancy_context.rb (Tenancy::Context pattern)
- app/controllers/admin/organizations_controller.rb (Phase 1 CRUD pattern with Turbo Streams)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-UI-SPEC.md (§6 CRM List Views)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-RESEARCH.md (§2.1 Existing Patterns)
</read_first>
<action>
Implement CRM module controllers and views:
1. Namespace: `CRM::` for internal-only controllers (like `Admin::`)
2. `CRM::LeadsController`: index (search, filter, paginate 25/page), show (modal), new, create, edit, update, destroy, convert (POST → creates Contact + Account or links existing)
3. `CRM::ContactsController`: index, show, new, create, edit, update, destroy (standard CRUD)
4. `CRM::AccountsController`: extends existing Tenancy::Account with CRM fields (status, source, industry, assigned_to); index/show/edit/update
5. Lead conversion: `convert` action creates Contact from Lead data, creates/links Account, marks Lead `converted_at`, redirects to Opportunity new with account_id
6. Views: reuse Phase 1 Organization index pattern (toolbar search, filter dropdown, "Nuevo" button, table with sortable headers, row click → Turbo Frame modal)
7. Authorization: all actions gated by `current_user.can?(:manage_leads/contacts/opportunities, scope: current_account)`
</action>
<acceptance_criteria>
- `GET /crm/leads` returns 200, renders index with search/filter/pagination
- `POST /crm/leads` with valid params creates Lead, redirects to index with success toast
- `POST /crm/leads/:id/convert` with valid account params creates Contact + Account, marks Lead converted, redirects to `/crm/opportunities/new?account_id=...`
- Lead conversion linking existing Account: finds Account by email/domain, associates Contact, does not duplicate
- `GET /crm/contacts` / `/crm/accounts` work with same pattern
- Unauthorized user (no manage_leads capability) gets 403 on all CRM actions
- Turbo Stream append/remove works on create/destroy (like Phase 1 organizations)
- System test: create lead → convert → verify Contact + Account created + Lead marked converted
</acceptance_criteria>

### Task 2.2: Opportunity + PipelineStage Management
<read_first>
- app/models/crm/opportunity.rb, app/models/pipeline_stage.rb (from Task 1.1)
- app/controllers/crm/leads_controller.rb (from Task 2.1 pattern)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-UI-SPEC.md (§5 Pipeline Stage Management, §6 CRM List Views)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-RESEARCH.md (§2.6 Pipeline Kanban Board)
</read_first>
<action>
Implement Opportunity and PipelineStage management:
1. `CRM::OpportunitiesController`: index (with stage filter), show (modal with notes/activity timeline), new, create, edit, update, destroy
2. `CRM::PipelineStagesController`: index (reorderable list), create, edit (modal per UI-SPEC §5), update, destroy (only if 0 opportunities)
3. PipelineStage modal: name, position, probability (0-100), color (hex picker with 8 presets + custom), live preview badge
4. Opportunity form: name, account (select), value_cents, probability (auto from stage), stage (select), user_id (owner, defaults to current_user), expected_close_date, source, notes
5. Opportunity show modal: tabs for Details, Notes/Activity (timeline), Tasks
6. Reorder PipelineStages: drag-drop in index → PATCH position updates via Turbo Stream
7. Authorization: manage_opportunities for CRUD, manage_pipeline_stages for stage CRUD
</action>
<acceptance_criteria>
- `GET /crm/opportunities` lists opportunities with stage filter, pagination
- `POST /crm/opportunities` creates opportunity with stage probability auto-filled
- `GET /crm/pipeline_stages` shows reorderable list with probability badges in stage colors
- `PATCH /crm/pipeline_stages/:id` updates name, probability, color; color badge updates live
- `DELETE /crm/pipeline_stages/:id` fails with 422 if opportunities exist in stage; succeeds if empty
- Opportunity `probability` defaults to `stage.probability` but overridable
- Opportunity `user_id` (owner) enforced: users only see opportunities they own OR where can?(:manage_opportunities, scope: account)
- System test: create stages → create opportunity → verify stage probability default → reorder stages
</acceptance_criteria>

### Task 2.3: Kanban Board UI (Drag-Drop, Modals, Turbo Streams)
<read_first>
- app/controllers/crm/opportunities_controller.rb (from Task 2.2)
- app/controllers/crm/pipeline_stages_controller.rb (from Task 2.2)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-UI-SPEC.md (§1 Kanban Board, §6 CRM List Views)
- .planning/phases/01-fundaci-n-e-identidad-segura/01-CONTEXT.md (Turbo Streams + Stimulus patterns)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-RESEARCH.md (§2.6 Pipeline Kanban Board)
</read_first>
<action>
Build Kanban board view for pipeline:
1. `CRM::PipelineController#show` — renders board with columns per PipelineStage (ordered by position)
2. Each column: header with stage name, probability badge (stage.color), opportunity count; click header → PipelineStage edit modal
3. Cards: minimal fields (name, company/account, value + probability, expected close, stage badge); click → Opportunity detail modal
4. Drag-and-drop: Stimulus controller `kanban-drag` using native HTML5 Drag API; on drop → PATCH opportunity stage_id + position via Turbo Stream
5. Empty column state: dashed border, "No hay oportunidades en esta etapa", "+" button in header opens new opportunity modal with stage pre-selected
6. "+" button in column header → new opportunity modal with stage_id pre-filled
7. Real-time updates: Turbo Stream broadcasts on opportunity create/update/destroy/move
8. Horizontal scroll container on desktop; touch support on mobile
9. Responsive per UI-SPEC §4: <640px horizontal scroll, 640-1024px 2-3 cols, >1024px all columns
</action>
<acceptance_criteria>
- `GET /crm/pipeline` renders board with all stages as columns
- Drag opportunity card from "Prospecting" to "Qualified" → PATCH to opportunities#update with new stage_id, Turbo Stream moves card
- Click column header → PipelineStage edit modal opens with current values
- Empty column shows correct empty state copy + "+" button creates opportunity in that stage
- Click opportunity card → detail modal opens (Turbo Frame)
- Mobile: horizontal scroll works; touch drag-drop functional
- Turbo Stream broadcasts: create opportunity → appends to column; update → replaces card; destroy → removes card
- `kanban-drag` Stimulus controller handles dragstart, dragend, drop events; keyboard accessible (Space to pick, arrows, Enter to drop)
- System test: create 3 opportunities in different stages → drag between columns → verify stage_id persisted
</acceptance_criteria>

---

## Wave 3: Assisted Conversion Wizard (Sequential — 5 Steps)

### Task 3.1: Wizard Steps 1-3 (Account → Organizations → Service Selection)
<read_first>
- app/models/crm/opportunity.rb (from Task 1.1)
- app/models/tenancy/account.rb, app/models/tenancy/organization.rb
- app/models/service_type.rb, app/models/service_instance.rb (from Task 1.2)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-UI-SPEC.md (§2 Assisted Conversion Wizard steps 1-3)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-CONTEXT.md (Assisted Conversion Wizard decisions)
- .planning/phases/01-fundaci-n-e-identidad-segura/01-CONTEXT.md (Turbo Frame modal pattern)
</read_first>
<action>
Build Conversion Wizard controller and steps 1-3:
1. `CRM::ConversionWizardController` with steps 1-5; session-based state (wizard_data hash in session)
2. Step 1 — Review/Confirm Account: pre-filled from Opportunity + Lead; editable fields (name, status, source, industry, assigned_to); validation: name required; "Continuar a organizaciones" disabled until valid
3. Step 2 — Create/Confirm Organizations: min 1 organization required; each has name, slug (auto), type; "Añadir organización" adds row; "Continuar a servicios" disabled if <1 org
4. Step 3 — Select Service Types: 3 cards (Email, Chatbot, Voice) with icon, description; each has "Añadir instancia" → inline name input + "Añadir" creates instance row; multiple per type allowed; "Configurar instancias" disabled if 0 total instances
5. Navigation: "Anterior" (secondary, enabled after step 1), "Siguiente" (primary, disabled until step valid), "Cancelar" (ghost) → rollback confirmation modal
6. Progress indicator: 5-step horizontal stepper (completed=check+accent, current=accent ring, pending=secondary)
7. Strict sequential validation: cannot advance without completing current step
8. All steps in Turbo Frame modal (full-screen mobile, 800px desktop)
</action>
<acceptance_criteria>
- `GET /crm/opportunities/:id/convert` starts wizard at step 1 with Opportunity data pre-filled
- Step 1: form validates name required; "Siguiente" enabled only when valid; submits → step 2
- Step 2: at least 1 organization required; "Añadir organización" adds validated row; "Siguiente" enabled when ≥1 org
- Step 3: 3 service type cards render; "Añadir instancia" creates inline row with name input; "Configurar instancias" enabled when total instances ≥1
- "Anterior" navigates back preserving entered data in session
- "Cancelar" shows confirmation modal; confirm → deletes any created orgs/instances/invitations in reverse order, clears session, redirects to opportunity
- Session `wizard_data` persists across steps; cleared on completion or cancel
- System test: start wizard → complete steps 1-3 → verify session data structure correct
</acceptance_criteria>

### Task 3.2: Wizard Steps 4-5 (Instance Configuration → Permissions/Invitations → Activation)
<read_first>
- app/controllers/crm/conversion_wizard_controller.rb (from Task 3.1)
- app/models/service_instance.rb + subclasses (from Task 1.2)
- app/models/tenancy/role_assignment.rb (permission engine)
- app/models/tenancy/invitation.rb (Phase 1 invitation pattern)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-UI-SPEC.md (§2 steps 4-5, §3 Service Instance Configuration Forms)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-CONTEXT.md (Wizard rollback, immediate activation, PortalActivated event)
</read_first>
<action>
Complete wizard steps 4-5 and activation:
1. Step 4 — Create Instances + Configure: accordion per instance (from step 3 selection); dynamic form fields per ServiceType CONFIG_SCHEMA (Email: inbound_email_domain*, auto_reply, escalation_rules, forwarding; Chatbot: welcome_message*, widget_theme, escalation_trigger, webhook; Voice: phone_number*, language*, voice_id, recording, transcription_provider); client-side + server-side JSON schema validation; "Configurar permisos" enabled when all instances valid
2. Step 5 — Permissions + Invite Users: role assignment grid (Organization × Role template); invitation forms (email, role, organization); "Activar portal" (primary, destructive-style confirmation modal on click)
3. On "Activar portal" confirm:
   - Persist all: Account (activate), Organizations, ServiceInstances (with configs), RoleAssignments, Invitations
   - Set Account `status = "active"` (portal enabled)
   - Emit `PortalActivated` event (for Phase 3 outbox) with account_id, organization_ids, instance_ids
   - Clear wizard session
   - Success toast: "Portal activado correctamente. El cliente ya puede acceder."
   - Redirect to Account dashboard
4. Full rollback on cancel at any step: destroy created Organizations, ServiceInstances, Invitations, RoleAssignments in reverse order (instances → orgs → invitations → roles)
5. Authorization: `convert_opportunity` capability required to start wizard
</action>
<acceptance_criteria>
- Step 4: dynamic forms render per instance type; validation errors show inline; "Configurar permisos" disabled until all valid
- Step 5: role grid shows organizations × roles; invitations create `Tenancy::Invitation` records with token digest storage
- "Activar portal" click → confirmation modal → confirm → all records persisted in single transaction
- `Account.find(wizard_account_id).status == "active"` after completion
- `PortalActivated` event emitted (verify via `EventLog` or outbox table)
- Created ServiceInstances have correct `configuration` JSONB, `contractual_state = "active"`, `operational_state = "running"`, `health_state = "unknown"`
- Rollback on cancel at step 4: no Organizations, ServiceInstances, Invitations, RoleAssignments remain
- Rollback on cancel at step 5: same, complete cleanup
- System test: full wizard flow from won opportunity → portal active → client can sign in
- System test: cancel at step 3 → verify zero orphaned records
</acceptance_criteria>

### Task 3.3: Wizard Integration Tests + Edge Cases
<read_first>
- app/controllers/crm/conversion_wizard_controller.rb (from Tasks 3.1, 3.2)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-RESEARCH.md (§5.2 Integration/System Tests, §5.3 Acceptance Criteria Mapping AC-028)
- .planning/phases/01-fundaci-n-e-identidad-segura/01-CONTEXT.md (System tests with Cuprite)
</read_first>
<action>
Write comprehensive system tests for wizard:
1. Full happy path: win opportunity → wizard steps 1-5 → portal active → client user invited can sign in
2. Rollback test: cancel at each step (1, 2, 3, 4, 5) → verify zero orphaned records
3. Validation test: invalid data at each step → "Siguiente" disabled, errors shown, cannot advance
4. Back navigation: step 3 → back to step 2 → data preserved → forward again
5. Duplicate service instances: add 2 EmailAssistant instances in step 3 → both configurable in step 4
6. Permission check: user without `convert_opportunity` cannot access wizard (403)
7. Impersonation during wizard: admin impersonating commercial → wizard actions audit with real actor
8. Network interruption simulation: Turbo Stream failure handling
</action>
<acceptance_criteria>
- All 8 system tests pass (Cuprite headless Chrome)
- AC-028 verified: `POST /crm/opportunities/:id/win` → wizard → `Account.status == "active"` only after step 5 confirm
- Rollback verified: `Organization.count`, `ServiceInstance.count`, `Invitation.count`, `RoleAssignment.count` all zero after cancel at any step
- Impersonation audit: `AuditLog.where(action: "conversion_wizard_step").last.actor_real == admin_user`
- Test suite runs in < 60 seconds
</acceptance_criteria>

---

## Wave 4: Service Instance Management + State Machines (Parallel)

### Task 4.1: ServiceInstance CRUD + Configuration UI (Per-Type Forms)
<read_first>
- app/models/service_instance.rb + subclasses (from Task 1.2)
- app/models/service_type.rb (from Task 1.2)
- app/controllers/admin/organizations_controller.rb (Phase 1 pattern)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-UI-SPEC.md (§3 Service Instance Configuration Forms, §4 Service Instance Management)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-CONTEXT.md (Service Instance Configuration decisions)
</read_first>
<action>
Build ServiceInstance management within Organization context:
1. `ServiceInstancesController` nested under Organization: `organization_service_instances_path(org)`
2. Index: table (desktop) / card grid (mobile <768px); columns: Nombre, Tipo (icon+badge), Contractual State, Operational State, Health, Actions; state badges per UI-SPEC §85
3. New: select ServiceType → renders dynamic configuration form (partial per type) + name/slug fields
4. Create: validates configuration against type schema; sets contractual_state="active", operational_state="running", health_state="unknown"
5. Edit: pre-fills configuration form; validates on update; audit log on config change
6. Show/Detail modal: tabs (Configuración, Estado, Métricas, Historial) per UI-SPEC §4
   - Config: read-only JSON formatted + "Editar" button
   - State: three badges + last transition timestamp
   - Health: visual indicator + last_heartbeat_at, error_rate, latency_ms
7. Destroy: confirmation modal with destructive copy; cascades (no dependent records in MVP)
8. Authorization: `manage_service_instances` for CRUD, `manage_service_config` for edit configuration
9. Scoped to current organization via `Tenancy::Context`
</action>
<acceptance_criteria>
- `GET /organizations/:org_id/service_instances` lists instances with state badges
- `GET /organizations/:org_id/service_instances/new` → select type → dynamic form renders
- `POST /organizations/:org_id/service_instances` with valid config creates instance; contractual_state="active"
- Create 2 EmailAssistantInstance in same org with different inbound_email_domain → both persist, separate configs
- `PATCH /organizations/:org_id/service_instances/:id` updates configuration; AuditLog entry with actor_real, changeset
- Detail modal tabs render correctly; Config tab shows formatted JSON
- User without `manage_service_config` sees read-only config; cannot edit
- RLS: user in Org A cannot see/access Org B instances (403 or empty result)
- System test: create 3 instances (1 per type) → edit each → verify configs independent
</acceptance_criteria>

### Task 4.2: Three-State Machine Implementation (Contractual, Operational, Health)
<read_first>
- app/models/service_instance.rb + subclasses (from Task 1.2)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-CONTEXT.md (Three-State Machine decisions)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-RESEARCH.md (§2.3 Three-State Machine Implementation)
- .planning/phases/01-fundaci-n-e-identidad-segura/01-CONTEXT.md (AuditLog pattern for state changes)
</read_first>
<action>
Implement state machines with transitions and audit:
1. Contractual state machine (controlled by `manage_services` capability):
   - States: `active`, `pending_start`, `scheduled_end`, `ended`, `cancelled`
   - Transitions: `pending_start → active` (on start_date), `active → scheduled_end` (set end_date), `scheduled_end → ended` (daily job), `active/cancelled → cancelled` (manual), `ended → active` (reactivate)
   - Only internal users with `manage_services` can transition
2. Operational state machine (auto + manual override by `tecnico`/`account_manager`):
   - States: `running`, `degraded`, `stopped`, `maintenance`, `error`
   - Auto: `running → degraded` (error_rate > 5% or latency > threshold), `degraded → running` (recovery), `running → error` (heartbeat > 2×freshness), `error → running` (heartbeat received)
   - Manual: `running ↔ maintenance`, `running → stopped` (manual), `stopped → running` (manual)
3. Health state machine (fully automatic):
   - States: `healthy`, `warning`, `critical`, `unknown`
   - Derived: `healthy` (error_rate < 1% && latency < p95 && heartbeat recent), `warning` (error_rate 1-5% || latency elevated), `critical` (error_rate > 5% || heartbeat > threshold), `unknown` (no events > 2×freshness)
   - Computed async via job; cached on instance
4. State transition service: `ServiceInstance::StateTransitionService` with `transition_contractual!`, `transition_operational!`, `update_health!` methods
5. All transitions create `AuditLog` entry with `actor_real`, `actor_effective`, `from_state`, `to_state`, `dimension`
6. API: `PATCH /service_instances/:id/state` with `{ dimension: "contractual", state: "scheduled_end", contractual_end_date: "2026-12-31" }`
</action>
<acceptance_criteria>
- `instance.transition_contractual_to!(:scheduled_end, contractual_end_date: Date.tomorrow)` succeeds for user with `manage_services`; fails for user without
- `instance.transition_operational_to!(:maintenance)` succeeds for `tecnico`/`account_manager`; fails for `comercial`
- Health computation: `instance.update_health!` sets correct state based on error_rate, latency, last_heartbeat_at
- `instance.health_state == "unknown"` when `last_heartbeat_at.nil?` or > 2×freshness_threshold (configurable per ServiceType)
- Invalid transitions raise `StateTransitionError` (e.g., `ended → active` without reactivate logic)
- AuditLog: every transition creates entry with dimension (contractual/operational/health), from/to, actor_real
- Unit tests: all valid transitions pass; all invalid transitions raise error; health thresholds configurable per ServiceType
- System test: manual operational override by Tecnico → audit log records real actor
</acceptance_criteria>

### Task 4.3: Scheduled End Job + Historical Visibility (AC-029, AC-030)
<read_first>
- app/models/service_instance.rb (from Task 1.2)
- config/solid_queue.yml (Phase 1 Solid Queue config)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-CONTEXT.md (Three-State Machine: Scheduled end transition, Post-termination visibility)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-RESEARCH.md (§2.3, §6.2 Seed Data)
</read_first>
<action>
Implement scheduled termination and historical access:
1. Solid Queue recurring job: `EndScheduledServicesJob` (daily at 00:00 UTC) — finds `ServiceInstance.where(contractual_state: "scheduled_end").where("contractual_end_date <= ?", Date.current)` → transitions each to `ended`, sets `historical_access_until = ended_at + service_type.default_retention_days` (overrideable per instance)
2. Job emits `ServiceInstanceEnded` event for Phase 3 outbox
3. Historical visibility scope: `ServiceInstance.with_historical_access` → `where("historical_access_until IS NULL OR historical_access_until >= ?", Date.current)`
4. Apply scope to all queries: index, show, API, dashboards (Phase 5)
5. Instance configuration: add `historical_access_until` override field (date) in Step 4 wizard and Edit form
6. ServiceType `default_retention_days`: Email=90, Chatbot=90, Voice=180 (seed data)
7. When `contractual_state == "ended"` and `historical_access_until < Date.current`: instance hidden from client portal, visible to internal users with `manage_service_instances`
</action>
<acceptance_criteria>
- `EndScheduledServicesJob.perform_now` transitions instances with `contractual_end_date <= today` from `scheduled_end` to `ended`
- Transitioned instances have `historical_access_until = ended_at + service_type.default_retention_days`
- `ServiceInstance.with_historical_access` excludes instances past their `historical_access_until`
- Client portal queries (Phase 3/5) use `with_historical_access` scope automatically
- Internal users with `manage_service_instances` see all instances including expired historical
- Override: instance with custom `historical_access_until` uses that instead of service_type default
- `ServiceInstanceEnded` event emitted with instance_id, account_id, ended_at
- System test: create instance with contractual_end_date yesterday → run job → verify state=ended, historical_access_until set, scope excludes from client view
- AC-029: instance with `contractual_end_date = tomorrow` remains `scheduled_end` (operational_state=running) until job runs
- AC-030: `historical_access_until` configurable per instance; client visibility respects it
</acceptance_criteria>

---

## Wave 5: Polish, Verification & Documentation

### Task 5.1: Acceptance Criteria Verification + System Test Suite
<read_first>
- All previous tasks' acceptance criteria
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-RESEARCH.md (§5.3 Acceptance Criteria Mapping)
- .planning/ROADMAP.md (Phase 2 Success Criteria)
</read_first>
<action>
Run and verify all acceptance criteria:
1. AC-028: Won opportunity → conversion wizard → portal active only after completion
2. AC-002: Organization with 2 EmailAssistant instances → separate configs, metrics, activity
3. AC-029: Service with contractual_end_date tomorrow → runs until date → job transitions to ended
4. AC-030: Ended service → historical_access_until configurable → client visibility respects date
5. Full regression: CRM CRUD, Pipeline Kanban, Wizard, ServiceInstance CRUD, State machines
6. Permission matrix: verify all new capabilities enforce correctly across roles
7. RLS isolation: cross-account/organization access blocked
8. Impersonation audit: all wizard and service actions log real actor
</action>
<acceptance_criteria>
- All 4 Phase 2 success criteria verified via automated system tests
- `rails test:system` exits 0 (all Phase 1 + Phase 2 tests pass)
- `rails test` (unit) exits 0
- RuboCop passes (no offenses)
- Type checking (if configured) passes
- No N+1 queries in Kanban, Wizard, ServiceInstance index (bullet gem or manual check)
- AuditLog entries present for all mutating actions
</acceptance_criteria>

### Task 5.2: Documentation + Edge Case Handling
<read_first>
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-CONTEXT.md (Deferred ideas)
- .planning/phases/02-crm-aprovisionamiento-y-cat-logo-de-servicios/02-UI-SPEC.md (Empty states, Error states)
- docs/architecture/ (if exists)
</read_first>
<action>
1. Document Phase 2 architecture decisions in `docs/architecture/adr/` (if new ADRs needed for STI, JSONB validation, state machines)
2. Update `docs/architecture/ARCHITECTURE.md` with CRM and ServiceCatalog module boundaries
3. Add inline code documentation (YARD) for new models, services, controllers
4. Handle edge cases per UI-SPEC:
   - Empty states for all lists (Kanban columns, ServiceInstance index, CRM lists)
   - Error states: form validation inline, wizard step invalid scroll-to-error, API error toast, offline banner, permission denied modal
   - Dark mode: all new components respect Phase 1 toggle
5. Accessibility audit: Kanban keyboard drag, wizard ARIA labels, form error associations, color+text badges
6. Responsive verification: test at 375px, 768px, 1024px, 1440px
</action>
<acceptance_criteria>
- ADR created for: ServiceInstance STI + JSONB pattern, Three-state machine design, Conversion wizard transactional rollback
- `docs/architecture/ARCHITECTURE.md` updated with module diagram
- Empty states render per UI-SPEC §11 table for all new views
- Error states match UI-SPEC §12 table
- Dark mode verified on all new pages/components
- Accessibility: axe-core or manual check passes for wizard, kanban, instance forms
- Responsive: no horizontal overflow at 375px; Kanban scrolls; wizard full-screen mobile
</acceptance_criteria>

---

## Verification Criteria (Gate for Phase Completion)

### Automated Checks (must pass)
- [ ] `rails db:migrate` + `rails db:seed` → clean
- [ ] `rails test` (unit) → 0 failures
- [ ] `rails test:system` → 0 failures (including all Phase 1 tests)
- [ ] `rubocop` → 0 offenses
- [ ] `brakeman` (if configured) → no new warnings

### Acceptance Criteria Verification (manual or scripted)
- [ ] **AC-028**: Win opportunity → wizard → portal activates only after step 5 confirm
- [ ] **AC-002**: Single org, 2 EmailAssistant instances → independent config, metrics queries, activity
- [ ] **AC-029**: Instance with `contractual_end_date = Date.tomorrow` → operational_state="running" until job runs
- [ ] **AC-030**: Ended instance → `historical_access_until` set → client queries respect cutoff

### Security Review (per QUALITY_BAR)
- [ ] RLS policies on all 9 new/modified tables verified
- [ ] Capability matrix matches RESEARCH.md §4.2
- [ ] No mass assignment vulnerabilities (strong parameters on all controllers)
- [ ] JSONB configuration validation prevents injection
- [ ] Impersonation audit covers wizard + service instance actions

### Performance Baseline
- [ ] Kanban board loads < 500ms with 100 opportunities (paginated/infinite scroll)
- [ ] Wizard step transitions < 200ms (Turbo Frame)
- [ ] ServiceInstance index < 300ms with 50 instances
- [ ] Health state computation cached, not computed per request

---

## Must-Haves (Goal-Backward Verification)

| Goal | Verification |
|------|--------------|
| Complete commercial cycle (lead → won → portal active) | `CRM::Opportunity` won → `ConversionWizard` completes → `Account.status == "active"` + `PortalActivated` event |
| Multiple instances per type per org | `org.service_instances.where(type: "EmailAssistantInstance").count >= 2` with distinct `configuration` |
| Three independent state machines | `instance.contractual_state`, `instance.operational_state`, `instance.health_state` transition independently per rules |
| Scheduled end + historical visibility | `EndScheduledServicesJob` transitions `scheduled_end→ended`; `with_historical_access` scope filters client views |
| CRM internal + Service Catalog operational separation | `CRM::` namespace controllers (internal only); `ServiceInstancesController` under Organization (client+internal) |
| Phase 1 patterns reused | Tenancy::Context, User#can?, AuditLog, Turbo Streams, Stimulus, RLS, Solid Queue all used identically |

---

## Dependencies Summary

```
Wave 1 (Sequential)
  1.1 CRM Models → 1.2 Service Catalog Models → 1.3 RLS + Permissions → 1.4 Seed + Validation

Wave 2 (Parallel after Wave 1)
  2.1 Lead/Contact/Account CRUD
  2.2 Opportunity + PipelineStage CRUD
  2.3 Kanban Board UI

Wave 3 (Sequential after Wave 2)
  3.1 Wizard Steps 1-3 → 3.2 Wizard Steps 4-5 + Activation → 3.3 Integration Tests

Wave 4 (Parallel after Wave 3)
  4.1 ServiceInstance CRUD + Config UI
  4.2 Three-State Machines
  4.3 Scheduled End Job + Historical Visibility

Wave 5 (Sequential after Wave 4)
  5.1 Acceptance Verification → 5.2 Documentation + Edge Cases
```

---

## Risk Mitigations (from RESEARCH.md §7)

| Risk | Mitigation in Plan |
|------|-------------------|
| JSONB schema validation complexity | Task 1.4 uses `activerecord-json_validator` gem + comprehensive unit tests |
| STI with configuration differences | Task 1.2 defines clear base + schema constants per subclass; Task 4.1 dynamic forms per type |
| Wizard rollback on partial failure | Task 3.2 explicit reverse-order destruction in transaction; Task 3.3 tests every cancel point |
| RLS policy complexity | Task 1.3 copies exact Phase 1 pattern; Task 5.1 verifies isolation |
| Solid Queue recurring job reliability | Task 4.3 uses standard Solid Queue recurring config; test job execution |
| Drag-and-drop UX edge cases | Task 2.3 uses native HTML5 + Stimulus; keyboard accessible; Turbo Stream fallback |

---

*Plan created: 2026-08-28*
*Phase: 02-crm-aprovisionamiento-y-cat-logo-de-servicios*
*Total tasks: 14 across 5 waves*
