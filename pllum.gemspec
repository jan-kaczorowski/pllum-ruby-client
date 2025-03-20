require_relative "lib/pllum/version"

Gem::Specification.new do |spec|
  spec.name          = "pllum"
  spec.version       = PLLUM::VERSION
  spec.authors       = ["Jan Kaczorowski"]
  spec.email         = ["jan.kaczorowski@gmail.com"]

  spec.summary       = "Ruby client for the PLLUM AI API"
  spec.description   = "A minimal Ruby client for interacting with the PLLUM AI API - a Polish language model"
  spec.homepage      = "https://github.com/jan-kaczorowski/pllum-ruby-client"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["lib/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 1.0.0"
  spec.add_dependency "event_stream_parser", "~> 0.3.0"
  
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end