require "rails_helper"

RSpec.describe "指数公式", type: :service do
  describe "HT-01 成人 BMI 与厘米体脂" do
    it "70 kg、175 cm 的 BMI 是 22.9，厘米式与英寸式相差小于 0.05" do
      expect(Indices::Bmi.value(70, 175)).to eq(22.9)

      centimeters = Indices::Navy.from_centimeters(sex: :male, waist_cm: 85, neck_cm: 38, height_cm: 175)
      inches = Indices::Navy.from_inches(sex: :male, waist_cm: 85, neck_cm: 38, height_cm: 175)

      expect(centimeters).to be_a(Numeric)
      expect((centimeters - inches).abs).to be < 0.05
    end
  end

  describe "HT-02 腰围不大于颈围" do
    it "海军体脂不可算，围度本身仍能保存" do
      expect(Indices::Navy.from_centimeters(sex: :male, waist_cm: 30, neck_cm: 38, height_cm: 175)).to be_nil
      expect(Indices::Navy.from_centimeters(sex: :male, waist_cm: 38, neck_cm: 38, height_cm: 175)).to be_nil

      user = User.create!(
        display_name: "甲",
        email: "ht02@example.com",
        password: "password",
        sex: :male,
        birth_date: Date.new(1990, 1, 1)
      )
      recorded_at = Time.zone.local(2026, 10, 16, 8, 0, 0)

      waist = user.measurements.create!(
        metric_type: "waist", recorded_on: Date.new(2026, 10, 16), recorded_at:,
        value: 30, idempotency_key: SecureRandom.uuid
      )
      neck = user.measurements.create!(
        metric_type: "neck", recorded_on: Date.new(2026, 10, 16), recorded_at:,
        value: 38, idempotency_key: SecureRandom.uuid
      )

      expect(waist).to be_persisted
      expect(neck).to be_persisted
    end
  end

  describe "HT-03 RFM 偏离分" do
    it "男 25 为 0，男 30 为 1，女 40 为 1" do
      male = Indices::Rfm.bounds(sex: :male)
      female = Indices::Rfm.bounds(sex: :female)

      expect(Indices::Deviation.score(25, **male)).to eq(0)
      expect(Indices::Deviation.score(30, **male)).to eq(1)
      expect(Indices::Deviation.score(40, **female)).to eq(1)
    end
  end

  describe "HT-04 10 岁男生 BMI" do
    let(:birth_date) { Date.new(2016, 6, 1) }
    let(:on) { Date.new(2026, 6, 1) }

    it "19.0 偏离分为 0，21.9 偏离分为 1" do
      band = Indices::Reference.bmi(sex: :male, birth_date:, on:)

      expect(band.deviation_for(19.0)).to eq(0)
      expect(band.deviation_for(21.9)).to eq(1)
    end
  end

  describe "HT-05 不适龄" do
    it "10 岁男生的海军体脂不适用，5 岁儿童的 BMI 偏离分为空" do
      expect(Indices::Reference.navy_note(birth_date: Date.new(2016, 6, 1), on: Date.new(2026, 6, 1)))
        .to eq("未满 18 岁不适用此公式")

      child = Indices::Reference.bmi(sex: :male, birth_date: Date.new(2021, 6, 1), on: Date.new(2026, 6, 1))
      expect(child.deviation_for(16.0)).to be_nil
      expect(child.note).to eq("未满 6 岁，暂不着色")
    end
  end

  describe "HT-06 图表点用记录日年龄" do
    let(:birth_date) { Date.new(2008, 6, 1) }

    it "17 岁生日当天的 BMI 色带不是成人界值，18 岁生日当天才切换" do
      at_seventeen = Indices::Reference.bmi(sex: :male, birth_date:, on: Date.new(2025, 6, 1))
      at_eighteen = Indices::Reference.bmi(sex: :male, birth_date:, on: Date.new(2026, 6, 1))

      expect(at_seventeen.high_health).to eq(23.7)
      expect(at_seventeen.high_warn).to eq(27.6)
      expect(at_eighteen.high_health).to eq(24)
      expect(at_eighteen.low_health).to eq(18.5)
    end
  end
end
