# frozen_string_literal: true

require "test_helper"

# Validación JSONB por esquema para VoiceAssistantInstance (SERV-04).
class VoiceAssistantInstanceTest < ActiveSupport::TestCase
  setup do
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Voice Co") }
    @org = Tenancy::Context.with(account_id: @account.id) {
      Tenancy::Organization.create!(name: "Org Voice", account: @account)
    }
    @type = ServiceType.create!(name: "voice_assistant",
                                config_schema: ServiceType::VOICE_ASSISTANT_SCHEMA,
                                default_config: {}, default_retention_days: 180)
  end

  def build(**cfg)
    Tenancy::Context.with(account_id: @account.id, organization_id: @org.id) do
      VoiceAssistantInstance.new(organization: @org, service_type: @type,
                                 name: "Linea", configuration: cfg)
    end
  end

  test "configuración válida (ambos requeridos)" do
    assert build(phone_number: "+34123456789", language: "es-ES").valid?
  end

  test "falta un campo requerido → inválido" do
    assert_not build(phone_number: "+34123456789").valid?
    assert_not build(language: "es-ES").valid?
  end

  test "enum transcription_provider inválido → inválido" do
    assert_not build(phone_number: "+34", language: "es",
                     transcription_provider: "other").valid?
    assert build(phone_number: "+34", language: "es",
                 transcription_provider: "whisper").valid?
  end

  test "tipo booleano en recording_enabled" do
    assert build(phone_number: "+34", language: "es", recording_enabled: true).valid?
    assert_not build(phone_number: "+34", language: "es", recording_enabled: "si").valid?
  end
end
