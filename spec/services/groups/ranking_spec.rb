require "rails_helper"

RSpec.describe Groups::Ranking, type: :service do
  it "同分并列，下一名次跳过，未满 6 岁不占名次" do
    group = Group.create!(name: "排名", public_id: "GH89JK23")
    first = User.create!(display_name: "甲", email: "rank-a@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    second = User.create!(display_name: "乙", email: "rank-b@example.com", password: "password", sex: :male, birth_date: Date.new(1991, 1, 1))
    child = User.create!(display_name: "丙", email: "rank-c@example.com", password: "password", sex: :male, birth_date: Date.new(2022, 1, 1))
    heavier = User.create!(display_name: "丁", email: "rank-d@example.com", password: "password", sex: :male, birth_date: Date.new(1992, 1, 1))
    [ first, second, child, heavier ].each do |user|
      Membership.create!(group:, user:, role: user == first ? :owner : :member, joined_at: Time.current)
    end
    [ first, second, child ].each { |user| weigh(user, 70) }
    weigh(heavier, 120)

    rows = described_class.for(group, on: Date.new(2026, 10, 17))
    ranked = rows.select(&:rank)

    expect(ranked.map { |row| [ row.user.display_name, row.rank ] }).to eq([ [ "甲", 1 ], [ "乙", 1 ], [ "丁", 3 ] ])
    expect(rows.last.user).to eq(child)
    expect(rows.last.rank).to be_nil
    expect(rows.last.basis).to eq("未满 6 岁，不参与排名")
  end

  def weigh(user, kilograms)
    user.measurements.create!(
      metric_type: "weight", value: kilograms, recorded_on: Date.new(2026, 10, 17),
      recorded_at: Time.zone.local(2026, 10, 17, 8, 0, 0), idempotency_key: SecureRandom.uuid
    )
    user.measurements.create!(
      metric_type: "height", value: 175, recorded_on: Date.new(2026, 10, 17),
      recorded_at: Time.zone.local(2026, 10, 17, 8, 0, 0), idempotency_key: SecureRandom.uuid
    )
  end
end
