# frozen_string_literal: true

require "test_helper"

# SERV-01..04: STI + estados + slug + visibilidad histórica del catálogo.
class ServiceInstanceTest < ActiveSupport::TestCase
  setup do
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Svc Co") }
    @org = Tenancy::Context.with(account_id: @account.id) {
      Tenancy::Organization.create!(name: "Org Svc", account: @account)
    }
    @email_type = ServiceType.create!(name: "email_assistant",
                                      config_schema: ServiceType::EMAIL_ASSISTANT_SCHEMA,
                                      default_config: {}, default_retention_days: 90)
  end

  test "STI: crear subclase persiste con type correcto" do
    instance = Tenancy::Context.with(account_id: @account.id, organization_id: @org.id) {
      EmailAssistantInstance.create!(
        organization: @org, service_type: @email_type, name: "Support Inbox",
        configuration: { inbound_email_domain: "example.com" }
      )
    }
    assert_equal "EmailAssistantInstance", instance.reload.type
  end

  test "enum de estados contractual/operativo/salud" do
    instance = Tenancy::Context.with(account_id: @account.id, organization_id: @org.id) {
      EmailAssistantInstance.create!(
        organization: @org, service_type: @email_type, name: "S",
        configuration: { inbound_email_domain: "example.com" }
      )
    }
    assert_equal "pending_start", instance.contractual_state
    assert_equal "stopped", instance.operational_state
    assert_equal "unknown", instance.health_state
  end

  test "slug se genera a partir del nombre y es único por organización" do
    Tenancy::Context.with(account_id: @account.id, organization_id: @org.id) do
      a = EmailAssistantInstance.create!(
        organization: @org, service_type: @email_type, name: "Mail de Ventas",
        configuration: { inbound_email_domain: "a.com" }
      )
      b = EmailAssistantInstance.create!(
        organization: @org, service_type: @email_type, name: "Mail de Ventas",
        configuration: { inbound_email_domain: "b.com" }
      )
      assert_equal "mail-de-ventas", a.slug
      assert_equal "mail-de-ventas-2", b.slug
    end
  end

  test "scope with_historical_access incluye activas y ended dentro de retención" do
    Tenancy::Context.with(account_id: @account.id, organization_id: @org.id) do
      active = EmailAssistantInstance.create!(
        organization: @org, service_type: @email_type, name: "Activa",
        contractual_state: "active",
        configuration: { inbound_email_domain: "a.com" }
      )
      ended_recent = EmailAssistantInstance.create!(
        organization: @org, service_type: @email_type, name: "Reciente",
        configuration: { inbound_email_domain: "b.com" },
        contractual_state: "ended", historical_access_until: Date.current + 10
      )
      EmailAssistantInstance.create!(
        organization: @org, service_type: @email_type, name: "Expira",
        configuration: { inbound_email_domain: "c.com" },
        contractual_state: "ended", historical_access_until: Date.current - 10
      )

      ids = ServiceInstance.with_historical_access.pluck(:id)
      assert_includes ids, active.id
      assert_includes ids, ended_recent.id
    end
  end
end
