require "rails_helper"

RSpec.describe "API 建议", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.api_token}" } }

  it "POST /api/v1/suggestions 提交建议" do
    expect {
      post "/api/v1/suggestions", params: { body: "建议加个深色模式" }, headers: headers, as: :json
    }.to change(Suggestion, :count).by(1)

    expect(response).to have_http_status(:created)
  end

  it "POST /api/v1/suggestions/:id/vote 投票" do
    suggestion = user.suggestions.create!(body: "测试建议")

    post "/api/v1/suggestions/#{suggestion.id}/vote", params: { choice: "reasonable" }, headers: headers, as: :json

    expect(response).to have_http_status(:ok)
    expect(suggestion.reload.reasonable_count).to eq(1)
  end
end
