module PLLUM
  # Manages a conversation with the PLLUM AI service
  # A conversation consists of multiple messages exchanged with the AI
  class Conversation
    attr_reader :chat_id, :log_id, :history, :client, :config

    # Initialize a new conversation
    #
    # @param client [PLLUM::Client] The client to use for API requests
    # @param options [Hash] Additional options for the conversation
    # @option options [String] :chat_id Existing chat_id to continue a conversation
    # @option options [Integer] :log_id Existing log_id to continue a conversation
    # @option options [Boolean] :auth_mode Whether to use auth mode for this conversation
    # @option options [String] :model The model to use for this conversation
    # @option options [Float] :temperature Controls randomness (0.0 to 1.0)
    # @option options [Float] :top_p Controls diversity via nucleus sampling (0.0 to 1.0)
    def initialize(client: nil, **options)
      @client = client || PLLUM::Client.new
      @chat_id = options[:chat_id]
      @log_id = options[:log_id]
      @history = []
      @config = {
        auth_mode: options[:auth_mode],
        model: options[:model] || 'pllum-12b-chat',
        temperature: options[:temperature] || 0.5,
        top_p: options[:top_p] || 0.5
      }
    end

    # Send a message to the PLLUM AI and get a response
    #
    # @param message [String] The message to send
    # @param options [Hash] Additional options for this specific request
    # @option options [Boolean] :auth_mode Override auth_mode for this request
    # @option options [String] :model Override model for this request
    # @option options [Float] :temperature Override temperature for this request
    # @option options [Float] :top_p Override top_p for this request
    # @param block [Block] Optional block for streaming response handling
    # @return [String] The AI's response text
    def send_message(message, **options, &block)
      request_options = @config.merge(options)
      response_text = ''

      if block_given?
        # For streaming, we need to capture the text while yielding chunks
        wrapper_block = create_wrapper_block(response_text, &block)
        response_info = make_api_request(message, request_options, &wrapper_block)
      else
        # For non-streaming mode, make request and then fetch the response
        response_info = make_api_request(message, request_options)
        response_text = fetch_response_directly(request_options)
      end

      update_conversation_state(response_info)
      update_history(message, response_text)
      response_text
    end

    # Alias for backward compatibility
    alias send send_message

    # Get the entire conversation history
    #
    # @return [Array<Hash>] The conversation history with role and content keys
    def messages
      @history
    end

    # Get the latest assistant response
    #
    # @return [String] The last assistant response or nil if none exists
    def last_response
      last_assistant_message = @history.select { |msg| msg[:role] == 'assistant' }.last
      last_assistant_message ? last_assistant_message[:content] : nil
    end

    # Get conversation state info as hash
    #
    # @return [Hash] The conversation state
    def state_info
      {
        chat_id: @chat_id,
        log_id: @log_id,
        history: @history,
        config: @config
      }
    end

    # Reset the conversation by clearing history and IDs
    def reset
      @chat_id = nil
      @log_id = nil
      @history = []
    end

    # Load conversation state from a hash
    #
    # @param state [Hash] The conversation state to load
    def load_state(state)
      @chat_id = state[:chat_id]
      @log_id = state[:log_id]
      @history = state[:history] || []
      @config = state[:config] || @config
    end

    private

    # Makes the initial API request to either continue or start a chat
    def make_api_request(message, request_options, &block)
      if @chat_id
        continue_existing_chat(message, request_options, &block)
      else
        start_new_chat(message, request_options, &block)
      end
    end

    # Start a new chat with the PLLUM API
    def start_new_chat(message, request_options, &block)
      @client.new_chat(
        prompt: message,
        model: request_options[:model],
        temperature: request_options[:temperature],
        top_p: request_options[:top_p],
        auth_mode: request_options[:auth_mode],
        &block
      )
    end

    # Continue an existing chat with the PLLUM API
    def continue_existing_chat(message, request_options, &block)
      @client.continue_chat(
        chat_id: @chat_id,
        prompt: message,
        model: request_options[:model],
        temperature: request_options[:temperature],
        top_p: request_options[:top_p],
        auth_mode: request_options[:auth_mode],
        &block
      )
    end

    # Updates the conversation state with new chat_id and log_id
    def update_conversation_state(response_info)
      @chat_id = response_info[:chat_id]
      @log_id = response_info[:log_id]
    end

    # Creates a wrapper block that captures the text while passing chunks to the original block
    def create_wrapper_block(response_text)
      lambda do |chunk, metadata = nil, is_end = false|
        unless is_end || chunk.nil?
          response_text << chunk.to_s
          yield(chunk, metadata, is_end) # Pass to original block
        end
      end
    end

    # Fetches the response directly for non-streaming mode
    def fetch_response_directly(request_options)
      auth_part = request_options[:auth_mode] ? 'pllum_12b_auth' : 'pllum_12b_no_auth'
      endpoint = @chat_id && @log_id != 0 ? 'to_chat' : 'new_chat'
      path = "/api/v1/#{auth_part}/stream/#{endpoint}/#{@chat_id}/#{@log_id}"
      @client.get(path: path)
    end

    # Updates the conversation history with the user message and AI response
    def update_history(message, response_text)
      @history << { role: 'user', content: message }
      @history << { role: 'assistant', content: response_text }
    end
  end
end
