# frozen_string_literal: true

class AddNotifyImpersonationToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :notify_impersonation, :boolean, default: false, null: false
  end
end
