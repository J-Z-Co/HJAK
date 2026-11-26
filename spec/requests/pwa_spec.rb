require "rails_helper"

RSpec.describe "主屏幕清单", type: :request do
  it "清单是中文名、独立窗口，并且从根路径打开" do
    get pwa_manifest_path(format: :json)

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["name"]).to eq("梅珊知安")
    expect(body["short_name"]).to eq("梅珊知安")
    expect(body["display"]).to eq("standalone")
    expect(body["start_url"]).to eq("/")
    expect(body["scope"]).to eq("/")
    expect(body["theme_color"]).to eq("#f4f1ec")
  end

  it "登录后的页面带清单链接和主屏幕说明；测试环境不登记服务工作线程" do
    user = User.create!(display_name: "甲", email: "pwa@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    sign_in user

    get me_path
    expect(response.body).to include(pwa_manifest_path(format: :json))
    expect(response.body).to include("添加到主屏幕")
    expect(response.body).to include("apple-mobile-web-app-title")

    expect(response.body).not_to include("serviceWorker.register")

    get "/service-worker"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("6 * 60 * 60 * 1000")
    expect(response.body).to include("phoenix-")
  end
end
