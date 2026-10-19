require "rails_helper"

RSpec.describe Measurements::Row, type: :service do
  it "按浅绿、浅黄、淡紫、从未记录排序，并写出超过建议时间的天数" do
    user = User.create!(display_name: "甲", email: "row@example.com", password: "password")
    today = Date.new(2026, 10, 16)
    travel_to today do
      user.measurements.create!(
        metric_type: "waist", recorded_on: Date.new(2026, 10, 1), recorded_at: Time.current,
        value: 80, idempotency_key: SecureRandom.uuid
      )
      user.measurements.create!(
        metric_type: "height", recorded_on: today, recorded_at: Time.current,
        value: 140, idempotency_key: SecureRandom.uuid
      )

      rows = described_class.build(user, on: today)
      expect(rows.map(&:key)).to eq(%w[waist height weight hip neck blood_pressure resting_heart_rate])
      expect(rows.first.caption).to eq("已超过建议时间 12 天，上次 15 天前")
      expect(rows.first.background).to eq("#FEF9C3")
      expect(rows.second.background).to eq("#EDE9FE")
      expect(rows.third.caption).to eq("还没有记录")
    end
  end

  it "超过 20 岁的人 3 天前称过体重，还没到下次；20 岁的人已经逾期" do
    today = Date.new(2026, 10, 16)
    travel_to today do
      adult = User.create!(display_name: "乙", email: "adult@example.com", password: "password", birth_date: Date.new(1990, 1, 1))
      young = User.create!(display_name: "丙", email: "young@example.com", password: "password", birth_date: Date.new(2006, 1, 1))
      [ adult, young ].each do |user|
        user.measurements.create!(
          metric_type: "weight", recorded_on: today - 3, recorded_at: Time.current,
          value: 70, idempotency_key: SecureRandom.uuid
        )
      end

      adult_row = described_class.build(adult, on: today).find { |row| row.key == "weight" }
      young_row = described_class.build(young, on: today).find { |row| row.key == "weight" }
      expect(adult_row.status).to eq(:early)
      expect(adult_row.caption).to eq("3 天前记录，建议下次约 10 月 20 日")
      expect(young_row.status).to eq(:overdue)
    end
  end
end
