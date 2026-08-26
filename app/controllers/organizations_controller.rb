# frozen_string_literal: true

# Walking skeleton: dashboard de organizaciones de la cuenta del usuario.
# Toda lectura/escritura tenant viaja dentro de Tenancy::Context (D-07);
# la organización activa pasa por OrganizationScoping (AC-001).
class OrganizationsController < ApplicationController
  include OrganizationScoping

  before_action :authorize_org_creation!, only: :create

  def index
    account_id = current_account_id
    org_id = current_organization&.id

    # AC-001: SOLO organizaciones accesibles para el usuario (la RLS es la
    # segunda barrera a nivel cuenta; la visibilidad por organización es app).
    @organizations = account_id ? accessible_organizations : []
    if account_id
      Tenancy::Context.with(account_id: account_id, organization_id: org_id) do
        @organization ||= Tenancy::Organization.new
      end
    else
      @organization ||= Tenancy::Organization.new
    end
  end

  def create
    created = nil
    account_id = current_account_id
    org_id = current_organization&.id

    Tenancy::Context.with(account_id: account_id, organization_id: org_id) do
      created = Tenancy::Organization.create!(organization_params.merge(account_id: account_id))
    end
    set_active_organization!(created)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("organizations", partial: "organizations/organization", locals: { organization: created }),
          # Si era la primera, fuera el empty state (no-op si ya no existe).
          turbo_stream.remove("empty_state"),
          turbo_stream.replace("new_organization", partial: "organizations/form", locals: { organization: Tenancy::Organization.new })
        ]
      end
      format.html { redirect_to organizations_path, notice: "Organización creada." }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "new_organization",
          partial: "organizations/form",
          locals: { organization: e.record },
          status: :unprocessable_entity
        )
      end
      format.html { redirect_to organizations_path, alert: e.record.errors.full_messages.to_sentence }
    end
  end

  # Selector de organización activa (AC-001): valida acceso antes de fijarla.
  def switch
    target = accessible_organizations.find { |o| o.id == params[:organization_id].to_i }
    return head :forbidden unless target

    set_active_organization!(target)
    redirect_to organizations_path, notice: "Organización activa: #{target.name}."
  end

  private

  # Crear organizaciones exige contexto activo O capability de gestión a nivel
  # cuenta (permite la PRIMERA organización de una cuenta nueva).
  def authorize_org_creation!
    return if current_organization.present?

    account = Tenancy::Account.find_by(id: current_account_id)
    return if account && Current.user.can?(:manage_organizations, scope: account)

    render plain: "Forbidden", status: :forbidden
  end

  def organization_params
    params.require(:tenancy_organization).permit(:name)
  end
end
