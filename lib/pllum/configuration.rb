module PLLUM
  class Configuration
    attr_accessor :uri_base, :request_timeout, :auth_mode

    DEFAULT_URI_BASE = 'https://pllum.clarin-pl.eu'.freeze
    DEFAULT_REQUEST_TIMEOUT = 120
    DEFAULT_AUTH_MODE = false

    def initialize
      @uri_base = DEFAULT_URI_BASE
      @request_timeout = DEFAULT_REQUEST_TIMEOUT
      @auth_mode = DEFAULT_AUTH_MODE
    end
  end
end
