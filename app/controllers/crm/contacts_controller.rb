# frozen_string_literal: true

# CRM::ContactsController — CRUD de contactos (CRM-02), scoped a la cuenta.
module CRM
  class ContactsController < ApplicationController
    before_action :authorize_manage_contacts!

    def index
      @account_id = current_account_id
      if @account_id.nil?
        @contacts = CRM::Contact.none
        @contact = CRM::Contact.new
        return
      end

      @contacts = Tenancy::Context.with(account_id: @account_id) do
        scope = CRM::Contact.order(created_at: :desc)
        scope = scope.search(params[:q]) if params[:q].present?
        scope.limit(25)
      end
      @contact = CRM::Contact.new
    end

    def show
      @contact = find_contact
    end

    def new
      @contact = CRM::Contact.new
    end

    def create
      account_id = current_account_id
      @contact = Tenancy::Context.with(account_id: account_id) do
        CRM::Contact.create!(contact_params.merge(account_id: account_id))
      end

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("contacts", partial: "crm/contacts/contact", locals: { contact: @contact }) }
        format.html { redirect_to crm_contacts_path, notice: "Contacto creado." }
      end
    rescue ActiveRecord::RecordInvalid => e
      @contact = e.record
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_contact", partial: "crm/contacts/form", locals: { contact: @contact }), status: :unprocessable_entity }
        format.html { redirect_to crm_contacts_path, alert: @contact.errors.full_messages.to_sentence }
      end
    end

    def edit
      @contact = find_contact
    end

    def update
      @contact = find_contact
      Tenancy::Context.with(account_id: current_account_id) { @contact.update!(contact_params) }

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@contact), partial: "crm/contacts/contact", locals: { contact: @contact }) }
        format.html { redirect_to crm_contacts_path, notice: "Contacto actualizado." }
      end
    rescue ActiveRecord::RecordInvalid
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("contact_form_#{@contact.id}", partial: "crm/contacts/form", locals: { contact: @contact }), status: :unprocessable_entity }
        format.html { redirect_to crm_contacts_path, alert: @contact.errors.full_messages.to_sentence }
      end
    end

    def destroy
      contact = find_contact
      Tenancy::Context.with(account_id: current_account_id) { contact.destroy! }

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(contact)) }
        format.html { redirect_to crm_contacts_path, notice: "Contacto eliminado." }
      end
    end

    private

    def authorize_manage_contacts!
      account = Tenancy::Account.find_by(id: current_account_id)
      return render(plain: "Forbidden", status: :forbidden) if account.nil?
      return if Current.user.can?(:manage_contacts, scope: account)

      render plain: "Forbidden", status: :forbidden
    end

    def find_contact
      id = params[:id]
      Tenancy::Context.with(account_id: current_account_id) { CRM::Contact.find(id) }
    end

    def contact_params
      params.require(:crm_contact).permit(:first_name, :last_name, :email, :phone, :role)
    end
  end
end
