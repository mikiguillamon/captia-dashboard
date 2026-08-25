# frozen_string_literal: true

require "test_helper"

module Auth
  module Mfa
    # AC-005 / T1-04 / T1-07: enrollment TOTP con QR, confirmación y
    # recovery codes mostrados una sola vez y guardados solo como digest.
    class EnrollmentFlowTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(email_address: "mfa@captia.test", password: "contrasena-segura-123")
        log_in(@user)
      end

      test "GET muestra QR SVG y el secreto se guarda cifrado" do
        get mfa_enrollment_path
        assert_response :ok

        @secret = @user.mfa_enrollment.reload.secret
        assert_equal 32, @secret.length
        assert_includes response.body, "<svg"

        # El valor en la BD NUNCA coincide con el secreto en claro (T1-07).
        raw = ActiveRecord::Base.connection.select_value(
          "SELECT secret FROM mfa_enrollments WHERE user_id = #{@user.id}"
        )
        refute_equal @secret, raw
        refute_includes raw.to_s, @secret
      end

      test "código incorrecto es rechazado y regenera el secreto" do
        get mfa_enrollment_path
        old_secret = @user.mfa_enrollment.secret

        post mfa_enrollment_path, params: { code: "000000" }
        assert_response :unprocessable_entity

        fresh = @user.reload.mfa_enrollment
        assert_not fresh.confirmed?
        refute_equal old_secret, fresh.secret,
                     "el secreto debe regenerarse tras un fallo (no reutilizar el mostrado)"
      end

      test "código válido confirma, genera 8 recovery codes SOLO como digest y se muestran una vez" do
        get mfa_enrollment_path
        secret = @user.mfa_enrollment.reload.secret
        code = rotp_for(secret).now

        post mfa_enrollment_path, params: { code: code }
        assert_response :ok

        assert_text_present = response.body.include?("no volveremos a mostrarlos")
        assert assert_text_present, "la vista debe advertir que los códigos no se vuelven a mostrar"

        enroll = @user.mfa_enrollment.reload
        assert enroll.confirmed?

        digests = @user.recovery_codes.pluck(:code_digest)
        assert_equal 8, digests.size
        assert digests.all? { |d| d.match?(/\A[0-9a-f]{64}\z/) },
               "los recovery codes deben almacenarse como digest SHA256"
        digests.each do |digest|
          refute_includes response.body, digest
        end
      end

      test "repetir la confirmación no reactiva ni expone códigos otra vez" do
        get mfa_enrollment_path
        secret = @user.mfa_enrollment.reload.secret
        code = rotp_for(secret).now

        post mfa_enrollment_path, params: { code: code }
        assert_response :ok

        # Un código válido del FUTURO (siguiente ventana) tampoco re-confirma:
        # el enrollment ya está activo y la ruta redirige sin exponer nada.
        post mfa_enrollment_path, params: { code: rotp_for(secret).at(Time.now + 30) }
        assert_redirected_to root_path
        assert_includes flash[:notice], "MFA ya activado"
      end

      private

      def rotp_for(secret)
        ROTP::TOTP.new(secret)
      end

      def log_in(user)
        post "/login", params: { email_address: user.email_address, password: "contrasena-segura-123" }
        assert_redirected_to root_url
      end
    end
  end
end
