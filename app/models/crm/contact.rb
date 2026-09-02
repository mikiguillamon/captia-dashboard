# frozen_string_literal: true

module CRM
  class Contact < ApplicationRecord
    self.table_name = "crm_contacts"

    belongs_to :account, class_name: "Tenancy::Account"

    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

    def full_name
      "#{first_name} #{last_name}"
    end
  end
end