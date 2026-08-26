# frozen_string_literal: true

class CreateRoleAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :role_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :scope_type, null: false # Tenancy::Account | Tenancy::Organization
      t.integer :scope_id, null: false
      t.string :role, null: false
      # D-09: excepción puntual {"allow": ["cap"], "deny": ["cap"]}.
      t.jsonb :exception

      t.timestamps
    end
    add_index :role_assignments, %i[scope_type scope_id]
    add_index :role_assignments, %i[user_id scope_type scope_id]
  end
end
