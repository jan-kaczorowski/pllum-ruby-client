require 'spec_helper'

RSpec.describe 'Chat Integration', :vcr do
  # Skip these tests by default as they require real API credentials
  # Run these tests with: rspec spec/integration/chat_integration_spec.rb --tag integration
  describe 'PLLUM chat API integration', :integration do
    let(:client) { PLLUM::Client.new }
    let(:prompt) { 'Kto jest prezydentem Polski?' }
    let(:follow_up) { 'A kto był nim przedtem?' }

    # Configure VCR to allow real API requests for this test
    around do |example|
      VCR.use_cassette('pllum_chat_integration', record: :new_episodes) do
        example.run
      end
    end

    xit 'successfully initiates a chat and gets a response' do
      result = nil

      # Using the non-streaming version for easier testing
      expect {
        result = client.new_chat(prompt: prompt)
      }.not_to raise_error

      expect(result).to be_a(Hash)
      expect(result[:chat_id]).not_to be_nil
      expect(result[:log_id]).not_to be_nil
    end

    xit 'successfully continues a chat with a follow-up question' do
      # First create a chat to get a chat_id
      initial_chat = client.new_chat(prompt: prompt)
      chat_id = initial_chat[:chat_id]
      
      # Now send a follow-up message
      result = nil
      
      expect {
        result = client.continue_chat(
          chat_id: chat_id, 
          prompt: follow_up
        )
      }.not_to raise_error
      
      expect(result).to be_a(Hash)
      expect(result[:chat_id]).to eq(chat_id)
      expect(result[:log_id]).not_to be_nil
    end
  end

  describe 'using the Conversation class', :integration do
    let(:conversation) { PLLUM::Conversation.new }
    let(:initial_message) { 'Jaka jest stolica Polski?' }
    let(:follow_up) { 'Wymień jeszcze inne duże miasta w Polsce.' }

    around do |example|
      VCR.use_cassette('pllum_conversation_integration', record: :new_episodes) do
        example.run
      end
    end

    it 'manages a multi-turn conversation' do
      # Send initial message
      response1 = conversation.send_message(initial_message)
      expect(response1).not_to be_nil
      expect(response1).to be_a(String)
      expect(conversation.history.size).to eq(2)
      
      # Send follow-up message
      response2 = conversation.send_message(follow_up)
      expect(response2).not_to be_nil
      expect(response2).to be_a(String)
      expect(conversation.history.size).to eq(4)
      
      # Check history structure
      expect(conversation.messages).to include(
        { role: 'user', content: initial_message },
        { role: 'assistant', content: response1 },
        { role: 'user', content: follow_up },
        { role: 'assistant', content: response2 }
      )
    end

    it 'allows saving and restoring conversation state' do
      # Start conversation
      conversation.send_message(initial_message)
      expect(conversation.chat_id).not_to be_nil
      
      # Save state
      state = conversation.state_info
      
      # Create new conversation and restore state
      restored = PLLUM::Conversation.new
      restored.load_state(state)
      
      # Verify state was properly restored
      expect(restored.chat_id).to eq(conversation.chat_id)
      expect(restored.log_id).to eq(conversation.log_id)
      expect(restored.history).to eq(conversation.history)
      
      # Continue conversation from restored state
      response = restored.send_message(follow_up)
      expect(response).not_to be_nil
      expect(restored.history.size).to eq(4)
    end
  end
end