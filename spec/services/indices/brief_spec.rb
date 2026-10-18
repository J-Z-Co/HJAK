require "rails_helper"

RSpec.describe Indices::Brief, type: :service do
  def record(user, type, value, secondary: nil, on: Date.new(2026, 10, 17))
    user.measurements.create!(
      metric_type: type, recorded_on: on, recorded_at: Time.zone.local(on.year, on.month, on.day, 8, 0, 0),
      value:, value_secondary: secondary, idempotency_key: SecureRandom.uuid
    )
  end

  it "偏离的成人用三句话概括四组里最差的情况" do
    user = User.create!(display_name: "队友", email: "brief-mate@example.com", password: "password", sex: :female, birth_date: Date.new(1992, 6, 1))
    record(user, "height", 164)
    record(user, "weight", 70)
    record(user, "waist", 84)
    record(user, "hip", 92)
    record(user, "neck", 33)
    record(user, "blood_pressure", 130, secondary: 82)
    record(user, "resting_heart_rate", 110)

    brief = described_class.for(Indices::Board.assemble(user, on: Date.new(2026, 10, 17)))

    expect(brief.lines.first).to eq("体重和体脂都高出健康区，脂肪也开始集中在腹部。")
    expect(brief.lines).to include(a_string_matching(/\A综合偏离 \d\.\d{2}。\z/))
    expect(brief.lines).to include("血压和心率离开了健康区。")
    expect(brief.groups.map(&:title)).to eq(%w[体重与代谢 体脂比例 脂肪分布 心血管])
    expect(brief.groups[0].status).to eq("偏高")
    expect(brief.groups[1].readings.map(&:key)).to eq(%w[navy rfm])
  end

  it "都在界内时只说健康区" do
    user = User.create!(display_name: "自己", email: "brief-self@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    record(user, "height", 175)
    record(user, "weight", 70)
    record(user, "waist", 80)
    record(user, "hip", 98)
    record(user, "neck", 38)
    record(user, "blood_pressure", 118, secondary: 76)
    record(user, "resting_heart_rate", 68)

    brief = described_class.for(Indices::Board.assemble(user, on: Date.new(2026, 10, 17)))

    expect(brief.lines.first).to eq("目前算得出的项目都在健康区。")
    expect(brief.lines.join).not_to include("离开了健康区")
    expect(brief.groups.map(&:status)).to eq([ "在健康区", "在健康区", "在健康区", "在健康区" ])
  end

  it "未满 6 岁不比较，未满 18 岁把整组不适用的成人公式收成一句" do
    child = User.create!(display_name: "幼儿", email: "brief-child@example.com", password: "password", sex: :male, birth_date: Date.new(2021, 6, 1))
    record(child, "height", 110, on: Date.new(2026, 6, 1))
    record(child, "weight", 18, on: Date.new(2026, 6, 1))
    brief = described_class.for(Indices::Board.assemble(child, on: Date.new(2026, 6, 1)))

    expect(brief.lines).to eq([ "这个年龄只记录数字，暂不比较偏离。" ])
    expect(brief.groups.find { |group| group.title == "体脂比例" }.note).to eq("未满 18 岁不适用此公式")
    expect(brief.groups.find { |group| group.title == "体重与代谢" }.status).to eq("暂不比较")
  end

  it "过期输入仍给结论，并补一句" do
    user = User.create!(display_name: "过期", email: "brief-stale@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    record(user, "height", 175, on: Date.new(2025, 1, 1))
    record(user, "weight", 70)

    brief = described_class.for(Indices::Board.assemble(user, on: Date.new(2026, 10, 17)))

    expect(brief.lines).to include("有过期输入，结论仍按最近一次。")
  end
end
