require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock

  # Filter sensitive information
  config.filter_sensitive_data("<PLLUM_API_BASE>") { PLLUM.configuration.uri_base }

  # Configure VCR to ignore streaming requests
  config.ignore_request do |request|
    request.uri.include?("/stream/")
  end

  # Allow connecting to localhost
  config.ignore_localhost = true

  # Only allow recorded requests to be replayed
  config.allow_http_connections_when_no_cassette = false

  # Record new requests when cassettes become out of date
  config.default_cassette_options = {
    record: :once,
    match_requests_on: %i[method uri body]
  }
end
