# frozen_string_literal: true

require "test_helper"

# Gate de acceso del walking skeleton: autenticación obligatoria y datos
# servidos desde el contexto transaccional (D-07).
class OrganizationsAccessTest < ActionDispatch::IntegrationTest
  test "index requiere autenticación y redirige a /login" do
    get organizations_path
    assert_redirected_to new_session_path
  end

  test "usuario autenticado ve solo las organizaciones de SU cuenta" do
    alpha = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Alpha") }
    beta  = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Beta") }

    Tenancy::Context.with(account_id: alpha.id) do
      Tenancy::Organization.create!(name: "Org Visible", account: alpha)
    end
    Tenancy::Context.with(account_id: beta.id) do
      Tenancy::Organization.create!(name: "Otra Cuenta", account: beta)
    end

    ana = User.create!(email_address: "ana@captia.test", password: "contrasena-segura-123", account: alpha)
    # Acceso vía rol a nivel cuenta (modelo AC-001 de 01-03).
    Tenancy::RoleAssignment.create!(user: ana, scope_type: "Tenancy::Account",
                                    scope_id: alpha.id, role: "admin_cuenta")

    post "/login", params: { email_address: ana.email_address, password: "contrasena-segura-123" }
    assert_redirected_to root_url

    follow_redirect!
    assert_response :ok
    assert_includes response.body, "Org Visible"
    assert_not_includes response.body, "Otra Cuenta",
                        "las organizaciones de otra cuenta no deben renderizarse"
  end
end
