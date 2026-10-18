module Indices
  class Rfm
    def self.value(sex:, waist_cm:, height_cm:)
      base = sex.to_sym == :male ? 64 : 76
      (base - 20.0 * (height_cm.to_f / waist_cm)).round(1)
    end

    def self.bounds(sex:)
      if sex.to_sym == :male
        { high_health: 25, high_warn: 30 }
      else
        { high_health: 35, high_warn: 40 }
      end
    end
  end
end
