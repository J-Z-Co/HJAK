module Indices
  class Assessment
    KEYS = %w[bmi whtr whr navy rfm central_obesity bmr cardio].freeze
    LABELS = {
      "bmi" => "身体质量指数",
      "whtr" => "腰高比",
      "whr" => "腰臀比",
      "navy" => "海军体脂率",
      "rfm" => "相对脂肪质量指数",
      "central_obesity" => "中心性肥胖",
      "bmr" => "基础代谢率",
      "cardio" => "心血管"
    }.freeze

    Result = Data.define(
      :key, :label, :position, :value_text, :numeric, :deviation, :group,
      :note, :note_anchor, :profile_fields, :stale_text, :clickable, :chart, :bounds
    ) do
      def group_rank
        { scored: 0, reference: 1, inapplicable: 2, missing: 3 }.fetch(group)
      end
    end

    def self.call(key:, metrics:, sex:, birth_date:, on:, stale_labels: [])
      key = key.to_s
      position = KEYS.index(key)
      return unless position

      years = birth_date.present? ? Reference.years_on(sex: sex || :male, birth_date:, on:) : nil
      built = dispatch(key, metrics:, sex:, birth_date:, on:, years:)
      profile_fields = []
      profile_fields << :birth_date if birth_date.blank? && built[:group] != :inapplicable
      profile_fields << :sex if sex.blank? && sex_needed?(key, years, built)
      stale_text = if stale_labels.any? && built[:numeric] && %i[scored reference].include?(built[:group])
        "#{stale_labels.join("、")}已超过建议记录时间，结果仍按最近一次计算"
      end

      Result.new(
        key:,
        label: LABELS.fetch(key),
        position:,
        value_text: built[:value_text],
        numeric: built[:numeric],
        deviation: built[:deviation],
        group: built[:group],
        note: built[:note],
        note_anchor: built[:note_anchor],
        profile_fields:,
        stale_text:,
        clickable: built[:chart].present? && built[:group] != :inapplicable,
        chart: built[:chart],
        bounds: built[:bounds]
      )
    end

    def self.requirements(key, sex)
      case key.to_s
      when "bmi", "bmr" then %w[weight height]
      when "whtr", "rfm" then %w[waist height]
      when "whr" then %w[waist hip]
      when "navy" then sex.to_s == "female" ? %w[neck waist hip height] : %w[neck waist height]
      when "central_obesity" then %w[waist]
      when "cardio" then %w[blood_pressure resting_heart_rate]
      else []
      end
    end

    def self.explanation(key, years:)
      case key.to_s
      when "bmi"
        bounds = if years && years < 18
          "学龄按半岁档：低于超重为健康区，达到肥胖为警告。这张表不标偏低。"
        else
          "健康区 18.5–24。偏高到 28、偏低到 16 时，偏离分为 1。"
        end
        "用体重和身高筛查体重过低、正常、超重和肥胖。它分不出脂肪和肌肉，肌肉很多的人可能被看成偏重，脂肪多的老年人也可能仍落在正常范围。#{bounds}"
      when "whtr"
        bounds = if years && years < 18
          "学龄不用成人的 0.50 健康上界，警告界是 0.50，不设过低界。"
        else
          "健康区 0.40–0.50。偏高到 0.60、偏低到 0.35 时，偏离分为 1。"
        end
        "看腹部脂肪相对身高占了多少。腹部脂肪偏多时，糖尿病和心血管病的风险更高，这比只看体重更接近脂肪堆在哪里。#{bounds}"
      when "whr"
        "看脂肪更靠腹部还是更靠臀部。比值高是腰腹更突出的分布，心血管和糖尿病风险更高。男健康区低于 0.90，女低于 0.85。再高 0.10 时颜色拉满，不设过低界。未满 18 岁不用这项。"
      when "navy"
        "用围度估算体脂率，比只看体重更接近脂肪占了多少，但不是体成分仪的读数。男健康区 10–20%，女 18–28%。男警告界 25 与 5，女 32 与 13。未满 18 岁不适用此公式。"
      when "rfm"
        "用腰围、身高和性别估算体脂率，不必先称体重。男低于 25、女低于 35 为健康区。男 30、女 40 为警告界。未满 18 岁不用这项。"
      when "central_obesity"
        "直接看腰围所代表的腹部脂肪。腹部脂肪过多比皮下脂肪更易伴随胰岛素抵抗、脂肪肝和动脉粥样硬化。男腰围 85 cm、女 80 cm 起为前期，男 90 cm、女 85 cm 为中心性肥胖。未满 18 岁改看腰高比。"
      when "bmr"
        formula = years && years < 18 ? "这个年龄用学龄公式，不是成人公式。" : "成人用 Mifflin–St Jeor。"
        "维持呼吸、心跳和体温所需的最低热量，是安排每天吃多少的底数。这里只给出这个底数，不乘活动系数。#{formula}没有好坏界，不参与综合分，图上也不铺色带。"
      when "cardio"
        "血压看血管承受的压力，静息心率看心脏每次搏动的效率。两者一起用来看心血管负担，也用来判断现在适不适合加大运动。收缩压低于 120、舒张压低于 80，并且心率 60–100，偏离分为 0。家庭血压到 135 或 85、心率到 120 或 50 时，偏离分为 1。心率 50–59 落在中间，长期运动者常见。诊室 140/90 不参与着色。未满 18 岁不套用这套成人界值。"
      end
    end

    def self.dispatch(key, metrics:, sex:, birth_date:, on:, years:)
      case key
      when "bmi" then bmi(metrics, sex:, birth_date:, on:, years:)
      when "whtr" then whtr(metrics, sex:, birth_date:, on:, years:)
      when "whr" then whr(metrics, sex:, years:)
      when "navy" then navy(metrics, sex:, years:)
      when "rfm" then rfm(metrics, sex:, years:)
      when "central_obesity" then central(metrics, sex:, years:)
      when "bmr" then bmr(metrics, sex:, years:)
      when "cardio" then cardio(metrics, years:)
      end
    end
    private_class_method :dispatch

    def self.bmi(metrics, sex:, birth_date:, on:, years:)
      return gap(%w[weight height], metrics, :band) if absent(%w[weight height], metrics)
      number = Bmi.value(metrics.fetch("weight"), metrics.fetch("height"))
      return faded(number, one_decimal(number), :line) if years && years < 6
      return plain(number, one_decimal(number), :line) if birth_date.blank? || (years < 18 && sex.blank?)

      painted(number, one_decimal(number), Reference.bmi(sex:, birth_date:, on:), :band)
    end

    def self.whtr(metrics, sex:, birth_date:, on:, years:)
      return gap(%w[waist height], metrics, :band) if absent(%w[waist height], metrics)
      number = Whtr.value(metrics.fetch("waist"), metrics.fetch("height"))
      text = two_decimal(number)
      return faded(number, text, :line) if years && years < 6
      return plain(number, text, :line) if birth_date.blank? || (years < 18 && sex.blank?)

      painted(number, text, Reference.whtr(sex:, birth_date:, on:), :band)
    end

    def self.whr(metrics, sex:, years:)
      return inapplicable(Reference::ADULT_FORMULA) if years && years < 18
      return undisclosed(:band) if sex.blank? || years.nil?
      return gap(%w[waist hip], metrics, :band) if absent(%w[waist hip], metrics)

      number = Whr.value(metrics.fetch("waist"), metrics.fetch("hip"))
      painted(number, two_decimal(number), Reference.whr(sex:), :band)
    end

    def self.navy(metrics, sex:, years:)
      return inapplicable(Reference::ADULT_FORMULA) if years && years < 18
      return undisclosed(:band) if sex.blank? || years.nil?

      needed = requirements("navy", sex)
      return gap(needed, metrics, :band) if absent(needed, metrics)

      raw = Navy.from_centimeters(
        sex:,
        waist_cm: metrics.fetch("waist"),
        neck_cm: metrics.fetch("neck"),
        height_cm: metrics.fetch("height"),
        hip_cm: metrics["hip"]
      )
      return { numeric: nil, value_text: nil, deviation: nil, group: :missing, note: "腰围不大于颈围，暂时算不出体脂率", note_anchor: nil, chart: :band, bounds: nil } unless raw

      number = BigDecimal(raw.to_s).round(1).to_f
      band = sex.to_sym == :male ? navy_male_band : navy_female_band
      painted(number, "#{one_decimal(number)}%", band, :band)
    end

    def self.rfm(metrics, sex:, years:)
      return inapplicable(Reference::ADULT_FORMULA) if years && years < 18
      return undisclosed(:band) if sex.blank? || years.nil?
      return gap(%w[waist height], metrics, :band) if absent(%w[waist height], metrics)

      number = Rfm.value(sex:, waist_cm: metrics.fetch("waist"), height_cm: metrics.fetch("height"))
      painted(number, "#{one_decimal(number)}%", Reference::Band.new(**Rfm.bounds(sex:), low_health: nil, low_warn: nil, note: nil), :band)
    end

    def self.central(metrics, sex:, years:)
      return inapplicable(Reference::CENTRAL_UNDER_18, anchor: "whtr") if years && years < 18
      return undisclosed(:central) if sex.blank? || years.nil?
      return gap(%w[waist], metrics, :central) if absent(%w[waist], metrics)

      waist = metrics.fetch("waist").to_f
      band = Reference.central(sex:)
      text = "#{CentralObesity.label(sex:, waist_cm: waist)} · #{whole(waist)} cm"
      painted(waist, text, band, :central)
    end

    def self.bmr(metrics, sex:, years:)
      return inapplicable(Reference::BMR_UNDER_3) if years && years < 3
      return undisclosed(:line) if sex.blank? || years.nil?
      return gap(%w[weight height], metrics, :line) if absent(%w[weight height], metrics)

      number = Bmr.value(sex:, weight_kg: metrics.fetch("weight"), height_cm: metrics.fetch("height"), age_years: years)
      plain(number, "#{number} kcal/日", :line)
    end

    def self.cardio(metrics, years:)
      systolic, diastolic = Array(metrics["blood_pressure"])
      heart = metrics["resting_heart_rate"]
      text = cardio_text(systolic, diastolic, heart)
      if years && years < 18
        return {
          numeric: nil, value_text: text || "还没有记录", deviation: nil,
          group: text ? :reference : :inapplicable, note: Reference::CARDIO_UNDER_18,
          note_anchor: nil, chart: nil, bounds: nil
        }
      end
      return undisclosed(:cardio) if years.nil?
      return gap(%w[blood_pressure resting_heart_rate], metrics, :cardio) if systolic.nil? || diastolic.nil? || heart.nil?

      deviation = Cardio.score(systolic:, diastolic:, heart_rate: heart)
      {
        numeric: systolic.to_f, value_text: text, deviation:, group: :scored, note: nil, note_anchor: nil,
        chart: :cardio,
        bounds: { systolic: band_hash(Reference::SYSTOLIC), diastolic: band_hash(Reference::DIASTOLIC), heart_rate: band_hash(Reference::HEART_RATE) }
      }
    end

    def self.navy_male_band
      Reference::Band.new(high_health: 20, high_warn: 25, low_health: 10, low_warn: 5, note: nil)
    end

    def self.navy_female_band
      Reference::Band.new(high_health: 28, high_warn: 32, low_health: 18, low_warn: 13, note: nil)
    end

    def self.painted(number, text, band, chart)
      if band.note
        faded(number, text, :line).merge(note: band.note)
      else
        {
          numeric: number, value_text: text, deviation: band.deviation_for(number), group: :scored,
          note: nil, note_anchor: nil, chart:, bounds: band_hash(band)
        }
      end
    end

    def self.faded(number, text, chart)
      { numeric: number, value_text: text, deviation: nil, group: :reference, note: Reference::UNDER_SIX.note, note_anchor: nil, chart:, bounds: nil }
    end

    def self.plain(number, text, chart)
      { numeric: number, value_text: text, deviation: nil, group: :reference, note: nil, note_anchor: nil, chart:, bounds: nil }
    end

    def self.gap(keys, metrics, chart)
      labels = keys.filter_map { |key| Metrics::Catalog.find(key)&.label unless present_metric?(metrics, key) }
      { numeric: nil, value_text: nil, deviation: nil, group: :missing, note: "点亮#{labels.join("、")}后可计算", note_anchor: nil, chart:, bounds: nil }
    end

    def self.undisclosed(chart)
      { numeric: nil, value_text: nil, deviation: nil, group: :missing, note: nil, note_anchor: nil, chart:, bounds: nil }
    end

    def self.inapplicable(note, anchor: nil)
      { numeric: nil, value_text: nil, deviation: nil, group: :inapplicable, note:, note_anchor: anchor, chart: nil, bounds: nil }
    end

    def self.absent(keys, metrics)
      keys.any? { |key| !present_metric?(metrics, key) }
    end

    def self.present_metric?(metrics, key)
      value = metrics[key]
      return false if value.nil?
      return value.compact.size == 2 if value.is_a?(Array)

      true
    end

    def self.sex_needed?(key, years, built)
      return false if built[:group] == :inapplicable

      case key
      when "bmi", "whtr" then years && years >= 6 && years < 18
      when "whr", "navy", "rfm", "central_obesity", "bmr" then true
      else false
      end
    end

    def self.band_hash(band)
      { low_warn: band.low_warn, low_health: band.low_health, high_health: band.high_health, high_warn: band.high_warn }
    end

    def self.cardio_text(systolic, diastolic, heart)
      parts = []
      parts << "#{whole(systolic)}/#{whole(diastolic)} mmHg" if systolic && diastolic
      parts << "#{whole(heart)} 次/分" if heart
      parts.join("，").presence
    end

    def self.one_decimal(number)
      format("%.1f", number)
    end

    def self.two_decimal(number)
      format("%.2f", number)
    end

    def self.whole(number)
      number.to_f.round.to_i.to_s
    end
    private_class_method :bmi, :whtr, :whr, :navy, :rfm, :central, :bmr, :cardio,
      :navy_male_band, :navy_female_band, :painted, :faded, :plain, :gap, :undisclosed, :inapplicable,
      :absent, :present_metric?, :sex_needed?, :band_hash, :cardio_text, :one_decimal, :two_decimal, :whole
  end
end
