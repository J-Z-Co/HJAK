require "rails_helper"

RSpec.describe "指数页", type: :request do
  it "只保存体重后，BMI 提示点亮身高，并打开 7 天图" do
    user = User.create!(display_name: "庚", email: "indices-page@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    sign_in user

    post measurements_path, params: {
      idempotency_key: SecureRandom.uuid,
      recorded_on: Time.zone.today,
      measurements: { weight: { value: "70" } }
    }

    get indices_path
    expect(response.body).to include("点亮身高后可计算")
    expect(response.body).to include("index-link-bmi")
    expect(response.body).to include("体重与代谢")
    expect(response.body).to include("着色依据成人筛查范围，不是诊断。")

    get index_path("bmi")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("range-7d")
    expect(response.body).to include("这段时间还没有足够的记录")

    get index_path("navy")
    expect(response).to have_http_status(:ok)
  end

  it "未满 18 岁打开海军体脂会回到列表" do
    user = User.create!(display_name: "辛", email: "indices-navy@example.com", password: "password", sex: :male, birth_date: Date.new(2016, 1, 1))
    sign_in user

    get index_path("navy")

    expect(response).to redirect_to(indices_path)
    follow_redirect!
    expect(response.body).to include("未满 18 岁不适用此公式")
  end
end
