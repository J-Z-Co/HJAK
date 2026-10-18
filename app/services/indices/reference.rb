module Indices
  class Reference
    Band = Data.define(:high_health, :high_warn, :low_health, :low_warn, :note) do
      def deviation_for(value)
        return if note

        Indices::Deviation.score(value, high_health:, high_warn:, low_health:, low_warn:)
      end
    end

    # WS/T 586—2018 半岁档：超重界、肥胖界。偏低侧不在这张表里。
    BMI_ROWS = {
      6.0 => { male: [ 16.4, 17.7 ], female: [ 16.2, 17.5 ] },
      6.5 => { male: [ 16.7, 18.1 ], female: [ 16.5, 18.0 ] },
      7.0 => { male: [ 17.0, 18.7 ], female: [ 16.8, 18.5 ] },
      7.5 => { male: [ 17.4, 19.2 ], female: [ 17.2, 19.0 ] },
      8.0 => { male: [ 17.8, 19.7 ], female: [ 17.6, 19.4 ] },
      8.5 => { male: [ 18.1, 20.3 ], female: [ 18.1, 19.9 ] },
      9.0 => { male: [ 18.5, 20.8 ], female: [ 18.5, 20.4 ] },
      9.5 => { male: [ 18.9, 21.4 ], female: [ 19.0, 21.0 ] },
      10.0 => { male: [ 19.2, 21.9 ], female: [ 19.5, 21.5 ] },
      10.5 => { male: [ 19.6, 22.5 ], female: [ 20.0, 22.1 ] },
      11.0 => { male: [ 19.9, 23.0 ], female: [ 20.5, 22.7 ] },
      11.5 => { male: [ 20.3, 23.6 ], female: [ 21.1, 23.3 ] },
      12.0 => { male: [ 20.7, 24.1 ], female: [ 21.5, 23.9 ] },
      12.5 => { male: [ 21.0, 24.7 ], female: [ 21.9, 24.5 ] },
      13.0 => { male: [ 21.4, 25.2 ], female: [ 22.2, 25.0 ] },
      13.5 => { male: [ 21.9, 25.7 ], female: [ 22.6, 25.6 ] },
      14.0 => { male: [ 22.3, 26.1 ], female: [ 22.8, 25.9 ] },
      14.5 => { male: [ 22.6, 26.4 ], female: [ 23.0, 26.3 ] },
      15.0 => { male: [ 22.9, 26.6 ], female: [ 23.2, 26.6 ] },
      15.5 => { male: [ 23.1, 26.9 ], female: [ 23.4, 26.9 ] },
      16.0 => { male: [ 23.3, 27.1 ], female: [ 23.6, 27.1 ] },
      16.5 => { male: [ 23.5, 27.4 ], female: [ 23.7, 27.4 ] },
      17.0 => { male: [ 23.7, 27.6 ], female: [ 23.8, 27.6 ] },
      17.5 => { male: [ 23.8, 27.8 ], female: [ 23.9, 27.8 ] }
    }.freeze

    ADULT_BMI = Band.new(high_health: 24, high_warn: 28, low_health: 18.5, low_warn: 16, note: nil)
    ADULT_WHTR = Band.new(high_health: 0.50, high_warn: 0.60, low_health: 0.40, low_warn: 0.35, note: nil)
    UNDER_SIX = Band.new(high_health: nil, high_warn: nil, low_health: nil, low_warn: nil, note: "未满 6 岁，暂不着色")
    NAVY_UNDER_18 = "未满 18 岁不适用此公式"
    ADULT_FORMULA = "未满 18 岁不适用此公式"
    CENTRAL_UNDER_18 = "请看腰高比"
    CARDIO_UNDER_18 = "未满 18 岁不套用成人界值"
    BMR_UNDER_3 = "未满 3 岁不计算"

    def self.bmi(sex:, birth_date:, on:)
      user = profile(sex:, birth_date:)
      years = user.age_years_on(on)
      return UNDER_SIX if years < 6
      return ADULT_BMI if years >= 18

      high_health, high_warn = BMI_ROWS.fetch(user.bmi_half_year_on(on)).fetch(sex.to_sym)
      Band.new(high_health:, high_warn:, low_health: nil, low_warn: nil, note: nil)
    end

    def self.whtr(sex:, birth_date:, on:)
      years = years_on(sex:, birth_date:, on:)
      return UNDER_SIX if years < 6
      return ADULT_WHTR if years >= 18

      high_health = if sex.to_sym == :female
        0.456
      elsif years < 13
        0.487
      else
        0.468
      end
      Band.new(high_health:, high_warn: 0.50, low_health: nil, low_warn: nil, note: nil)
    end

    def self.whr(sex:)
      if sex.to_sym == :male
        Band.new(high_health: 0.90, high_warn: 1.00, low_health: nil, low_warn: nil, note: nil)
      else
        Band.new(high_health: 0.85, high_warn: 0.95, low_health: nil, low_warn: nil, note: nil)
      end
    end

    def self.central(sex:)
      if sex.to_sym == :male
        Band.new(high_health: 85, high_warn: 90, low_health: nil, low_warn: nil, note: nil)
      else
        Band.new(high_health: 80, high_warn: 85, low_health: nil, low_warn: nil, note: nil)
      end
    end

    SYSTOLIC = Band.new(high_health: 120, high_warn: 135, low_health: 90, low_warn: 80, note: nil)
    DIASTOLIC = Band.new(high_health: 80, high_warn: 85, low_health: 60, low_warn: 50, note: nil)
    HEART_RATE = Band.new(high_health: 100, high_warn: 120, low_health: 60, low_warn: 50, note: nil)

    def self.navy_note(birth_date:, on:)
      years = years_on(sex: :male, birth_date:, on:)
      NAVY_UNDER_18 if years < 18
    end

    def self.years_on(sex:, birth_date:, on:)
      profile(sex:, birth_date:).age_years_on(on)
    end

    def self.profile(sex:, birth_date:)
      User.new(sex:, birth_date:)
    end
    private_class_method :profile
  end
end
