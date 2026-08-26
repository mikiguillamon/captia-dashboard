# frozen_string_literal: true

class AuthMailer < ApplicationMailer
  # Correo transaccional de identidad (SMTP autoalojado en producción;
  # letter_opener en desarrollo — ver config/environments/development.rb).
  def reset_instructions(user, raw_token)
    @user = user
    @reset_url = "#{root_url}password/reset?token=#{CGI.escape(raw_token)}"

    mail to: user.email_address, subject: "Restablece tu contraseña — Captia"
  end
end
