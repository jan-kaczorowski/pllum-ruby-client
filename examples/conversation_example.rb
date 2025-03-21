#!/usr/bin/env ruby
# Example of using the PLLUM Ruby client with the Conversation class for continuous chat

require 'pllum'

# Configure the client (optional)
PLLUM.configure do |config|
  config.request_timeout = 180 # Longer timeout for demonstration
  config.auth_mode = false     # Default is no_auth mode
end

puts "PLLUM Conversation Example"
puts "=========================="
puts

# Create a new conversation
conversation = PLLUM.conversation

# Function to display streaming responses nicely
def stream_response(conversation, message)
  print "You: #{message}\nPLLUM: "
  
  conversation.send(message) do |chunk, _metadata, is_end|
    unless is_end
      print chunk if chunk && !chunk.nil?
    end
  end
  
  puts "\n"
end

# Start conversation with an initial question
stream_response(conversation, "Kto jest prezydentem Polski?")

# Continue with follow-up questions
stream_response(conversation, "A kto był nim przedtem?")
stream_response(conversation, "Wymień jeszcze kilku poprzednich prezydentów.")

# Show conversation history
puts "Conversation History:"
puts "===================="
conversation.messages.each do |message|
  role = message[:role] == "user" ? "You" : "PLLUM"
  content = message[:content]
  puts "#{role}: #{content}"
end

# Save conversation state
state = conversation.save_state
puts "\nSaved conversation state with chat_id: #{state[:chat_id]}"

# Create a new conversation with the saved state
puts "\nRestoring conversation from saved state..."
restored_conversation = PLLUM.conversation
restored_conversation.load_state(state)

# Continue the conversation from where we left off
stream_response(restored_conversation, "Kiedy Andrzej Duda został prezydentem?")

puts "Conversation completed!"