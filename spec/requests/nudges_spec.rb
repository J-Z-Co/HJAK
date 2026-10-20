require "rails_helper"

RSpec.describe "催催", type: :request do
  def person(email, name)
    User.create!(display_name: name, email:, password: "password", sex: :male, birth_date: Date.new(1990, 1, 1))
  end

  def overdue(user)
    user.measurements.create!(
      metric_type: "waist", value: 80, recorded_on: Time.zone.today - 30, recorded_at: 30.days.ago,
      idempotency_key: SecureRandom.uuid
    )
  end

  it "图标留到对方新保存一条测量，纠正旧记录不会清掉" do
    actor = person("nudge-actor@example.com", "甲")
    other = person("nudge-other@example.com", "乙")
    third = person("nudge-third@example.com", "丙")
    blank = person("nudge-blank@example.com", "丁")
    group = Group.create!(name: "催促", public_id: "NG23CM45")
    other_group = Group.create!(name: "另一群", public_id: "NG89PT23")
    [ actor, other, third, blank ].each { |user| Membership.create!(group:, user:, role: user == actor ? :owner : :member, joined_at: Time.current) }
    Membership.create!(group: other_group, user: actor, role: :owner, joined_at: Time.current)
    Membership.create!(group: other_group, user: other, role: :member, joined_at: Time.current)
    overdue(actor)
    record = overdue(other)
    sign_in actor

    get group_path(group)
    expect(response.body).to include("催促乙")
    expect(response.body).not_to include("催促甲")
    expect(response.body).not_to include("催促丁")

    expect {
      post nudge_group_path(group), params: { subject_id: other.id }
    }.to change(Nudge, :count).by(1)
    follow_redirect!
    expect(response.body).to include("😜")
    expect(response.body).to include("今天已催")

    expect {
      post nudge_group_path(group), params: { subject_id: other.id }
    }.not_to change(Nudge, :count)

    sign_in third
    post nudge_group_path(group), params: { subject_id: other.id }
    follow_redirect!
    expect(response.body.scan("😜").size).to eq(2)
    expect(response.body).not_to include("+2")

    travel_to Time.zone.today + 1 do
      sign_in actor
      get group_path(group)
      expect(response.body.scan("😜").size).to eq(2)
      post nudge_group_path(group), params: { subject_id: other.id }
      follow_redirect!
      expect(response.body.scan("😜").size).to eq(3)
    end

    get group_path(other_group)
    expect(response.body).not_to include("😜")

    sign_in other
    patch correction_entry_path("waist", record), params: { value: "81" }
    expect(response).to redirect_to(correction_path("waist"))
    expect(Nudge.where(subject: other, resolved_at: nil).count).to eq(3)

    post measurements_path, params: {
      idempotency_key: SecureRandom.uuid,
      recorded_on: Time.zone.today,
      measurements: { weight: { value: "70" } }
    }
    expect(Nudge.where(subject: other, resolved_at: nil)).to be_empty
  end
end