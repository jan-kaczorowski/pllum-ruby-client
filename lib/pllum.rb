require 'faraday'
require 'json'
require 'event_stream_parser'

require_relative 'pllum/version'
require_relative 'pllum/configuration'
require_relative 'pllum/http'
require_relative 'pllum/client'

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
end
