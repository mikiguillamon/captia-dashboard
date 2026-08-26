# frozen_string_literal: true

require "test_helper"

# SEG-03 / FR-014 / AC-006: organizaciones con require_mfa=true bloquean a sus
# usuarios sin enrollment confirmado; quien ya tiene MFA pasa sin fricción.
class OrgRequiredMfaTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "MFA Co") }
    @org = Tenancy::Context.with(account_id: @account.id) do
      Tenancy::Organization.create!(name: "Org Estricta", account: @account, require_mfa: true)
    end
  end

  test "la columna require_mfa es NOT NULL con default false" do
    column = Tenancy::Organization.columns.find { |c| c.name == "require_mfa" }
    assert_not column.null
    assert_equal false, column.default
  end

  test "AC-006: usuario SIN enrollment en org con flag NO obtiene sesión de acceso" do
    user = User.create!(email_address: "bloqueado@captia.test",
                        password: "contrasena-segura-123", account: @account)

    post "/login", params: { email_address: user.email_address, password: "contrasena-segura-123" }
    assert_response :forbidden
    assert_includes response.body, "Esta organización exige MFA. Actívalo desde tu perfil."
    assert_equal 0, Session.count, "no debe crearse Session de acceso"
    assert_empty cookies[:session_id] || ""
  end

  test "usuario CON MFA confirmado en org con flag completa challenge y accede sin fricción extra" do
    user = User.create!(email_address: "mfa-ok@captia.test",
                        password: "contrasena-segura-123", account: @account)
    Identity::MfaEnrollment.create!(user: user, secret: ROTP::Base32.random_base32(32)).tap do |e|
      e.confirm_with!(ROTP::TOTP.new(e.secret).at(Time.now - 30))
    end

    post "/login", params: { email_address: user.email_address, password: "contrasena-segura-123" }
    assert_redirected_to new_mfa_challenge_path

    post mfa_challenge_path, params: { code: ROTP::TOTP.new(user.mfa_enrollment.secret).now }
    assert_redirected_to root_url
    assert_equal 1, Session.count
  end

  test "org sin el flag no bloquea a usuarios sin MFA" do
    Tenancy::Context.with(account_id: @account.id) do
      Tenancy::Organization.create!(name: "Org Normal", account: @account, require_mfa: false)
    end
    user = User.create!(email_address: "normal@captia.test",
                        password: "contrasena-segura-123", account: @account)
    Tenancy::Context.with(account_id: @account.id) { @org.update!(require_mfa: false) }

    post "/login", params: { email_address: user.email_address, password: "contrasena-segura-123" }
    assert_redirected_to root_url
    assert_equal 1, Session.count
  end

  test "el flag no es togglable por rutas públicas (solo flujos administrativos internos)" do
    user = User.create!(email_address: "intentona@captia.test",
                        password: "contrasena-segura-123", account: @account)
    post "/login", params: { email_address: user.email_address, password: "contrasena-segura-123" }

    # No existe ruta pública de actualización: el framework responde 404
    # (show_exceptions :rescuable) y el flag permanece intacto.
    patch "/organizations/#{@org.id}", params: { tenancy_organization: { require_mfa: false } }
    assert_response :not_found
    assert Tenancy::Context.with(account_id: @account.id) {
      Tenancy::Organization.find(@org.id).require_mfa
    }, "el flag debe permanecer intacto"
  end
end
