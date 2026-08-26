module Tenancy
  class Organization < ApplicationRecord
    belongs_to :account

    validates :name, presence: true

    # SEG-03/FR-014: el toggle solo se gestiona desde flujos administrativos
    # internos (consola/seeds hoy; controlador admin con RBAC en 01-03).
    # Nunca expuesto como atributo asignable en masa de rutas públicas.
  end
end
