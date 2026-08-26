# frozen_string_literal: true

require "test_helper"

module Security
  # SEG-05: audit_log NUNCA visible a clientes (sin rutas públicas; cuando
  # exista UI de auditoría irá tras gate internal-only + capability view_audit).
  # SEG-11: acciones directas vs impersonadas DISTINGUIBLES por columnas actor.
  class AuditVisibilityTest < ActionDispatch::IntegrationTest
    setup do
      @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Aud Co") }
      Tenancy::Context.with(account_id: @account.id) do
        @org = Tenancy::Organization.create!(name: "Org Aud", account: @account)
      end

      @staff = User.create!(email_address: "auditor@captia.test",
                            password: "contrasena-segura-123", account: @account)
      Tenancy::RoleAssignment.create!(user: @staff, scope_type: "Tenancy::Account",
                                      scope_id: @account.id, role: "superadmin")

      @cliente = User.create!(email_address: "cliente@captia.test",
                              password: "contrasena-segura-123", account: @account)
      Tenancy::RoleAssignment.create!(user: @cliente, scope_type: "Tenancy::Organization",
                                      scope_id: @org.id, role: "operativo")
      Tenancy::Context.with(account_id: @account.id) do
        Tenancy::Membership.create!(user: @cliente, organization: @org)
      end
    end

    test "SEG-05: cliente no accede a rutas de auditoría" do
      log_in(@cliente)

      get "/audit_logs"
      assert_response :not_found
      get "/admin/audit_logs"
      assert_response :not_found
    end

    test "SEG-11: acción directa vs impersonada distinguibles por columnas actor" do
      Tenancy::Context.with(account_id: @account.id, organization_id: @org.id) do
        AuditLog.create!(actor_real: @staff, actor_effective: @staff,
                         action: "organizations#create", ip: "10.0.0.1")
      end
      direct = AuditLog.find_by(action: "organizations#create")
      assert_equal @staff.id, direct.actor_real_id
      assert_equal @staff.id, direct.actor_effective_id

      impersonation = Impersonation.create!(
        initiator: @staff, target_user: @cliente,
        started_at: Time.current, expires_at: 30.minutes.from_now
      )
      Current.impersonation = impersonation

      audited = AuditLog.create!(
        actor_real: Current.actor_real, actor_effective: Current.actor_effective,
        action: "organizations#create", ip: "10.0.0.2"
      )
      assert_equal @staff.id, audited.actor_real_id, "actor REAL es el empleado"
      assert_equal @cliente.id, audited.actor_effective_id, "actor EFFECTIVE es el cliente"
      refute_equal audited.actor_real_id, audited.actor_effective_id,
                   "las columnas permiten distinguir directa vs impersonada"

      Current.impersonation = nil
    end

    private

    def log_in(user)
      post "/login", params: { email_address: user.email_address,
                               password: "contrasena-segura-123" }
      follow_redirect! if @response.redirect?
    end
  end
end
