require "rails_helper"

RSpec.describe "API 鉴权", type: :request do
  describe "POST /api/v1/auth/wechat" do
    it "用 code 换取 token 并自动创建新用户" do
      allow(WechatClient).to receive(:jscode2session).and_return({ "openid" => "openid-abc" })

      expect {
        post "/api/v1/auth/wechat", params: { code: "c0de" }, as: :json
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body["new_user"]).to be(true)
      expect(body["user"]["display_name"]).to eq("微信用户")
      expect(User.find_by(openid: "openid-abc").api_token).to eq(body["token"])
    end

    it "老用户再次登录沿用同一账号并刷新 token" do
      allow(WechatClient).to receive(:jscode2session).and_return({ "openid" => "openid-abc" })
      user = create(:user, openid: "openid-abc")
      old_token = user.api_token

      expect {
        post "/api/v1/auth/wechat", params: { code: "c0de" }, as: :json
      }.not_to change(User, :count)

      expect(response).to have_http_status(:ok)
      expect(user.reload.api_token).not_to eq(old_token)
    end

    it "缺少 code 返回 422" do
      post "/api/v1/auth/wechat", params: {}, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("missing code")
    end
  end

  it "未带 token 访问受保护接口返回 401" do
    get "/api/v1/me"
    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)["error"]).to eq("unauthorized")
  end
end
