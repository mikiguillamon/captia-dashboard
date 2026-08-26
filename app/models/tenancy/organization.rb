module Tenancy
  class Organization < ApplicationRecord
    belongs_to :account

    has_many :memberships, dependent: :destroy
    has_many :users, through: :memberships
    # Los role_assignments referencian aquí vía (scope_type, scope_id) plano;
    # sin belongs_to polimórfico para mantener creaciones por columnas (D-01).

    validates :name, presence: true

    # SEG-03/FR-014: el toggle solo se gestiona desde flujos administrativos
    # internos (consola/seeds hoy; controlador admin con RBAC en 01-03).
    # Nunca expuesto como atributo asignable en masa de rutas públicas.
  end
end
