module Indices
  class Navy
    CM_PER_INCH = BigDecimal("2.54")

    def self.from_centimeters(sex:, waist_cm:, neck_cm:, height_cm:, hip_cm: nil)
      return if log_argument(sex:, waist_cm:, neck_cm:, hip_cm:).nil?

      if sex.to_sym == :male
        86.010 * Math.log10(waist_cm - neck_cm) - 70.041 * Math.log10(height_cm) + male_constant
      else
        163.205 * Math.log10(waist_cm + hip_cm - neck_cm) - 97.684 * Math.log10(height_cm) + female_constant
      end
    end

    def self.from_inches(sex:, waist_cm:, neck_cm:, height_cm:, hip_cm: nil)
      return if log_argument(sex:, waist_cm:, neck_cm:, hip_cm:).nil?

      waist = waist_cm / CM_PER_INCH
      neck = neck_cm / CM_PER_INCH
      height = height_cm / CM_PER_INCH
      if sex.to_sym == :male
        86.010 * Math.log10(waist - neck) - 70.041 * Math.log10(height) + 36.76
      else
        hip = hip_cm / CM_PER_INCH
        163.205 * Math.log10(waist + hip - neck) - 97.684 * Math.log10(height) - 78.387
      end
    end

    def self.male_constant
      36.76 - (86.010 - 70.041) * Math.log10(CM_PER_INCH)
    end

    def self.female_constant
      -78.387 - (163.205 - 97.684) * Math.log10(CM_PER_INCH)
    end

    def self.log_argument(sex:, waist_cm:, neck_cm:, hip_cm:)
      argument = if sex.to_sym == :male
        waist_cm - neck_cm
      else
        return if hip_cm.nil?

        waist_cm + hip_cm - neck_cm
      end
      argument if argument.positive?
    end
    private_class_method :log_argument
  end
end
