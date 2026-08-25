class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Puente provisional del skeleton (ver migración); memberships lo sustituye en 01-03.
  belongs_to :account, optional: true, class_name: "Tenancy::Account"

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # D-05: política mínima de longitud (≥12). allow_nil permite actualizar el
  # usuario sin cambiar la contraseña.
  validates :password, length: { minimum: 12 }, allow_nil: true
end
