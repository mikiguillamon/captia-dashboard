# frozen_string_literal: true

class ServiceType < ApplicationRecord
  has_many :service_instances, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :config_schema, presence: true
  validates :default_retention_days, numericality: { greater_than: 0 }

  scope :ordered, -> { order(:display_order) }

  # Predefined MVP service types
  EMAIL_ASSISTANT_SCHEMA = {
    type: "object",
    required: ["inbound_email_domain"],
    properties: {
      inbound_email_domain: { type: "string", description: "Dominio para emails entrantes" },
      auto_reply_enabled: { type: "boolean", default: false },
      escalation_rules: {
        type: "array",
        items: {
          type: "object",
          properties: {
            condition: { type: "string" },
            action: { type: "string" }
          },
          required: ["condition", "action"]
        }
      },
      forwarding_addresses: { type: "array", items: { type: "string", format: "email" } }
    }
  }.freeze

  CHATBOT_SCHEMA = {
    type: "object",
    required: ["welcome_message"],
    properties: {
      welcome_message: { type: "string", description: "Mensaje de bienvenida" },
      widget_theme: { type: "string", enum: ["light", "dark", "auto"], default: "auto" },
      escalation_trigger: { type: "string", enum: ["keyword", "sentiment", "manual"], default: "keyword" },
      integration_webhook: { type: "string", format: "uri" }
    }
  }.freeze

  VOICE_ASSISTANT_SCHEMA = {
    type: "object",
    required: ["phone_number", "language"],
    properties: {
      phone_number: { type: "string", description: "Número de teléfono" },
      language: { type: "string", default: "es-ES" },
      voice_id: { type: "string" },
      recording_enabled: { type: "boolean", default: true },
      transcription_provider: { type: "string", enum: ["whisper", "deepgram", "assemblyai"], default: "whisper" }
    }
  }.freeze
end