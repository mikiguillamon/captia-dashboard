# frozen_string_literal: true

module Auth
  module Mfa
    # Enrollment TOTP (AC-005): generar secreto, mostrar QR, confirmar con
    # código válido y entregar recovery codes UNA sola vez (solo digests).
    class EnrollmentsController < ApplicationController
      RECOVERY_CODES_COUNT = 8

      def new
        return redirect_to root_path, notice: "MFA ya activado." if Current.user.mfa_enrollment&.confirmed?

        @enrollment = fresh_enrollment
        @qr_svg = qr_svg(@enrollment.provisioning_uri)
      end

      def create
        @enrollment = Current.user.mfa_enrollment
        return redirect_to root_path, notice: "MFA ya activado." if @enrollment&.confirmed?

        if @enrollment&.confirm_with!(params[:code])
          @recovery_codes = generate_recovery_codes!
          render :recovery, status: :ok
        else
          # Reemplazamos el secreto para no dejar expuesto uno ya mostrado.
          @enrollment&.destroy
          @enrollment = fresh_enrollment
          flash.now[:alert] = "Código incorrecto. Vuelve a escanear el nuevo código e inténtalo de nuevo."
          @qr_svg = qr_svg(@enrollment.provisioning_uri)
          render :new, status: :unprocessable_entity
        end
      end

      private

      def fresh_enrollment
        Current.user.mfa_enrollment&.destroy if Current.user.mfa_enrollment&.confirmed? == false
        Current.user.build_mfa_enrollment(
          secret: ROTP::Base32.random_base32(32)
        ).tap(&:save!)
      end

      def generate_recovery_codes!
        codes = Array.new(RECOVERY_CODES_COUNT) { SecureRandom.base58(10) }
        Current.user.recovery_codes.delete_all
        codes.each { |c| Current.user.recovery_codes.create!(code_digest: Digest::SHA256.hexdigest(c)) }
        codes
      end

      def qr_svg(uri)
        RQRCode::QRCode.new(uri).as_svg(
          fill: "white",
          color: "0f172a",
          shape_rendering: "crispEdges",
          module_size: 4,
          standalone: true
        ).html_safe
      end
    end
  end
end
