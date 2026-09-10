# frozen_string_literal: true

# CRM::LeadsController — CRUD de leads + conversión a Cuenta/Contacto (CRM-01/03).
# Toda lectura/escritura tenant va dentro de Tenancy::Context (D-07); el scope
# de la cuenta del usuario es la barrera de RLS.
module CRM
  class LeadsController < ApplicationController
    before_action :authorize_manage_leads!

    def index
      @account_id = current_account_id
      if @account_id.nil?
        @leads = CRM::Lead.none
        @lead = CRM::Lead.new
        return
      end

      @leads = Tenancy::Context.with(account_id: @account_id) do
        scope = CRM::Lead.includes(:assigned_to).order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.search(params[:q]) if params[:q].present?
        scope.limit(25)
      end
      @lead = CRM::Lead.new
    end

    def show
      @lead = find_lead
    end

    def new
      @lead = CRM::Lead.new(status: "new")
    end

    def create
      account_id = current_account_id
      @lead = Tenancy::Context.with(account_id: account_id) do
        CRM::Lead.create!(lead_params.merge(account_id: account_id))
      end

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("leads", partial: "crm/leads/lead", locals: { lead: @lead }) }
        format.html { redirect_to crm_leads_path, notice: "Lead creado." }
      end
    rescue ActiveRecord::RecordInvalid => e
      @lead = e.record
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_lead", partial: "crm/leads/form", locals: { lead: @lead }), status: :unprocessable_entity }
        format.html { redirect_to crm_leads_path, alert: @lead.errors.full_messages.to_sentence }
      end
    end

    def edit
      @lead = find_lead
    end

    def update
      @lead = find_lead
      Tenancy::Context.with(account_id: current_account_id) do
        @lead.update!(lead_params)
      end

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@lead), partial: "crm/leads/lead", locals: { lead: @lead }) }
        format.html { redirect_to crm_leads_path, notice: "Lead actualizado." }
      end
    rescue ActiveRecord::RecordInvalid
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("lead_form_#{@lead.id}", partial: "crm/leads/form", locals: { lead: @lead }), status: :unprocessable_entity }
        format.html { redirect_to crm_leads_path, alert: @lead.errors.full_messages.to_sentence }
      end
    end

    def destroy
      lead = find_lead
      Tenancy::Context.with(account_id: current_account_id) { lead.destroy! }

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(lead)) }
        format.html { redirect_to crm_leads_path, notice: "Lead eliminado." }
      end
    end

    def convert
      lead = find_lead
      result = Tenancy::Context.with(account_id: current_account_id) do
        lead.convert!
      end

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(lead), partial: "crm/leads/lead", locals: { lead: result[:lead] || lead }) }
        format.html { redirect_to crm_leads_path, notice: "Lead convertido en cuenta #{result[:account].name}." }
      end
    end

    private

    def authorize_manage_leads!
      account = Tenancy::Account.find_by(id: current_account_id)
      return render(plain: "Forbidden", status: :forbidden) if account.nil?
      return if Current.user.can?(:manage_leads, scope: account)

      render plain: "Forbidden", status: :forbidden
    end

    def find_lead
      id = params[:id]
      Tenancy::Context.with(account_id: current_account_id) { CRM::Lead.find(id) }
    end

    def lead_params
      params.require(:crm_lead).permit(:name, :email, :company, :source, :status, :assigned_to_id)
    end
  end
end
