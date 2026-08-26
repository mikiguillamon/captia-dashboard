# frozen_string_literal: true

# T1-09 / AC-007: registro de auditoría con actor real SIEMPRE presente.
class AuditLog < ApplicationRecord
  belongs_to :actor_real, class_name: "User"
  belongs_to :actor_effective, class_name: "User"
  belongs_to :subject, polymorphic: true, optional: true

  validates :action, presence: true
end
