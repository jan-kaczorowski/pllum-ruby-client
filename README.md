# PLLUM Ruby Client

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

### Starting a New Chat

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

### Continuing a Chat

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

### Auth Mode

PLLUM API supports two modes: `auth` and `no_auth`. You can configure the default mode globally or override it per request:

```ruby
# Set globally
PLLUM.configure do |config|
  config.auth_mode = true # Use auth mode by default
end

# Override per request
client.new_chat(
  prompt: "Kto jest prezydentem Polski?",
  auth_mode: false # Override to use no_auth mode for this request
)

client.continue_chat(
  chat_id: "67d2fb583cb909b2f5440e22",
  prompt: "A kto był nim przedtem?",
  auth_mode: true # Override to use auth mode for this request
)
```

### Additional Parameters

You can adjust the model's output by providing these parameters:

```ruby
client.new_chat(
  prompt: "Kto jest prezydentem Polski?",
  model: "pllum-12b-chat",  # Model to use
  temperature: 0.7,         # Controls randomness (0.0 to 1.0)
  top_p: 0.9                # Controls diversity (0.0 to 1.0)
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).