class Current < ActiveSupport::CurrentAttributes
  attribute :session
  # D-06: impersonación activa (fila Impersonation) durante el request.
  attribute :impersonation

  delegate :user, to: :session, allow_nil: true

  # T1-09: par de actores obligatorio en toda escritura auditada.
  # actor_real es SIEMPRE el empleado que inició la impersonación (no la
  # sesión activa, que pertenece al usuario impersonado).
  def actor_real
    impersonation&.initiator || session&.user
  end

  def actor_effective
    impersonation&.target_user || actor_real
  end

  def impersonating?
    impersonation.present?
  end
end
