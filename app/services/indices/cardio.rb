module Indices
  class Cardio
    def self.score(systolic:, diastolic:, heart_rate:)
      [
        Reference::SYSTOLIC.deviation_for(systolic),
        Reference::DIASTOLIC.deviation_for(diastolic),
        Reference::HEART_RATE.deviation_for(heart_rate)
      ].max
    end
  end
end
