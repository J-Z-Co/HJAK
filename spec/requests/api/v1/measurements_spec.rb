require "rails_helper"

RSpec.describe "API 记录", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.api_token}" } }

  describe "GET /api/v1/measurements/new" do
    it "返回 7 行记录与进度" do
      get "/api/v1/measurements/new", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["rows"].size).to eq(7)
      expect(body["idempotency_key"]).to be_present
      expect(body["progress"]["badges"]).to be_an(Array)
    end
  end

  describe "POST /api/v1/measurements" do
    it "保存体重并返回 201" do
      expect {
        post "/api/v1/measurements",
             params: { recorded_on: Time.zone.today.to_s, idempotency_key: SecureRandom.uuid, measurements: { weight: { value: "70" } } },
             headers: headers, as: :json
      }.to change(user.measurements, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["saved"]).to eq([ "体重" ])
    end

    it "血压只填收缩压返回 422 且不新增" do
      expect {
        post "/api/v1/measurements",
             params: { recorded_on: Time.zone.today.to_s, idempotency_key: SecureRandom.uuid, measurements: { blood_pressure: { value: "120", value_secondary: "" } } },
             headers: headers, as: :json
      }.not_to change(Measurement, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to have_key("blood_pressure")
    end
  end

  describe "DELETE /api/v1/measurements/:id" do
    it "删除自己的记录" do
      measurement = create(:measurement, user: user)
      expect {
        delete "/api/v1/measurements/#{measurement.id}", headers: headers
      }.to change(user.measurements, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "不能删除别人的记录" do
      other = create(:user)
      measurement = create(:measurement, user: other)
      delete "/api/v1/measurements/#{measurement.id}", headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(Measurement.exists?(measurement.id)).to be(true)
    end
  end
end
