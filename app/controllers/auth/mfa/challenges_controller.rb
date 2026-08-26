# frozen_string_literal: true

module Auth
  module Mfa
    # Segundo paso AC-005: tras password correcto, usuarios con MFA confirmado
    # NO obtienen Session hasta superar el challenge TOTP/recovery.
    class ChallengesController < ApplicationController
      include Authentication
      allow_unauthenticated_access only: %i[new create destroy]

      # Mismo límite que el login (10/min por IP) y misma respuesta uniforme.
      rate_limit to: 10, within: 1.minute, only: :create, with: -> {
        redirect_to new_mfa_challenge_path, alert: GENERIC_ERROR, status: :see_other
      }

      GENERIC_ERROR = Auth::SessionsController::GENERIC_ERROR

      before_action :require_pending_user, except: :destroy

      def new
      end

      def create
        if consume_code!(params[:code])
          user = pending_user
          clear_pending!
          # Regeneramos identidad de sesión: nada del estado pre-MFA sobrevive.
          start_new_session_for user
          redirect_to after_authentication_url
        else
          redirect_to new_mfa_challenge_path, alert: GENERIC_ERROR, status: :see_other
        end
      end

      def destroy
        clear_pending!
        redirect_to new_session_path, status: :see_other
      end

      private

      def pending_user
        @pending_user ||=
          if session[:mfa_pending_user_id]
            User.find_by(id: session[:mfa_pending_user_id])
          end
      end

      def require_pending_user
        return if pending_user

        redirect_to new_session_path, status: :see_other
      end

      def consume_code!(code)
        return false if code.blank?
        return false unless pending_user.mfa_enrollment&.confirmed?

        pending_user.mfa_enrollment.verify_and_consume!(code.to_s.strip) ||
          Identity::RecoveryCode.consume!(user: pending_user, code: code)
      end

      def clear_pending!
        session.delete(:mfa_pending_user_id)
      end
    end
  end
end
