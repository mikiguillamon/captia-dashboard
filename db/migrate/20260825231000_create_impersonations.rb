# frozen_string_literal: true

class CreateImpersonations < ActiveRecord::Migration[8.1]
  def change
    create_table :impersonations do |t|
      t.references :initiator, null: false, foreign_key: { to_table: :users }
      t.references :target_user, null: false, foreign_key: { to_table: :users }
      t.datetime :started_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :ended_at

      t.timestamps
    end
    add_index :impersonations, %i[target_user_id ended_at]
  end
end
