# frozen_string_literal: true

module Identity
  # Códigos de recuperación MFA de un solo uso. Se guardan SOLO como digest
  # SHA256 — el código en claro se muestra una única vez al confirmar.
  class RecoveryCode < ApplicationRecord
    belongs_to :user

    validates :code_digest, presence: true

    # Claim ATÓMICO (review F9): update_all condicional evita doble consumo
    # bajo concurrencia; devuelve true solo si ESTE request lo reclamó.
    def self.consume!(user:, code:)
      digest = Digest::SHA256.hexdigest(code.to_s.strip)
      updated = user.recovery_codes
                    .where(code_digest: digest, used_at: nil)
                    .update_all(used_at: Time.current)
      updated == 1
    end
  end
end
