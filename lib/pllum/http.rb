module PLLUM
  module HTTP
    def get(path:)
      response = conn.get(uri(path: path)) do |req|
        req.headers = headers
      end
      parse_response(response.body)
    end

    def json_post(path:, parameters:)
      response = conn.post(uri(path: path)) do |req|
        req.headers = headers.merge({ 'Content-Type' => 'application/json; charset=UTF-8' })
        req.body = parameters.to_json
      end
      parse_json(response.body)
    end

    def stream_get(path:, handler:)
      parser = EventStreamParser::Parser.new
      buffer = ''

      conn.get(uri(path: path)) do |req|
        req.headers = headers.merge({
                                      'Accept' => '*/*',
                                      'Accept-Charset' => 'UTF-8'
                                    })
        req.options.on_data = proc do |chunk, _bytes, env|
          if env && env.status != 200
            raise_error = Faraday::Response::RaiseError.new
            raise_error.on_complete(env)
          end

          # Force UTF-8 encoding for the chunk
          chunk = chunk.force_encoding('UTF-8') if chunk.respond_to?(:force_encoding)

          begin
            parser.feed(chunk) do |event_type, data|
              # Force UTF-8 encoding on the data
              data = data.force_encoding('UTF-8') if data.respond_to?(:force_encoding)

              case event_type
              when 'new_message'
                # For messages, we can directly pass the data to the handler
                handler.call(data) unless data.empty?
              when 'end_event'
                # For the end event, we need to parse the Python-style JSON
                # Convert Python-style JSON to valid JSON:
                # 1. Replace single quotes with double quotes
                # 2. Replace Python True/False with JSON true/false
                # 3. Replace Python None with null
                json_string = data.gsub("'", '"')
                                  .gsub(/\bTrue\b/, 'true')
                                  .gsub(/\bFalse\b/, 'false')
                                  .gsub(/\bNone\b/, 'null')

                begin
                  json_data = JSON.parse(json_string)
                  handler.call(nil, json_data, true)
                rescue JSON::ParserError => e
                  puts "Warning: Error parsing end_event JSON: #{e.message}"
                  puts "Attempted to parse: #{json_string.inspect}"
                  # Instead of failing, provide the chat_id and log_id from the data if we can extract them
                  begin
                    # Try to extract values using regex instead of JSON parsing
                    chat_id_match = data.match(/'chat_id':\s*'([^']+)'/)
                    log_id_match = data.match(/'log_id':\s*'([^']+)'/)

                    fallback_data = {
                      'chat_id' => chat_id_match ? chat_id_match[1] : nil,
                      'log_id' => log_id_match ? log_id_match[1] : nil,
                      'raw_data' => data
                    }

                    handler.call(nil, fallback_data, true)
                  rescue StandardError => regex_error
                    puts "Warning: Could not extract data with regex: #{regex_error.message}"
                    # Last resort: return the raw data
                    handler.call(nil, { 'raw_data' => data }, true)
                  end
                end
              end
            end
          rescue StandardError => e
            # If there's an error in the parser, try to handle it gracefully
            puts "Warning: Error parsing stream data: #{e.message}"

            # When the parser fails, it might be due to incomplete data
            # Let's store it in a buffer and try to extract useful information
            buffer += chunk

            # Try to detect if it's an end_event
            if buffer.include?('event: end_event')
              begin
                # Extract the data portion using regex
                if end_event_match = buffer.match(/data:\s*(\{.*?\})/m)
                  end_data = end_event_match[1]

                  # Convert Python-style literals to JSON
                  json_string = end_data.gsub("'", '"')
                                        .gsub(/\bTrue\b/, 'true')
                                        .gsub(/\bFalse\b/, 'false')
                                        .gsub(/\bNone\b/, 'null')

                  begin
                    json_data = JSON.parse(json_string)
                    handler.call(nil, json_data, true)
                    buffer = '' # Clear buffer after successful handling
                  rescue JSON::ParserError => je
                    puts "Warning: Could not parse end_event JSON: #{je.message}"
                    # Try regex extraction as a fallback
                    chat_id_match = end_data.match(/'chat_id':\s*'([^']+)'/)
                    log_id_match = end_data.match(/'log_id':\s*'([^']+)'/)

                    fallback_data = {
                      'chat_id' => chat_id_match ? chat_id_match[1] : nil,
                      'log_id' => log_id_match ? log_id_match[1] : nil,
                      'raw_data' => end_data
                    }

                    handler.call(nil, fallback_data, true)
                    buffer = '' # Clear buffer after handling
                  end
                else
                  # If we couldn't extract data with regex, provide what we have
                  handler.call(nil, { 'raw_data' => buffer }, true)
                  buffer = '' # Clear buffer after handling
                end
              rescue StandardError => regex_error
                puts "Warning: Error handling buffered data: #{regex_error.message}"
                # Last resort: just pass the buffer as text
                handler.call(buffer, nil, false)
              end
            else
              # If it's not an end_event, it might be message data
              # Try to extract complete lines and send them
              lines = buffer.split("\n")
              if lines.size > 3 # Enough for an SSE message
                handler.call(lines.join(''), nil, false)
                buffer = '' # Clear buffer after handling
              end
              # Otherwise keep buffering
            end

            # Don't re-raise the error, try to continue
          end
        end
      end
    end

    private

    def parse_json(response)
      return unless response

      # Ensure the response is UTF-8 encoded
      response = response.force_encoding('UTF-8') if response.respond_to?(:force_encoding)

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
        'Accept' => 'application/json',
        'Accept-Language' => 'pl',
        'Cache-Control' => 'no-cache',
        'Origin' => PLLUM.configuration.uri_base,
        'Pragma' => 'no-cache',
        'Content-Type' => 'application/json; charset=UTF-8'
      }
    end
  end
end
