# frozen_string_literal: true

class CreateMfaEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_table :mfa_enrollments do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :secret, null: false
      t.integer :last_used_timestep, null: false, default: 0
      t.datetime :confirmed_at

      t.timestamps
    end
  end
end
