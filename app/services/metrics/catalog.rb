module Metrics
  class Catalog
    # 超过 20 岁不再长高：身高记过一次以后就不用更新
    ADULT_AFTER_YEARS = 20

    Entry = Data.define(:key, :label, :unit, :interval_days, :min, :max, :secondary_min, :secondary_max, :settles_in_adulthood) do
      def initialize(settles_in_adulthood: false, **rest)
        super
      end

      def blood_pressure?
        key == "blood_pressure"
      end

      # 建议记录间隔（天）。years 是今天的整岁年龄，不知道年龄时按默认间隔。
      # 返回 nil 表示记过一次之后不用再更新
      def interval_for(years)
        return if settles_in_adulthood && years && years > ADULT_AFTER_YEARS

        interval_days
      end
    end

    ENTRIES = [
      Entry.new(key: "weight", label: "体重", unit: "kg", interval_days: 1, min: 5, max: 300, secondary_min: nil, secondary_max: nil),
      Entry.new(key: "height", label: "身高", unit: "cm", interval_days: 365, settles_in_adulthood: true, min: 50, max: 250, secondary_min: nil, secondary_max: nil),
      Entry.new(key: "waist", label: "腰围", unit: "cm", interval_days: 3, min: 20, max: 200, secondary_min: nil, secondary_max: nil),
      Entry.new(key: "hip", label: "臀围", unit: "cm", interval_days: 7, min: 20, max: 200, secondary_min: nil, secondary_max: nil),
      Entry.new(key: "neck", label: "颈围", unit: "cm", interval_days: 7, min: 15, max: 80, secondary_min: nil, secondary_max: nil),
      Entry.new(key: "blood_pressure", label: "血压", unit: "mmHg", interval_days: 3, min: 70, max: 250, secondary_min: 40, secondary_max: 150),
      Entry.new(key: "resting_heart_rate", label: "静息心率", unit: "次/分", interval_days: 1, min: 30, max: 220, secondary_min: nil, secondary_max: nil)
    ].freeze

    def self.all
      ENTRIES
    end

    def self.find(key)
      ENTRIES.find { |entry| entry.key == key.to_s }
    end
  end
end
