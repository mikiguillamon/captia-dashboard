class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :mfa_enrollment, class_name: "Identity::MfaEnrollment", dependent: :destroy
  has_many :recovery_codes, class_name: "Identity::RecoveryCode", dependent: :delete_all
  has_many :password_reset_tokens, class_name: "Identity::PasswordResetToken", dependent: :delete_all

  # Puente provisional del skeleton (ver migración); memberships lo sustituye en 01-03.
  belongs_to :account, optional: true, class_name: "Tenancy::Account"

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # D-05: política mínima de longitud (≥12). allow_nil permite actualizar el
  # usuario sin cambiar la contraseña.
  validates :password, length: { minimum: 12 }, allow_nil: true
end
