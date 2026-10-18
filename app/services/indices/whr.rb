module Indices
  class Whr
    def self.value(waist_cm, hip_cm)
      (BigDecimal(waist_cm.to_s) / BigDecimal(hip_cm.to_s)).round(2).to_f
    end
  end
end
