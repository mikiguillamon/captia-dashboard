# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  def invite(organization:, email:, raw_token:)
    @organization = organization
    @accept_url = "#{root_url}invitations/accept?token=#{CGI.escape(raw_token)}"

    mail to: email, subject: "Te han invitado a #{organization.name} — Captia"
  end
end
