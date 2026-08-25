# frozen_string_literal: true

require "test_helper"

module Auth
  # T1-02/T1-03: login server-side con rate limit y respuestas uniformes.
  class LoginTest < ActionDispatch::IntegrationTest
    setup do
      Rails.cache.clear
      @user = User.create!(email_address: "ana@captia.test", password: "contrasena-segura-123")
    end

    test "login correcto crea Session, cookie HttpOnly y redirige" do
      assert_difference "Session.count", 1 do
        post "/login", params: { email_address: @user.email_address, password: "contrasena-segura-123" }
      end

      assert_redirected_to root_url
      set_cookie = @response.headers["Set-Cookie"].to_s
      assert_includes set_cookie, "session_id"
      assert_match(/httponly/i, set_cookie, "la cookie de sesión debe ser HttpOnly")
    end

    test "login incorrecto muestra el error genérico del UI-SPEC" do
      post "/login", params: { email_address: @user.email_address, password: "contrasena-mala-99" }

      assert_redirected_to new_session_path
      follow_redirect!
      assert_response :ok
      assert_includes response.body, Auth::SessionsController::GENERIC_ERROR
      assert_equal 0, Session.count
    end

    test "email inexistente produce la MISMA respuesta que contraseña errónea (anti-enumeración)" do
      post "/login", params: { email_address: "fantasma@captia.test", password: "contrasena-mala-99" }
      assert_equal Auth::SessionsController::GENERIC_ERROR, flash[:alert]

      post "/login", params: { email_address: @user.email_address, password: "contrasena-mala-99" }
      assert_equal Auth::SessionsController::GENERIC_ERROR, flash[:alert]
      assert_equal 0, Session.count
    end

    test "el 11º intento en un minuto es rate-limited con mensaje uniforme" do
      ip = { "REMOTE_ADDR" => "10.0.0.77" }
      params = { email_address: @user.email_address, password: "contrasena-mala-99" }

      10.times { post "/login", params: params, env: ip }
      assert_equal 0, Session.count
      assert_not flash[:alert].nil?, "los 10 primeros intentos muestran error normal"

      post "/login", params: params, env: ip
      assert_redirected_to new_session_path
      follow_redirect!
      assert_includes response.body, Auth::SessionsController::GENERIC_ERROR,
                      "el rate limit debe responder con copy uniforme, sin revelar estado"
    end
  end
end
