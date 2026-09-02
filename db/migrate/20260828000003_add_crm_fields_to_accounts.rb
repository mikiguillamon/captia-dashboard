# frozen_string_literal: true

class AddCrmFieldsToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :status, :string, null: false, default: "prospect"
    add_column :accounts, :source, :string
    add_column :accounts, :industry, :string
    add_column :accounts, :assigned_to_id, :bigint

    add_index :accounts, :assigned_to_id
    add_index :accounts, :status
  end
end