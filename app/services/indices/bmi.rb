module Indices
  class Bmi
    def self.value(weight_kg, height_cm)
      height_m = BigDecimal(height_cm.to_s) / 100
      body_mass = BigDecimal(weight_kg.to_s) / (height_m * height_m)
      body_mass.round(1).to_f
    end
  end
end
