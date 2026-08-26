# frozen_string_literal: true

require "test_helper"

# TEN-11 / FR-011: invitaciones gobernadas por capability invite_users +
# autogestión habilitada para invitadores cliente; token un-uso 7 días;
# membership creada dentro de Tenancy::Context.
class AdminInvitationsTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Inv Co") }
    Tenancy::Context.with(account_id: @account.id) do
      @org = Tenancy::Organization.create!(name: "Org Inv", account: @account,
                                           allow_self_invite: false)
    end

    @admin_org = User.create!(email_address: "inviter@captia.test",
                              password: "contrasena-segura-123", account: @account)
    Tenancy::RoleAssignment.create!(user: @admin_org, scope_type: "Tenancy::Organization",
                                    scope_id: @org.id, role: "admin_org")
    Tenancy::Context.with(account_id: @account.id) do
      Tenancy::Membership.create!(user: @admin_org, organization: @org)
    end

    @sin_capacidad = User.create!(email_address: "operativo@captia.test",
                                  password: "contrasena-segura-123", account: @account)
    Tenancy::RoleAssignment.create!(user: @sin_capacidad, scope_type: "Tenancy::Organization",
                                    scope_id: @org.id, role: "operativo")
    Tenancy::Context.with(account_id: @account.id) do
      Tenancy::Membership.create!(user: @sin_capacidad, organization: @org)
    end

    @comercial = User.create!(email_address: "staff@captia.test",
                              password: "contrasena-segura-123")
    Tenancy::RoleAssignment.create!(user: @comercial, scope_type: "Tenancy::Account",
                                    scope_id: @account.id, role: "comercial")

    log_in(@admin_org)
  end

  test "invitador sin capability invite_users recibe 403" do
    delete "/logout"
    log_in(@sin_capacidad)

    post organization_invitations_path(organization_id: @org.id),
         params: invitation_params(role: "operativo")
    assert_response :forbidden
    assert_equal 0, Tenancy::Invitation.count
  end

  test "cliente sin autogestión habilitada NO puede invitar (FR-011)" do
    # admin_org ES cliente y allow_self_invite=false en setup.
    post organization_invitations_path(organization_id: @org.id),
         params: invitation_params(role: "operativo")
    assert_response :forbidden
    assert_equal 0, Tenancy::Invitation.count
  end

  test "rol destino no-cliente es rechazado" do
    @org.update_columns(allow_self_invite: true)

    post organization_invitations_path(organization_id: @org.id),
         params: invitation_params(role: "superadmin")
    assert_response :forbidden
    assert_equal 0, Tenancy::Invitation.count
  end

  test "flujo completo: token emitido, aceptación crea User+Membership en contexto y sesión" do
    @org.update_columns(allow_self_invite: true)

    post organization_invitations_path(organization_id: @org.id),
         params: invitation_params(role: "operativo")
    assert_redirected_to organizations_path

    raw = Tenancy::Invitation.last.tap { |i| assert i.valid? && i.used_at.nil? }
                                 .token_digest # no usable; obtenemos el claro vía mailer abajo
    nil and raw

    # Recreamos token para tener el valor en claro (issue! devuelve raw).
    delete "/logout"
    log_in(@admin_org)
    raw = Tenancy::Invitation.issue!(organization: @org, invited_by: @admin_org,
                                     email: "nuevo@captia.test", role: "operativo")

    get accept_invitation_path, params: { token: raw }
    assert_response :ok

    patch = nil
    post accept_invitations_path, params: {
      token: raw, email_address: "nuevo@captia.test", password: "contrasena-nueva-9"
    }
    assert_redirected_to organizations_path

    nuevo = User.find_by!(email_address: "nuevo@captia.test")
    membership = Tenancy::Membership.find_by(user: nuevo, organization: @org)
    assert_not_nil membership, "la membership debe crearse dentro del contexto transaccional"

    # El invitado queda autenticado con su nueva sesión.
    assert_equal 1, Session.where(user: nuevo).count
  end

  test "token reusado o expirado es rechazado con respuesta uniforme" do
    @org.update_columns(allow_self_invite: true)
    raw = Tenancy::Invitation.issue!(organization: @org, invited_by: @admin_org,
                                     email: "reuso@captia.test", role: "operativo")

    post accept_invitations_path, params: {
      token: raw, email_address: "reuso@captia.test", password: "contrasena-larga-7"
    }
    assert_response :see_other

    post accept_invitations_path, params: {
      token: raw, email_address: "reuso@captia.test", password: "contrasena-larga-7"
    }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_includes response.body, InvitationsController::GENERIC_INVALID

    # Expiración >7 días.
    raw2 = Tenancy::Invitation.issue!(organization: @org, invited_by: @admin_org,
                                      email: "tarde@captia.test", role: "operativo")
    travel 8.days do
      get accept_invitation_path, params: { token: raw2 }
    end
    assert_redirected_to new_session_path
    follow_redirect!
    assert_includes response.body, InvitationsController::GENERIC_INVALID
  end

  private

  def invitation_params(role:)
    { invitation: { email: "candidato@captia.test", role: role } }
  end

  def log_in(user)
    post "/login", params: { email_address: user.email_address, password: "contrasena-segura-123" }
    follow_redirect! if @response.redirect?
  end
end
