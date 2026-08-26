# frozen_string_literal: true

require "test_helper"

# AUTH-04..07/SEG-04/11 lado servidor: re-auth obligatoria, destino solo
# cliente, expiración 30min con restauración de sesión del empleado y
# notificación configurable (job encolado).
class ImpersonationSecurityTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Sec Imp") }
    Tenancy::Context.with(account_id: @account.id) do
      @org_notify = Tenancy::Organization.create!(name: "Org Notifica", account: @account,
                                                  notify_impersonation: true)
    end

    @staff = User.create!(email_address: "staff@captia.test",
                          password: "contrasena-segura-123", account: @account)
    Tenancy::RoleAssignment.create!(user: @staff, scope_type: "Tenancy::Account",
                                    scope_id: @account.id, role: "superadmin")

    @cliente = User.create!(email_address: "cli@captia.test",
                            password: "contrasena-segura-123", account: @account)
    Tenancy::RoleAssignment.create!(user: @cliente, scope_type: "Tenancy::Organization",
                                    scope_id: @org_notify.id, role: "operativo")
    Tenancy::Context.with(account_id: @account.id) do
      Tenancy::Membership.create!(user: @cliente, organization: @org_notify)
    end

    @otro_staff = User.create!(email_address: "tecnico@captia.test",
                               password: "contrasena-segura-123", account: @account)
    Tenancy::RoleAssignment.create!(user: @otro_staff, scope_type: "Tenancy::Account",
                                    scope_id: @account.id, role: "tecnico")

    post "/login", params: { email_address: @staff.email_address, password: "contrasena-segura-123" }
  end

  test "sin re-auth password la impersonación responde 403" do
    assert_no_difference [ "Impersonation.count", "AuditLog.count" ] do
      post impersonation_path, params: { target_user_id: @cliente.id, password: "" }
    end
    assert_response :forbidden
  end

  test "password incorrecta → 403" do
    post impersonation_path, params: { target_user_id: @cliente.id, password: "mala-contra-9999" }
    assert_response :forbidden
  end

  test "no se puede impersonar a otro interno" do
    post impersonation_path, params: { target_user_id: @otro_staff.id, password: "contrasena-segura-123" }
    assert_response :forbidden
  end

  test "expiración a los ~30 min fuerza salida y restaura sesión del empleado" do
    start_impersonation!

    travel 31.minutes do
      get organizations_path
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, @staff.email_address, "vuelve la identidad del empleado"
    assert_not_includes response.body, "Estás operando como"

    imp = Impersonation.last
    assert imp.ended_at.present?
  end

  test "al finalizar con notify_impersonation=true se encola el job de email" do
    start_impersonation!

    assert_enqueued_with job: ImpersonationNotificationJob do
      delete impersonation_path
    end
    assert_redirected_to root_path
  end

  private

  def start_impersonation!
    post impersonation_path, params: {
      target_user_id: @cliente.id, password: "contrasena-segura-123"
    }
    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "Estás operando como"
  end
end
