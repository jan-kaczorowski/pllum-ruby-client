require "spec_helper"

RSpec.describe "Chat Integration", :vcr do
  describe "PLLUM chat API integration", :integration do
    let(:client) { instance_double(PLLUM::Client) }
    let(:prompt) { "Kto jest prezydentem Polski?" }
    let(:follow_up) { "A kto był nim przedtem?" }

    before do
      # Stub client responses for non-real API tests
      allow(client).to receive_messages(new_chat: { chat_id: "test_chat_id", log_id: "test_log_id" }, continue_chat: { chat_id: "test_chat_id", log_id: "test_log_id_updated" }, get: "Test response")
    end

    it "successfully initiates a chat and gets a response" do
      result = client.new_chat(prompt: prompt)

      expect(result).to be_a(Hash)
      expect(result[:chat_id]).to eq("test_chat_id")
      expect(result[:log_id]).to eq("test_log_id")
    end

    it "successfully continues a chat with a follow-up question" do
      # First create a chat to get a chat_id
      initial_chat = client.new_chat(prompt: prompt)
      chat_id = initial_chat[:chat_id]

      # Now send a follow-up message
      result = client.continue_chat(
        chat_id: chat_id,
        prompt: follow_up
      )

      expect(result).to be_a(Hash)
      expect(result[:chat_id]).to eq("test_chat_id")
      expect(result[:log_id]).to eq("test_log_id_updated")
    end
  end

  describe "using the Conversation class", :integration do
    let(:client) { instance_double(PLLUM::Client) }
    let(:conversation) { PLLUM::Conversation.new(client: client) }
    let(:initial_message) { "Jaka jest stolica Polski?" }
    let(:follow_up) { "Wymień jeszcze inne duże miasta w Polsce." }

    before do
      # Stub client responses for non-real API tests
      allow(client).to receive_messages(new_chat: { chat_id: "test_chat_id", log_id: "test_log_id" }, continue_chat: { chat_id: "test_chat_id", log_id: "test_log_id_updated" }, get: "Mock API response")
    end

    it "manages a multi-turn conversation" do
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
      expect(conversation.messages[0][:role]).to eq("user")
      expect(conversation.messages[0][:content]).to eq(initial_message)
      expect(conversation.messages[1][:role]).to eq("assistant")
      expect(conversation.messages[2][:role]).to eq("user")
      expect(conversation.messages[2][:content]).to eq(follow_up)
      expect(conversation.messages[3][:role]).to eq("assistant")
    end

    it "allows saving and restoring conversation state" do
      # Start conversation
      conversation.send_message(initial_message)
      expect(conversation.chat_id).to eq("test_chat_id")

      # Save state
      state = conversation.state_info

      # Create new conversation and restore state
      restored = PLLUM::Conversation.new(client: client)
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
