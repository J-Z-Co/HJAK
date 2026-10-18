module Indices
  class Bmr
    def self.value(sex:, weight_kg:, height_cm:, age_years:)
      return if age_years.nil? || age_years < 3

      amount = if age_years >= 18
        mifflin(sex:, weight_kg:, height_cm:, age_years:)
      else
        schofield(sex:, weight_kg:, height_cm:, age_years:)
      end
      amount.round(0).to_i
    end

    def self.mifflin(sex:, weight_kg:, height_cm:, age_years:)
      base = (10 * BigDecimal(weight_kg.to_s)) + (BigDecimal("6.25") * height_cm) - (5 * age_years)
      base + (sex.to_sym == :male ? 5 : -161)
    end

    def self.schofield(sex:, weight_kg:, height_cm:, age_years:)
      weight = BigDecimal(weight_kg.to_s)
      height = BigDecimal(height_cm.to_s)
      if age_years < 10
        if sex.to_sym == :male
          (19.6 * weight) + (1.303 * height) + 414.9
        else
          (16.97 * weight) + (1.618 * height) + 371.2
        end
      elsif sex.to_sym == :male
        (16.25 * weight) + (1.372 * height) + 515.5
      else
        (8.365 * weight) + (4.65 * height) + 200
      end
    end
    private_class_method :mifflin, :schofield
  end
end
