require 'spec_helper'

RSpec.describe PLLUM::Configuration do
  describe 'initialization' do
    let(:config) { described_class.new }

    it 'sets default values' do
      expect(config.uri_base).to eq(PLLUM::Configuration::DEFAULT_URI_BASE)
      expect(config.request_timeout).to eq(PLLUM::Configuration::DEFAULT_REQUEST_TIMEOUT) 
      expect(config.auth_mode).to eq(PLLUM::Configuration::DEFAULT_AUTH_MODE)
    end
  end

  describe 'global configuration' do
    after do
      # Reset to defaults after each test
      PLLUM.configuration = PLLUM::Configuration.new
    end

    it 'allows setting global configuration options' do
      PLLUM.configure do |config|
        config.uri_base = 'https://custom-pllum.example.com'
        config.request_timeout = 240
        config.auth_mode = true
      end

      expect(PLLUM.configuration.uri_base).to eq('https://custom-pllum.example.com')
      expect(PLLUM.configuration.request_timeout).to eq(240)
      expect(PLLUM.configuration.auth_mode).to eq(true)
    end

    it 'allows partial configuration updates' do
      PLLUM.configure do |config|
        config.uri_base = 'https://another-pllum.example.com'
      end

      expect(PLLUM.configuration.uri_base).to eq('https://another-pllum.example.com')
      expect(PLLUM.configuration.request_timeout).to eq(PLLUM::Configuration::DEFAULT_REQUEST_TIMEOUT)
      expect(PLLUM.configuration.auth_mode).to eq(PLLUM::Configuration::DEFAULT_AUTH_MODE)
    end
  end
end