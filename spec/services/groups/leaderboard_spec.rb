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

  it "现状榜沿用综合偏离，未满 6 岁不排名，过期输入仍计分" do
    travel_to today do
      create(:measurement, user: adult, metric_type: "height", value: 175, recorded_on: today)
      create(:measurement, user: adult, metric_type: "weight", value: 70, recorded_on: today)
      create(:measurement, user: adult, metric_type: "waist", value: 90, recorded_on: today - 40)

      rows = described_class.for(group, board: "health", on: today)
      adult_row = rows.find { |row| row.user == adult }
      expect(adult_row.rank).to eq(1)
      expect(adult_row.note).to include("有过期输入")
      expect(rows.find { |row| row.user == child }.note).to eq("未满 6 岁，不参与排名")
    end
  end

  it "改善用周一前的测量做起点，变差的人仍有名次" do
    travel_to today do
      [ adult, other ].each do |user|
        create(:measurement, user:, metric_type: "height", value: 175, recorded_on: Date.new(2026, 10, 10))
      end
      create(:measurement, user: adult, metric_type: "weight", value: 90, recorded_on: Date.new(2026, 10, 10))
      create(:measurement, user: adult, metric_type: "weight", value: 70, recorded_on: today)
      create(:measurement, user: other, metric_type: "weight", value: 70, recorded_on: Date.new(2026, 10, 10))
      create(:measurement, user: other, metric_type: "weight", value: 90, recorded_on: today)

      rows = described_class.for(group, board: "trend", on: today)
      expect(rows.find { |row| row.user == adult }.value).to be > 0
      expect(rows.find { |row| row.user == other }.value).to be < 0
      expect(rows.find { |row| row.user == adult }.rank).to eq(1)
      expect(rows.find { |row| row.user == other }.rank).to eq(2)
      expect(rows.find { |row| row.user == adult }.note).to include("比较了")
      expect(rows.find { |row| row.user == child }.note).to eq("未满 6 岁，不参与排名")
      expect(Groups::Week.start_on(today)).to eq(Date.new(2026, 10, 12))
    end
  end

  it "达标榜计入时效内的项，成年已记身高算一项，0 也有名次，未满 6 岁参加" do
    travel_to today do
      create(:measurement, user: adult, metric_type: "height", value: 175, recorded_on: today - 400)
      create(:measurement, user: adult, metric_type: "weight", value: 70, recorded_on: today)
      create(:measurement, user: adult, metric_type: "waist", value: 80, recorded_on: today - 30)
      create(:measurement, user: child, metric_type: "weight", value: 18, recorded_on: today)

      rows = described_class.for(group, board: "fresh", on: today)
      adult_row = rows.find { |row| row.user == adult }
      expect(adult_row.value).to eq(2)
      expect(adult_row.note).to include("腰围已过期")
      expect(rows.find { |row| row.user == child }.rank).to eq(2)
      expect(rows.find { |row| row.user == other }.rank).to eq(3)
      expect(rows.find { |row| row.user == other }.value).to eq(0)
    end
  end

  it "徽章 0 枚不排名，旧的天数榜和连续榜地址回到现状" do
    travel_to today do
      expect(described_class.board("week").key).to eq("health")
      expect(described_class.board("streak").key).to eq("health")
      expect(described_class.board("badges").label).to eq("徽章")
      rows = described_class.for(group, board: "badges", on: today)
      expect(rows.map(&:rank)).to all(be_nil)
    end
  end

  it "不认识的榜单回到现状，未满 6 岁不排名" do
    travel_to today do
      rows = described_class.for(group, board: "nope", on: today)
      expect(rows.find { |row| row.user == child }.note).to eq("未满 6 岁，不参与排名")
    end
  end
end
