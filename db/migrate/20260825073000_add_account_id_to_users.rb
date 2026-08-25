class AddAccountIdToUsers < ActiveRecord::Migration[8.1]
  # Puente provisional del walking skeleton: vincula el usuario a su cuenta
  # hasta que memberships (01-03) sea la fuente canónica; entonces se elimina.
  def change
    add_reference :users, :account, foreign_key: true, null: true
  end
end
