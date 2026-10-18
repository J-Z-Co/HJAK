module Indices
  class Board
    attr_reader :readings, :years

    def self.assemble(user, on: Time.zone.today)
      latest = user.measurements.order(recorded_on: :desc, recorded_at: :desc).group_by(&:metric_type).transform_values(&:first)
      metrics = latest.each_with_object({}) do |(key, measurement), collected|
        collected[key] = if key == "blood_pressure"
          [ measurement.value.to_f, measurement.value_secondary&.to_f ]
        else
          measurement.value.to_f
        end
      end
      years = user.birth_date.present? ? Reference.years_on(sex: user.sex || :male, birth_date: user.birth_date, on:) : nil
      readings = Assessment::KEYS.map { |key| reading_for(key, user, metrics, latest, on) }
      readings.sort_by! { |reading| [ reading.group_rank, reading.deviation || 0, reading.position ] }
      new(readings:, years:)
    end

    def self.reading_for(key, user, metrics, latest, on)
      stale = Assessment.requirements(key, user.sex).filter_map do |metric|
        measurement = latest[metric]
        Metrics::Catalog.find(metric).label if measurement && overdue?(measurement, on)
      end
      Assessment.call(key:, metrics:, sex: user.sex, birth_date: user.birth_date, on:, stale_labels: stale)
    end

    def self.overdue?(measurement, on)
      entry = Metrics::Catalog.find(measurement.metric_type)
      due = measurement.recorded_on + entry.interval_days
      on > due + 1
    end
    private_class_method :reading_for, :overdue?

    def initialize(readings:, years:)
      @readings = readings
      @years = years
    end

    def banner
      return "填写出生日期后，才能按年龄着色。" unless years

      if years >= 18
        "着色依据成人筛查范围，不是诊断。"
      elsif years >= 6
        "着色依据学龄筛查范围，不是诊断。海军体脂等成人公式不会套用。"
      else
        "这个年龄只记录数字，暂不着色。"
      end
    end

    def basis
      return unless years && years >= 6

      prefix = years >= 18 ? "按成人界值" : "按未成年界值"
      "#{prefix}，#{scored.size} 项可算"
    end

    def scored
      readings.select { |reading| reading.group == :scored }
    end

    def mean
      return if scored.empty?

      scored.sum(&:deviation) / scored.size
    end

    def compare?
      years && years >= 6
    end
  end
end
