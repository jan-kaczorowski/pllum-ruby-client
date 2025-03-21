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
        model: options[:model] || "pllum-12b-chat",
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
    def send(message, **options, &block)
      request_options = @config.merge(options)
      
      # If we already have a chat_id, continue the chat
      if @chat_id
        response_info = @client.continue_chat(
          chat_id: @chat_id,
          prompt: message,
          model: request_options[:model],
          temperature: request_options[:temperature],
          top_p: request_options[:top_p],
          auth_mode: request_options[:auth_mode],
          &block
        )
      else
        # Otherwise, start a new chat
        response_info = @client.new_chat(
          prompt: message,
          model: request_options[:model],
          temperature: request_options[:temperature],
          top_p: request_options[:top_p],
          auth_mode: request_options[:auth_mode],
          &block
        )
      end
      
      # Update conversation state
      @chat_id = response_info[:chat_id]
      @log_id = response_info[:log_id]
      
      # Add to history - we'll collect the response in streaming mode
      # or non-streaming mode based on the block
      response_text = ""
      if block_given?
        # If we used streaming, we need to create a wrapper block to capture the text
        wrapper_block = ->(chunk, metadata = nil, is_end = false) {
          if is_end
            # End event - do nothing with metadata here
          else
            # Content chunk
            unless chunk.nil?
              response_text += chunk.to_s
              yield(chunk, metadata, is_end) # Pass to original block
            end
          end
        }
        
        # Re-call the API with our wrapper block
        if @chat_id && @log_id != 0
          @client.continue_chat(
            chat_id: @chat_id,
            prompt: message,
            model: request_options[:model],
            temperature: request_options[:temperature],
            top_p: request_options[:top_p],
            auth_mode: request_options[:auth_mode],
            &wrapper_block
          )
        else
          @client.new_chat(
            prompt: message,
            model: request_options[:model],
            temperature: request_options[:temperature],
            top_p: request_options[:top_p],
            auth_mode: request_options[:auth_mode],
            &wrapper_block
          )
        end
      else
        # For non-streaming mode, we need to manually get the response
        auth_part = request_options[:auth_mode] ? "pllum_12b_auth" : "pllum_12b_no_auth"
        if @chat_id && @log_id != 0
          path = "/api/v1/#{auth_part}/stream/to_chat/#{@chat_id}/#{@log_id}"
        else
          path = "/api/v1/#{auth_part}/stream/new_chat/#{@chat_id}/#{@log_id}"
        end
        response_text = @client.get(path: path)
      end
      
      # Add message and response to history
      @history << { role: "user", content: message }
      @history << { role: "assistant", content: response_text }
      
      response_text
    end
    
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
      last_assistant_message = @history.select { |msg| msg[:role] == "assistant" }.last
      last_assistant_message ? last_assistant_message[:content] : nil
    end
    
    # Reset the conversation by clearing history and IDs
    def reset
      @chat_id = nil
      @log_id = nil
      @history = []
    end
    
    # Save conversation state to a hash
    #
    # @return [Hash] The conversation state
    def save_state
      {
        chat_id: @chat_id,
        log_id: @log_id,
        history: @history,
        config: @config
      }
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
  end
end