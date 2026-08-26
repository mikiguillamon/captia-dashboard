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
        assignment: assignment, actor_real: @actor, deny: [:manage_organizations]
      )

      assert_not @user.can?(:manage_organizations, scope: @org_a),
                 "el deny puntual debe ganar al allow heredado"
      assert @user.can?(:invite_users, scope: @org_a), "resto de capacidades intactas"
    end

    test "una excepción allow puntual concede sin plantilla previa" do
      assignment = Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Organization",
                                                   scope_id: @org_a.id, role: "operativo")
      Tenancy::RoleAssignment.set_exception!(
        assignment: assignment, actor_real: @actor, allow: [:view_audit]
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
          assignment: assignment, actor_real: @actor, deny: [:invite_users]
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
          assignment: assignment, actor_real: @actor, allow: ["capacidad_inexistente"]
        )
      end
      assert_match(/desconocidas/, error.message)
    end
  end
end
