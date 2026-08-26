# frozen_string_literal: true

module Identity
  # D-05: recuperación de contraseña con token aleatorio de un solo uso,
  # expiración ≈30 min. En BD solo vive el digest SHA256 del token; el valor
  # en claro viaja exclusivamente en el enlace del email.
  class PasswordResetToken < ApplicationRecord
    LIFETIME = 30.minutes

    belongs_to :user

    validates :token_digest, presence: true
    validates :expires_at, presence: true

    scope :unused, -> { where(used_at: nil) }
    # Aún no consumido Y no expirado (expires_at >= ahora).
    scope :valid, -> { unused.where(expires_at: Time.current..) }

    class << self
      def issue!(user)
        # Un solo enlace activo por usuario: los anteriores quedan invalidados.
        user.password_reset_tokens.unused.update_all(used_at: Time.current)

        raw = SecureRandom.urlsafe_base64(32)
        create!(user: user, token_digest: digest(raw), expires_at: LIFETIME.from_now)
        raw
      end

      def consume!(raw)
        record = find_valid_record(raw)
        return nil unless record

        record.update!(used_at: Time.current)
        record.user
      end

      # Devuelve el registro válido SIN consumirlo (permite validar la nueva
      # contraseña antes de marcar el uso definitivo).
      def find_valid(raw)
        find_valid_record(raw)
      end

      def digest(raw)
        Digest::SHA256.hexdigest(raw.to_s)
      end

      private

      def find_valid_record(raw)
        return nil if raw.blank?

        valid.find_by(token_digest: digest(raw))
      end
    end
  end
end
