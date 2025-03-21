# PLLuM Ruby Client

A minimal Ruby client for interacting with the [PLLUM](https://pllum.clarin-pl.eu/) Polish language model API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pllum'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install pllum
```

## Usage

### Configuration

Configure the client with your preferred settings:

```ruby
PLLUM.configure do |config|
  config.uri_base = "https://pllum.clarin-pl.eu" # Default API endpoint
  config.request_timeout = 120 # Timeout in seconds
  config.auth_mode = false # Whether to use the auth mode (default: false)
end
```

### Using the Conversation Interface (Recommended)

The Conversation interface provides an easy way to maintain continuous conversations with PLLUM:

```ruby
require 'pllum'

# Create a new conversation
conversation = PLLUM.conversation

# Send the first message and stream the response
conversation.send_message("Kto jest prezydentem Polski?") do |chunk, metadata, is_end|
  print chunk unless chunk.nil? || is_end
end

# Continue the conversation with follow-up questions automatically
conversation.send_message("A kto był nim przedtem?") do |chunk, metadata, is_end|
  print chunk unless chunk.nil? || is_end
end

# The Conversation class maintains history
conversation.messages
# => [{role: "user", content: "Kto jest prezydentem Polski?"}, 
#     {role: "assistant", content: "Prezydentem Polski jest Andrzej Duda."}, 
#     {role: "user", content: "A kto był nim przedtem?"}, 
#     {role: "assistant", content: "Przed Andrzejem Dudą, urząd Prezydenta Rzeczypospolitej Polskiej pełnił Bronisław Komorowski."}]

# Save conversation state for later use
state = conversation.state_info

# Later, restore the conversation
restored = PLLUM.conversation
restored.load_state(state)

# Continue where you left off
restored.send_message("Kiedy Andrzej Duda został prezydentem?")
```

See the `examples/interactive_chat.rb` file for a complete interactive chat application.

#### Starting a New Chat

```ruby
require 'pllum'

client = PLLUM::Client.new

# Without streaming
chat_info = client.new_chat(prompt: "Kto jest prezydentem Polski?")
# => { chat_id: "67d2fb583cb909b2f5440e22", log_id: 0 }

# With streaming
client.new_chat(prompt: "Kto jest prezydentem Polski?") do |chunk|
  print chunk unless chunk.nil?
end
# Streaming output: "Prezydentem Polski jest Andrzej Duda."
```

#### Continuing a Chat

```ruby
# Continue the chat with a follow-up question
continue_info = client.continue_chat(
  chat_id: chat_info[:chat_id],
  prompt: "A kto był nim przedtem?"
) do |chunk, metadata, is_end|
  if is_end
    puts "\nChat complete!"
  else
    print chunk unless chunk.nil?
  end
end
# Streaming output: "Przed Andrzejem Dudą, urząd Prezydenta Rzeczypospolitej Polskiej pełnił Bronisław Komorowski."
# Chat complete!
```

### Additional Parameters

You can adjust the model's output by providing these parameters:

```ruby
# With Client API
client.new_chat(
  prompt: "Kto jest prezydentem Polski?",
  model: "pllum-12b-chat",  # Model to use
  temperature: 0.7,         # Controls randomness (0.0 to 1.0)
  top_p: 0.9                # Controls diversity (0.0 to 1.0)
)

# With Conversation API
conversation = PLLUM.conversation(
  model: "pllum-12b-chat",
  temperature: 0.7,
  top_p: 0.9
)

# Or override per message
conversation.send_message("Kto jest prezydentem Polski?", temperature: 0.9)
```

## Examples

The repository includes several example scripts:

- `examples/chat_example.rb`: Basic chat example using the Client API
- `examples/conversation_example.rb`: Multi-turn conversation example using the Conversation API
- `examples/interactive_chat.rb`: Interactive CLI chat application with save/load functionality

Run the examples to see PLLUM in action:

```bash
$ ruby examples/interactive_chat.rb
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
