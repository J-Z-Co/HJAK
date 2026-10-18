module Indices
  class Brief
    Group = Data.define(:title, :status, :note, :aside, :readings)
    Result = Data.define(:lines, :groups)

    SECTIONS = [
      { title: "体重与代谢", keys: %w[bmi bmr], judged: %w[bmi] },
      { title: "体脂比例", keys: %w[navy rfm], judged: %w[navy rfm] },
      { title: "脂肪分布", keys: %w[whtr whr central_obesity], judged: %w[whtr whr central_obesity] },
      { title: "心血管", keys: %w[cardio], judged: %w[cardio] }
    ].freeze

    def self.for(board)
      new(board).to_result
    end

    def initialize(board)
      @board = board
    end

    def to_result
      Result.new(lines:, groups:)
    end

    private

    def lines
      return [ "这个年龄只记录数字，暂不比较偏离。" ] if @board.years && @board.years < 6

      written = [ lead ]
      written << "综合偏离 #{format('%.2f', @board.mean)}。" if @board.mean
      written << cardio_line if cardio_line
      written << "有过期输入，结论仍按最近一次。" if stale?
      written
    end

    def lead
      bits = [ weight_phrase, fat_phrase, place_phrase ].compact
      return scored? ? "目前算得出的项目都在健康区。" : "还缺测量，暂时给不出整体结论。" if bits.empty?

      sentence(bits)
    end

    def sentence(bits)
      merged = bits.dup
      if merged.include?("体重高出健康区") && merged.include?("体脂高出健康区")
        merged -= [ "体重高出健康区", "体脂高出健康区" ]
        merged.unshift("体重和体脂都高出健康区")
      end
      if merged == [ "体重和体脂都高出健康区", "脂肪开始集中在腹部" ]
        return "体重和体脂都高出健康区，脂肪也开始集中在腹部。"
      end

      return "#{merged.first}。" if merged.one?

      "#{merged[0..-2].join('，')}，#{merged.last}。"
    end

    def weight_phrase
      phrase("bmi", mild_high: "体重高出健康区", warn_high: "体重到了警告界", mild_low: "体重偏低", warn_low: "体重偏低到了警告界")
    end

    def fat_phrase
      phrase(%w[navy rfm], mild_high: "体脂高出健康区", warn_high: "体脂到了警告界", mild_low: "体脂偏低", warn_low: "体脂偏低到了警告界")
    end

    def place_phrase
      phrase(%w[whtr whr central_obesity], mild_high: "脂肪开始集中在腹部", warn_high: "脂肪分布到了警告界", mild_low: "脂肪分布偏低", warn_low: "脂肪分布偏低到了警告界")
    end

    def phrase(keys, phrases)
      readings = Array(keys).filter_map { |key| reading_for(key) }.select { |reading| reading.group == :scored && reading.deviation.to_f.positive? }
      return if readings.empty?

      phrases[level(readings.max_by { |reading| reading.deviation.to_f })]
    end

    def cardio_line
      reading = reading_for("cardio")
      return unless reading&.group == :scored && reading.deviation.to_f.positive?

      reading.deviation.to_f >= 1 ? "血压和心率到了警告界。" : "血压和心率离开了健康区。"
    end

    def stale?
      @board.readings.any? { |reading| reading.group == :scored && reading.stale_text.present? }
    end

    def scored?
      @board.readings.any? { |reading| reading.group == :scored }
    end

    def groups
      SECTIONS.map do |section|
        readings = section[:keys].map { |key| reading_for(key) }
        judged = section[:judged].map { |key| reading_for(key) }
        if judged.all? { |reading| reading.group == :inapplicable }
          Group.new(title: section[:title], status: nil, note: judged.filter_map(&:note).uniq.first, aside: nil, readings: [])
        else
          skipped = judged.select { |reading| reading.group == :inapplicable }
          aside = skipped.empty? ? nil : "#{skipped.map(&:label).join('、')}未满 18 岁不看。"
          Group.new(
            title: section[:title],
            status: status_for(judged),
            note: nil,
            aside:,
            readings: readings.reject { |reading| reading.group == :inapplicable }
          )
        end
      end
    end

    def status_for(judged)
      scored = judged.select { |reading| reading.group == :scored }
      if scored.empty?
        return "暂不比较" if judged.any? { |reading| reading.group == :reference }

        return "还缺数据"
      end

      case level(scored.max_by { |reading| reading.deviation.to_f })
      when :ok then "在健康区"
      when :mild_high then "偏高"
      when :warn_high then "到了警告界"
      else "偏低"
      end
    end

    def level(reading)
      return :ok if reading.deviation.to_f.zero?

      low_bound = reading.bounds&.[](:low_health)
      side = low_bound && reading.numeric && reading.numeric < low_bound ? "low" : "high"
      reading.deviation.to_f >= 1 ? :"warn_#{side}" : :"mild_#{side}"
    end

    def reading_for(key)
      @board.readings.find { |reading| reading.key == key }
    end
  end
end
