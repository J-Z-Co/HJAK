module Indices
  class Palette
    # 0 浅紫，0.5 琥珀，1 浅红，1.5 起深红。超过 2 不再加深。
    STOPS = [
      [ 0.0, [ 139, 124, 199 ] ],
      [ 0.5, [ 217, 119, 6 ] ],
      [ 1.0, [ 220, 90, 90 ] ],
      [ 1.5, [ 153, 27, 27 ] ],
      [ 2.0, [ 127, 29, 29 ] ]
    ].freeze

    def self.css(deviation)
      "rgb(#{rgb(deviation).join(", ")})"
    end

    def self.background(deviation)
      "rgba(#{rgb(deviation).join(", ")}, 0.12)"
    end

    def self.rgb(deviation)
      value = deviation.to_f.clamp(0, 2)
      left, right = STOPS.each_cons(2).find { |a, b| value <= b[0] }
      span = right[0] - left[0]
      ratio = span.zero? ? 0 : (value - left[0]) / span
      left[1].zip(right[1]).map { |from, to| (from + (to - from) * ratio).round }
    end
  end
end
