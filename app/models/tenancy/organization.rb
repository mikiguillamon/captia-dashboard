module Tenancy
  class Organization < ApplicationRecord
    belongs_to :account

    has_many :memberships, dependent: :destroy
    has_many :users, through: :memberships
    # Fase 2: catálogo de servicios (SERV-01..02). Una organización mantiene
    # múltiples instancias de servicio; la generación de slug de ServiceInstance
    # consulta esta asociación para garantizar unicidad por organización.
    has_many :service_instances, dependent: :destroy
    # Los role_assignments referencian aquí vía (scope_type, scope_id) plano;
    # sin belongs_to polimórfico para mantener creaciones por columnas (D-01).

    validates :name, presence: true

    # SEG-03/FR-014: el toggle solo se gestiona desde flujos administrativos
    # internos (consola/seeds hoy; controlador admin con RBAC en 01-03).
    # Nunca expuesto como atributo asignable en masa de rutas públicas.
  end
end
