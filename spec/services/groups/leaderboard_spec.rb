require "rails_helper"

RSpec.describe Groups::Leaderboard, type: :service do
  let(:today) { Date.new(2026, 10, 17) }
  let(:group) { Group.create!(name: "排行", public_id: "LB23KM45") }
  let(:adult) { create(:user, display_name: "甲") }
  let(:other) { create(:user, display_name: "乙") }
  let(:child) { create(:user, :under_six, display_name: "丙") }

  before do
    [ adult, other, child ].each { |user| Membership.create!(group:, user:, role: user == adult ? :owner : :member, joined_at: Time.current) }
  end

  def record(user, days_ago)
    create(:measurement, user:, metric_type: "resting_heart_rate", recorded_on: today - days_ago)
  end

  it "连续榜按连续天数从多到少，并列同名次，未满 6 岁也参加，0 天不给名次" do
    travel_to today do
      [ 0, 1, 2 ].each { |days| record(child, days) }
      [ 0, 1, 2 ].each { |days| record(adult, days) }

      rows = described_class.for(group, board: "streak", on: today)
      expect(rows.map { |row| [ row.user.display_name, row.rank, row.value ] }).to eq([ [ "甲", 1, 3 ], [ "丙", 1, 3 ], [ "乙", nil, 0 ] ])
      expect(rows.first.value_text).to eq("3 天")
    end
  end

  it "本周榜只数最近 7 天里有记录的天数" do
    travel_to today do
      [ 0, 3, 6, 7, 20 ].each { |days| record(other, days) }

      row = described_class.for(group, board: "week", on: today).find { |item| item.user == other }
      expect(row.value).to eq(3)
      expect(row.rank).to eq(1)
    end
  end

  it "不认识的榜单回到综合，未满 6 岁不排名" do
    travel_to today do
      rows = described_class.for(group, board: "nope", on: today)
      expect(rows.find { |row| row.user == child }.note).to eq("未满 6 岁，不参与排名")
    end
  end
end
