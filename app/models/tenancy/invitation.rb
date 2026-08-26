# frozen_string_literal: true

module Tenancy
  # TEN-11/FR-011: invitación a una organización con token un-uso de 7 días.
  # En BD solo el digest; el valor claro va únicamente en el enlace del email.
  class Invitation < ApplicationRecord
    LIFETIME = 7.days
    CLIENT_ROLES = %w[admin_cuenta admin_org operativo].freeze

    belongs_to :organization
    belongs_to :invited_by, class_name: "User"

    normalizes :email, with: ->(e) { e.strip.downcase }

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :role, inclusion: { in: CLIENT_ROLES }

    scope :valid, -> { where(used_at: nil).where(expires_at: Time.current..) }

    class << self
      def issue!(organization:, invited_by:, email:, role:)
        raw = SecureRandom.urlsafe_base64(32)
        create!(
          organization: organization, invited_by: invited_by,
          email: email, role: role,
          token_digest: digest(raw), expires_at: LIFETIME.from_now
        )
        raw
      end

      def consume!(raw)
        record = valid.find_by(token_digest: digest(raw))
        return nil unless record

        record.update!(used_at: Time.current)
        record
      end

      def digest(raw)
        Digest::SHA256.hexdigest(raw.to_s)
      end
    end

    def client_role?
      CLIENT_ROLES.include?(role)
    end
  end
end
