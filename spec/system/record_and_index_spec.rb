require "rails_helper"

RSpec.describe "记录后看指数", type: :system do
  before { driven_by :rack_test }

  it "HT-13 底栏都在，只填体重后能看到点亮身高和 7 天图" do
    User.create!(display_name: "壬", email: "ht13@example.com", password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
    visit new_user_session_path
    fill_in "邮箱", with: "ht13@example.com"
    fill_in "密码", with: "password"
    click_button "登录"

    expect(page).to have_css("[data-testid=tab-record]")
    expect(page).to have_css("[data-testid=tab-indices]")
    expect(page).to have_css("[data-testid=tab-groups]")
    expect(page).to have_css("[data-testid=tab-me]")

    fill_in "measurements_weight_value", with: "70"
    click_button "保存本次记录"
    expect(page).to have_content("已保存体重")

    click_link "指数"
    expect(page).to have_content("点亮身高")
    click_link "身体质量指数"
    expect(page).to have_css("[data-testid=range-7d]")
    expect(page).to have_content("健康区 18.5–24")
  end
end
