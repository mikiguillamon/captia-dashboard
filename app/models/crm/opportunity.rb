# frozen_string_literal: true

module CRM
  class Opportunity < ApplicationRecord
    self.table_name = "crm_opportunities"

    belongs_to :account, class_name: "Tenancy::Account"
    belongs_to :stage, class_name: "PipelineStage", optional: true
    belongs_to :owner, class_name: "User", optional: true

    # Nota: notas/actividades/tareas del ciclo comercial pertenecen a Fase 6
    # (feedback, tareas e incidencias). No se declaran aquí para evitar
    # referencias a modelos/tablas aún inexistentes.

    validates :name, presence: true
    validates :value_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :probability, numericality: { in: 0..100 }

    scope :won, -> { joins(:stage).where(pipeline_stages: { probability: 100 }) }
    scope :open, -> { where.not(stage_id: PipelineStage.where(probability: [0, 100]).select(:id)) }
  end
end