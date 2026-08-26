# frozen_string_literal: true

class Impersonation < ApplicationRecord
  belongs_to :initiator, class_name: "User"
  belongs_to :target_user, class_name: "User"

  # D-06: expiración corta ≈30 min.
  LIFETIME = 30.minutes

  scope :active, -> { where(ended_at: nil).where(expires_at: Time.current..) }

  validates :expires_at, presence: true

  def expired?
    expires_at.past?
  end

  def active?
    ended_at.nil? && !expired?
  end
end
