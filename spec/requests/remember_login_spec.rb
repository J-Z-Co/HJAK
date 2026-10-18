require "rails_helper"

RSpec.describe "记住登录", type: :request do
  def create_user(email)
    User.create!(display_name: "甲", email: email, password: "password")
  end

  it "登录后在会话 cookie 消失时仍保持登录，退出后必须重新登录" do
    user = create_user("remember-login@example.com")

    post user_session_path, params: {
      user: { email: user.email, password: "password", remember_me: "1" }
    }

    expect(response).to redirect_to(root_path)
    expect(cookies["remember_user_token"]).to be_present
    expect(user.reload.remember_created_at).to be_present

    cookies.delete(Rails.application.config.session_options[:key])
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("保存本次记录")

    delete destroy_user_session_path
    expect(user.reload.remember_created_at).to be_nil

    get root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "注册成功后同样记住" do
    post user_registration_path, params: {
      user: {
        display_name: "乙",
        email: "remember-register@example.com",
        password: "password",
        password_confirmation: "password"
      }
    }

    user = User.find_by!(email: "remember-register@example.com")
    expect(response).to redirect_to(root_path)
    expect(cookies["remember_user_token"]).to be_present
    expect(user.remember_created_at).to be_present
  end
end
