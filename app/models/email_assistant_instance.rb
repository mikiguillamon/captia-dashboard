# frozen_string_literal: true

class EmailAssistantInstance < ServiceInstance
  CONFIG_SCHEMA = ServiceType::EMAIL_ASSISTANT_SCHEMA

  store_accessor :configuration,
    :inbound_email_domain,
    :auto_reply_enabled,
    :escalation_rules,
    :forwarding_addresses

  validates :configuration, presence: true
end