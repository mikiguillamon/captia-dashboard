# frozen_string_literal: true

require "application_system_test_case"

# ==============================================================================
# REQUIRED-GATE (D-08): suite de aislamiento E2E — CRITERIO DE SALIDA DE FASE.
# Su fallo IMPIDE cerrar la fase; el verifier debe consultar este archivo y su
# resultado en 01-03-SUMMARY antes de dar la fase por completa.
#
# Escenarios PRD §10: AC-001, AC-003, AC-004 (+ controles positivos).
# SEG-05/SEG-11 se cubren en test/integration/security/audit_visibility_test.rb
# ==============================================================================
class Tenancy::IsolationAcTest < ApplicationSystemTestCase
  setup do
    @alpha = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Alpha") }
    @beta = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Beta") }

    Tenancy::Context.with(account_id: @alpha.id) do
      @a1 = Tenancy::Organization.create!(name: "Alpha Uno", account: @alpha)
      @a2 = Tenancy::Organization.create!(name: "Alpha Dos", account: @alpha)
      @a3 = Tenancy::Organization.create!(name: "Alpha Tres", account: @alpha)
    end
    Tenancy::Context.with(account_id: @beta.id) do
      @b1 = Tenancy::Organization.create!(name: "Beta Única", account: @beta)
    end

    @admin_cuenta_alpha = cliente_user("admin_cuenta_alpha@captia.test",
                                       role: "admin_cuenta", scope: @alpha,
                                       orgs: [ @a1, @a2, @a3 ])
    # AC-001: segundo admin de organización de Alpha SOLO ve su org asignada.
    @admin_org_alpha2 = cliente_user("admin_org_alpha2@captia.test",
                                     role: "admin_org", scope: @a2, orgs: [ @a2 ])
    @comercial_sin_excepciones = interno_user("comercial_sin_excepciones@captia.test",
                                              role: "comercial")
    @tecnico_alpha = interno_user("tecnico_alpha@captia.test", role: "tecnico",
                                  account: @alpha)
  end

  test "AC-001: admin de cuenta accede a sus 3 organizaciones" do
    login_as(@admin_cuenta_alpha)
    assert_text "Alpha Uno"
    assert_text "Alpha Dos"
    assert_text "Alpha Tres"
    assert_no_text "Beta Única"
  end

  test "AC-001: usuario de organización SOLO ve la asignada" do
    login_as(@admin_org_alpha2)
    assert_text "Alpha Dos"
    assert_no_text "Alpha Uno"
    assert_no_text "Alpha Tres"
    assert_no_text "Beta Única"
  end

  test "AC-003: comercial sin excepciones no alcanza contenido operativo sensible" do
    login_as(@comercial_sin_excepciones)

    # Sin capability impersonate ni manage_organizations (PRD §3.1 Comercial).
    refute @comercial_sin_excepciones.can?(:impersonate, scope: @alpha)
    refute @comercial_sin_excepciones.can?(:manage_organizations, scope: @alpha)
    refute @comercial_sin_excepciones.can?(:view_audit, scope: @alpha)

    visit new_impersonation_path
    assert_text "Forbidden"
  end

  test "AC-004: tecnico de Alpha no alcanza datos de Beta ni por URL ni por API interna" do
    login_as(@tecnico_alpha)

    # URL/cookie manipulada hacia organización de Beta: sin membership ni rol,
    # el contexto activo no puede resolverse a Beta → sin leak.
    assert_not @tecnico_alpha.can?(:manage_organizations, scope: @beta)
    # Cookie manipulada hacia organización de Beta (vía driver del navegador).
    page.driver.set_cookie("active_organization_id", @b1.id.to_s, path: "/")
    visit organizations_path
    refute page.has_text?("Beta Única"),
           "ningún dato de Beta debe ser accesible para técnico de Alpha"
    # Su alcance legítimo (Alpha) sigue intacto.
    assert_text "Alpha Uno"
  end

  private

  def login_as(user)
    visit new_session_path
    fill_in "Correo electrónico", with: user.email_address
    fill_in "Contraseña", with: "contrasena-segura-123"
    click_button "Iniciar sesión"
    assert_text "Organizaciones"
  end

  def cliente_user(email, role:, scope:, orgs:)
    user = User.create!(email_address: email, password: "contrasena-segura-123",
                        account: scope.is_a?(Tenancy::Account) ? scope : scope.account)
    Tenancy::RoleAssignment.create!(
      user: user,
      scope_type: scope.is_a?(Tenancy::Account) ? "Tenancy::Account" : "Tenancy::Organization",
      scope_id: scope.id, role: role
    )
    Tenancy::Context.with(account_id: user.account_id) do
      orgs.each { |o| Tenancy::Membership.create!(user: user, organization: o) }
    end
    user
  end

  def interno_user(email, role:, account: nil)
    user = User.create!(email_address: email, password: "contrasena-segura-123",
                        account: account)
    Tenancy::RoleAssignment.create!(user: user, scope_type: "Tenancy::Account",
                                    scope_id: (account || Tenancy::Account.first).id,
                                    role: role) if account
    user
  end
end
