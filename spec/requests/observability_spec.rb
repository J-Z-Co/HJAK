require "rails_helper"

RSpec.describe "生产统计脚本", type: :request do
  it "测试环境的页面不加载统计脚本" do
    get new_user_session_path

    expect(response.body).not_to include("/_vercel/insights/script.js")
    expect(response.body).not_to include("/_vercel/speed-insights/script.js")
  end

  it "生产环境的页面加载同域统计脚本" do
    allow(Rails.env).to receive(:production?).and_return(true)

    get new_user_session_path

    expect(response.body).to include('src="/_vercel/insights/script.js"')
    expect(response.body).to include('src="/_vercel/speed-insights/script.js"')
    expect(response.body).to include("window.vaq")
    expect(response.body).to include("window.siq")
  end
end
