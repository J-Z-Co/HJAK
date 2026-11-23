require "rails_helper"

RSpec.describe "API 纠错", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.api_token}" } }

  it "GET /api/v1/corrections 返回指标列表" do
    get "/api/v1/corrections", headers: headers

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["metrics"].size).to eq(7)
  end

  it "GET /api/v1/corrections/weight 返回该指标的记录" do
    create(:measurement, user: user, metric_type: "weight", value: 70)

    get "/api/v1/corrections/weight", headers: headers

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["metric"]["key"]).to eq("weight")
    expect(body["measurements"].size).to eq(1)
  end

  it "PATCH /api/v1/corrections/weight/entries/:id 修改记录" do
    measurement = create(:measurement, user: user, metric_type: "weight", value: 70)

    patch "/api/v1/corrections/weight/entries/#{measurement.id}",
          params: { value: "71" }, headers: headers, as: :json

    expect(response).to have_http_status(:ok)
    expect(measurement.reload.value).to eq(71)
  end
end
