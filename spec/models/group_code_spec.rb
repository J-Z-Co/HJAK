require "rails_helper"

RSpec.describe GroupCode, type: :model do
  describe "HT-07" do
    it "从裸代号和加入链接里取出同一个代号" do
      code = "AB23CD45"

      expect(described_class.parse(code)).to eq(code)
      expect(described_class.parse("https://example.com/groups/join?code=#{code}")).to eq(code)
    end
  end
end
