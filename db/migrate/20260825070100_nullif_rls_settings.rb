# Reaplica las políticas con NULLIF(current_setting(...), '')::bigint:
# tras un SET LOCAL revertido, current_setting devuelve '' y el cast directo
# lanzaba error en lugar de negar la fila.
class NullifRlsSettings < ActiveRecord::Migration[8.1]
  POLICY_FILES = %w[accounts_rls organizations_rls].freeze

  def up
    POLICY_FILES.each do |file|
      sql = File.read(Rails.root.join("db/policies/#{file}.sql"))
      sql.split(/;\s*$/).map(&:strip).reject(&:empty?).each { |statement| execute(statement) }
    end
  end

  def down
    # Vuelve a la versión sin NULLIF (no recomendada; solo reversibilidad).
    execute("DROP POLICY IF EXISTS accounts_provision_read ON accounts")
  end
end
