# frozen_string_literal: true

module Identity
  # Enrollment TOTP por usuario (D-03, AC-005). El secret NUNCA se almacena
  # en claro: ActiveRecord encrypted attribute (encrypts).
  class MfaEnrollment < ApplicationRecord
    belongs_to :user

    encrypts :secret, deterministic: false

    validates :secret, presence: true
    validates :user_id, uniqueness: true

    # Un código ya consumido en su ventana se rechaza (anti-replay T1-04):
    # solo se aceptan timesteps estrictamente mayores al último usado.
    def verify_and_consume!(code, drift: 1)
      timestep = current_timestep(code, drift: drift)
      return false if timestep.nil? || timestep <= last_used_timestep.to_i

      update!(last_used_timestep: timestep)
      true
    end

    def confirm_with!(code)
      timestep = current_timestep(code, drift: 1)
      return false if timestep.nil?

      update!(confirmed_at: Time.current, last_used_timestep: timestep)
      true
    end

    def confirmed?
      confirmed_at.present?
    end

    def provisioning_uri
      ROTP::TOTP.new(secret, issuer: "Captia").provisioning_uri(user.email_address)
    end

    private

    # rotp 6.x: verify() usa comparación constante-time (T1-05) y devuelve el
    # timestep del match (Integer) o nil si el código no es válido.
    def current_timestep(code, drift:)
      totp = ROTP::TOTP.new(secret)
      totp.verify(code.to_s, drift_ahead: drift, drift_behind: drift)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
