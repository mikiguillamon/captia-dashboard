# frozen_string_literal: true

class ChatbotInstance < ServiceInstance
  CONFIG_SCHEMA = ServiceType::CHATBOT_SCHEMA

  store_accessor :configuration,
    :welcome_message,
    :widget_theme,
    :escalation_trigger,
    :integration_webhook

  validates :configuration, presence: true
end