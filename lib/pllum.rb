require "faraday"
require "json"
require "event_stream_parser"
require "debug"

require_relative "pllum/version"
require_relative "pllum/configuration"
require_relative "pllum/http"
require_relative "pllum/client"
require_relative "pllum/conversation"

module PLLUM
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class AuthenticationError < Error; end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= PLLUM::Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  # Helper method to create a new conversation
  #
  # @param options [Hash] Options to pass to the Conversation constructor
  # @return [PLLUM::Conversation] A new conversation instance
  def self.conversation(**options)
    PLLUM::Conversation.new(**options)
  end
end
