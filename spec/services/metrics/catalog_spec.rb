require "rails_helper"

RSpec.describe Metrics::Catalog, type: :service do
  describe "体重的建议间隔" do
    let(:weight) { described_class.find("weight") }

    it "超过 20 岁改为每周一次；20 岁及以下、不知道年龄时仍是每天" do
      expect(weight.interval_for(21)).to eq(7)
      expect(weight.interval_for(45)).to eq(7)
      expect(weight.interval_for(20)).to eq(1)
      expect(weight.interval_for(10)).to eq(1)
      expect(weight.interval_for(nil)).to eq(1)
    end

    it "其他指标不随年龄变" do
      expect(described_class.find("resting_heart_rate").interval_for(45)).to eq(1)
      expect(described_class.find("waist").interval_for(45)).to eq(3)
    end
  end
end
