require "rails_helper"

RSpec.describe "群组", type: :request do
  def person(email, birth_date: Date.new(1990, 1, 1))
    User.create!(display_name: email, email:, password: "password", sex: :male, birth_date:)
  end

  it "HT-12 打开加入链接不入组，提交后才入组" do
    owner = person("group-owner@example.com")
    guest = person("group-guest@example.com")
    group = Group.create!(name: "家里", public_id: "AB23CD45")
    Membership.create!(group:, user: owner, role: :owner, joined_at: Time.current)
    sign_in guest

    expect {
      get join_group_path(code: group.public_id)
    }.not_to change(Membership, :count)
    expect(response.body).to include("家里")
    expect(response.body).to include("join-group")

    expect {
      post join_group_path, params: { code: "https://example.com/groups/join?code=#{group.public_id}" }
    }.to change(Membership, :count).by(1)
    expect(response).to redirect_to(group_path(group))
  end

  it "代号不存在时不入组" do
    guest = person("group-missing@example.com")
    sign_in guest

    expect {
      post join_group_path, params: { code: "ZZZZZZZZ" }
    }.not_to change(Membership, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("没有这个群组")
  end

  it "已经是成员时直接进入，不新增成员" do
    user = person("group-again@example.com")
    group = Group.create!(name: "旧群", public_id: "CD45EF67")
    Membership.create!(group:, user:, role: :member, joined_at: Time.current)
    sign_in user

    expect {
      post join_group_path, params: { code: group.public_id }
    }.not_to change(Membership, :count)
    expect(response).to redirect_to(group_path(group))
  end

  it "同组成员可以打开对方的指数" do
    actor = person("group-viewer@example.com")
    mate = person("group-mate@example.com")
    mate.update!(display_name: "同组")
    group = Group.create!(name: "可见", public_id: "GH89JK23")
    Membership.create!(group:, user: actor, role: :owner, joined_at: Time.current)
    Membership.create!(group:, user: mate, role: :member, joined_at: Time.current)
    sign_in actor

    get group_member_indices_path(group, mate)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("同组的指数")
    expect(response.body).to include("未点亮")
  end

  it "同组成员可以打开过期指数的图表" do
    actor = person("group-chart@example.com")
    mate = person("group-chart-mate@example.com")
    group = Group.create!(name: "图表", public_id: "JK23LM45")
    Membership.create!(group:, user: actor, role: :owner, joined_at: Time.current)
    Membership.create!(group:, user: mate, role: :member, joined_at: Time.current)
    on = Date.new(2026, 10, 17)
    mate.measurements.create!(metric_type: "height", value: 175, recorded_on: on, recorded_at: Time.zone.local(2026, 10, 17, 8), idempotency_key: SecureRandom.uuid)
    mate.measurements.create!(metric_type: "waist", value: 80, recorded_on: on - 40, recorded_at: Time.zone.local(2026, 9, 7, 8), idempotency_key: SecureRandom.uuid)
    sign_in actor

    get group_member_index_path(group, mate, "whtr")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("腰围已超过建议记录时间，结果仍按最近一次计算")
    expect(response.body).to include("健康区 0.40–0.50")
  end

  it "群里还有别人时群主不能退出" do
    owner = person("group-stay@example.com")
    other = person("group-other@example.com", birth_date: Date.new(2021, 1, 1))
    group = Group.create!(name: "两个人", public_id: "EF67GH89")
    Membership.create!(group:, user: owner, role: :owner, joined_at: Time.current)
    Membership.create!(group:, user: other, role: :member, joined_at: Time.current)
    sign_in owner

    delete group_membership_path(group.public_id)

    expect(response).to redirect_to(group_path(group))
    expect(group.memberships.where(user: owner)).to exist
    follow_redirect!
    expect(response.body).to include("群里还有别人，群主不能退出")
    expect(response.body).to include("未满 6 岁，不参与排名")
  end
end
