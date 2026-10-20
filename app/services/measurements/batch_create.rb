module Measurements
  class BatchCreate
    Result = Data.define(:saved, :errors, :already_saved)

    def self.call(user:, recorded_on:, idempotency_key:, rows:)
      new(user:, recorded_on:, idempotency_key:, rows:).call
    end

    def initialize(user:, recorded_on:, idempotency_key:, rows:)
      @user = user
      @recorded_on = recorded_on
      @idempotency_key = idempotency_key
      @rows = rows || {}
    end

    def call
      return Result.new(saved: [], errors: { base: "不能晚于今天" }, already_saved: false) if date.nil? || date > Time.zone.today
      return Result.new(saved: [], errors: {}, already_saved: true) if already_saved?

      prepared = prepare_rows
      return Result.new(saved: [], errors: prepared[:errors], already_saved: false) if prepared[:errors].any?
      return Result.new(saved: [], errors: {}, already_saved: false) if prepared[:entries].empty?

      saved = Measurement.transaction do
        prepared[:entries].map { |entry| @user.measurements.create!(entry) }
      end
      Result.new(saved:, errors: {}, already_saved: false)
    rescue ActiveRecord::RecordNotUnique
      Result.new(saved: [], errors: {}, already_saved: true)
    end

    private

    def date
      return @date if defined?(@date)

      @date = @recorded_on.is_a?(Date) ? @recorded_on : Date.iso8601(@recorded_on.to_s)
    rescue Date::Error
      @date = nil
    end

    def already_saved?
      @user.measurements.exists?(idempotency_key: @idempotency_key)
    end

    def prepare_rows
      errors = {}
      entries = []
      Metrics::Catalog.all.each do |metric|
        raw = @rows[metric.key] || @rows[metric.key.to_sym] || {}
        decimals = metric.blood_pressure? ? 0 : 2
        value = self.class.parse(raw[:value] || raw["value"], decimals:)
        secondary = self.class.parse(raw[:value_secondary] || raw["value_secondary"], decimals: 0)
        next if value.nil? && secondary.nil?

        error = self.class.validate_pair(metric, value, secondary)
        if error
          errors[metric.key] = error
        else
          entries << {
            metric_type: metric.key,
            recorded_on: date,
            recorded_at: Time.current,
            value: value,
            value_secondary: metric.blood_pressure? ? secondary : nil,
            idempotency_key: @idempotency_key
          }
        end
      end
      { errors:, entries: }
    end

    public

    def self.parse(raw, decimals: 2)
      text = raw.to_s.strip.tr("，。．", "...")
      return nil if text.empty?

      BigDecimal(text).round(decimals, :half_up)
    rescue ArgumentError
      :invalid
    end

    def self.check(metric, raw_value, raw_secondary)
      decimals = metric.blood_pressure? ? 0 : 2
      validate_pair(metric, parse(raw_value, decimals:), parse(raw_secondary, decimals: 0))
    end

    def self.validate_pair(metric, value, secondary)
      if metric.blood_pressure?
        return "请同时填写收缩压和舒张压" if value.nil? || secondary.nil? || value == :invalid || secondary == :invalid
        return "收缩压需在 #{metric.min}–#{metric.max}" unless value.between?(metric.min, metric.max)
        return "舒张压需在 #{metric.secondary_min}–#{metric.secondary_max}" unless secondary.between?(metric.secondary_min, metric.secondary_max)
        return "收缩压要大于舒张压" unless value > secondary

        nil
      else
        return "请填写数字" if value == :invalid || value.nil?
        return "#{metric.label}需在 #{metric.min}–#{metric.max} #{metric.unit}" unless value.between?(metric.min, metric.max)

        nil
      end
    end
  end
end
