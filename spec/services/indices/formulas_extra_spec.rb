require "rails_helper"

RSpec.describe "其余指数", type: :service do
  it "成人腰高比、腰臀比、中心性肥胖和心血管偏离分" do
    expect(Indices::Whtr.value(80, 175)).to eq(0.46)
    expect(Indices::Reference.whtr(sex: :male, birth_date: Date.new(1990, 1, 1), on: Date.new(2026, 1, 1)).deviation_for(0.46)).to eq(0)
    expect(Indices::Reference.whtr(sex: :male, birth_date: Date.new(2014, 1, 1), on: Date.new(2026, 1, 1)).high_health).to eq(0.487)
    expect(Indices::Reference.whtr(sex: :male, birth_date: Date.new(2013, 1, 1), on: Date.new(2026, 1, 1)).high_health).to eq(0.468)
    expect(Indices::Reference.whtr(sex: :female, birth_date: Date.new(2014, 1, 1), on: Date.new(2026, 1, 1)).high_health).to eq(0.456)

    male_whr = Indices::Reference.whr(sex: :male)
    expect(male_whr.deviation_for(0.90)).to eq(0)
    expect(male_whr.deviation_for(1.00)).to eq(1)
    expect(Indices::CentralObesity.label(sex: :male, waist_cm: 84)).to eq("未达")
    expect(Indices::CentralObesity.label(sex: :male, waist_cm: 86)).to eq("前期")
    expect(Indices::CentralObesity.label(sex: :female, waist_cm: 85)).to eq("中心性肥胖")
    expect(Indices::Cardio.score(systolic: 118, diastolic: 76, heart_rate: 70)).to eq(0)
    expect(Indices::Cardio.score(systolic: 135, diastolic: 76, heart_rate: 70)).to eq(1)
  end

  it "成人 Mifflin 与 10 岁 Schofield 取整" do
    adult = Indices::Bmr.value(sex: :male, weight_kg: 70, height_cm: 175, age_years: 30)
    child = Indices::Bmr.value(sex: :male, weight_kg: 32, height_cm: 140, age_years: 10)

    expect(adult).to eq(1649)
    expect(child).to eq(1228)
    expect(Indices::Bmr.value(sex: :male, weight_kg: 12, height_cm: 90, age_years: 2)).to be_nil
  end
end
