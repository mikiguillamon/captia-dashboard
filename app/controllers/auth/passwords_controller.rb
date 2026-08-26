# frozen_string_literal: true

module Auth
  # D-05 / T1-06: recuperación por token efímero de un solo uso con
  # respuestas SIEMPRE uniformes (anti-enumeración) y rate limit.
  class PasswordsController < ApplicationController
    allow_unauthenticated_access only: %i[new_forgot create_forgot new_reset update_reset]
    rate_limit to: 10, within: 1.minute, only: :create_forgot, with: -> {
      redirect_to forgot_password_path, notice: Auth::PasswordsController::UNIFORM_NOTICE, status: :see_other
    }

    UNIFORM_NOTICE = "Si el email existe, recibirás instrucciones para restablecer la contraseña."
    GENERIC_INVALID = "El enlace no es válido o ha expirado. Solicita uno nuevo."

    # GET /password/forgot
    def new_forgot
    end

    # POST /password/forgot
    def create_forgot
      user = User.find_by(email_address: params[:email_address])
      raw_token = Identity::PasswordResetToken.issue!(user) if user
      AuthMailer.reset_instructions(user, raw_token).deliver_later if user

      redirect_to new_session_path, notice: UNIFORM_NOTICE, status: :see_other
    end

    # GET /password/reset?token=
    def new_reset
      @token = params[:token].to_s
      unless token_valid?(@token)
        redirect_to forgot_password_path, alert: GENERIC_INVALID, status: :see_other
      end
    end

    # PATCH/PUT /password/reset
    def update_reset
      record = Identity::PasswordResetToken.find_valid(params[:token])
      return invalid_link_redirect unless record

      user = record.user
      if user.update(params.permit(:password, :password_confirmation))
        # D-05: consumo definitivo SOLO tras éxito; invalida tokens previos y
        # REVOCAS todas las sesiones activas.
        record.update!(used_at: Time.current)
        user.password_reset_tokens.unused.update_all(used_at: Time.current)
        user.sessions.destroy_all
        redirect_to new_session_path,
                    notice: "Contraseña restablecida. Inicia sesión con tu nueva contraseña.",
                    status: :see_other
      else
        flash.now[:alert] = user.errors.full_messages_for(:password).to_sentence
        @token = params[:token].to_s
        render :new_reset, status: :unprocessable_entity
      end
    end

    private

    def token_valid?(raw)
      Identity::PasswordResetToken.valid.exists?(token_digest: Identity::PasswordResetToken.digest(raw))
    end

    def invalid_link_redirect
      redirect_to forgot_password_path, alert: GENERIC_INVALID, status: :see_other
    end
  end
end
