# frozen_string_literal: true

class CreateServiceCatalogModels < ActiveRecord::Migration[8.1]
  def change
    create_table :service_types do |t|
      t.string :name, null: false
      t.text :description
      t.jsonb :config_schema, null: false, default: {}
      t.jsonb :default_config, null: false, default: {}
      t.integer :default_retention_days, null: false, default: 365
      t.string :icon
      t.integer :display_order, null: false, default: 0

      t.timestamps
    end

    add_index :service_types, :name, unique: true
    add_index :service_types, :display_order

    create_table :service_instances do |t|
      t.bigint :organization_id, null: false
      t.bigint :service_type_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.string :type, null: false
      t.jsonb :configuration, null: false, default: {}
      t.string :contractual_state, null: false, default: "pending_start"
      t.string :operational_state, null: false, default: "stopped"
      t.string :health_state, null: false, default: "unknown"
      t.date :contractual_start_date
      t.date :contractual_end_date
      t.date :historical_access_until
      t.datetime :last_heartbeat_at
      t.float :error_rate, null: false, default: 0.0
      t.integer :latency_ms, null: false, default: 0

      t.timestamps
    end

    add_index :service_instances, :organization_id
    add_index :service_instances, :service_type_id
    add_index :service_instances, :type
    add_index :service_instances, :contractual_state
    add_index :service_instances, :operational_state
    add_index :service_instances, :health_state
    add_index :service_instances, [:organization_id, :slug], unique: true
    add_index :service_instances, [:organization_id, :service_type_id]
  end
end