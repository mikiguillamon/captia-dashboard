# frozen_string_literal: true

require "test_helper"

module Tenancy
  # D-09: motor de permisos con plantillas PRD §3, herencia account→org y
  # excepciones puntuales SIEMPRE auditadas.
  class RoleAssignmentTest < ActiveSupport::TestCase
    setup do
      @actor = User.create!(email_address: "actor@captia.test", password: "contrasena-segura-123")
      @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Perm Co") }
      @org_a = Tenancy::Context.with(account_id: @account.id) {
        Tenancy::Organization.create!(name: "Org A", account: @account)
      }
      @user = User.create!(email_address: "perm@captia.test",
                           password: "contrasena-segura-123", account: @account)
    end

    test "las 8 plantillas de rol existen con nombres exactos del PRD §3" do
      expected = %w[superadmin direccion comercial account_manager tecnico
                    admin_cuenta admin_org operativo]
      assert_equal expected.sort, Tenancy::RoleAssignment::ROLE_TEMPLATES.keys.sort
    end

    test "membership es única por par usuario-organización" do
      Tenancy::Context.with(account_id: @account.id, organization_id: @org_a.id) do
        Tenancy::Membership.create!(user: @user, organization: @org_a)
        error = assert_raises(ActiveRecord::RecordInvalid) do
          Tenancy::Membership.create!(user: @user, organization: @org_a)
        end
        assert_match(/taken/, error.message)
      end
    end

    test "can? respeta herencia account→organización" do
      Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Account",
                                      scope_id: @account.id, role: "admin_cuenta")

      # Sin rol en la organización concreta, hereda capacidades de la cuenta.
      assert @user.can?(:manage_organizations, scope: @org_a)
      assert_not @user.can?(:impersonate, scope: @org_a)
    end

    test "una excepción deny puntual gana al allow heredado" do
      assignment = Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Account",
                                                   scope_id: @account.id, role: "admin_cuenta")
      Tenancy::RoleAssignment.set_exception!(
        assignment: assignment, actor_real: @actor, deny: [ :manage_organizations ]
      )

      assert_not @user.can?(:manage_organizations, scope: @org_a),
                 "el deny puntual debe ganar al allow heredado"
      assert @user.can?(:invite_users, scope: @org_a), "resto de capacidades intactas"
    end

    test "una excepción allow puntual concede sin plantilla previa" do
      assignment = Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Organization",
                                                   scope_id: @org_a.id, role: "operativo")
      Tenancy::RoleAssignment.set_exception!(
        assignment: assignment, actor_real: @actor, allow: [ :view_audit ]
      )

      assert @user.can?(:view_audit, scope: @org_a)
      assert_not @user.can?(:view_audit, scope: @account),
                 "la excepción es puntual al scope concreto"
    end

    test "toda modificación de excepciones escribe audit_log con actor real" do
      assignment = Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Account",
                                                   scope_id: @account.id, role: "admin_cuenta")

      assert_difference "AuditLog.count", 1 do
        Tenancy::RoleAssignment.set_exception!(
          assignment: assignment, actor_real: @actor, deny: [ :invite_users ]
        )
      end
      log = AuditLog.last
      assert_equal @actor.id, log.actor_real_id
      assert_equal "role_assignment.exception.update", log.action
      assert_equal assignment, log.subject
    end

    test "excepción con capacidad desconocida es inválida" do
      assignment = Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Account",
                                                   scope_id: @account.id, role: "tecnico")
      error = assert_raises(ActiveRecord::RecordInvalid) do
        Tenancy::RoleAssignment.set_exception!(
          assignment: assignment, actor_real: @actor, allow: [ "capacidad_inexistente" ]
        )
      end
      assert_match(/desconocidas/, error.message)
    end

    # --- Fase 2 (Plan 02): capacidades CRM + Servicios -------------------------

    test "Fase 2: comercial tiene capacidades CRM comerciales y desencadena wizard" do
      Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Account",
                                      scope_id: @account.id, role: "comercial")
      assert @user.can?(:manage_leads, scope: @account)
      assert @user.can?(:manage_contacts, scope: @account)
      assert @user.can?(:manage_opportunities, scope: @account)
      assert @user.can?(:manage_pipeline_stages, scope: @account)
      assert @user.can?(:convert_opportunity, scope: @account)
      # Comercial NO gestiona catálogo de servicios (AC-003).
      assert_not @user.can?(:manage_service_instances, scope: @account)
      assert_not @user.can?(:manage_service_types, scope: @account)
    end

    test "Fase 2: tecnico gestiona instancias y configuración operativa" do
      Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Account",
                                      scope_id: @account.id, role: "tecnico")
      assert @user.can?(:manage_service_instances, scope: @account)
      assert @user.can?(:manage_service_config, scope: @account)
      assert_not @user.can?(:manage_leads, scope: @account)
    end

    test "Fase 2: solo superadmin gestiona tipos de servicio" do
      sa = Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Account",
                                           scope_id: @account.id, role: "superadmin")
      assert @user.can?(:manage_service_types, scope: @account)

      sa.update!(role: "account_manager")
      assert_not @user.can?(:manage_service_types, scope: @account)
    end

    test "Fase 2: cliente admin_cuenta gestiona instancias de su organización" do
      Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Account",
                                      scope_id: @account.id, role: "admin_cuenta")
      assert @user.can?(:manage_service_instances, scope: @org_a)
      # Sin capacidades CRM (cliente ajeno al ciclo comercial interno).
      assert_not @user.can?(:manage_leads, scope: @account)
      assert_not @user.can?(:convert_opportunity, scope: @account)
    end
  end
end
