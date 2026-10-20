module Groups
  module Week
    # 北京时间周一 00:00 所在的日期。周日的 wday 是 0，Ruby 里 (-1) % 7 等于 6。
    def self.start_on(on = Time.zone.today)
      on - ((on.wday - 1) % 7)
    end
  end
end
