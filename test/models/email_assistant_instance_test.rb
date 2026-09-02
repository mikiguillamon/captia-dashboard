# frozen_string_literal: true

require "test_helper"

# Validación JSONB por esquema para EmailAssistantInstance (SERV-04).
class EmailAssistantInstanceTest < ActiveSupport::TestCase
  setup do
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Email Co") }
    @org = Tenancy::Context.with(account_id: @account.id) {
      Tenancy::Organization.create!(name: "Org Email", account: @account)
    }
    @type = ServiceType.create!(name: "email_assistant",
                                config_schema: ServiceType::EMAIL_ASSISTANT_SCHEMA,
                                default_config: {}, default_retention_days: 90)
  end

  def build(**cfg)
    Tenancy::Context.with(account_id: @account.id, organization_id: @org.id) do
      EmailAssistantInstance.new(organization: @org, service_type: @type,
                                 name: "Mail", configuration: cfg)
    end
  end

  test "configuración válida" do
    assert build(inbound_email_domain: "example.com").valid?
  end

  test "campo requerido ausente → inválido" do
    record = build(auto_reply_enabled: true)
    assert_not record.valid?
    assert_includes record.errors[:configuration].to_s, "inbound_email_domain"
  end

  test "tipo incorrecto (string vs boolean) → inválido" do
    assert_not build(inbound_email_domain: "x.com", auto_reply_enabled: "si").valid?
  end

  test "propiedad no declarada (strict) → inválido" do
    assert_not build(inbound_email_domain: "x.com", unknown_key: 1).valid?
  end

  test "formato email en forwarding_addresses" do
    assert_not build(inbound_email_domain: "x.com",
                     forwarding_addresses: [ "no-email" ]).valid?,
               "formato email aplica a items del array"
    assert build(inbound_email_domain: "x.com",
                 forwarding_addresses: [ "ok@example.com" ]).valid?
  end
end
