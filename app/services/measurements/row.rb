module Measurements
  class Row
    RANK = { due: 0, overdue: 1, early: 2, settled: 2, never: 3 }.freeze
    COLORS = { due: "#DCFCE7", overdue: "#FEF9C3", early: "#EDE9FE", settled: "#EDE9FE" }.freeze

    attr_reader :entry, :latest, :history, :error, :submitted_value, :submitted_secondary, :index

    def self.build(user, on: Time.zone.today, errors: {}, submitted: {})
      grouped = user.measurements.order(recorded_on: :desc, recorded_at: :desc).group_by(&:metric_type)
      years = user.age_years_on(on)
      Metrics::Catalog.all.map.with_index do |entry, index|
        raw = submitted[entry.key] || {}
        new(
          entry:,
          latest: grouped[entry.key]&.first,
          history: Array(grouped[entry.key]).first(30).reverse,
          on:,
          interval: entry.interval_for(years),
          index:,
          error: errors[entry.key],
          submitted_value: raw[:value] || raw["value"],
          submitted_secondary: raw[:value_secondary] || raw["value_secondary"]
        )
      end.sort_by { |row| [ row.sort_rank, row.index ] }
    end

    def initialize(entry:, latest:, history:, on:, interval:, index:, error:, submitted_value:, submitted_secondary:)
      @entry = entry
      @latest = latest
      @history = history
      @on = on
      @interval = interval
      @index = index
      @error = error
      @submitted_value = submitted_value
      @submitted_secondary = submitted_secondary
    end

    def key
      entry.key
    end

    def status
      return :never unless latest
      return :settled if @interval.nil?

      due = latest.recorded_on + @interval
      if @on < due - 1
        :early
      elsif @on > due + 1
        :overdue
      else
        :due
      end
    end

    def sort_rank
      RANK.fetch(status)
    end

    def background
      COLORS[status]
    end

    def caption
      case status
      when :never
        "还没有记录"
      when :settled
        "#{days_ago}，成年后无需更新"
      when :early
        "#{days_ago}，建议下次约 #{format_date(latest.recorded_on + @interval)}"
      when :due
        "已到建议记录时间，上次 #{relative_day}"
      when :overdue
        due = latest.recorded_on + @interval
        "已超过建议时间 #{(@on - due).to_i} 天，上次 #{relative_day}"
      end
    end

    private

    def days_ago
      days = (@on - latest.recorded_on).to_i
      days.zero? ? "今天记录" : "#{days} 天前记录"
    end

    def relative_day
      days = (@on - latest.recorded_on).to_i
      days.zero? ? "就在今天" : "#{days} 天前"
    end

    def format_date(date)
      "#{date.month} 月 #{date.day} 日"
    end
  end
end
