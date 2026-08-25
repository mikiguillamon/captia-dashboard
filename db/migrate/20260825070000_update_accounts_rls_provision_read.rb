# Reaplica las políticas de accounts tras añadir accounts_provision_read
# (necesaria porque INSERT ... RETURNING exige visibilidad SELECT de la fila
# insertada; ver 01-01-SUMMARY, decisión de provisión).
class UpdateAccountsRlsProvisionRead < ActiveRecord::Migration[8.1]
  def up
    sql = File.read(Rails.root.join("db/policies/accounts_rls.sql"))
    sql.split(/;\s*$/).map(&:strip).reject(&:empty?).each { |statement| execute(statement) }
  end

  def down
    execute("DROP POLICY IF EXISTS accounts_provision_read ON accounts")
  end
end
