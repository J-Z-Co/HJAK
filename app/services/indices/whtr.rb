module Indices
  class Whtr
    def self.value(waist_cm, height_cm)
      (BigDecimal(waist_cm.to_s) / BigDecimal(height_cm.to_s)).round(2).to_f
    end
  end
end
