---
phase: 2
slug: crm-aprovisionamiento-y-catalogo-de-servicios
status: draft
shadcn_initialized: false
preset: none
created: 2026-08-28
---

# Phase 2 — UI Design Contract

> Visual and interaction contract for Phase 2: CRM, aprovisionamiento y catálogo de servicios. Generated based on Phase 1 patterns, CONTEXT.md decisions, and RESEARCH.md.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | shadcn (Phase 1 uses Hotwire + Stimulus, no shadcn yet — evaluate in Phase 1) |
| Preset | none |
| Component library | none (native HTML + Stimulus controllers + Turbo Frames) |
| Icon library | Heroicons (inline SVG) — consistent with Phase 1 |
| Font | Inter (system fallback) — Phase 1 default |

---

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, badge padding, inline form element gaps |
| sm | 8px | Compact spacing: card padding, form field gaps, modal content padding |
| md | 16px | Default: section margins, container padding, list item gaps |
| lg | 24px | Section separation: between Kanban columns, wizard steps |
| xl | 32px | Layout gaps: page-level containers, sidebar/main separation |
| 2xl | 48px | Major breaks: wizard step containers, full-page sections |
| 3xl | 64px | Page-level: only for full-screen wizard modal wrapper |

Exceptions: none

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 14px | 400 | 1.5 |
| Label | 12px | 500 | 1.4 |
| Heading | 20px | 600 | 1.3 |
| Display | 28px | 700 | 1.2 |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | #ffffff / #f8fafc (dark: #0f172a) | Page backgrounds, card surfaces, modal backgrounds |
| Secondary (30%) | #f1f5f9 / #e2e8f0 (dark: #1e293b) | Sidebar, table headers, input backgrounds, Kanban column headers |
| Accent (10%) | #2563eb (blue-600) | Primary buttons, active Kanban column header, wizard progress indicator, links |
| Destructive | #dc2626 (red-600) | Delete actions, error states, destructive confirmations only |

Accent reserved for: Primary CTA buttons, active wizard step indicator, Kanban drag preview highlight, focus rings on interactive elements

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | "Crear oportunidad" / "Iniciar conversión" / "Activar portal" |
| Empty state heading (Kanban) | "No hay oportunidades en esta etapa" |
| Empty state body (Kanban) | "Arrastra una oportunidad aquí o haz clic en + para crear una" |
| Empty state heading (Services) | "Esta organización no tiene servicios configurados" |
| Empty state body (Services) | "Añade tu primera instancia de Email Assistant, Chatbot o Voice Assistant" |
| Error state (Wizard) | "Completa los campos requeridos para continuar. Revisa los errores marcados." |
| Destructive confirmation (Instance) | "Eliminar instancia: Esta acción no se puede deshacer. La configuración y métricas se perderán." |
| Destructive confirmation (Opportunity) | "Eliminar oportunidad: Se perderán todas las notas y actividad asociada." |
| Success toast (Wizard complete) | "Portal activado correctamente. El cliente ya puede acceder." |
| State badge: Contractual | "Activo" / "Pendiente inicio" / "Programado fin" / "Finalizado" / "Cancelado" |
| State badge: Operational | "Ejecutándose" / "Degradado" / "Detenido" / "Mantenimiento" / "Error" |
| State badge: Health | "Saludable" / "Advertencia" / "Crítico" / "Desconocido" |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| custom Stimulus controllers | kanban-drag, wizard-stepper, config-form-validator | code review required |

---

## Component Specifications

### 1. Kanban Board (Pipeline)

**Layout:**
- Horizontal scroll container with flex columns (one per PipelineStage)
- Column min-width: 300px, max-width: 360px
- Column header: Stage name + probability badge (color from stage.color) + opportunity count
- Column header clickable → opens PipelineStage edit modal

