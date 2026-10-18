FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "factory-user-#{n}@example.com" }
    sequence(:display_name) { |n| "成员#{n}" }
    password { "password" }
    sex { :male }
    birth_date { Date.new(1990, 1, 1) }

    trait :child do
      birth_date { 10.years.ago.to_date }
    end

    trait :under_six do
      birth_date { 5.years.ago.to_date }
    end
  end
end
