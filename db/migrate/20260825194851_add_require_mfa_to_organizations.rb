# frozen_string_literal: true

class AddRequireMfaToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :require_mfa, :boolean, default: false, null: false
  end
end
