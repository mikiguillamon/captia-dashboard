# frozen_string_literal: true

require "test_helper"

module Auth
  module Mfa
    # AC-005 end-to-end: password correcto NO basta con enrollment confirmado;
    # anti-replay TOTP (T1-04); recovery un-solo-uso; rate limit como login.
    class ChallengeFlowTest < ActionDispatch::IntegrationTest
      setup do
        Rails.cache.clear
        @user = User.create!(email_address: "challenge@captia.test", password: "contrasena-segura-123")
        enroll_and_confirm!(@user)
      end

      test "password correcto NO crea Session definitiva: redirige a challenge" do
        post "/login", params: login_params
        assert_redirected_to new_mfa_challenge_path
        assert_equal 0, Session.count, "ninguna ruta debe saltarse el challenge (AC-005)"
      end

      test "código TOTP correcto crea Session real; el MISMO código se rechaza (anti-replay)" do
        post "/login", params: login_params
        code = totp.now

        post mfa_challenge_path, params: { code: code }
        assert_redirected_to root_url
        assert_equal 1, Session.count

        # Anti-replay: cerramos y repetimos login+challenge con el MISMO código.
        delete "/logout"
        post "/login", params: login_params
        post mfa_challenge_path, params: { code: code }
        assert_redirected_to new_mfa_challenge_path
        follow_redirect!
        assert_includes response.body, ChallengesController::GENERIC_ERROR
        assert_equal 0, Session.count,
                     "el código reutilizado no debe abrir ninguna nueva sesión"
      end

      test "recovery code funciona UNA sola vez" do
        codes = recovery_codes_for(@user)
        post "/login", params: login_params

        post mfa_challenge_path, params: { code: codes.first }
        assert_redirected_to root_url

        delete "/logout"
        post "/login", params: login_params
        post mfa_challenge_path, params: { code: codes.first }
        assert_redirected_to new_mfa_challenge_path,
                             "un recovery code usado no puede volver a usarse"
      end

      test "código incorrecto muestra error genérico sin revelar estado" do
        post "/login", params: login_params

        post mfa_challenge_path, params: { code: "000000" }
        assert_redirected_to new_mfa_challenge_path
        follow_redirect!
        assert_includes response.body, ChallengesController::GENERIC_ERROR
        assert_equal 0, Session.count
      end

      test "sin pending user el challenge redirige al login" do
        get new_mfa_challenge_path
        assert_redirected_to new_session_path

        post mfa_challenge_path, params: { code: "123456" }
        assert_redirected_to new_session_path
      end

      test "rate limit del challenge replica el del login (10/min) con copy uniforme" do
        post "/login", params: login_params
        wrong = { code: "000000" }

        10.times { post mfa_challenge_path, params: wrong }
        post mfa_challenge_path, params: wrong
        assert_redirected_to new_mfa_challenge_path
        follow_redirect!
        assert_includes response.body, ChallengesController::GENERIC_ERROR
      end

      test "usuario SIN enrollment confirmado entra directo tras password (flujo base)" do
        plain = User.create!(email_address: "plain@captia.test", password: "contrasena-segura-123")

        post "/login", params: { email_address: plain.email_address, password: "contrasena-segura-123" }
        assert_redirected_to root_url
        assert_equal 1, Session.count
      end

      private

      def login_params
        { email_address: @user.email_address, password: "contrasena-segura-123" }
      end

      def enroll_and_confirm!(user)
        Identity::MfaEnrollment.create!(user: user, secret: ROTP::Base32.random_base32(32)).tap do |e|
          # Confirmamos con un PASO ANTERIOR para dejar libre la ventana actual:
          # así el challenge del test usa un timestep nuevo y determinista.
          e.confirm_with!(ROTP::TOTP.new(e.secret).at(Time.now - 30))
        end
      end

      def totp
        ROTP::TOTP.new(@user.mfa_enrollment.secret)
      end

      def recovery_codes_for(user)
        codes = Array.new(2) { SecureRandom.base58(10) }
        user.recovery_codes.delete_all
        codes.each { |c| user.recovery_codes.create!(code_digest: Digest::SHA256.hexdigest(c)) }
        codes
      end
    end
  end
end
