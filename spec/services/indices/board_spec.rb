require "rails_helper"

RSpec.describe Indices::Board, type: :service do
  def record(user, type, value, on:, secondary: nil)
    user.measurements.create!(
      metric_type: type, recorded_on: on, recorded_at: Time.zone.local(on.year, on.month, on.day, 8, 0, 0),
      value:, value_secondary: secondary, idempotency_key: SecureRandom.uuid
    )
  end

  it "腰围没记时，腰高比排在队尾并提示点亮腰围" do
    user = User.create!(display_name: "甲", email: "board-waist@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    record(user, "weight", 70, on: Date.new(2026, 10, 16))
    record(user, "height", 175, on: Date.new(2026, 10, 16))

    readings = described_class.assemble(user, on: Date.new(2026, 10, 16)).readings
    bmi = readings.find { |reading| reading.key == "bmi" }
    whtr = readings.find { |reading| reading.key == "whtr" }

    expect(bmi.group).to eq(:scored)
    expect(bmi.value_text).to eq("22.9")
    expect(whtr.group).to eq(:missing)
    expect(whtr.note).to eq("点亮腰围后可计算")
    expect(readings.index(bmi)).to be < readings.index(whtr)
  end

  it "过期腰围仍计算腰高比，并写明仍按最近一次" do
    user = User.create!(display_name: "乙", email: "board-stale@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    record(user, "weight", 70, on: Date.new(2026, 10, 16))
    record(user, "height", 175, on: Date.new(2026, 1, 1))
    record(user, "waist", 80, on: Date.new(2026, 4, 1))

    whtr = described_class.assemble(user, on: Date.new(2026, 10, 16)).readings.find { |reading| reading.key == "whtr" }

    expect(whtr.group).to eq(:scored)
    expect(whtr.stale_text).to eq("腰围已超过建议记录时间，结果仍按最近一次计算")
  end

  it "成人围度齐全时海军体脂给出百分比" do
    user = User.create!(display_name: "戊", email: "board-navy@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    on = Date.new(2026, 10, 16)
    record(user, "weight", 70, on:)
    record(user, "height", 175, on:)
    record(user, "waist", 80, on:)
    record(user, "neck", 38, on:)

    navy = described_class.assemble(user, on:).readings.find { |reading| reading.key == "navy" }

    expect(navy.group).to eq(:scored)
    expect(navy.value_text).to eq("12.8%")
  end

  it "10 岁男生 BMI 着色，海军体脂不适用" do
    user = User.create!(display_name: "丙", email: "board-boy@example.com", password: "password", sex: :male, birth_date: Date.new(2016, 6, 1))
    record(user, "weight", 32, on: Date.new(2026, 6, 1))
    record(user, "height", 140, on: Date.new(2026, 6, 1))
    record(user, "waist", 60, on: Date.new(2026, 6, 1))
    record(user, "neck", 30, on: Date.new(2026, 6, 1))

    board = described_class.assemble(user, on: Date.new(2026, 6, 1))
    bmi = board.readings.find { |reading| reading.key == "bmi" }
    navy = board.readings.find { |reading| reading.key == "navy" }

    expect(bmi.deviation).to eq(0)
    expect(bmi.clickable).to be(true)
    expect(navy.group).to eq(:inapplicable)
    expect(navy.note).to eq("未满 18 岁不适用此公式")
    expect(navy.clickable).to be(false)
    expect(board.basis).to eq("按未成年界值，2 项可算")
  end

  it "5 岁儿童的 BMI 有数字但不着色" do
    user = User.create!(display_name: "丁", email: "board-child@example.com", password: "password", sex: :male, birth_date: Date.new(2021, 6, 1))
    record(user, "weight", 18, on: Date.new(2026, 6, 1))
    record(user, "height", 110, on: Date.new(2026, 6, 1))

    board = described_class.assemble(user, on: Date.new(2026, 6, 1))
    bmi = board.readings.find { |reading| reading.key == "bmi" }

    expect(bmi.value_text).to be_present
    expect(bmi.deviation).to be_nil
    expect(bmi.note).to eq("未满 6 岁，暂不着色")
    expect(board.compare?).to be(false)
    expect(board.banner).to eq("这个年龄只记录数字，暂不着色。")
  end
end
