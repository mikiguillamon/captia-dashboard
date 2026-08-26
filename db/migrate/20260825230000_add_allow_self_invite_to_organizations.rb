# frozen_string_literal: true

class AddAllowSelfInviteToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :allow_self_invite, :boolean, default: false, null: false
  end
end
