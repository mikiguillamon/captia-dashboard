# frozen_string_literal: true

require "test_helper"

# Aislamiento RLS de los modelos de Fase 2 (CRM + catálogo de servicios).
# Verify: un usuario/contexto de la cuenta A jamás ve filas de la cuenta B.
class CrmServiceRlsIsolationTest < ActionDispatch::IntegrationTest
  setup do
    @alpha = create_account!("Alpha CRM")
    @beta  = create_account!("Beta CRM")

    @email_type = ServiceType.create!(name: "email_assistant",
                                      config_schema: ServiceType::EMAIL_ASSISTANT_SCHEMA,
                                      default_config: {}, default_retention_days: 90)

    # Poblar Alpha con datos CRM + servicio.
    Tenancy::Context.with(account_id: @alpha.id) do
      @alpha_org = Tenancy::Organization.create!(name: "Org Alpha", account: @alpha)
      PipelineStage.create!(name: "Prospecting", position: 1, probability: 10,
                            color: "#64748b", account: @alpha)
      # Filas objetivo para las aserciones.
      @alpha_lead = CRM::Lead.create!(email: "a@a.test", name: "A Lead", account: @alpha)
      @alpha_contact = CRM::Contact.create!(first_name: "A", last_name: "C",
                                            email: "ac@a.test", account: @alpha)
      @alpha_si = EmailAssistantInstance.create!(
        organization: @alpha_org, service_type: @email_type,
        name: "Mail A", slug: "mail-a",
        configuration: { inbound_email_domain: "a.test" }
      )
    end

    clear_tenant_context!
  end

  test "leer fila de otra cuenta con contexto propio devuelve 0" do
    Tenancy::Context.with(account_id: @beta.id) do
      assert_equal 0, CRM::Lead.count, "leads de Alpha no visibles desde Beta"
      assert_equal 0, CRM::Contact.count
      assert_equal 0, CRM::Opportunity.count
      assert_equal 0, PipelineStage.count
      assert_equal 0, ServiceInstance.count
    end
  end

  test "la cuenta propia sí ve sus filas con contexto válido" do
    Tenancy::Context.with(account_id: @alpha.id) do
      assert_equal 1, CRM::Lead.where(id: @alpha_lead.id).count
      assert_equal 1, CRM::Contact.where(id: @alpha_contact.id).count
      assert_equal 1, ServiceInstance.where(id: @alpha_si.id).count
    end
  end

  test "ServiceType (referencia global) sin RLS es legible sin contexto" do
    clear_tenant_context!
    assert_equal 1, ServiceType.where(name: "email_assistant").count
  end

  test "escribir tenant SIN contexto es rechazado por RLS" do
    clear_tenant_context!
    conn = ActiveRecord::Base.connection
    error = assert_raises(ActiveRecord::StatementInvalid) do
      conn.execute(
        "INSERT INTO crm_leads (account_id, email, name, created_at, updated_at) " \
        "VALUES (#{@alpha.id}, 'x@x.test', 'Ilegal', now(), now())"
      )
    end
    assert_match(/row-level security/, error.message)
  end

  private

  def create_account!(name)
    Tenancy::Context.provisioning { Tenancy::Account.create!(name: name) }
  end

  def clear_tenant_context!
    conn = ActiveRecord::Base.connection
    %w[app.account_id app.organization_id app.provisioning].each do |guc|
      conn.execute("SELECT set_config('#{guc}', '', false)")
    end
  end
end
