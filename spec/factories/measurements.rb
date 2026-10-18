FactoryBot.define do
  factory :measurement do
    user
    metric_type { "weight" }
    recorded_on { Time.zone.today }
    recorded_at { Time.current }
    value { 70 }
    idempotency_key { SecureRandom.uuid }

    trait :blood_pressure do
      metric_type { "blood_pressure" }
      value { 120 }
      value_secondary { 80 }
    end
  end
end
