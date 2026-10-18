require "rails_helper"

RSpec.describe "手测夹具" do
  it "能造出学龄、未满 6 岁、血压，以及带群主的群组" do
    child = create(:user, :child)
    young = create(:user, :under_six)
    expect(child.age_years_on(Time.zone.today)).to eq(10)
    expect(young.age_years_on(Time.zone.today)).to eq(5)

    pressure = create(:measurement, :blood_pressure)
    expect(pressure.value_secondary).to eq(80)

    group = create(:group_with_owner)
    expect(group.memberships.sole).to be_owner
  end
end
