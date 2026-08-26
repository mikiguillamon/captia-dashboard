class Session < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(expires_at: [ nil, Time.current.. ]) }

  # D-06: la sesión impersonada vive ≈30 min.
  def expired?
    expires_at.present? && expires_at.past?
  end
end
