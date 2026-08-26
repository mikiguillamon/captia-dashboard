# frozen_string_literal: true

require "application_system_test_case"

# AC-007 completo en navegador: re-auth, banner persistente con copy UI-SPEC,
# auditoría de acción impersonada con actor real, salida limpia.
class AdminImpersonationsTest < ApplicationSystemTestCase
  setup do
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Imp Co") }
    Tenancy::Context.with(account_id: @account.id) do
      @org = Tenancy::Organization.create!(name: "Org Imp", account: @account)
    end

    @staff = User.create!(email_address: "soporte@captia.test",
                          password: "contrasena-segura-123", account: @account)
    Tenancy::RoleAssignment.create!(user: @staff, scope_type: "Tenancy::Account",
                                    scope_id: @account.id, role: "superadmin")

    @cliente = User.create!(email_address: "clientecito@captia.test",
                            password: "contrasena-segura-123", account: @account)
    Tenancy::RoleAssignment.create!(user: @cliente, scope_type: "Tenancy::Organization",
                                    scope_id: @org.id, role: "operativo")
    Tenancy::Context.with(account_id: @account.id) do
      Tenancy::Membership.create!(user: @cliente, organization: @org)
    end

    login_as(@staff)
  end

  test "impersona con re-auth, banner persistente, acción auditada y salir" do
    visit new_impersonation_path

    select @cliente.email_address, from: "Usuario a impersonar"
    fill_in "Tu contraseña", with: "contrasena-segura-123"
    click_button "Iniciar impersonación"

    # Copy EXACTO del UI-SPEC.
    assert_text "Estás operando como #{@cliente.email_address} a petición de #{@staff.email_address}. Todas las acciones quedan registradas."

    # El banner persiste al navegar (todas las páginas).
    click_button "Org Imp" if has_button?("Org Imp")
    visit organizations_path
    assert_text "Todas las acciones quedan registradas."

    # Acción mutativa impersonada → audit_log con actor REAL = empleado (AC-007).
    fill_in "Nombre", with: "Org Creada Por Staff"
    click_button "Crear organización"
    assert_text "Org Creada Por Staff"

    log = AuditLog.find_by(action: "organizations#create")
    assert_not_nil log, "la escritura impersonada debe quedar auditada"
    assert_equal @staff.id, log.actor_real_id
    assert_equal @cliente.id, log.actor_effective_id

    # Salir restaura la identidad del empleado.
    click_button "Salir"
    assert_no_text "Estás operando como"
    assert_text "soporte@captia.test"

    end_log = AuditLog.find_by(action: "impersonation.end")
    assert_not_nil end_log
    assert_equal @staff.id, end_log.actor_real_id
  end

  private

  def login_as(user)
    visit new_session_path
    fill_in "Correo electrónico", with: user.email_address
    fill_in "Contraseña", with: "contrasena-segura-123"
    click_button "Iniciar sesión"
    assert_text "Organizaciones"
  end
end
