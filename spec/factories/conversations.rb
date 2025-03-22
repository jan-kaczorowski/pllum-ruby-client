FactoryBot.define do
  factory :conversation, class: PLLUM::Conversation do
    client { build(:client) }
    chat_id { nil }
    log_id { nil }

    initialize_with { new(client: client, chat_id: chat_id, log_id: log_id) }

    trait :with_history do
      transient do
        message_count { 2 } # One user message, one assistant response
      end

      after(:build) do |conversation, evaluator|
        if evaluator.message_count > 0
          (evaluator.message_count / 2).times do |i|
            # Directly set the history without calling private method
            conversation.instance_variable_get(:@history) << { role: "user", content: "User message #{i + 1}" }
            conversation.instance_variable_get(:@history) << { role: "assistant", content: "Assistant response #{i + 1}" }
          end
        end
      end
    end

    trait :with_existing_chat do
      chat_id { "test_chat_id_#{SecureRandom.hex(8)}" }
      log_id { "test_log_id_#{SecureRandom.hex(8)}" }
    end

    trait :with_custom_config do
      transient do
        model { "custom-model" }
        temperature { 0.7 }
        top_p { 0.8 }
      end

      after(:build) do |conversation, evaluator|
        conversation.instance_variable_set(:@config, {
                                             auth_mode: conversation.config[:auth_mode],
                                             model: evaluator.model,
                                             temperature: evaluator.temperature,
                                             top_p: evaluator.top_p
                                           })
      end
    end
  end
end
