require "rails_helper"

RSpec.describe Groups::YearChart, type: :service do
  it "每个点截止到该周开始前，算不出的人整段为空" do
    on = Date.new(2026, 10, 20)
    group = Group.create!(name: "一年", public_id: "YR23CH45")
    adult = create(:user, display_name: "甲")
    child = create(:user, :under_six, display_name: "丙")
    [ adult, child ].each { |user| Membership.create!(group:, user:, role: user == adult ? :owner : :member, joined_at: Time.current) }
    sunday = Groups::Week.start_on(on) - 1
    travel_to on do
      create(:measurement, user: adult, metric_type: "height", value: 175, recorded_on: sunday)
      create(:measurement, user: adult, metric_type: "weight", value: 90, recorded_on: sunday)
      create(:measurement, user: adult, metric_type: "weight", value: 70, recorded_on: on)

      chart = described_class.for(group, on:)
      expect(chart[:mondays].size).to eq(52)
      member = chart[:members].find { |item| item[:name] == "甲" }
      baseline = Indices::Board.assemble(adult, on: sunday, as_of: sunday).mean
      expect(member[:values].last).to be_within(0.0001).of(baseline)
      expect(member[:values][-2]).to be_nil
      expect(chart[:members].find { |item| item[:name] == "丙" }[:values]).to all(be_nil)
    end
  end
end
