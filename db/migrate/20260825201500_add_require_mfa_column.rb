# frozen_string_literal: true

# Correctiva: 20260825194851 se registró vacía antes de incluir la columna.
class AddRequireMfaColumn < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:organizations, :require_mfa)
      add_column :organizations, :require_mfa, :boolean, default: false, null: false
    end
  end
end
