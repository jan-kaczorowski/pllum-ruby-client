module PLLUM
  class Client
    include PLLUM::HTTP
    
    CONFIG_KEYS = %i[uri_base request_timeout auth_mode].freeze
    attr_reader *CONFIG_KEYS
    
    def initialize(config = {})
      CONFIG_KEYS.each do |key|
        instance_variable_set(
          "@#{key}",
          config[key].nil? ? PLLUM.configuration.send(key) : config[key]
        )
      end
    end
    
    # Starts a new chat with PLLUM and returns the response
    #
    # @param prompt [String] The message to send to the PLLUM AI
    # @param model [String] The PLLUM model to use
    # @param temperature [Float] Controls randomness (0.0 to 1.0)
    # @param top_p [Float] Controls diversity via nucleus sampling (0.0 to 1.0)
    # @param auth_mode [Boolean] Whether to use auth mode (overrides global config)
    # @param block [Block] Optional block for streaming response handling
    # @return [Hash] Contains chat_id and log_id for continuing the chat
    #
    # @example
    #   client = PLLUM::Client.new
    #   # With blocking response
    #   response = client.new_chat(prompt: "Kto jest prezydentem Polski?")
    #
    #   # With streaming response
    #   client.new_chat(prompt: "Kto jest prezydentem Polski?") do |chunk|
    #     print chunk unless chunk.nil?
    #   end
    def new_chat(prompt:, model: "pllum-12b-chat", temperature: 0.5, top_p: 0.5, auth_mode: nil, &block)
      parameters = {
        prompt: prompt,
        model: model,
        temperature: temperature,
        top_p: top_p
      }
      
      # Determine which auth mode to use
      use_auth = auth_mode.nil? ? @auth_mode : auth_mode
      auth_part = use_auth ? "pllum_12b_auth" : "pllum_12b_no_auth"
      
      # First request to start chat and get chat_id
      response = json_post(path: "/api/v1/#{auth_part}/stream/new_chat/", parameters: parameters)
      chat_id = response["chat_id"]
      log_id = response["log_id"]
      
      # Second request to stream the response
      if block_given?
        stream_get(path: "/api/v1/#{auth_part}/stream/new_chat/#{chat_id}/#{log_id}", handler: block)
      else
        get(path: "/api/v1/#{auth_part}/stream/new_chat/#{chat_id}/#{log_id}")
      end
      
      # Return chat_id and log_id for continuation
      { chat_id: chat_id, log_id: log_id }
    end
    
    # Continues an existing chat with PLLUM and returns the response
    #
    # @param chat_id [String] The chat ID from a previous response
    # @param prompt [String] The follow-up message to send
    # @param model [String] The PLLUM model to use
    # @param temperature [Float] Controls randomness (0.0 to 1.0)
    # @param top_p [Float] Controls diversity via nucleus sampling (0.0 to 1.0)
    # @param auth_mode [Boolean] Whether to use auth mode (overrides global config)
    # @param block [Block] Optional block for streaming response handling
    # @return [Hash] Contains chat_id and updated log_id for continuing the chat
    #
    # @example
    #   client = PLLUM::Client.new
    #   # With streaming response
    #   client.continue_chat(
    #     chat_id: "67d2fb583cb909b2f5440e22",
    #     prompt: "A kto był nim przedtem?"
    #   ) do |chunk, metadata, is_end|
    #     if is_end
    #       puts "Chat complete: #{metadata}"
    #     else
    #       print chunk unless chunk.nil?
    #     end
    #   end
    def continue_chat(chat_id:, prompt:, model: "pllum-12b-chat", temperature: 0.5, top_p: 0.5, auth_mode: nil, &block)
      parameters = {
        prompt: prompt,
        model: model,
        temperature: temperature,
        top_p: top_p,
        chat_id: chat_id
      }
      
      # Determine which auth mode to use
      use_auth = auth_mode.nil? ? @auth_mode : auth_mode
      auth_part = use_auth ? "pllum_12b_auth" : "pllum_12b_no_auth"
      
      # First request to continue chat and get updated log_id
      response = json_post(path: "/api/v1/#{auth_part}/stream/to_chat/", parameters: parameters)
      log_id = response["log_id"]
      
      # Second request to stream the response
      if block_given?
        stream_get(path: "/api/v1/#{auth_part}/stream/to_chat/#{chat_id}/#{log_id}", handler: block)
      else
        get(path: "/api/v1/#{auth_part}/stream/to_chat/#{chat_id}/#{log_id}")
      end
      
      # Return chat_id and log_id for further continuation
      { chat_id: chat_id, log_id: log_id }
    end
  end
end