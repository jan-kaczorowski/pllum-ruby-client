FactoryBot.define do
  factory :client, class: PLLUM::Client do
    uri_base { PLLUM::Configuration::DEFAULT_URI_BASE }
    request_timeout { PLLUM::Configuration::DEFAULT_REQUEST_TIMEOUT }
    auth_mode { PLLUM::Configuration::DEFAULT_AUTH_MODE }

    initialize_with { new(uri_base: uri_base, request_timeout: request_timeout, auth_mode: auth_mode) }

    trait :with_auth do
      auth_mode { true }
    end

    trait :custom_timeout do
      request_timeout { 180 }
    end
  end
end
