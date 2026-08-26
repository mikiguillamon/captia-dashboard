# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_account_id

  # D-06: estado de impersonación resuelto ANTES de la autenticación, para
  # poder salir con gracia (restaurando al empleado) incluso cuando la sesión
  # impersonada ya expiró.
  prepend_before_action :resolve_impersonation_state

  # AC-007/T1-09: toda escritura DURANTE impersonación registra audit_log con
  # AMBOS actores (el par real/effective viene de Current).
  around_action :audit_mutative_request

  MUTATIVE_METHODS = %w[POST PUT PATCH DELETE].freeze

  private

  # Puente provisional del walking skeleton: la cuenta del usuario vía
  # users.account_id hasta que memberships sea la fuente canónica.
  def current_account_id
    if Current.impersonating?
      Current.actor_effective.account_id
    else
      Current.user&.account_id
    end
  end

  def resolve_impersonation_state
    return if session[:impersonation_id].blank?

    impersonation = Impersonation.find_by(id: session[:impersonation_id])
    target_session = Session.find_by(id: cookies.signed[:session_id])
    state_ok = impersonation && target_session&.impersonated? &&
               target_session.user_id == impersonation.target_user_id

    if state_ok && impersonation.active? && !target_session.expired?
      Current.impersonation = impersonation
      Current.session ||= target_session
    else
      finish_impersonation!
      redirect_to root_path,
                  alert: "La sesión de impersonación ha finalizado." unless performed?
    end
  end

  # Salida de impersonación: restaura la sesión del empleado, cierra la sesión
  # impersonada, audita el fin y notifica si la organización lo tiene activo.
  def finish_impersonation!
    impersonation = session[:impersonation_id] && Impersonation.find_by(id: session[:impersonation_id])
    staff_session_id = session[:impersonator_session_id]
    target = impersonation&.target_user

    AuditLog.create!(
      actor_real: impersonation&.initiator || Current.actor_real,
      actor_effective: target || Current.actor_effective || Current.actor_real,
      action: "impersonation.end",
      subject: impersonation,
      ip: request.remote_ip
    ) if impersonation

    impersonation&.update!(ended_at: Time.current)
    Session.where(id: cookies.signed[:session_id]).destroy_all if Current.session&.impersonated?
    Current.impersonation = nil
    session.delete(:impersonation_id)

    if staff_session_id && Session.active.exists?(id: staff_session_id)
      cookies.signed[:session_id] = { value: staff_session_id, httponly: true, same_site: :lax }
      session.delete(:impersonator_session_id)
      Current.session = nil # se re-resuelve con la cookie del empleado
    else
      cookies.delete(:session_id)
      session.delete(:impersonator_session_id)
      Current.session = nil
    end

    enqueue_impersonation_notification(impersonation, target) if impersonation&.ended_at.present? && target
  end

  def enqueue_impersonation_notification(impersonation, target)
    return if target.account_id.nil?

    # La configuración de organizaciones es dato tenant → contexto obligatorio.
    notify = Tenancy::Context.with(account_id: target.account_id) do
      Tenancy::Organization.where(notify_impersonation: true).exists?
    end
    ImpersonationNotificationJob.perform_later(impersonation.id) if notify
  rescue StandardError => e
    Rails.logger.warn("notify check failed: #{e.message}")
  end

  def audit_mutative_request
    yield
    log_mutation_audit!
  end

  def log_mutation_audit!
    return unless Current.impersonating?
    return unless MUTATIVE_METHODS.include?(request.method)
    return if controller_path.start_with?("admin/impersonations", "auth/")

    AuditLog.create!(
      actor_real: Current.actor_real,
      actor_effective: Current.actor_effective,
      action: "#{controller_path}##{action_name}",
      ip: request.remote_ip
    )
  rescue StandardError => e
    Rails.logger.warn("audit log failed: #{e.message}")
  end
end
