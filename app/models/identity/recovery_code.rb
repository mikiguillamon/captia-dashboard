# frozen_string_literal: true

module Identity
  # Códigos de recuperación MFA de un solo uso. Se guardan SOLO como digest
  # SHA256 — el código en claro se muestra una única vez al confirmar.
  class RecoveryCode < ApplicationRecord
    belongs_to :user

    validates :code_digest, presence: true

    def self.consume!(user:, code:)
      digest = Digest::SHA256.hexdigest(code.to_s.strip)
      record = user.recovery_codes.find_by(code_digest: digest, used_at: nil)
      return false unless record

      record.update!(used_at: Time.current)
      true
    end
  end
end
