# frozen_string_literal: true

module Admin
  # D-06 / AUTH-04..07 / SEG-04/05/11: impersonación con re-autenticación del
  # interno en el mismo request, expiración ≈30 min y auditoría actor real.
  class ImpersonationsController < ApplicationController
    before_action :require_impersonate_capability, only: :new

    def new
      # Review F4: solo usuarios del ALCANCE del iniciador (misma cuenta en el
      # skeleton); jamás emails cross-tenant.
      @targets = User.where(account_id: Current.user.account_id)
                     .where.not(id: Current.user.id).order(:email_address)
    end

    def create
      initiator = Current.user
      target = User.find_by(id: params[:target_user_id])

      return head :forbidden unless impersonation_allowed?(initiator, target, params[:password])

      start_impersonation!(initiator, target)
      redirect_to root_path, notice: "Estás operando como #{target.email_address}.", status: :see_other
    end

    def destroy
      finish_impersonation!
      redirect_to root_path, notice: "Has salido de la sesión de impersonación.", status: :see_other
    end

    private

    # SEG-04: solo quien posea la capability sobre la cuenta activa ve el flujo.
    def require_impersonate_capability
      scope = Tenancy::Account.find_by(id: Current.user&.account_id)
      return if scope && Current.user.can?(:impersonate, scope: scope)

      render plain: "Forbidden", status: :forbidden
    end

    def impersonation_allowed?(initiator, target, password)
      return false if target.nil?
      return false unless initiator.authenticate(password.to_s) # re-auth mismo request
      return false unless initiator.can?(:impersonate, scope: target_account(target))
      return false if target.role_assignments.exists?(role: INTERNAL_ROLES)

      true
    end

    def start_impersonation!(initiator, target)
      now = Time.current
      impersonation = Impersonation.create!(
        initiator: initiator, target_user: target,
        started_at: now, expires_at: now + Impersonation::LIFETIME
      )

      AuditLog.create!(
        actor_real: initiator, actor_effective: initiator,
        action: "impersonation.start", subject: impersonation, ip: request.remote_ip
      )

      # Sesión impersonada de vida corta para el objetivo.
      target_session = target.sessions.create!(
        user_agent: request.user_agent, ip_address: request.remote_ip,
        impersonated: true, expires_at: impersonation.expires_at
      )
      session[:impersonator_session_id] = cookies.signed[:session_id] # sesión real del empleado
      session[:impersonation_id] = impersonation.id
      cookies.signed[:session_id] = { value: target_session.id, httponly: true, same_site: :lax }
      Current.session = target_session
      Current.impersonation = impersonation
    end

    def target_account(target)
      return nil if target.account_id.nil?

      Tenancy::Account.find(target.account_id)
    end

    INTERNAL_ROLES = %w[superadmin direccion comercial account_manager tecnico].freeze
  end
end
