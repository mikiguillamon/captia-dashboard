# frozen_string_literal: true

module Tenancy
  class Account < ApplicationRecord
    has_many :organizations, dependent: :destroy
    has_many :crm_leads, class_name: "CRM::Lead", dependent: :destroy
    has_many :crm_contacts, class_name: "CRM::Contact", dependent: :destroy
    has_many :crm_opportunities, class_name: "CRM::Opportunity", dependent: :destroy
    has_many :pipeline_stages, dependent: :destroy

    validates :name, presence: true

    scope :active, -> { where(status: "active") }

    def self.create_from_lead!(lead)
      create!(
        name: lead.company.presence || lead.name,
        status: "active",
        source: lead.source,
        industry: nil,
        assigned_to_id: lead.assigned_to_id
      )
    end
  end
end