# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      # D-06/T1-09: SIEMPRE ambos actores. actor_real = empleado autenticado
      # (NOT NULL); actor_effective = identidad bajo la que se ejecutó.
      t.references :actor_real, null: false, foreign_key: { to_table: :users }
      t.references :actor_effective, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.references :subject, polymorphic: true, null: true
      t.inet :ip

      t.timestamps
    end
    add_index :audit_logs, :action
  end
end
