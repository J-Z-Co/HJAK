require "rails_helper"

RSpec.describe "个人资料", type: :request do
  it "保存性别和出生日期后能看到已保存" do
    user = User.create!(display_name: "甲", email: "profile-save@example.com", password: "password")
    sign_in user

    patch me_path, params: { user: { display_name: "不胖", sex: "male", birth_date: "1996-04-17" } }

    expect(response).to redirect_to(me_path)
    expect(user.reload.sex).to eq("male")
    expect(user.birth_date).to eq(Date.new(1996, 4, 17))
    follow_redirect!
    expect(response.body).to include("已保存")
    expect(response.body).not_to include("填写后才能计算需要它们的指数")
  end
end
