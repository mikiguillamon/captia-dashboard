# frozen_string_literal: true

# FR-018: notificación al cliente al finalizar una impersonación, cuando su
# organización tiene notify_impersonation=true. Cola Solid Queue (ADR-0005).
class ImpersonationNotificationJob < ApplicationJob
  queue_as :default

  def perform(impersonation_id)
    impersonation = Impersonation.find_by(id: impersonation_id)
    return if impersonation.nil? || impersonation.target_user.nil?

    ImpersonationMailer.notify_ended(impersonation).deliver_later
  end
end
