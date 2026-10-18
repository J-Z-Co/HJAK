FactoryBot.define do
  factory :group_with_owner, class: "Group" do
    name { "家里" }

    after(:create) do |group|
      create(:membership, group:, user: create(:user), role: :owner, joined_at: Time.current)
    end
  end

  factory :membership do
    group
    user
    role { :member }
    joined_at { Time.current }
  end

  factory :group do
    name { "群组" }
  end
end
