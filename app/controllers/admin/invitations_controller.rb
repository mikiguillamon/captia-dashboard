# frozen_string_literal: true

module Admin
  # TEN-11/FR-011: crear invitaciones exige capability invite_users sobre la
  # organización activa Y autogestión habilitada si quien invita es cliente.
  class InvitationsController < ApplicationController
    include OrganizationScoping

    before_action :require_organization_membership!
    rate_limit to: 10, within: 1.minute, only: :create, with: -> {
      redirect_to organizations_path, alert: "Demasiados intentos. Inténtalo más tarde.", status: :see_other
    }

    def create
      organization = current_organization
      inviter = Current.user

      return head :forbidden unless inviter.can?(:invite_users, scope: organization)
      return self_management_blocked if cliente_inviter_without_self_invite?(inviter, organization)

      params_invitation = invitation_params
      return head :forbidden unless Tenancy::Invitation::CLIENT_ROLES.include?(params_invitation[:role])

      raw = Tenancy::Invitation.issue!(
        organization: organization, invited_by: inviter,
        email: params_invitation[:email], role: params_invitation[:role]
      )
      InvitationMailer.invite(organization: organization, email: params_invitation[:email],
                              raw_token: raw).deliver_later

      redirect_to organizations_path, notice: UNIFORM_NOTICE, status: :see_other
    end

    UNIFORM_NOTICE = "Invitación registrada. El invitado recibirá un correo para completar su acceso."

    # PRD §3.1: los 5 roles internos; el resto (cliente) queda sujeto a la
    # autogestión habilitada de su organización.
    INTERNAL_ROLES = %w[superadmin direccion comercial account_manager tecnico].freeze

    private

    def cliente_inviter_without_self_invite?(inviter, organization)
      return false if internal_inviter?(inviter)

      !organization.allow_self_invite
    end

    def internal_inviter?(user)
      user.role_assignments.exists?(role: INTERNAL_ROLES)
    end

    def invitation_params
      # Sin permit masivo (brakeman PermitAttributes): claves explícitas;
      # role se valida contra CLIENT_ROLES en modelo y controlador.
      {
        email: params.dig(:invitation, :email),
        role: params.dig(:invitation, :role)
      }
    end

    def self_management_blocked
      render plain: "Forbidden", status: :forbidden
    end
  end
end
