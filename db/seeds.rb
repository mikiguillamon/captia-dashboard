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
