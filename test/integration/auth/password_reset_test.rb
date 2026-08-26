# frozen_string_literal: true

require "test_helper"

# D-05 / T1-06: token un-solo-uso ≈30min, invalidación de tokens previos,
# revocación total de sesiones tras el reset, respuestas uniformes.
class PasswordResetFlowTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    Rails.cache.clear
    @user = User.create!(email_address: "reset@captia.test", password: "contrasena-vieja-123")
  end

  test "forgot responde SIEMPRE igual exista o no el email (anti-enumeración)" do
    post "/password/forgot", params: { email_address: @user.email_address }
    assert_redirected_to new_session_path
    notice = flash[:notice]

    post "/password/forgot", params: { email_address: "fantasma@captia.test" }
    assert_redirected_to new_session_path
    assert_equal notice, flash[:notice],
                 "la respuesta para email inexistente debe ser idéntica"
  end

  test "token emitido se guarda solo como digest y expira a los ~30 min" do
    freeze_time
    raw = Identity::PasswordResetToken.issue!(@user)

    record = @user.password_reset_tokens.reload.last
    refute_equal raw, record.token_digest
    assert_match(/\A[0-9a-f]{64}\z/, record.token_digest)
    assert_in_delta 30.minutes.from_now, record.expires_at, 2.seconds

    # Vigente justo antes de expirar; rechazado justo después.
    travel 29.minutes
    assert_not_nil Identity::PasswordResetToken.consume!(raw)
    u2 = User.create!(email_address: "x@captia.test", password: "contrasena-vieja-123")
    raw2 = Identity::PasswordResetToken.issue!(u2)
    travel 31.minutes
    assert_nil Identity::PasswordResetToken.consume!(raw2), "token >30 min debe ser rechazado"
    unfreeze_time
  end

  test "flujo completo: reset cambia contraseña, revoca sesiones e invalida tokens previos" do
    # Sesión activa que DEBE morir con el reset.
    post "/login", params: { email_address: @user.email_address, password: "contrasena-vieja-123" }
    assert_equal 1, Session.count

    get "/password/forgot"
    assert_response :ok

    raw_first = Identity::PasswordResetToken.issue!(@user)
    raw = Identity::PasswordResetToken.issue!(@user) # emitir uno nuevo invalida al anterior
    assert Identity::PasswordResetToken.unused.where(token_digest: Identity::PasswordResetToken.digest(raw_first)).none?,
           "emitir un enlace nuevo invalida el anterior"

    delete "/logout" # el flujo de recuperación va sin sesión activa
    get "/password/reset", params: { token: raw }
    assert_response :ok

    patch "/password/reset", params: { token: raw, password: "nueva-contra-1234", password_confirmation: "nueva-contra-1234" }
    assert_redirected_to new_session_path

    assert_equal 0, Session.count, "el reset debe revocar TODAS las sesiones activas"
    assert_equal 0, @user.password_reset_tokens.unused.count, "no quedan tokens reutilizables"

    # La nueva contraseña funciona; la vieja no.
    post "/login", params: { email_address: @user.email_address, password: "contrasena-vieja-123" }
    assert_response :see_other
    post "/login", params: { email_address: @user.email_address, password: "nueva-contra-1234" }
    assert_redirected_to root_url
  end

  test "token reusado es rechazado (un-solo-uso)" do
    raw = Identity::PasswordResetToken.issue!(@user)
    patch "/password/reset", params: { token: raw, password: "nueva-contra-1234", password_confirmation: "nueva-contra-1234" }
    assert_redirected_to new_session_path

    patch "/password/reset", params: { token: raw, password: "otra-clave-9999", password_confirmation: "otra-clave-9999" }
    assert_redirected_to forgot_password_path
    follow_redirect!
    assert_includes response.body, Auth::PasswordsController::GENERIC_INVALID
  end

  test "enlace con token inválido redirige con aviso genérico" do
    get "/password/reset", params: { token: "basura-invalida" }
    assert_redirected_to forgot_password_path
    follow_redirect!
    assert_includes response.body, Auth::PasswordsController::GENERIC_INVALID
  end

  test "la nueva contraseña exige longitud mínima 12" do
    raw = Identity::PasswordResetToken.issue!(@user)
    delete "/logout"

    patch "/password/reset", params: { token: raw, password: "corta-12345", password_confirmation: "corta-12345" }
    assert_response :unprocessable_entity
    assert_includes response.body, "too short"

    # El token sigue válido (el fallo de validación no lo consume).
    assert Identity::PasswordResetToken.valid.exists?(token_digest: Identity::PasswordResetToken.digest(raw))
  end

  test "el mailer genera enlace con el token en claro" do
    raw = Identity::PasswordResetToken.issue!(@user)
    mail = AuthMailer.reset_instructions(@user, raw)

    # decoded revierte quoted-printable (el token puede quedar partido).
    text_body = mail.text_part.decoded
    html_body = mail.html_part.decoded
    [ text_body, html_body ].each do |body|
      assert_includes body, CGI.escape(raw), "el enlace debe contener el token"
    end
    assert_equal [ @user.email_address ], mail.to
  end
end
