module Indices
  class Series
    RANGES = { "7d" => 7, "30d" => 30, "365d" => 365 }.freeze

    def self.call(user:, key:, range:, on: Time.zone.today)
      key = key.to_s
      selected = if range.blank?
        "7d"
      elsif RANGES.key?(range)
        range
      else
        "30d"
      end
      start_on = on - (RANGES.fetch(selected) - 1)
      metrics = Assessment.requirements(key, user.sex)
      history = user.measurements.where(metric_type: metrics).where(recorded_on: ..on).order(:recorded_at, :id).to_a
      points = []

      # 同一天的身高和腰围会各来一条记录。指数按记录日收成一个点，用当天最后的快照。
      history.select { |event| event.recorded_on >= start_on }.group_by(&:recorded_on).each_value do |events|
        event = events.max_by { |measurement| [ measurement.recorded_at, measurement.id ] }
        snapshot = snapshot_at(history, metrics, event)
        reading = Assessment.call(key:, metrics: snapshot, sex: user.sex, birth_date: user.birth_date, on: event.recorded_on)
        next if reading.nil? || reading.numeric.nil? || reading.group == :inapplicable

        points << point_for(key, event, snapshot, reading)
      end

      { range: selected, kind: kind_for(key), points: }
    end

    def self.point_for(key, event, snapshot, reading)
      point = {
        at: event.recorded_at.iso8601,
        value: reading.numeric,
        text: reading.value_text,
        label: "#{event.recorded_on.month} 月 #{event.recorded_on.day} 日 #{reading.value_text}"
      }
      if key == "cardio"
        systolic, diastolic = Array(snapshot["blood_pressure"])
        point.merge(systolic:, diastolic:, heart_rate: snapshot["resting_heart_rate"], bands: reading.bounds)
      else
        point.merge(reading.bounds || {})
      end
    end

    def self.kind_for(key)
      case key
      when "central_obesity" then "central"
      when "bmr" then "line"
      when "cardio" then "cardio"
      else "band"
      end
    end

    def self.snapshot_at(history, metrics, event)
      metrics.to_h do |metric|
        chosen = history.select do |measurement|
          measurement.metric_type == metric && (
            measurement.recorded_at < event.recorded_at ||
            (measurement.recorded_at == event.recorded_at && measurement.id <= event.id)
          )
        end.max_by { |measurement| [ measurement.recorded_at, measurement.id ] }
        amount = if chosen.nil?
          nil
        elsif metric == "blood_pressure"
          [ chosen.value.to_f, chosen.value_secondary&.to_f ]
        else
          chosen.value.to_f
        end
        [ metric, amount ]
      end
    end
    private_class_method :point_for, :kind_for, :snapshot_at
  end
end
