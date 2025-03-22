require "spec_helper"

RSpec.describe PLLUM do
  describe ".VERSION" do
    it "has a version number" do
      expect(PLLUM::VERSION).not_to be nil
    end
  end

  describe ".conversation" do
    it "creates a new conversation instance" do
      conversation = PLLUM.conversation
      expect(conversation).to be_a(PLLUM::Conversation)
    end

    it "passes options to the conversation constructor" do
      model = "custom-model"
      temperature = 0.8
      auth_mode = true

      conversation = PLLUM.conversation(
        model: model,
        temperature: temperature,
        auth_mode: auth_mode
      )

      expect(conversation.config[:model]).to eq(model)
      expect(conversation.config[:temperature]).to eq(temperature)
      expect(conversation.config[:auth_mode]).to eq(auth_mode)
    end
  end

  describe "error classes" do
    it "defines necessary error classes" do
      expect(PLLUM::Error).to be < StandardError
      expect(PLLUM::ConfigurationError).to be < PLLUM::Error
      expect(PLLUM::AuthenticationError).to be < PLLUM::Error
    end
  end

  describe "configuration" do
    after do
      # Reset to defaults
      PLLUM.configuration = PLLUM::Configuration.new
    end

    it "returns a default configuration when not explicitly set" do
      config = PLLUM.configuration
      expect(config).to be_a(PLLUM::Configuration)
      expect(config.uri_base).to eq(PLLUM::Configuration::DEFAULT_URI_BASE)
    end

    it "uses the configured values" do
      custom_uri = "https://custom.example.com"
      PLLUM.configure do |config|
        config.uri_base = custom_uri
      end

      expect(PLLUM.configuration.uri_base).to eq(custom_uri)
    end

    it "allows direct setting of the configuration" do
      custom_config = PLLUM::Configuration.new
      custom_config.request_timeout = 300

      PLLUM.configuration = custom_config
      expect(PLLUM.configuration.request_timeout).to eq(300)
    end
  end
end