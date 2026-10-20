require "rails_helper"

RSpec.describe "注册", type: :request do
  def registration_params(overrides = {})
    {
      display_name: "丙",
      email: "register-profile@example.com",
      password: "password",
      password_confirmation: "password",
      sex: "male",
      birth_date: "1990-01-01"
    }.merge(overrides)
  end

  it "注册时必须填写性别和出生日期，填了才会建账号" do
    expect {
      post user_registration_path, params: { user: registration_params(sex: "", birth_date: "") }
    }.not_to change(User, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("性别不能为空").and include("出生日期不能为空")

    post user_registration_path, params: { user: registration_params(birth_date: Time.zone.tomorrow.iso8601) }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("出生日期不能晚于今天")
    expect(User.find_by(email: "register-profile@example.com")).to be_nil

    post user_registration_path, params: { user: registration_params }
    user = User.find_by!(email: "register-profile@example.com")
    expect(response).to redirect_to(root_path)
    expect(user).to be_male
    expect(user.birth_date).to eq(Date.new(1990, 1, 1))
  end

  it "已经注册但还没补资料的人，仍可以只改显示名" do
    user = User.create!(display_name: "丁", email: "old-profile@example.com", password: "password")
    sign_in user

    patch me_path, params: { user: { display_name: "丁丁", sex: "", birth_date: "" } }
    expect(response).to redirect_to(me_path)
    expect(user.reload.display_name).to eq("丁丁")
    expect(user.sex).to be_nil
    expect(user.birth_date).to be_nil
  end
end
