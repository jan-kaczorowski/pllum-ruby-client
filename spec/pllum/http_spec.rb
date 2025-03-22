require "spec_helper"

RSpec.describe PLLUM::HTTP do
  # Create a test class to include the HTTP module
  let(:http_test_class) do
    Class.new do
      include PLLUM::HTTP

      attr_accessor :uri_base, :request_timeout

      def initialize(uri_base: nil, request_timeout: nil)
        @uri_base = uri_base
        @request_timeout = request_timeout
      end
    end
  end

  let(:http) { http_test_class.new }
  let(:custom_http) { http_test_class.new(uri_base: "https://custom.example.com", request_timeout: 60) }

  describe "#get" do
    let(:path) { "/api/v1/test" }
    let(:response_body) { '{"key": "value"}' }

    before do
      stub_request(:get, "#{PLLUM::Configuration::DEFAULT_URI_BASE}#{path}")
        .to_return(status: 200, body: response_body)
    end

    it "performs a GET request and parses the response" do
      result = http.get(path: path)
      expect(result).to eq({ "key" => "value" })
    end

    it "handles non-JSON responses" do
      stub_request(:get, "#{PLLUM::Configuration::DEFAULT_URI_BASE}#{path}")
        .to_return(status: 200, body: "Plain text response")

      result = http.get(path: path)
      expect(result).to eq("Plain text response")
    end

    it "uses custom base URI when specified" do
      stub_request(:get, "https://custom.example.com#{path}")
        .to_return(status: 200, body: response_body)

      result = custom_http.get(path: path)
      expect(result).to eq({ "key" => "value" })
    end
  end

  describe "#json_post" do
    let(:path) { "/api/v1/test_post" }
    let(:params) { { key: "value", number: 42 } }
    let(:response_body) { '{"status": "success"}' }

    before do
      stub_request(:post, "#{PLLUM::Configuration::DEFAULT_URI_BASE}#{path}")
        .with(
          body: params.to_json,
          headers: { "Content-Type" => "application/json; charset=UTF-8" }
        )
        .to_return(status: 200, body: response_body)
    end

    it "performs a POST request with JSON payload and parses the response" do
      result = http.json_post(path: path, parameters: params)
      expect(result).to eq({ "status" => "success" })
    end
  end

  describe "error handling" do
    let(:path) { "/api/v1/error_test" }

    it "raises Faraday::Error for HTTP errors" do
      stub_request(:get, "#{PLLUM::Configuration::DEFAULT_URI_BASE}#{path}")
        .to_return(status: 404, body: '{"error": "Not found"}')

      expect { http.get(path: path) }.to raise_error(Faraday::Error)
    end

    it "raises Faraday::Error for server errors" do
      stub_request(:get, "#{PLLUM::Configuration::DEFAULT_URI_BASE}#{path}")
        .to_return(status: 500, body: '{"error": "Server error"}')

      expect { http.get(path: path) }.to raise_error(Faraday::Error)
    end
  end

  describe "#stream_get" do
    let(:path) { "/api/v1/stream_test" }

    it "sets up a proper streaming request" do
      chunks = []

      stub = stub_request(:get, "#{PLLUM::Configuration::DEFAULT_URI_BASE}#{path}")
             .with(headers: { "Accept" => "*/*" })
             .to_return(status: 200, body: "data: Chunk 1\n\ndata: Chunk 2\n\nevent: end_event\ndata: {\"status\":\"complete\"}\n\n")

      handler = proc { |chunk, metadata, is_end|
        chunks << [chunk, metadata, is_end] unless chunk.nil? && metadata.nil?
      }

      http.stream_get(path: path, handler: handler)

      expect(stub).to have_been_requested
      # Due to event stream parsing complexity, we won't test the exact chunks here
    end

    it "sets custom timeout for requests" do
      # Verify timeout is set in the Faraday connection
      expect_any_instance_of(Faraday::Connection).to receive(:get) do |instance, *_args|
        expect(instance.options[:timeout]).to eq(60)
        double(Faraday::Response, body: "", headers: {})
      end

      custom_http.stream_get(path: path, handler: proc {})
    end
  end

  describe "parse_json" do
    it "parses valid JSON" do
      result = http.send(:parse_json, '{"key": "value"}')
      expect(result).to eq({ "key" => "value" })
    end

    it "returns the original response for invalid JSON" do
      invalid_json = '{"key": invalid_json'
      result = http.send(:parse_json, invalid_json)
      expect(result).to eq(invalid_json)
    end

    it "returns nil for nil input" do
      result = http.send(:parse_json, nil)
      expect(result).to be_nil
    end
  end

  describe "uri" do
    it "joins base URI and path correctly" do
      path = "/api/v1/test"
      result = http.send(:uri, path: path)
      expect(result).to eq("#{PLLUM::Configuration::DEFAULT_URI_BASE}#{path}")
    end

    it "handles custom base URI" do
      path = "/api/v1/test"
      result = custom_http.send(:uri, path: path)
      expect(result).to eq("https://custom.example.com#{path}")
    end
  end
end
