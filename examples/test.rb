#!/usr/bin/env ruby
# Simple test script to verify the PLLUM Conversation class

require_relative '../lib/pllum'

puts '===== PLLUM Conversation Test ====='

# Create a new conversation
conversation = PLLUM::Conversation.new

# Test the methods
puts 'Testing conversation methods:'
puts "- chat_id: #{conversation.chat_id.inspect}"
puts "- log_id: #{conversation.log_id.inspect}"
puts "- history: #{conversation.history.inspect}"
puts "- config: #{conversation.config.inspect}"

# Try saving and loading state
state = conversation.save_state
puts "\nSaved state: #{state.inspect}"

# Reset and load
conversation.reset
puts "\nAfter reset:"
puts "- chat_id: #{conversation.chat_id.inspect}"
puts "- history: #{conversation.history.inspect}"

conversation.load_state(state)
puts "\nAfter load_state:"
puts "- chat_id: #{conversation.chat_id.inspect}"
puts "- history: #{conversation.history.inspect}"

puts "\nTest completed successfully!"
