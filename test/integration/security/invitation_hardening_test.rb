# frozen_string_literal: true

require "test_helper"

# Regresiones del code review de fase (F1 crítico, F5, F6).
module Security
  class InvitationHardeningTest < ActionDispatch::IntegrationTest
    setup do
      @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Hard Co") }
      Tenancy::Context.with(account_id: @account.id) do
        @org = Tenancy::Organization.create!(name: "Org Hard", account: @account,
                                             allow_self_invite: true)
        @victima = User.create!(email_address: "victima@captia.test",
                                password: "contrasena-victima-1", account: @account)
        Tenancy::Membership.create!(user: @victima, organization: @org)
      end

      @inviter = User.create!(email_address: "inviter@captia.test",
                              password: "contrasena-segura-123", account: @account)
      Tenancy::RoleAssignment.create!(user: @inviter, scope_type: "Tenancy::Account",
                                      scope_id: @account.id, role: "admin_cuenta")
      Tenancy::Context.with(account_id: @account.id) do
        Tenancy::Membership.create!(user: @inviter, organization: @org)
      end
      @raw = Tenancy::Invitation.issue!(organization: @org, invited_by: @inviter,
                                        email: "candidata@captia.test", role: "operativo")
    end

    test "F1 CRÍTICO: aceptar con email ajeno NO inicia sesión como ese usuario" do
      post accept_invitations_path, params: {
        token: @raw, email_address: @victima.email_address, password: "cualquiera-larga-9"
      }
      assert_redirected_to new_session_path # rechazo uniforme, NO sesión de víctima
      follow_redirect!
      assert_equal 0, Session.where(user: @victima).count
    end

    test "F6: contraseña inválida NO quema el token; reintento válido funciona" do
      get accept_invitation_path, params: { token: @raw }
      assert_response :ok

      post accept_invitations_path, params: {
        token: @raw, email_address: "candidata@captia.test", password: "corta"
      }
      assert_response :unprocessable_entity
      assert Tenancy::Invitation.valid.exists?(token_digest: Tenancy::Invitation.digest(@raw)),
             "el token debe seguir válido tras un fallo de validación"

      post accept_invitations_path, params: {
        token: @raw, email_address: "candidata@captia.test", password: "contrasena-buena-99"
      }
      assert_redirected_to organizations_path
      assert_equal 0, Tenancy::Invitation.valid.count
    end
  end
end
