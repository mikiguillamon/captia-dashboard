# frozen_string_literal: true

module CRM
  class Lead < ApplicationRecord
    self.table_name = "crm_leads"

    STATUSES = %w[new contacted qualified converted lost].freeze

    belongs_to :account, class_name: "Tenancy::Account", optional: true
    belongs_to :organization, class_name: "Tenancy::Organization", optional: true
    belongs_to :assigned_to, class_name: "User", optional: true

    validates :email, presence: true
    validates :name, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :active, -> { where.not(status: %w[converted lost]) }

    def convert!(account_attributes = {})
      Tenancy::Account.transaction do
        account = account_attributes[:id] ? Tenancy::Account.find(account_attributes[:id]) : account.create!(account_attributes.except(:id))

        contact = account.crm_contacts.create!(
          first_name: name.split.first,
          last_name: name.split.last,
          email: email
        )

        update!(status: "converted", converted_at: Time.current, account: account, organization: account.organizations.first)

        { account: account, contact: contact }
      end
    end
  end
end