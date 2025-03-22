module PLLUM
  module HTTP
    # Performs a GET request to the specified path
    #
    # @param path [String] The path to request
    # @return [String, Hash] The parsed response
    def get(path:)
      response = conn.get(uri(path: path)) do |req|
        req.headers = headers
      end
      parse_response(response.body)
    end

    def json_post(path:, parameters:)
      response = conn.post(uri(path: path)) do |req|
        req.headers = headers.merge({ "Content-Type" => "application/json; charset=UTF-8" })
        req.body = parameters.to_json
      end
      parse_json(response.body)
    end

    def stream_get(path:, handler:)
      parser = EventStreamParser::Parser.new
      buffer = ""

      conn.get(uri(path: path)) do |req|
        req.headers = streaming_headers
        req.options.on_data = proc do |chunk, _bytes, env|
          verify_response_status(env)
          process_chunk(chunk, parser, buffer, handler)
        end
      end
    end

    private

    def streaming_headers
      headers.merge({
                      "Accept" => "*/*",
                      "Accept-Charset" => "UTF-8"
                    })
    end

    def verify_response_status(env)
      return unless env && env.status != 200

      raise_error = Faraday::Response::RaiseError.new
      raise_error.on_complete(env)
    end

    def process_chunk(chunk, parser, buffer, handler)
      chunk = ensure_utf8(chunk)

      begin
        parser.feed(chunk) { |event_type, data| handle_event(event_type, data, handler) }
      rescue StandardError => e
        handle_parser_error(e, chunk, buffer, handler)
      end
    end

    def ensure_utf8(text)
      text.respond_to?(:force_encoding) ? text.force_encoding("UTF-8") : text
    end

    def handle_event(event_type, data, handler)
      data = ensure_utf8(data)

      case event_type
      when "new_message"
        handler.call(data) unless data.empty?
      when "end_event"
        process_end_event(data, handler)
      end
    end

    def process_end_event(data, handler)
      json_string = convert_python_to_json(data)

      begin
        json_data = JSON.parse(json_string)
        handler.call(nil, json_data, true)
      rescue JSON::ParserError => e
        puts "Warning: Error parsing end_event JSON: #{e.message}"
        puts "Attempted to parse: #{json_string.inspect}"
        extract_fallback_data(data, handler)
      end
    end

    def convert_python_to_json(data)
      data.gsub("'", '"')
          .gsub(/\bTrue\b/, "true")
          .gsub(/\bFalse\b/, "false")
          .gsub(/\bNone\b/, "null")
    end

    def extract_fallback_data(data, handler)
      chat_id_match = data.match(/'chat_id':\s*'([^']+)'/)
      log_id_match = data.match(/'log_id':\s*'([^']+)'/)

      fallback_data = {
        "chat_id" => chat_id_match ? chat_id_match[1] : nil,
        "log_id" => log_id_match ? log_id_match[1] : nil,
        "raw_data" => data
      }

      handler.call(nil, fallback_data, true)
    rescue StandardError => e
      puts "Warning: Could not extract data with regex: #{e.message}"
      handler.call(nil, { "raw_data" => data }, true)
    end

    def handle_parser_error(error, chunk, buffer, handler)
      puts "Warning: Error parsing stream data: #{error.message}"
      buffer << chunk

      if buffer.include?("event: end_event")
        process_buffered_end_event(buffer, handler)
      else
        process_buffered_message(buffer, handler)
      end
    end

    def process_buffered_end_event(buffer, handler)
      if (end_event_match = buffer.match(/data:\s*(\{.*?\})/m))
        end_data = end_event_match[1]
        json_string = convert_python_to_json(end_data)

        begin
          json_data = JSON.parse(json_string)
          handler.call(nil, json_data, true)
          buffer.clear
        rescue JSON::ParserError => e
          puts "Warning: Could not parse end_event JSON: #{e.message}"
          process_end_event_fallback(end_data, buffer, handler)
        end
      else
        handler.call(nil, { "raw_data" => buffer }, true)
        buffer.clear
      end
    rescue StandardError => e
      puts "Warning: Error handling buffered data: #{e.message}"
      handler.call(buffer, nil, false)
    end

    def process_end_event_fallback(end_data, buffer, handler)
      chat_id_match = end_data.match(/'chat_id':\s*'([^']+)'/)
      log_id_match = end_data.match(/'log_id':\s*'([^']+)'/)

      fallback_data = {
        "chat_id" => chat_id_match ? chat_id_match[1] : nil,
        "log_id" => log_id_match ? log_id_match[1] : nil,
        "raw_data" => end_data
      }

      handler.call(nil, fallback_data, true)
      buffer.clear
    end

    def process_buffered_message(buffer, handler)
      lines = buffer.split("\n")
      return unless lines.size > 3 # Enough for an SSE message

      handler.call(lines.join, nil, false)
      buffer.clear
    end

    def parse_json(response)
      return unless response

      # Ensure the response is UTF-8 encoded
      response = response.force_encoding("UTF-8") if response.respond_to?(:force_encoding)

      JSON.parse(response)
    rescue JSON::ParserError
      response
    end

    def parse_response(response)
      parse_json(response) || response
    end

    def conn
      Faraday.new do |f|
        f.options[:timeout] = @request_timeout || PLLUM.configuration.request_timeout
        f.response :raise_error
      end
    end

    def uri(path:)
      base = @uri_base || PLLUM.configuration.uri_base
      File.join(base, path)
    end

    def headers
      {
        "Accept" => "application/json",
        "Accept-Language" => "pl",
        "Cache-Control" => "no-cache",
        "Origin" => PLLUM.configuration.uri_base,
        "Pragma" => "no-cache",
        "Content-Type" => "application/json; charset=UTF-8"
      }
    end
  end
end
