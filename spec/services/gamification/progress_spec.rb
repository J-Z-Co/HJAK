require "rails_helper"

RSpec.describe Gamification::Progress, type: :service do
  let(:today) { Date.new(2026, 10, 16) }
  let(:user) { create(:user) }

  def record(metric_type, days_ago)
    create(:measurement, user:, metric_type:, recorded_on: today - days_ago)
  end

  it "今天还没记时，连续天数从昨天往回数；最长连续单独算" do
    travel_to today do
      [ 1, 2, 3 ].each { |days| record("weight", days) }
      [ 10, 11, 12, 13, 14 ].each { |days| record("weight", days) }

      progress = described_class.for(user, on: today)
      expect(progress.streak).to eq(3)
      expect(progress.best_streak).to eq(5)
    end
  end

  it "今天的进度 = 今天记下的项 / 今天记下的项加上该测和逾期的项" do
    travel_to today do
      # 静息心率任何年龄都是每天；体重对成年人是每周，不适合这里
      record("resting_heart_rate", 1)
      record("waist", 10)
      record("height", 0)

      progress = described_class.for(user, on: today)
      expect(progress.today_done).to eq(1)
      expect(progress.today_total).to eq(3)
      expect(progress.today_complete?).to be(false)
    end
  end

  it "徽章只看记录习惯：七项都记过点亮「全部点亮」，有逾期就没有「准时达人」" do
    travel_to today do
      Metrics::Catalog.all.each { |entry| create(:measurement, user:, metric_type: entry.key, recorded_on: today, value_secondary: (80 if entry.blood_pressure?), value: (120 if entry.blood_pressure?) || 70) }
      earned = described_class.for(user, on: today).badges.select(&:earned).map(&:key)
      expect(earned).to include("first", "all_lit", "on_time")
      expect(earned).not_to include("week", "hundred")
    end

    travel_to today + 10 do
      earned = described_class.for(user, on: today + 10).badges.select(&:earned).map(&:key)
      expect(earned).to include("all_lit")
      expect(earned).not_to include("on_time")
    end
  end

  it "没有任何记录时一枚徽章也没有" do
    travel_to today do
      progress = described_class.for(user, on: today)
      expect(progress.earned_count).to eq(0)
      expect(progress.streak).to eq(0)
    end
  end
end
