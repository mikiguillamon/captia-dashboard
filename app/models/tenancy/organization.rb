module Tenancy
  class Organization < ApplicationRecord
    belongs_to :account

    validates :name, presence: true
  end
end
