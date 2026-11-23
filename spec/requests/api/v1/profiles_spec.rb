require "rails_helper"

RSpec.describe "API 我的", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.api_token}" } }

  it "GET /api/v1/me 返回用户与进度" do
    get "/api/v1/me", headers: headers

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["user"]["display_name"]).to eq(user.display_name)
    expect(body["progress"]).to have_key("streak")
  end

  it "PATCH /api/v1/me 更新资料" do
    patch "/api/v1/me",
          params: { display_name: "新名字", sex: "female", birth_date: "1995-05-05" },
          headers: headers, as: :json

    expect(response).to have_http_status(:ok)
    expect(user.reload.sex).to eq("female")
    expect(user.birth_date).to eq(Date.new(1995, 5, 5))
  end
end
