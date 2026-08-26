# frozen_string_literal: true

require "application_system_test_case"

# AC-001: admin_cuenta cambia entre sus 3 organizaciones; admin_org ve SOLO
# la suya en el selector y jamás accede a otra.
class OrganizationScopeTest < ApplicationSystemTestCase
  setup do
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Scope Co") }
    Tenancy::Context.with(account_id: @account.id) do
      @org1 = Tenancy::Organization.create!(name: "Org Uno", account: @account)
      @org2 = Tenancy::Organization.create!(name: "Org Dos", account: @account)
      @org3 = Tenancy::Organization.create!(name: "Org Tres", account: @account)
    end

    @admin_cuenta = User.create!(email_address: "cuenta@captia.test",
                                 password: "contrasena-segura-123", account: @account)
    Tenancy::RoleAssignment.create!(user: @admin_cuenta, scope_type: "Tenancy::Account",
                                    scope_id: @account.id, role: "admin_cuenta")
    [@org1, @org2, @org3].each do |org|
      Tenancy::Context.with(account_id: @account.id) do
        Tenancy::Membership.create!(user: @admin_cuenta, organization: org)
      end
    end

    @admin_org2 = User.create!(email_address: "org2@captia.test",
                               password: "contrasena-segura-123", account: @account)
    Tenancy::RoleAssignment.create!(user: @admin_org2, scope_type: "Tenancy::Organization",
                                    scope_id: @org2.id, role: "admin_org")
    Tenancy::Context.with(account_id: @account.id) do
      Tenancy::Membership.create!(user: @admin_org2, organization: @org2)
    end
  end

  def login_as(user)
    visit new_session_path
    fill_in "Correo electrónico", with: user.email_address
    fill_in "Contraseña", with: "contrasena-segura-123"
    click_button "Iniciar sesión"
    assert_text "Organizaciones"
  end

  test "admin de cuenta ve las 3 organizaciones y cambia entre ellas" do
    login_as(@admin_cuenta)

    assert_text "Org Uno"
    assert_text "Org Dos"
    assert_text "Org Tres"

    click_button "Org Dos"
    assert_text "Organización activa: Org Dos"

    click_button "Org Tres"
    assert_text "Organización activa: Org Tres"
  end

  test "admin de organización solo ve la suya en el selector" do
    login_as(@admin_org2)

    assert_text "Org Dos"
    assert_no_text "Org Uno"
    assert_no_text "Org Tres"
    assert_button "Org Dos", count: 1
    assert_no_button "Org Uno"
  end
end
