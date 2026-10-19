require "rails_helper"

RSpec.describe "记录", type: :request do
  def create_user(email)
    User.create!(display_name: email, email:, password: "password", birth_date: Date.new(2016, 1, 1), sex: :male)
  end

  describe "HT-08" do
    it "只提交体重时只多一条体重，5 kg 可以保存" do
      user = create_user("ht08@example.com")
      sign_in user

      expect {
        post measurements_path, params: {
          idempotency_key: SecureRandom.uuid,
          recorded_on: Time.zone.today,
          measurements: { weight: { value: "5" }, height: { value: "" } }
        }
      }.to change { user.measurements.count }.by(1)

      expect(user.measurements.sole.metric_type).to eq("weight")
      expect(user.measurements.sole.value).to eq(5)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("已保存体重")
    end
  end

  describe "HT-09" do
    it "血压只填收缩压时返回 422，且不新增记录" do
      user = create_user("ht09@example.com")
      sign_in user

      expect {
        post measurements_path, params: {
          idempotency_key: SecureRandom.uuid,
          recorded_on: Time.zone.today,
          measurements: { blood_pressure: { value: "120", value_secondary: "" }, weight: { value: "40" } }
        }
      }.not_to change(Measurement, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("请同时填写收缩压和舒张压")
    end
  end

  describe "HT-10" do
    it "同一个幂等键提交两次仍然只有一条" do
      user = create_user("ht10@example.com")
      sign_in user
      key = SecureRandom.uuid
      params = {
        idempotency_key: key,
        recorded_on: Time.zone.today,
        measurements: { weight: { value: "42" } }
      }

      post measurements_path, params: params
      post measurements_path, params: params.merge(measurements: { weight: { value: "99" } })

      expect(user.measurements.where(metric_type: "weight").count).to eq(1)
      expect(user.measurements.sole.value).to eq(42)
      follow_redirect!
      expect(response.body).to include("这次记录已经保存")
    end
  end

  describe "HT-11" do
    it "不能删除别人的记录，也不能打开没有共同群组的指数" do
      actor = create_user("ht11-a@example.com")
      other = create_user("ht11-b@example.com")
      sign_in actor
      record = other.measurements.create!(
        metric_type: "weight",
        recorded_on: Time.zone.today,
        recorded_at: Time.current,
        value: 30,
        idempotency_key: SecureRandom.uuid
      )
      group = Group.create!(name: "家", public_id: "AB23CD45")
      Membership.create!(group:, user: other, role: :owner, joined_at: Time.current)

      delete measurement_path(record)
      expect(Measurement.exists?(record.id)).to be(true)
      expect(response).to redirect_to(root_path)

      get group_member_indices_path(group.public_id, other.id)
      expect(response).to redirect_to(groups_path)
      follow_redirect!
      expect(response.body).to include("只能查看同组成员")
    end
  end

  it "低于 5 kg 的体重不会保存" do
    user = create_user("light@example.com")
    sign_in user

    expect {
      post measurements_path, params: {
        idempotency_key: SecureRandom.uuid,
        recorded_on: Time.zone.today,
        measurements: { weight: { value: "4.9" } }
      }
    }.not_to change(Measurement, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  describe "未到下次的行" do
    it "收进默认关闭的折叠区，该测的行照常展开" do
      user = create_user("early@example.com")
      user.measurements.create!(metric_type: "height", recorded_on: Time.zone.today, recorded_at: Time.current, value: 140, idempotency_key: SecureRandom.uuid)
      sign_in user

      get root_path
      html = Nokogiri::HTML(response.body)
      folded = html.at_css("[data-testid=record-early]")
      expect(folded).to be_present
      expect(folded["open"]).to be_nil
      expect(folded.at_css("[data-testid=record-row-height]")).to be_present
      expect(folded.at_css("[data-testid=record-row-weight]")).to be_nil
      expect(html.at_css("[data-testid=record-row-weight]")).to be_present
    end
  end
end
