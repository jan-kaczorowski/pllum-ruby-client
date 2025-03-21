#!/usr/bin/env ruby
# Interactive CLI chat with PLLUM AI using the Conversation class

require_relative '../lib/pllum'
require 'json'
require 'fileutils'

# Configure the client
PLLUM.configure do |config|
  config.request_timeout = 300 # Longer timeout for interactive sessions
  config.auth_mode = false
end

# Setup colors for terminal output
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def blue
    colorize(34)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def red
    colorize(31)
  end
end

# Banner
puts "\n#{'=' * 60}"
puts 'PLLUM Interactive Chat'.center(60)
puts 'Type your messages and chat with PLLUM AI'.center(60)
puts "Type 'quit', 'exit', or press Ctrl+C to end the session".center(60)
puts "Type 'save' to save the conversation".center(60)
puts "Type 'load <filename>' to load a saved conversation".center(60)
puts "#{'=' * 60}\n"

# Create a save directory if it doesn't exist
SAVE_DIR = File.join(Dir.home, '.pllum_chats')
FileUtils.mkdir_p(SAVE_DIR)

# Initialize a new conversation
conversation = PLLUM.conversation

# Save conversation to file
def save_conversation(conversation)
  filename = "pllum_chat_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"
  path = File.join(SAVE_DIR, filename)

  state = conversation.state_info
  File.write(path, JSON.pretty_generate(state))

  puts "Conversation saved to #{path}".green
  filename
end

# Load conversation from file
def load_conversation(filename)
  # Handle full path or just filename
  path = filename.include?('/') ? filename : File.join(SAVE_DIR, filename)

  # If no extension is given, assume .json
  path = "#{path}.json" unless path.end_with?('.json')

  if File.exist?(path)
    state = JSON.parse(File.read(path), symbolize_names: true)
    conversation = PLLUM.conversation
    conversation.load_state(state)
    puts "Conversation loaded from #{path}".green
    conversation
  else
    puts "File not found: #{path}".red
    nil
  end
end

# List saved conversations
def list_saved_conversations
  files = Dir.glob(File.join(SAVE_DIR, '*.json'))
  if files.empty?
    puts 'No saved conversations found'.yellow
    return
  end

  puts 'Saved conversations:'.yellow
  files.each_with_index do |file, index|
    filename = File.basename(file)
    size = File.size(file)
    time = File.mtime(file).strftime('%Y-%m-%d %H:%M:%S')
    puts "#{index + 1}. #{filename} (#{size} bytes, saved on #{time})"
  end
end

# Main chat loop
puts 'Starting new conversation. Type your first message:'.blue
loop do
  print 'You: '.blue
  input = gets.chomp

  # Exit commands
  break if %w[exit quit].include?(input.downcase)

  # Save command
  if input.downcase == 'save'
    save_conversation(conversation)
    next
  end

  # Load command
  if input.downcase.start_with?('load')
    parts = input.split(' ', 2)
    if parts.size < 2
      puts 'Usage: load <filename>'.yellow
      list_saved_conversations
    else
      loaded = load_conversation(parts[1])
      conversation = loaded if loaded
    end
    next
  end

  # List saved conversations
  if input.downcase == 'list'
    list_saved_conversations
    next
  end

  # Help command
  if ['help', '?'].include?(input.downcase)
    puts 'Commands:'.yellow
    puts '  save - Save the current conversation'.yellow
    puts '  load <filename> - Load a saved conversation'.yellow
    puts '  list - List saved conversations'.yellow
    puts '  exit, quit - End the session'.yellow
    puts '  help, ? - Show this help message'.yellow
    next
  end

  # Send message to PLLUM
  print 'PLLUM: '.green
  begin
    conversation.send_message(input) do |chunk, _metadata, is_end|
      print chunk if !is_end && (chunk && !chunk.nil?)
    end
    puts "\n"
  rescue StandardError => e
    puts "\nError: #{e.message}".red
  end
end

puts "\nChat session ended. Goodbye!".blue
