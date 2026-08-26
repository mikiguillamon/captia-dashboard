# frozen_string_literal: true

class AddImpersonationFieldsToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :impersonated, :boolean, default: false, null: false
    add_column :sessions, :expires_at, :datetime
    add_index :sessions, :expires_at
  end
end
