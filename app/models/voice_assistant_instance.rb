# frozen_string_literal: true

class VoiceAssistantInstance < ServiceInstance
  CONFIG_SCHEMA = ServiceType::VOICE_ASSISTANT_SCHEMA

  store_accessor :configuration,
    :phone_number,
    :language,
    :voice_id,
    :recording_enabled,
    :transcription_provider

  validates :configuration, presence: true
end