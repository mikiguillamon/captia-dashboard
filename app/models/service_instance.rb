# frozen_string_literal: true

class ServiceInstance < ApplicationRecord
  self.inheritance_column = :type

  belongs_to :organization, class_name: "Tenancy::Organization"
  belongs_to :service_type

  # El identificador estable y único por organización es el slug (índice único
  # [:organization_id, :slug] en la migración). El nombre es una etiqueta de
  # presentación que puede repetirse entre instancias (AC-002 permite varias
  # instancias del mismo tipo; el slug las diferencia). Por eso el nombre solo
  # valida presencia, no unicidad.
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :organization_id }
  validates :configuration, presence: true
  validates :configuration,
            json_schema: { schema: ->(record) { record.class.const_get(:CONFIG_SCHEMA) } },
            if: -> { self.class.const_defined?(:CONFIG_SCHEMA) }

  enum :contractual_state, {
    pending_start: "pending_start",
    active: "active",
    scheduled_end: "scheduled_end",
    ended: "ended",
    cancelled: "cancelled"
  }

  enum :operational_state, {
    stopped: "stopped",
    running: "running",
    degraded: "degraded",
    maintenance: "maintenance",
    error: "error"
  }

  enum :health_state, {
    unknown: "unknown",
    healthy: "healthy",
    warning: "warning",
    critical: "critical"
  }

  scope :with_historical_access, ->(date = Date.current) {
    where(contractual_state: :active)
      .or(where("contractual_state = ? AND (historical_access_until IS NULL OR historical_access_until >= ?)", "ended", date))
  }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  def display_state
    {
      contractual: contractual_state.humanize,
      operational: operational_state.humanize,
      health: health_state.humanize
    }
  end

  def active_with_historical_access?
    active? || (ended? && historical_access_until.present? && historical_access_until >= Date.current)
  end

  private

  def generate_slug
    base = name.parameterize
    candidate = base
    counter = 1

    while organization.service_instances.where(slug: candidate).where.not(id: id).exists?
      counter += 1
      candidate = "#{base}-#{counter}"
    end

    self.slug = candidate
  end
end
