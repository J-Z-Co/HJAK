require "rails_helper"

RSpec.describe Metrics::Catalog, type: :service do
  describe "建议间隔" do
    it "体重任何年龄都是每天" do
      weight = described_class.find("weight")
      expect(weight.interval_for(45)).to eq(1)
      expect(weight.interval_for(10)).to eq(1)
      expect(weight.interval_for(nil)).to eq(1)
    end

    it "身高超过 20 岁不用再更新；20 岁及以下、不知道年龄时每年一次" do
      height = described_class.find("height")
      expect(height.interval_for(21)).to be_nil
      expect(height.interval_for(45)).to be_nil
      expect(height.interval_for(20)).to eq(365)
      expect(height.interval_for(10)).to eq(365)
      expect(height.interval_for(nil)).to eq(365)
    end

    it "其他指标不随年龄变" do
      expect(described_class.find("waist").interval_for(45)).to eq(3)
      expect(described_class.find("resting_heart_rate").interval_for(45)).to eq(1)
    end
  end
end
