# Configure SimpleCov first
require_relative "support/simplecov"

require "bundler/setup"
require "pllum"
require "vcr"
require "factory_bot"
require "webmock/rspec"
require "securerandom" # For generating random IDs in factories

# Require all files in the support directory
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Configure FactoryBot
  config.before(:suite) do
    FactoryBot.find_definitions
  end
  
  # Configure VCR to ignore integration tests by default
  config.before(:all, :integration) do
    WebMock.allow_net_connect!
  end

  config.after(:all, :integration) do
    WebMock.disable_net_connect!
  end
  
  # Reset the PLLUM configuration between tests
  config.after(:each) do
    PLLUM.configuration = PLLUM::Configuration.new
  end
end

# Set up factory paths
FactoryBot.definition_file_paths = [File.join(File.dirname(__FILE__), "factories")]
# Factory definitions will be loaded in the before(:suite) block above