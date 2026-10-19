module Gamification
  # 只奖励「记录」这个习惯：连续天数、今天的进度、徽章。
  # 不拿指数的好坏发奖，家里有未成年人，也不希望把健康结果做成比赛。
  # 和指数一样现算，不落库。
  class Progress
    Badge = Data.define(:key, :title, :hint, :icon, :earned)

    attr_reader :streak, :best_streak, :week_days, :today_done, :today_total, :badges, :total_records

    def self.for(user, on: Time.zone.today, rows: nil)
      rows ||= ::Measurements::Row.build(user, on:)
      new(user, on:, rows:)
    end

    def initialize(user, on:, rows:)
      @on = on
      dates = user.measurements.where(recorded_on: ..on).distinct.pluck(:recorded_on).sort
      @total_records = user.measurements.count
      @streak = current_streak(dates)
      @best_streak = longest_streak(dates)
      @week_days = dates.count { |date| date > on - 7 }
      recorded_today = user.measurements.where(recorded_on: on).distinct.pluck(:metric_type)
      waiting = rows.select { |row| %i[due overdue].include?(row.status) }.map(&:key)
      @today_done = recorded_today.size
      @today_total = (recorded_today | waiting).size
      @badges = build_badges(rows)
    end

    def today_complete?
      today_total.positive? && today_done >= today_total
    end

    def earned_count
      badges.count(&:earned)
    end

    private

    # 今天还没记不算断：从今天或昨天往回数
    def current_streak(dates)
      set = dates.to_set
      day = set.include?(@on) ? @on : @on - 1
      count = 0
      while set.include?(day)
        count += 1
        day -= 1
      end
      count
    end

    def longest_streak(dates)
      best = 0
      run = 0
      previous = nil
      dates.each do |date|
        run = previous && date == previous + 1 ? run + 1 : 1
        best = run if run > best
        previous = date
      end
      best
    end

    def build_badges(rows)
      all_lit = rows.none? { |row| row.status == :never }
      [
        Badge.new(key: "first", title: "初次点亮", hint: "记下第一项指标", icon: :sparkles, earned: total_records.positive?),
        Badge.new(key: "week", title: "一周不断", hint: "连续 7 天都有记录", icon: :fire, earned: best_streak >= 7),
        Badge.new(key: "month", title: "坚持一月", hint: "连续 30 天都有记录", icon: :trophy, earned: best_streak >= 30),
        Badge.new(key: "all_lit", title: "全部点亮", hint: "七项指标都记过", icon: :star, earned: all_lit),
        Badge.new(key: "on_time", title: "准时达人", hint: "全部点亮且没有逾期", icon: :clock, earned: all_lit && rows.none? { |row| row.status == :overdue }),
        Badge.new(key: "hundred", title: "百次记录", hint: "累计记下 100 条", icon: :chart_line, earned: total_records >= 100)
      ]
    end
  end
end
