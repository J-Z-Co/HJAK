require "rails_helper"

RSpec.describe "改善建议", type: :request do
  def create_user(name, email)
    User.create!(display_name: name, email: email, password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
  end

  it "未登录不能进入" do
    get suggestions_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "可以提交建议和一条补充，不能在补充下面再补充" do
    user = create_user("甲", "suggest-create@example.com")
    sign_in user

    get me_path
    expect(response.body).to include("改善建议")

    post suggestions_path, params: { suggestion: { body: "希望记录页的字再大一点" } }
    suggestion = Suggestion.find_by!(body: "希望记录页的字再大一点")
    expect(response).to redirect_to(suggestions_path)
    follow_redirect!
    expect(response.body).to include("希望记录页的字再大一点")
    expect(response.body).to include("甲")

    post suggestions_path, params: { parent_id: suggestion.id, suggestion: { body: "尤其是日期" } }
    reply = Suggestion.find_by!(body: "尤其是日期")
    expect(reply.parent_id).to eq(suggestion.id)
    follow_redirect!
    expect(response.body).to include("存在 1 条补充意见")

    post suggestions_path, params: { parent_id: reply.id, suggestion: { body: "不应该出现" } }
    expect(response).to have_http_status(:not_found)
    expect(Suggestion.where(body: "不应该出现")).to be_none
  end

  it "空白内容不保存，计数每次请求加一，只能删除自己的" do
    user = create_user("乙", "suggest-vote@example.com")
    other = create_user("丙", "suggest-other@example.com")
    suggestion = other.suggestions.create!(body: "按钮太小")
    sign_in user

    post suggestions_path, params: { suggestion: { body: "   " } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(Suggestion.where(user: user)).to be_none

    post vote_suggestion_path(suggestion), params: { choice: "reasonable" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(suggestion.reload.reasonable_count).to eq(1)

    post vote_suggestion_path(suggestion), params: { choice: "reasonable" }, as: :json
    expect(suggestion.reload.reasonable_count).to eq(2)

    post vote_suggestion_path(suggestion), params: { choice: "wrong" }, as: :json
    expect(suggestion.reload.wrong_count).to eq(1)
    expect(suggestion.reasonable_count).to eq(2)

    delete suggestion_path(suggestion)
    expect(response).to have_http_status(:not_found)
    expect(Suggestion.exists?(suggestion.id)).to be(true)

    own = user.suggestions.create!(body: "我写的")
    delete suggestion_path(own)
    expect(response).to redirect_to(suggestions_path)
    expect(Suggestion.exists?(own.id)).to be(false)
  end
end
