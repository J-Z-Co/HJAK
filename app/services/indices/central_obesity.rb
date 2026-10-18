module Indices
  class CentralObesity
    def self.label(sex:, waist_cm:)
      band = Reference.central(sex:)
      if waist_cm < band.high_health
        "未达"
      elsif waist_cm < band.high_warn
        "前期"
      else
        "中心性肥胖"
      end
    end
  end
end
