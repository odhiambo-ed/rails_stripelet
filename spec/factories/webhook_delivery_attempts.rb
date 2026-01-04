FactoryBot.define do
  factory :webhook_delivery_attempt do
    association :webhook_event
    association :webhook_endpoint
    attempt_number { 1 }
    status { 'pending' }
    response_code { nil }
    response_body { nil }
    attempted_at { Time.current }

    trait :success do
      status { 'success' }
      response_code { 200 }
      response_body { '{"success": true}' }
    end

    trait :failed do
      status { 'failed' }
      response_code { 500 }
      response_body { '{"error": "Internal Server Error"}' }
    end
  end
end