**Cards:**
- Background: white (dark: #1e293b)
- Border: 1px solid #e2e8f0 (dark: #334155)
- Border-radius: 8px
- Padding: md (16px)
- Shadow: 0 1px 2px rgba(0,0,0,0.05)
- Content: Opportunity name (Heading), Company (Label), Value + Probability (Label row), Expected close (Label), Stage badge (xs padding)
- Hover: shadow 0 4px 6px rgba(0,0,0,0.1), cursor: grab
- Drag: opacity 0.8, rotate 2deg, z-index: 50

**Empty Column:**
- Dashed border 2px #cbd5e1 (dark: #475569)
- Centered text: Empty state heading + body
- Min-height: 200px

**Drag & Drop:**
- Native HTML5 Drag API + Stimulus controller `kanban-drag`
- Drop zone highlight: Accent border 2px dashed
- Touch support: `touch-action: none` on cards during drag

### 2. Assisted Conversion Wizard (5 Steps)

**Modal Container:**
- Full-screen on mobile (< 768px), centered modal 800px max-width on desktop
- Turbo Frame wrapper for each step
- Progress indicator: 5-step horizontal stepper at top
- Step states: completed (check + accent), current (accent ring), pending (secondary)

**Step 1 — Review/Confirm Account:**
- Form: Account name, status, source, industry, assigned_to (select)
- Pre-filled from Lead data
- CTA: "Continuar a organizaciones" (Primary, disabled until valid)

**Step 2 — Create/Confirm Organizations:**
- List of organizations (min 1 required)
- Each: name, slug (auto), type select
- "Añadir organización" button (Secondary)
- CTA: "Continuar a servicios" (Primary, disabled if < 1 org)

**Step 3 — Select Service Types:**
- 3 Service Type cards (Email, Chatbot, Voice)
- Each card: Icon, name, description, "Añadir instancia" button
- Inline instance adder: Name input + "Añadir" (creates row below)
- Multiple instances per type allowed
- CTA: "Configurar instancias" (Primary, disabled if 0 instances total)

**Step 4 — Create Instances + Configure:**
- Per instance: Accordion with configuration form
- Form fields per ServiceType CONFIG_SCHEMA (dynamic)
- Validation: JSON schema client-side + server-side on submit
- CTA: "Configurar permisos" (Primary)

**Step 5 — Permissions + Invite Users:**
- Role assignment grid: Organization × Role template
- Invitation forms: email, role, organization scope
- CTA: "Activar portal" (Primary, destructive-style confirmation modal on click)

**Navigation:**
- "Anterior" button (Secondary) — enabled after step 1
- "Siguiente" / Final CTA (Primary) — disabled until step valid
- Cancel: "Cancelar" (Ghost) — triggers rollback confirmation modal

### 3. Service Instance Configuration Forms

**Per-Type Forms (Dynamic):**

**Email Assistant:**
- Dominio de email entrante* (text, required)
- Respuesta automática (toggle)
- Reglas de escalado (repeater: condición + acción)
- Reenvío a emails (tag input)

**Chatbot:**
- Tema del widget (select: light/dark/auto)
- Mensaje de bienvenida* (textarea, required)
- Disparador de escalado (select: keyword/sentiment/manual)
- Webhook de integración (url)

**Voice Assistant:**
- Número de teléfono* (tel, required)
- Idioma (select)
- Voz (select)
- Grabación habilitada (toggle)
- Proveedor transcripción (select: whisper/deepgram/assemblyai)

**Common to all:**
- Nombre de la instancia* (text, required, unique per org)
- Identificador (slug, auto from name, editable)

### 4. Service Instance Management

**List View (per Organization):**
- Table or card grid (responsive: cards < 768px)
- Columns: Nombre, Tipo (icon + badge), Estado contractual, Estado operativo, Salud, Acciones
- State badges: Contractual (blue/green/gray/red), Operational (green/orange/gray/blue/red), Health (green/yellow/red/gray)
- Actions: Ver detalle, Editar config, Cambiar estado, Eliminar

**Detail Modal:**
- Tabs: Configuración, Estado, Métricas, Historial
- Config: Read-only JSON view (formatted) + "Editar" button
- State: Three badges with last transition timestamp
- Health: Visual indicator + last heartbeat, error rate, latency

### 5. Pipeline Stage Management

**Modal (triggered from Kanban column header click):**
- Fields: Nombre*, Posición (number), Probabilidad %* (0-100), Color (hex picker)
- Color picker: 8 preset swatches + custom input
- Live preview: badge with name + probability in selected color
- Save: "Guardar cambios" (Primary)
- Delete: "Eliminar etapa" (Destructive, only if 0 opportunities)

### 6. CRM List Views (Leads, Contacts, Opportunities)

**Consistent Pattern (reuse Phase 1 Organization index):**
- Toolbar: Search (debounced 300ms), Filter dropdown, "Nuevo" button
- Table: Sortable headers, pagination (25/page), row click → detail modal
- Actions column: Ver, Editar, (Oportunidad) Convertir / Eliminar
- Empty state: "No hay [leads/contactos/oportunidades] aún. Crea tu primero."

---

## Interaction States

| Component | Hover | Focus | Active | Disabled | Loading |
|-----------|-------|-------|--------|----------|---------|
| Primary Button | bg-blue-700 | ring-2 ring-blue-500 | bg-blue-800 | opacity-50 cursor-not-allowed | spinner + "Procesando..." |
| Secondary Button | bg-slate-200 | ring-2 ring-slate-400 | bg-slate-300 | opacity-50 | spinner |
| Ghost Button | bg-slate-100 | ring-2 ring-slate-400 | bg-slate-200 | opacity-50 | — |
| Kanban Card | shadow-md, cursor-grab | ring-2 ring-blue-500 | rotating 2deg | — | — |
| Form Input | border-slate-400 | ring-2 ring-blue-500 | — | bg-slate-50 cursor-not-allowed | — |
| Wizard Step (completed) | — | — | — | — | — |
| State Badge | — | — | — | — | pulse animation (health: unknown) |

---

## Responsive Breakpoints

| Breakpoint | Kanban | Wizard | Instance List | Tables |
|------------|--------|--------|---------------|--------|
| < 640px | Horizontal scroll, cards stack | Full-screen modal, single column | Cards, stacked fields | Horizontal scroll |
| 640–1024px | 2-3 columns visible | Modal 90vw | Cards 2-col | Table with actions dropdown |
| > 1024px | All columns, no scroll | Modal 800px | Table | Full table |

---

## Accessibility

- All modals: `role="dialog"`, `aria-modal="true"`, focus trap, ESC to close
- Kanban: `aria-roledescription="column"`, `aria-label="Etapa: {name}"`, drag via keyboard (Space to pick, arrows to move, Enter to drop)
- Wizard: `aria-label="Paso {n} de 5: {name}"`, progress `role="progressbar"`
- Forms: `aria-describedby` for errors, `aria-invalid` on error
- Color: All state badges have text labels (not color-only)
- Focus order: Logical tab sequence in all modals/forms

---

## Animation & Transitions

- Modal enter: fade-in (150ms) + scale(0.95→1)
- Modal exit: fade-out (100ms) + scale(1→0.95)
- Wizard step: slide left/right (200ms ease-out)
- Kanban drag: transform only (60fps), no layout thrash
- Toast: slide up (300ms), auto-dismiss 4s
- Accordion: height transition (200ms)

---

## Empty States (Complete)

| Context | Heading | Body | Action |
|---------|---------|------|--------|
| Kanban column (0 opps) | "No hay oportunidades en esta etapa" | "Arrastra una oportunidad aquí o haz clic en + para crear una" | + button in column header |
| Pipeline (0 stages) | "Pipeline sin configurar" | "Crea tus primeras etapas para empezar a gestionar oportunidades" | "Crear etapa" button |
| Organization services (0) | "Esta organización no tiene servicios configurados" | "Añade tu primera instancia de Email Assistant, Chatbot o Voice Assistant" | "Añadir servicio" |
| Leads/Contacts/Opportunities (0) | "No hay [entidad] aún" | "Crea tu primer [entidad] para empezar" | "Nuevo [entidad]" |

---

## Error States

| Context | Display |
|---------|---------|
| Form validation | Inline below field: red text + icon, field border red |
| Wizard step invalid | "Siguiente" disabled, scroll to first error on click |
| API error (save) | Toast: "Error al guardar. Intenta de nuevo." + inline form errors |
| Network offline | Banner top: "Sin conexión. Los cambios se sincronizarán al reconectar." |
| Permission denied | Modal: "No tienes permisos para esta acción" + "Entendido" |

---

## Dark Mode

- All colors defined with dark variants (see Color table)
- Toggle: inherits from Phase 1 implementation (system preference + manual toggle in user menu)
- Kanban drag preview: respects current theme

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending

---

*Phase: 02-crm-aprovisionamiento-y-catalogo-de-servicios*
*UI-SPEC created: 2026-08-28 via gsd-ui-phase*