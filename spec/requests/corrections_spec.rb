require "rails_helper"

RSpec.describe "纠正误输入", type: :request do
  it "记录页只负责新增，改正从「我」进入" do
    user = User.create!(display_name: "甲", email: "correct-self@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    sign_in user
    2.times do |index|
      user.measurements.create!(
        metric_type: "weight", recorded_on: Time.zone.today - index, recorded_at: Time.current - index.days,
        value: 70 + index, idempotency_key: SecureRandom.uuid
      )
    end

    get root_path
    expect(response.body).to include("最近 2 次体重")
    expect(response.body).to include("#{Time.zone.today.month}/#{Time.zone.today.day}")
    expect(response.body).to include("#{(Time.zone.today - 1).month}/#{(Time.zone.today - 1).day}")
    expect(response.body).not_to include("删除最近一次")

    get me_path
    expect(response.body).to include("纠正误输入")
  end

  it "可以修改和删除自己的数值，不能改别人的，也不能改成非法数字" do
    user = User.create!(display_name: "乙", email: "correct-edit@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    other = User.create!(display_name: "丙", email: "correct-other@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    own = user.measurements.create!(
      metric_type: "weight", recorded_on: Time.zone.today, recorded_at: Time.current,
      value: 70, idempotency_key: SecureRandom.uuid
    )
    foreign = other.measurements.create!(
      metric_type: "weight", recorded_on: Time.zone.today, recorded_at: Time.current,
      value: 80, idempotency_key: SecureRandom.uuid
    )
    sign_in user

    get correction_path("weight")
    expect(response.body).to include("70")
    expect(response.body).not_to include("80 kg")

    patch correction_entry_path("weight", foreign), params: { value: "71" }
    expect(foreign.reload.value).to eq(80)

    patch correction_entry_path("weight", own), params: { value: "1" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(own.reload.value).to eq(70)

    patch correction_entry_path("weight", own), params: { value: "71.5" }
    expect(own.reload.value).to eq(71.5)

    delete correction_entry_path("weight", own)
    expect(user.measurements.where(id: own.id)).to be_empty
  end

  it "血压要两个数一起改" do
    user = User.create!(display_name: "丁", email: "correct-bp@example.com", password: "password", sex: :female, birth_date: Date.new(1992, 6, 1))
    record = user.measurements.create!(
      metric_type: "blood_pressure", recorded_on: Time.zone.today, recorded_at: Time.current,
      value: 120, value_secondary: 80, idempotency_key: SecureRandom.uuid
    )
    sign_in user

    patch correction_entry_path("blood_pressure", record), params: { value: "118" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(record.reload.value).to eq(120)

    patch correction_entry_path("blood_pressure", record), params: { value: "118", value_secondary: "76" }
    expect(record.reload.value).to eq(118)
    expect(record.reload.value_secondary).to eq(76)
  end
end
