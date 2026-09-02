# Datos demo idempotentes para desarrollo (soporte AC-001 y roles PRD §3).
# Altas de cuentas = provisión interna → Tenancy::Context.provisioning;
# escrituras tenant siempre dentro de Context.with (D-07).
# SOLO desarrollo: db:seed en producción no debe crear un superadmin con
# contraseña conocida (review F2).
return unless Rails.env.development?

TENANCY_DEMO_PASSWORD = "captia-demo-2026"

Tenancy::Context.provisioning do
  alpha = Tenancy::Account.find_or_create_by!(name: "Alpha Demo")

  orgs = {}
  Tenancy::Context.with(account_id: alpha.id) do
    [ "Alpha Ops", "Alpha Growth", "Alpha Labs" ].each do |nombre|
      orgs[nombre] = Tenancy::Organization.find_or_create_by!(account: alpha, name: nombre)
    end
  end

  demo_user = lambda do |email, role:, scope:, memberships: []|
    u = User.find_or_create_by!(email_address: email) { |x| x.password = TENANCY_DEMO_PASSWORD }
    u.update!(account: alpha) unless u.account_id == alpha.id
    memberships.each do |org|
      Tenancy::Context.with(account_id: alpha.id, organization_id: org.id) do
        Tenancy::Membership.find_or_create_by!(user: u, organization: org)
      end
    end
    scope_key = scope.is_a?(Tenancy::Organization) ? "Tenancy::Organization" : "Tenancy::Account"
    Tenancy::RoleAssignment.find_or_create_by!(
      user: u, scope_type: scope_key, scope_id: scope.id, role: role
    )
    u
  end

  # Internos (PRD §3.1) — alcance cuenta para el skeleton.
  demo_user.call("superadmin@captia.test", role: "superadmin", scope: alpha,
                 memberships: orgs.values)
  demo_user.call("direccion@captia.test", role: "direccion", scope: alpha)
  demo_user.call("comercial@captia.test", role: "comercial", scope: alpha)
  demo_user.call("account_manager@captia.test", role: "account_manager", scope: alpha)
  demo_user.call("tecnico@captia.test", role: "tecnico", scope: alpha)

  # Cliente (PRD §3.2): AC-001 — admin_cuenta ve las 3; admin_org SOLO la suya.
  demo_user.call("admin_cuenta@captia.test", role: "admin_cuenta", scope: alpha,
                 memberships: orgs.values)
  growth = orgs["Alpha Growth"]
  demo_user.call("admin_org@captia.test", role: "admin_org", scope: growth,
                 memberships: [ growth ])
  demo_user.call("operativo@captia.test", role: "operativo", scope: growth,
                 memberships: [ growth ])

  demo = User.find_or_create_by!(email_address: "demo@captia.test") do |u|
    u.password = TENANCY_DEMO_PASSWORD
  end
  demo.update!(account: alpha) unless demo.account_id == alpha.id
end

# ServiceType reference data (Phase 2)
ServiceType.find_or_create_by!(name: "email_assistant") do |st|
  st.description = "Procesamiento automático de emails entrantes"
  st.config_schema = ServiceType::EMAIL_ASSISTANT_SCHEMA
  st.default_config = {}
  st.default_retention_days = 90
  st.icon = "mail"
  st.display_order = 1
end

ServiceType.find_or_create_by!(name: "chatbot") do |st|
  st.description = "Asistente conversacional para web/chat"
  st.config_schema = ServiceType::CHATBOT_SCHEMA
  st.default_config = {}
  st.default_retention_days = 90
  st.icon = "chat-bubble-left-right"
  st.display_order = 2
end

ServiceType.find_or_create_by!(name: "voice_assistant") do |st|
  st.description = "Asistente de voz para llamadas telefónicas"
  st.config_schema = ServiceType::VOICE_ASSISTANT_SCHEMA
  st.default_config = {}
  st.default_retention_days = 180
  st.icon = "phone"
  st.display_order = 3
end

# Default pipeline stages for demo account
if alpha = Tenancy::Account.find_by(name: "Alpha Demo")
  stages = [
    { name: "Prospecting", position: 1, probability: 10, color: "#64748b" },
    { name: "Qualified", position: 2, probability: 25, color: "#0ea5e9" },
    { name: "Proposal", position: 3, probability: 50, color: "#f59e0b" },
    { name: "Negotiation", position: 4, probability: 75, color: "#8b5cf6" },
    { name: "Won", position: 5, probability: 100, color: "#22c55e" },
    { name: "Lost", position: 6, probability: 0, color: "#ef4444" }
  ]
  stages.each do |attrs|
    alpha.pipeline_stages.find_or_create_by!(name: attrs[:name]) do |ps|
      ps.assign_attributes(attrs)
    end
  end
end
