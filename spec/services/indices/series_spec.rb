require "rails_helper"

RSpec.describe Indices::Series, type: :service do
  it "17 岁那天的 BMI 色带不是成人界值" do
    user = User.create!(display_name: "戊", email: "series-age@example.com", password: "password", sex: :male, birth_date: Date.new(2008, 6, 1))
    user.measurements.create!(
      metric_type: "weight", recorded_on: Date.new(2025, 6, 1), recorded_at: Time.zone.local(2025, 6, 1, 9, 0, 0),
      value: 60, idempotency_key: SecureRandom.uuid
    )
    user.measurements.create!(
      metric_type: "height", recorded_on: Date.new(2025, 6, 1), recorded_at: Time.zone.local(2025, 6, 1, 9, 1, 0),
      value: 175, idempotency_key: SecureRandom.uuid
    )

    series = described_class.call(user:, key: "bmi", range: "365d", on: Date.new(2025, 6, 1))

    expect(series[:points].last[:high_health]).to eq(23.7)
    expect(series[:points].last[:high_warn]).to eq(27.6)
    expect(series[:range]).to eq("365d")
  end

  it "同一天的身高和腰围只留下一个腰高比点，用当天最后的快照" do
    user = User.create!(display_name: "学生", email: "series-same-day@example.com", password: "password", sex: :male, birth_date: Date.new(2016, 6, 1))
    on = Date.new(2026, 10, 17)
    user.measurements.create!(
      metric_type: "waist", recorded_on: on - 14, recorded_at: Time.zone.local(2026, 10, 3, 8, 0, 0),
      value: 62, idempotency_key: SecureRandom.uuid
    )
    user.measurements.create!(
      metric_type: "height", recorded_on: on, recorded_at: Time.zone.local(2026, 10, 17, 8, 0, 0),
      value: 140, idempotency_key: SecureRandom.uuid
    )
    user.measurements.create!(
      metric_type: "waist", recorded_on: on, recorded_at: Time.zone.local(2026, 10, 17, 8, 0, 0),
      value: 68, idempotency_key: SecureRandom.uuid
    )

    series = described_class.call(user:, key: "whtr", range: "30d", on:)
    today = series[:points].select { |point| point[:label].start_with?("10 月 17 日") }

    expect(today.size).to eq(1)
    expect(today.first[:value]).to eq(0.49)
  end

  it "非法窗口按 30 天" do
    user = User.create!(display_name: "己", email: "series-range@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))

    expect(described_class.call(user:, key: "bmi", range: "nope")[:range]).to eq("30d")
    expect(described_class.call(user:, key: "bmi", range: nil)[:range]).to eq("7d")
  end
end
