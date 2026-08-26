# frozen_string_literal: true

require "application_system_test_case"

# Walking skeleton E2E: login → empty state → crear organización vía formulario
# Turbo → aparece en lista → logout.
class OrganizationsFlowTest < ApplicationSystemTestCase
  setup do
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Flow Co") }
    @user = User.create!(email_address: "flow@captia.test", password: "flow-secret-123", account: @account)
    Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Account",
                                    scope_id: @account.id, role: "admin_cuenta")
  end

  test "login, crear organización por UI con Turbo y logout" do
    visit new_session_path

    fill_in "Correo electrónico", with: @user.email_address
    fill_in "Contraseña", with: "flow-secret-123"
    click_button "Iniciar sesión"

    assert_text "Organizaciones"
    # Empty state del UI-SPEC visible antes de crear nada.
    assert page.has_text?("Sin organizaciones todavía"),
           "el empty state del UI-SPEC debe verse antes de crear nada"

    fill_in "Nombre", with: "Org Turbo"
    click_button "Crear organización"

    assert_text "Org Turbo"
    assert_no_text "Sin organizaciones todavía"

    click_button "Cerrar sesión"
    assert_button "Iniciar sesión"
  end
end
