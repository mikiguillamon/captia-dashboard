# frozen_string_literal: true

module Auth
  # Login password-only del walking skeleton. En 01-02 el flujo pasa a dos
  # pasos (challenge TOTP) sin cambiar estas rutas ni este contrato de errores.
  class SessionsController < ApplicationController
    include Authentication
    allow_unauthenticated_access only: %i[new create]
    # T1-02 credential stuffing: 10 intentos/minuto por IP, respuesta uniforme
    # (no revela si existe el email).
    rate_limit to: 10, within: 1.minute, only: :create, with: -> {
      redirect_to new_session_path, alert: Auth::SessionsController::GENERIC_ERROR, status: :see_other
    }

    GENERIC_ERROR = "Credenciales o código incorrectos. Compruébalos e inténtalo de nuevo."

    def new
    end

    def create
      if (user = User.authenticate_by(params.permit(:email_address, :password)))
        if user.mfa_enrollment&.confirmed?
          # AC-005: sin Session definitiva hasta superar el challenge TOTP.
          session[:mfa_pending_user_id] = user.id
          redirect_to new_mfa_challenge_path
        elsif organization_requires_mfa?(user)
          # AC-006: bloqueado SIN sesión; pantalla explicativa con copy UI-SPEC.
          render "auth/mfa/required", status: :forbidden
        else
          start_new_session_for user
          redirect_to after_authentication_url
        end
      else
        redirect_to new_session_path, alert: GENERIC_ERROR, status: :see_other
      end
    end

    def destroy
      terminate_session
      redirect_to new_session_path, status: :see_other
    end
  end
end
