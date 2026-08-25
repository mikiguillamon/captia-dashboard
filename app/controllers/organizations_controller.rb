# frozen_string_literal: true

# Walking skeleton: dashboard de organizaciones de la cuenta del usuario.
# Toda lectura/escritura tenant viaja dentro de Tenancy::Context (D-07).
class OrganizationsController < ApplicationController
  def index
    @organizations = Tenancy::Context.with(account_id: current_account_id) do
      Tenancy::Organization.order(:created_at).to_a
    end
    @organization = Tenancy::Organization.new
  end

  def create
    created = nil
    Tenancy::Context.with(account_id: current_account_id) do
      created = Tenancy::Organization.create!(organization_params.merge(account_id: current_account_id))
    end

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

  private

  def organization_params
    params.require(:tenancy_organization).permit(:name)
  end
end
