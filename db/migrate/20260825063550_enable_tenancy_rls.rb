# Aplica las políticas RLS de tenancy (D-07 / ADR-0002) desde db/policies/.
# Nota: el dumper de schema NO serializa políticas RLS; por eso la app usa
# config.active_record.schema_format = :sql (db/structure.sql) y los tests
# reciben las políticas al preparar la base test.
class EnableTenancyRls < ActiveRecord::Migration[8.1]
  POLICY_FILES = %w[accounts_rls organizations_rls].freeze

  def up
    POLICY_FILES.each do |file|
      sql = File.read(Rails.root.join("db/policies/#{file}.sql"))
      sql.split(/;\s*$/).map(&:strip).reject(&:empty?).each { |statement| execute(statement) }
    end
  end

  def down
    execute("DROP POLICY IF EXISTS organizations_tenant_isolation ON organizations")
    execute("ALTER TABLE organizations NO FORCE ROW LEVEL SECURITY")
    execute("ALTER TABLE organizations DISABLE ROW LEVEL SECURITY")

    %w[accounts_tenant_read accounts_tenant_update accounts_provision_insert].each do |policy|
      execute("DROP POLICY IF EXISTS #{policy} ON accounts")
    end
    execute("ALTER TABLE accounts NO FORCE ROW LEVEL SECURITY")
    execute("ALTER TABLE accounts DISABLE ROW LEVEL SECURITY")
  end
end
