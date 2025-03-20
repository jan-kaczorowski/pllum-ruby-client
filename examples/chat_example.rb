#!/usr/bin/env ruby
# Example of using the PLLUM Ruby client

require 'pllum'

# Configure the client (optional)
PLLUM.configure do |config|
  config.request_timeout = 180 # Longer timeout for demonstration
  config.auth_mode = false     # Default is no_auth mode
end

# Initialize client
client = PLLUM::Client.new

puts "Example 1: Starting a new chat with no_auth mode (default)..."
puts "Initial prompt: Kto jest prezydentem Polski?"

# Start a new chat with streaming response using no_auth mode (default)
chat_info = client.new_chat(prompt: "Kto jest prezydentem Polski?") do |chunk|
  # Make sure the output is properly encoded
  if chunk && !chunk.nil?
    chunk = chunk.force_encoding("UTF-8") if chunk.respond_to?(:force_encoding)
    print chunk
  end
end

puts "\n\nChat ID: #{chat_info[:chat_id]}"
puts "Log ID: #{chat_info[:log_id]}"

puts "\nContinuing chat with follow-up question (still using no_auth)..."
puts "Follow-up: A kto był nim przedtem?"

# Continue the chat with a follow-up question
continue_info = client.continue_chat(
  chat_id: chat_info[:chat_id],
  prompt: "A kto był nim przedtem?"
) do |chunk, metadata, is_end|
  if is_end
    puts "\nMetadata from end event: #{metadata}"
  else
    if chunk && !chunk.nil?
      chunk = chunk.force_encoding("UTF-8") if chunk.respond_to?(:force_encoding)
      print chunk
    end
  end
end

puts "\nUpdated Log ID: #{continue_info[:log_id]}"
puts "First chat complete!"

# ------------------------------------------------------------
puts "\n\nExample 2: Starting a new chat with auth mode (override)..."
puts "Initial prompt: Jaka jest stolica Polski?"

# Override auth_mode for this specific call
chat_info_auth = client.new_chat(
  prompt: "Jaka jest stolica Polski?", 
  auth_mode: true
) do |chunk|
  if chunk && !chunk.nil?
    chunk = chunk.force_encoding("UTF-8") if chunk.respond_to?(:force_encoding)
    print chunk
  end
end

puts "\n\nChat ID: #{chat_info_auth[:chat_id]}"
puts "Log ID: #{chat_info_auth[:log_id]}"

puts "\nContinuing chat with follow-up question (using auth mode)..."
puts "Follow-up: Jakie są inne ważne miasta w Polsce?"

# Continue the chat with auth mode
continue_info_auth = client.continue_chat(
  chat_id: chat_info_auth[:chat_id],
  prompt: "Jakie są inne ważne miasta w Polsce?",
  auth_mode: true
) do |chunk, metadata, is_end|
  if is_end
    puts "\nMetadata from end event: #{metadata}"
  else
    if chunk && !chunk.nil?
      chunk = chunk.force_encoding("UTF-8") if chunk.respond_to?(:force_encoding)
      print chunk
    end
  end
end

puts "\nUpdated Log ID: #{continue_info_auth[:log_id]}"
puts "Second chat complete!"