require 'spec_helper'

RSpec.describe PLLUM::Client do
  let(:default_client) { build(:client) }
  let(:auth_client) { build(:client, :with_auth) }
  let(:custom_client) { build(:client, request_timeout: 300, uri_base: 'https://custom-api.example.com') }

  describe 'initialization' do
    it 'uses global configuration by default' do
      expect(default_client.uri_base).to eq(PLLUM::Configuration::DEFAULT_URI_BASE)
      expect(default_client.request_timeout).to eq(PLLUM::Configuration::DEFAULT_REQUEST_TIMEOUT)
      expect(default_client.auth_mode).to eq(PLLUM::Configuration::DEFAULT_AUTH_MODE)
    end

    it 'allows override of configuration options' do
      expect(custom_client.uri_base).to eq('https://custom-api.example.com')
      expect(custom_client.request_timeout).to eq(300)
    end
  end

  describe '#new_chat' do
    let(:prompt) { 'Kto jest prezydentem Polski?' }
    let(:response_body) { { 'chat_id' => 'test_chat_id', 'log_id' => 'test_log_id' }.to_json }
    let(:auth_part) { 'pllum_12b_no_auth' }

    before do
      # Stub the first POST request to /new_chat/
      stub_request(:post, "#{PLLUM::Configuration::DEFAULT_URI_BASE}/api/v1/#{auth_part}/stream/new_chat/")
        .with(
          body: hash_including(
            prompt: prompt,
            model: PLLUM::Client::DEFAULT_MODEL,
            temperature: PLLUM::Client::DEFAULT_TEMPERATURE,
            top_p: PLLUM::Client::DEFAULT_TOP_P
          )
        )
        .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })

      # Stub the GET request to retrieve the response
      stub_request(:get, "#{PLLUM::Configuration::DEFAULT_URI_BASE}/api/v1/#{auth_part}/stream/new_chat/test_chat_id/test_log_id")
        .to_return(status: 200, body: "Test response", headers: { 'Content-Type' => 'text/plain' })
    end

    it 'starts a new chat and returns chat_id and log_id' do
      result = default_client.new_chat(prompt: prompt)
      expect(result).to be_a(Hash)
      expect(result[:chat_id]).to eq('test_chat_id')
      expect(result[:log_id]).to eq('test_log_id')
    end

    context 'with streaming response' do
      it 'handles streaming response with a block' do
        chunks = []
        result = default_client.new_chat(prompt: prompt) do |chunk|
          chunks << chunk unless chunk.nil?
        end

        expect(result).to be_a(Hash)
        expect(result[:chat_id]).to eq('test_chat_id')
        expect(result[:log_id]).to eq('test_log_id')
      end
    end

    context 'with auth mode' do
      let(:auth_part) { 'pllum_12b_auth' }

      before do
        # Re-stub the requests with auth mode path
        stub_request(:post, "#{PLLUM::Configuration::DEFAULT_URI_BASE}/api/v1/#{auth_part}/stream/new_chat/")
          .with(body: hash_including(prompt: prompt))
          .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{PLLUM::Configuration::DEFAULT_URI_BASE}/api/v1/#{auth_part}/stream/new_chat/test_chat_id/test_log_id")
          .to_return(status: 200, body: "Test auth response", headers: { 'Content-Type' => 'text/plain' })
      end

      it 'uses auth mode when configured' do
        result = auth_client.new_chat(prompt: prompt)
        expect(result[:chat_id]).to eq('test_chat_id')
        expect(result[:log_id]).to eq('test_log_id')
      end

      it 'allows overriding auth mode for a specific request' do
        result = default_client.new_chat(prompt: prompt, auth_mode: true)
        expect(result[:chat_id]).to eq('test_chat_id')
        expect(result[:log_id]).to eq('test_log_id')
      end
    end
  end

  describe '#continue_chat' do
    let(:chat_id) { 'existing_chat_id' }
    let(:prompt) { 'A kto był nim przedtem?' }
    let(:response_body) { { 'log_id' => 'new_log_id' }.to_json }
    let(:auth_part) { 'pllum_12b_no_auth' }

    before do
      # Stub the POST request to /to_chat/
      stub_request(:post, "#{PLLUM::Configuration::DEFAULT_URI_BASE}/api/v1/#{auth_part}/stream/to_chat/")
        .with(
          body: hash_including(
            prompt: prompt,
            chat_id: chat_id,
            model: PLLUM::Client::DEFAULT_MODEL,
            temperature: PLLUM::Client::DEFAULT_TEMPERATURE,
            top_p: PLLUM::Client::DEFAULT_TOP_P
          )
        )
        .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })

      # Stub the GET request to retrieve the response
      stub_request(:get, "#{PLLUM::Configuration::DEFAULT_URI_BASE}/api/v1/#{auth_part}/stream/to_chat/#{chat_id}/new_log_id")
        .to_return(status: 200, body: "Continued chat response", headers: { 'Content-Type' => 'text/plain' })
    end

    it 'continues an existing chat and returns updated chat_id and log_id' do
      result = default_client.continue_chat(chat_id: chat_id, prompt: prompt)
      expect(result).to be_a(Hash)
      expect(result[:chat_id]).to eq(chat_id)
      expect(result[:log_id]).to eq('new_log_id')
    end

    context 'with streaming response' do
      it 'handles streaming response with a block' do
        chunks = []
        metadata = nil
        is_end = false

        result = default_client.continue_chat(chat_id: chat_id, prompt: prompt) do |chunk, meta, end_flag|
          chunks << chunk unless chunk.nil?
          metadata = meta if meta
          is_end = end_flag if end_flag
        end

        expect(result).to be_a(Hash)
        expect(result[:chat_id]).to eq(chat_id)
        expect(result[:log_id]).to eq('new_log_id')
      end
    end

    context 'with custom parameters' do
      let(:custom_model) { 'custom-model' }
      let(:custom_temperature) { 0.8 }
      let(:custom_top_p) { 0.9 }

      before do
        # Re-stub the request with custom parameters
        stub_request(:post, "#{PLLUM::Configuration::DEFAULT_URI_BASE}/api/v1/#{auth_part}/stream/to_chat/")
          .with(
            body: hash_including(
              prompt: prompt,
              chat_id: chat_id,
              model: custom_model,
              temperature: custom_temperature,
              top_p: custom_top_p
            )
          )
          .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'accepts custom parameters for the request' do
        result = default_client.continue_chat(
          chat_id: chat_id,
          prompt: prompt,
          model: custom_model,
          temperature: custom_temperature,
          top_p: custom_top_p
        )
        expect(result[:chat_id]).to eq(chat_id)
        expect(result[:log_id]).to eq('new_log_id')
      end
    end
  end
end