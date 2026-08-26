# frozen_string_literal: true

class ImpersonationMailer < ApplicationMailer
  def notify_ended(impersonation)
    @impersonation = impersonation
    @target = impersonation.target_user

    mail to: @target.email_address,
         subject: "Sesión de soporte finalizada — Captia"
  end
end
