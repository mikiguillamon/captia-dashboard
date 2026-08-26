# frozen_string_literal: true

# Aceptación pública de invitación (token un-uso): crea User + Membership
# dentro de Tenancy::Context (D-07). Respuestas uniformes ante fallos de token.
class InvitationsController < ApplicationController
  allow_unauthenticated_access only: %i[new_accept create_accept]
  rate_limit to: 10, within: 1.minute, only: :create_accept, with: -> {
    redirect_to root_path, alert: GENERIC_INVALID, status: :see_other
  }

  GENERIC_INVALID = "Esta invitación no es válida o ha expirado."

  def new_accept
    @invitation = Tenancy::Invitation.valid.find_by(
      token_digest: Tenancy::Invitation.digest(params[:token])
    )
    return invalid_redirect unless @invitation

    @token = params[:token]
  end

  def create_accept
    invitation = Tenancy::Invitation.valid.find_by(
      token_digest: Tenancy::Invitation.digest(params[:token])
    )
    return invalid_redirect unless invitation

    # Review F6: validar TODO antes de consumir; el token se quema solo si la
    # aceptación completa va a tener éxito (una errata no lo invalida).
    requested_email = params[:email_address].to_s.strip.downcase
    return invalid_redirect unless requested_email == invitation.email

    account_id = invitation.organization.account_id
    user = nil
    Tenancy::Context.with(account_id: account_id, organization_id: invitation.organization_id) do
      user = User.find_or_initialize_by(email_address: invitation.email)
      user.password = params[:password] if user.new_record?
      unless user.save
        @invitation = invitation
        @token = params[:token]
        flash.now[:alert] = user.errors.full_messages.to_sentence
        render :new_accept, status: :unprocessable_entity and return
      end
      Tenancy::Membership.create!(user: user, organization: invitation.organization)
    end

    # Consumo definitivo del token: éxito garantizado a partir de aquí.
    invitation.update!(used_at: Time.current)

    # SEG-03/AC-006: mismo criterio que el login para orgs con MFA exigido.
    if organization_requires_mfa?(user)
      redirect_to new_session_path,
                  alert: Auth::SessionsController::GENERIC_ERROR,
                  status: :see_other and return
    end

    # Sesión directa tras aceptar (el usuario acaba de crear credenciales).
    start_new_session_for(user)
    redirect_to organizations_path,
                notice: "Bienvenido a #{invitation.organization.name}.",
                status: :see_other
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    invalid_redirect
  end

  private

  def invalid_redirect
    redirect_to new_session_path, alert: GENERIC_INVALID, status: :see_other
  end
end
