module Indices
  class Deviation
    CAP = 2

    def self.score(value, high_health:, high_warn:, low_health: nil, low_warn: nil)
      value = decimal(value)
      high_health = decimal(high_health)
      return 0 if value <= high_health && (low_health.nil? || value >= decimal(low_health))

      raw = if value > high_health
        (value - high_health) / (decimal(high_warn) - high_health)
      else
        low_health = decimal(low_health)
        (low_health - value) / (low_health - decimal(low_warn))
      end
      raw.to_f.clamp(0, CAP)
    end

    def self.decimal(number)
      BigDecimal(number.to_s)
    end
    private_class_method :decimal
  end
end
