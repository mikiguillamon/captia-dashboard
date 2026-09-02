# frozen_string_literal: true

require "test_helper"

# Validación JSONB por esquema para ChatbotInstance (SERV-04).
class ChatbotInstanceTest < ActiveSupport::TestCase
  setup do
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Chat Co") }
    @org = Tenancy::Context.with(account_id: @account.id) {
      Tenancy::Organization.create!(name: "Org Chat", account: @account)
    }
    @type = ServiceType.create!(name: "chatbot",
                                config_schema: ServiceType::CHATBOT_SCHEMA,
                                default_config: {}, default_retention_days: 90)
  end

  def build(**cfg)
    Tenancy::Context.with(account_id: @account.id, organization_id: @org.id) do
      ChatbotInstance.new(organization: @org, service_type: @type,
                          name: "Bot", configuration: cfg)
    end
  end

  test "configuración válida" do
    assert build(welcome_message: "Hola").valid?
  end

  test "campo requerido ausente → inválido" do
    assert_not build(widget_theme: "dark").valid?
  end

  test "enum: widget_theme fuera de valores admitidos → inválido" do
    assert_not build(welcome_message: "Hi", widget_theme: "neon").valid?
    assert build(welcome_message: "Hi", widget_theme: "dark").valid?
  end

  test "enum: escalation_trigger inválido → inválido" do
    assert_not build(welcome_message: "Hi", escalation_trigger: "voice").valid?
    assert build(welcome_message: "Hi", escalation_trigger: "keyword").valid?
  end

  test "formato uri en integration_webhook" do
    assert_not build(welcome_message: "Hi", integration_webhook: "not-a-uri").valid?
    assert build(welcome_message: "Hi", integration_webhook: "https://hook.example.com").valid?
  end
end
