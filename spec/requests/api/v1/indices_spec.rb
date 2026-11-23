require "rails_helper"

RSpec.describe "API 指数", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.api_token}" } }

  it "GET /api/v1/indices 返回 board 与 brief" do
    get "/api/v1/indices", headers: headers

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["board"]["readings"].size).to eq(8)
    expect(body["brief"]["lines"]).to be_an(Array)
  end

  it "GET /api/v1/indices/bmi 返回 reading 与 series" do
    get "/api/v1/indices/bmi", headers: headers

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["reading"]["key"]).to eq("bmi")
    expect(body["reading"]).to have_key("numeric")
    expect(body).to have_key("series")
  end
end
