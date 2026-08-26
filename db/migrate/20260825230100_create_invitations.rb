# frozen_string_literal: true

class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.string :email, null: false
      t.references :organization, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :role, null: false # SOLO roles cliente
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end
    add_index :invitations, :token_digest, unique: true
    add_index :invitations, %i[organization_id email]
  end
end
