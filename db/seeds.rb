# Datos demo idempotentes para desarrollo (AC-001 futuro: 1 cuenta, 3 organizaciones).
# El alta de cuentas es provisión interna → Tenancy::Context.provisioning;
# las organizaciones se escriben ya bajo el contexto de SU cuenta (D-07).

Tenancy::Context.provisioning do
  alpha = Tenancy::Account.find_or_create_by!(name: "Alpha Demo")

  Tenancy::Context.with(account_id: alpha.id) do
    [ "Alpha Ops", "Alpha Growth", "Alpha Labs" ].each do |nombre|
      Tenancy::Organization.find_or_create_by!(account: alpha, name: nombre)
    end
  end

  demo = User.find_or_create_by!(email_address: "demo@captia.test") do |u|
    u.password = "captia-demo-2026"
  end
  demo.update!(account: alpha) unless demo.account_id == alpha.id
end
