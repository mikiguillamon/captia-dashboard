# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :mfa_enrollment, class_name: "Identity::MfaEnrollment", dependent: :destroy
  has_many :recovery_codes, class_name: "Identity::RecoveryCode", dependent: :delete_all
  has_many :password_reset_tokens, class_name: "Identity::PasswordResetToken", dependent: :delete_all
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :role_assignments, class_name: "Tenancy::RoleAssignment", dependent: :destroy

  # Puente provisional del skeleton (ver migración); memberships lo sustituye en 01-03.
  belongs_to :account, optional: true, class_name: "Tenancy::Account"

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # D-05: política mínima de longitud (≥12). allow_nil permite actualizar el
  # usuario sin cambiar la contraseña.
  validates :password, length: { minimum: 12 }, allow_nil: true

  # D-09: evaluación plantilla → herencia account→org → excepciones.
  # Orden DETERMINISTA (review F8): primero asignaciones a nivel cuenta, luego
  # las de la organización concreta; así una excepción de org más específica
  # decide siempre al final, independientemente del orden de filas de PG.
  def can?(capability, scope:)
    return false if capability.blank?

    assignments = role_assignments.for_scope_chain(scope).to_a.sort_by do |a|
      [ a.scope_type == "Tenancy::Organization" ? 1 : 0, a.id ]
    end

    decision = assignments.any? { |a| a.template_capabilities.include?(capability.to_s) }

    assignments.each do |a|
      exc = a.exception.presence || {}
      decision = false if Array(exc["deny"]).include?(capability.to_s)
      decision = true if Array(exc["allow"]).include?(capability.to_s)
    end
    decision
  end
end
