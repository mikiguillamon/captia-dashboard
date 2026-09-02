# frozen_string_literal: true

# Aplica las políticas RLS de CRM + catálogo de servicios (Fase 2) desde
# db/policies/crm_service_rls.sql. Mismo mecanismo que EnableTenancyRls:
# dev/prod ejecutan esta migración; la BD de TEST las recibe vía reaplicación
# idempotente en test/test_helper.rb (el dumper de schema.rb no serializa RLS).
class AddRlsToCrmAndServiceModels < ActiveRecord::Migration[8.1]
  def up
    sql = File.read(Rails.root.join("db/policies/crm_service_rls.sql"))
    sql.split(/;\s*$/).map(&:strip).reject(&:empty?).each { |statement| execute(statement) }
  end

  def down
    {
      "service_instances" => "service_instances_tenant_isolation",
      "pipeline_stages"    => "pipeline_stages_tenant_isolation",
      "crm_opportunities"  => "crm_opportunities_tenant_isolation",
      "crm_contacts"       => "crm_contacts_tenant_isolation",
      "crm_leads"          => "crm_leads_tenant_isolation"
    }.each do |table, policy|
      execute("DROP POLICY IF EXISTS #{policy} ON #{table}")
    end

    %w[service_instances pipeline_stages crm_opportunities crm_contacts crm_leads].each do |table|
      execute("ALTER TABLE #{table} NO FORCE ROW LEVEL SECURITY")
      execute("ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY")
    end
  end
end
