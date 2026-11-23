require "rails_helper"

RSpec.describe "API 群组", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.api_token}" } }

  it "POST /api/v1/groups 创建群组并成为群主" do
    expect {
      post "/api/v1/groups", params: { name: "家" }, headers: headers, as: :json
    }.to change(Group, :count).by(1)

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body["group"]["role"]).to eq("owner")
  end

  it "GET /api/v1/groups 返回我的群组" do
    group = create(:group, name: "家")
    create(:membership, group: group, user: user, role: :owner, joined_at: Time.current)

    get "/api/v1/groups", headers: headers

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["groups"].size).to eq(1)
  end

  it "POST /api/v1/groups/join 用代号加入群组" do
    group = create(:group, name: "家")
    create(:membership, group: group, user: create(:user), role: :owner, joined_at: Time.current)

    post "/api/v1/groups/join", params: { code: group.public_id }, headers: headers, as: :json

    expect(response).to have_http_status(:created)
    expect(group.memberships.exists?(user: user)).to be(true)
  end

  it "GET /api/v1/groups/:public_id 返回榜单" do
    group = create(:group, name: "家")
    create(:membership, group: group, user: user, role: :owner, joined_at: Time.current)

    get "/api/v1/groups/#{group.public_id}", headers: headers

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["boards"].size).to eq(4)
    expect(body["rows"]).to be_an(Array)
  end
end
