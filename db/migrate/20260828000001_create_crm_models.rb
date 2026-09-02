# frozen_string_literal: true

class CreateCrmModels < ActiveRecord::Migration[8.1]
  def change
    create_table :crm_leads do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :company
      t.string :source
      t.string :status, null: false, default: "new"
      t.bigint :assigned_to_id
      t.datetime :converted_at
      t.bigint :account_id
      t.bigint :organization_id

      t.timestamps
    end

    add_index :crm_leads, :account_id
    add_index :crm_leads, :email
    add_index :crm_leads, :organization_id
    add_index :crm_leads, :assigned_to_id
    add_index :crm_leads, :status

    create_table :crm_contacts do |t|
      t.bigint :account_id, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.string :role

      t.timestamps
    end

    add_index :crm_contacts, :account_id
    add_index :crm_contacts, :email

    create_table :crm_opportunities do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.integer :value_cents, null: false, default: 0
      t.integer :probability, null: false, default: 0
      t.bigint :stage_id
      t.bigint :user_id
      t.date :expected_close_date
      t.string :source
      t.text :notes

      t.timestamps
    end

    add_index :crm_opportunities, :account_id
    add_index :crm_opportunities, :stage_id
    add_index :crm_opportunities, :user_id

    create_table :pipeline_stages do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.integer :probability, null: false, default: 0
      t.string :color, null: false, default: "#64748b"

      t.timestamps
    end

    add_index :pipeline_stages, :account_id
    add_index :pipeline_stages, [:account_id, :position], unique: true
  end
end