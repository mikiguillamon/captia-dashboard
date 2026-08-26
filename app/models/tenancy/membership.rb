# frozen_string_literal: true

module Tenancy
  # Pertenencia usuario↔organización (AC-001). Par único.
  class Membership < ApplicationRecord
    belongs_to :user
    belongs_to :organization

    validates :user_id, uniqueness: { scope: :organization_id }
    validates :organization_id, presence: true
  end
end
