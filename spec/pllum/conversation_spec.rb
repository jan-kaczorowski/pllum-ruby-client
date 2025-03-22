require 'spec_helper'

RSpec.describe PLLUM::Conversation do
  let(:client) { instance_double(PLLUM::Client) }
  let(:conversation) { build(:conversation, client: client) }
  let(:existing_conversation) { build(:conversation, :with_existing_chat, client: client) }
  let(:conversation_with_history) { build(:conversation, :with_history, client: client) }

  describe 'initialization' do
    context 'with default parameters' do
      it 'initializes with defaults' do
        # When no client is provided, it should create a new one
        conv = PLLUM::Conversation.new
        expect(conv.client).to be_a(PLLUM::Client)
        expect(conv.chat_id).to be_nil
        expect(conv.log_id).to be_nil
        expect(conv.history).to eq([])
        expect(conv.config[:model]).to eq(PLLUM::Client::DEFAULT_MODEL)
        expect(conv.config[:temperature]).to eq(PLLUM::Client::DEFAULT_TEMPERATURE)
        expect(conv.config[:top_p]).to eq(PLLUM::Client::DEFAULT_TOP_P)
      end
    end

    context 'with custom parameters' do
      let(:custom_conversation) { 
        build(:conversation, :with_custom_config, model: 'custom-model', temperature: 0.7, top_p: 0.8) 
      }

      it 'accepts custom configuration' do
        expect(custom_conversation.config[:model]).to eq('custom-model')
        expect(custom_conversation.config[:temperature]).to eq(0.7)
        expect(custom_conversation.config[:top_p]).to eq(0.8)
      end
    end

    context 'with existing chat' do
      it 'accepts chat_id and log_id' do
        expect(existing_conversation.chat_id).not_to be_nil
        expect(existing_conversation.log_id).not_to be_nil
      end
    end
  end

  describe '#send_message' do
    let(:message) { 'Test message' }
    let(:response_text) { 'Test response' }
    let(:chat_info) { { chat_id: 'new_chat_id', log_id: 'new_log_id' } }

    context 'when starting a new chat' do
      before do
        allow(client).to receive(:new_chat).and_return(chat_info)
        allow(client).to receive(:get).and_return(response_text)
      end

      it 'starts a new chat and updates conversation state' do
        expect(client).to receive(:new_chat).with(
          hash_including(prompt: message)
        )

        response = conversation.send_message(message)
        
        expect(response).to eq(response_text)
        expect(conversation.chat_id).to eq('new_chat_id')
        expect(conversation.log_id).to eq('new_log_id')
        expect(conversation.history).to include(
          { role: 'user', content: message },
          { role: 'assistant', content: response_text }
        )
      end

      it 'supports streaming mode with a block' do
        chunks = []
        
        # Properly stub the client's new_chat method to capture and call the block
        expect(client).to receive(:new_chat) do |*args, **kwargs, &block|
          # Make sure a block is provided
          expect(block).to be_a(Proc)
          
          # Call the provided block to simulate streaming
          block.call("Chunk 1")
          block.call("Chunk 2")
          
          # Return the expected result
          chat_info
        end

        # No need to stub get when streaming
        allow(client).to receive(:get)

        conversation.send_message(message) do |chunk, _metadata, _is_end|
          chunks << chunk unless chunk.nil?
        end

        expect(chunks).to eq(["Chunk 1", "Chunk 2"])
        expect(conversation.chat_id).to eq('new_chat_id')
        expect(conversation.log_id).to eq('new_log_id')
      end
    end

    context 'when continuing an existing chat' do
      let(:existing_chat_id) { 'existing_chat_id' }
      let(:existing_log_id) { 'existing_log_id' }
      let(:continue_info) { { chat_id: existing_chat_id, log_id: 'updated_log_id' } }

      before do
        allow(client).to receive(:continue_chat).and_return(continue_info)
        allow(client).to receive(:get).and_return(response_text)
      end

      it 'continues an existing chat and updates conversation state' do
        conversation = build(:conversation, client: client, chat_id: existing_chat_id, log_id: existing_log_id)

        expect(client).to receive(:continue_chat).with(
          hash_including(chat_id: existing_chat_id, prompt: message)
        )

        response = conversation.send_message(message)
        
        expect(response).to eq(response_text)
        expect(conversation.chat_id).to eq(existing_chat_id)
        expect(conversation.log_id).to eq('updated_log_id')
        expect(conversation.history).to include(
          { role: 'user', content: message },
          { role: 'assistant', content: response_text }
        )
      end
    end

    context 'with request option overrides' do
      let(:custom_model) { 'custom-model' }
      let(:custom_temp) { 0.9 }
      let(:custom_top_p) { 0.95 }

      it 'allows overriding request options for a single message' do
        expect(client).to receive(:new_chat).with(
          hash_including(
            prompt: message,
            model: custom_model,
            temperature: custom_temp,
            top_p: custom_top_p
          )
        ).and_return(chat_info)

        allow(client).to receive(:get).and_return(response_text)

        conversation.send_message(
          message, 
          model: custom_model, 
          temperature: custom_temp, 
          top_p: custom_top_p
        )
      end
    end
  end

  describe '#messages' do
    it 'returns the conversation history' do
      expect(conversation_with_history.messages).to be_an(Array)
      expect(conversation_with_history.messages.size).to eq(2)
      expect(conversation_with_history.messages.first[:role]).to eq('user')
      expect(conversation_with_history.messages.last[:role]).to eq('assistant')
    end
  end

  describe '#last_response' do
    it 'returns the last assistant response' do
      expect(conversation_with_history.last_response).to eq('Assistant response 1')
    end

    it 'returns nil when there are no assistant responses' do
      expect(conversation.last_response).to be_nil
    end
  end

  describe '#state_info' do
    it 'returns the conversation state as a hash' do
      state = existing_conversation.state_info
      expect(state).to be_a(Hash)
      expect(state[:chat_id]).to eq(existing_conversation.chat_id)
      expect(state[:log_id]).to eq(existing_conversation.log_id)
      expect(state[:history]).to eq(existing_conversation.history)
      expect(state[:config]).to eq(existing_conversation.config)
    end
  end

  describe '#reset' do
    it 'resets the conversation state' do
      conversation = build(:conversation, :with_existing_chat, :with_history)
      
      expect(conversation.chat_id).not_to be_nil
      expect(conversation.log_id).not_to be_nil
      expect(conversation.history).not_to be_empty
      
      conversation.reset
      
      expect(conversation.chat_id).to be_nil
      expect(conversation.log_id).to be_nil
      expect(conversation.history).to be_empty
    end
  end

  describe '#load_state' do
    let(:state) do
      {
        chat_id: 'saved_chat_id',
        log_id: 'saved_log_id',
        history: [
          { role: 'user', content: 'Saved message' },
          { role: 'assistant', content: 'Saved response' }
        ],
        config: {
          model: 'saved-model',
          temperature: 0.3,
          top_p: 0.4,
          auth_mode: true
        }
      }
    end

    it 'loads conversation state from a hash' do
      conversation.load_state(state)
      
      expect(conversation.chat_id).to eq('saved_chat_id')
      expect(conversation.log_id).to eq('saved_log_id')
      expect(conversation.history).to eq(state[:history])
      expect(conversation.config).to eq(state[:config])
    end

    it 'handles partial state information' do
      conversation.load_state(chat_id: 'partial_chat_id')
      
      expect(conversation.chat_id).to eq('partial_chat_id')
      expect(conversation.log_id).to be_nil
      expect(conversation.history).to be_empty
    end
  end
end