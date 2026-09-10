# frozen_string_literal: true

module CRM
  class Lead < ApplicationRecord
    self.table_name = "crm_leads"

    STATUSES = %w[new contacted qualified converted lost].freeze

    belongs_to :account, class_name: "Tenancy::Account", optional: true
    belongs_to :organization, class_name: "Tenancy::Organization", optional: true
    belongs_to :assigned_to, class_name: "User", optional: true

    validates :email, presence: true
    validates :name, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :active, -> { where.not(status: %w[converted lost]) }

    scope :search, ->(query) {
      return all if query.blank?

      q = "%#{query.strip}%"
      where("name ILIKE :q OR email ILIKE :q OR company ILIKE :q", q: q)
    }

    # Convierte un lead en Contacto + Cuenta cliente (CRM-01, paso previo a
    # CRM-09/10). El lead permanece bajo su cuenta propietaria (ventas interna)
    # por consistencia RLS y trazabilidad; el vínculo con la cuenta cliente
    # creada queda en el Contacto y la nueva Cuenta.
    def convert!(account: nil)
      # El lead pertenece a la cuenta propietaria (ventas interna); la cuenta
      # cliente de destino puede ser distinta. Cada escritura debe ejecutarse
      # bajo su propio GUC `app.account_id` porque `SET LOCAL` del contexto
      # anidado sobrescribe el del padre (PITFALL #1).
      target = account || Tenancy::Context.provisioning { Tenancy::Account.create_from_lead!(self) }

      contact = Tenancy::Context.with(account_id: target.id) do
        target.crm_contacts.create!(
          first_name: first_name_part,
          last_name: last_name_part,
          email: email
        )
      end

      Tenancy::Context.with(account_id: self.account_id) do
        update!(status: "converted", converted_at: Time.current)
      end

      { account: target, contact: contact }
    end

    private

    def first_name_part
      name.to_s.split.first.to_s.presence || "Sin nombre"
    end

    def last_name_part
      name.to_s.split.drop(1).join(" ").presence || company.to_s.presence || "—"
    end
  end
end
