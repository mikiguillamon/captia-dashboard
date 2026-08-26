# frozen_string_literal: true

module Tenancy
  # Motor de permisos D-09 (roles plantilla PRD §3 + herencia account→org +
  # excepciones puntuales auditadas). Catálogo INICIAL mínimo de esta fase;
  # el catálogo atómico definitivo es la decisión abierta OD-008 (escalar al
  # usuario antes de Fase 3 según AUTONOMY_POLICY).
  class RoleAssignment < ApplicationRecord
    ROLE_TEMPLATES = {
      # Internos (PRD §3.1)
      "superadmin"       => %w[manage_organizations view_dashboard invite_users impersonate view_audit],
      "direccion"        => %w[view_dashboard view_audit],
      "comercial"        => %w[view_dashboard], # sin contenido operativo sensible (AC-003)
      "account_manager"  => %w[view_dashboard],
      "tecnico"          => %w[view_dashboard],
      # Cliente (PRD §3.2)
      "admin_cuenta"     => %w[manage_organizations view_dashboard invite_users],
      "admin_org"        => %w[view_dashboard invite_users],
      "operativo"        => %w[view_dashboard]
    }.freeze

    belongs_to :user

    validates :role, inclusion: { in: ROLE_TEMPLATES.keys }
    validates :scope_type, inclusion: { in: %w[Tenancy::Account Tenancy::Organization] }
    validate  :exception_shape, if: -> { exception.present? }

    scope :for_scope_chain, ->(scope) {
      case scope
      when Tenancy::Organization
        where("(scope_type = ? AND scope_id = ?) OR (scope_type = ? AND scope_id = ?)",
              "Tenancy::Account", scope.account_id,
              "Tenancy::Organization", scope.id)
      when Tenancy::Account
        where(scope_type: "Tenancy::Account", scope_id: scope.id)
      else
        none
      end
    }

    class << self
      # ÚNICO punto de alta/modificación de excepciones — SIEMPRE audita (D-09).
      def set_exception!(assignment:, actor_real:, allow: [], deny: [])
        assignment.with_lock do
          assignment.exception = {
            "allow" => Array(allow).map(&:to_s),
            "deny" => Array(deny).map(&:to_s)
          }
          assignment.save!
          AuditLog.create!(
            actor_real: actor_real,
            actor_effective: actor_real,
            action: "role_assignment.exception.update",
            subject: assignment
          )
        end
        assignment.reload
      end
    end

    def template_capabilities
      ROLE_TEMPLATES.fetch(role, [])
    end

    private

    def exception_shape
      caps = ROLE_TEMPLATES.values.flatten.uniq
      %w[allow deny].each do |key|
        list = exception[key]
        next if list.nil? || (list.is_a?(Array) && list.all? { |c| caps.include?(c) })

        errors.add(:exception, "contiene capacidades desconocidas en #{key}")
      end
    end
  end
end
