module Groups
  # 现状、改善、达标、徽章。旧的「最近 7 天有记录的天数」不再单独成榜。
  class Leaderboard
    Board = Data.define(:key, :label, :hint, :unit)
    Row = Data.define(
      :user, :rank, :value, :value_text, :note, :streak, :deviation, :kind,
      :nudge_count, :nudgeable, :nudged_today
    )

    BOARDS = [
      Board.new(key: "health", label: "现状", hint: "此刻的综合偏离，越小越接近健康区", unit: nil),
      Board.new(key: "trend", label: "改善", hint: "本周开始前到现在，综合偏离下降得越多越靠前", unit: nil),
      Board.new(key: "fresh", label: "达标", hint: "此刻仍在建议时间内的项数，共 7 项", unit: nil),
      Board.new(key: "badges", label: "徽章", hint: "已经点亮的徽章数，0 枚不排名", unit: "枚")
    ].freeze

    def self.board(key)
      BOARDS.find { |board| board.key == key.to_s } || BOARDS.first
    end

    def self.for(group, board: "health", on: Time.zone.today, actor: nil)
      new(group, board: self.board(board), on:, actor:).rows
    end

    def initialize(group, board:, on:, actor:)
      @group = group
      @board = board
      @on = on
      @actor = actor
    end

    def rows
      built = case @board.key
      when "trend" then trend_rows
      when "fresh" then fresh_rows
      when "badges" then badge_rows
      else health_rows
      end
      attach_nudges(built).sort_by { |row| [ row.rank || 1_000_000, row.user.id ] }
    end

    private

    def members
      @members ||= @group.memberships.includes(:user).map(&:user)
    end

    def measurement_rows
      @measurement_rows ||= members.to_h { |user| [ user.id, ::Measurements::Row.build(user, on: @on) ] }
    end

    def progress_for(user)
      ::Gamification::Progress.for(user, on: @on, rows: measurement_rows[user.id])
    end

    def health_rows
      ::Groups::Ranking.for(@group, on: @on).map do |row|
        stale = row.board.readings.any? { |reading| reading.group == :scored && reading.stale_text.present? }
        note = row.basis
        note = "#{note}，有过期输入" if row.rank && stale && note.present?
        build_row(
          user: row.user, rank: row.rank, value: row.score, deviation: row.score,
          value_text: row.score ? format("%.2f", row.score) : "不排名",
          note:, progress: progress_for(row.user)
        )
      end
    end

    def trend_rows
      baseline = Week.start_on(@on) - 1
      built = members.map do |user|
        now = ::Indices::Board.assemble(user, on: @on)
        earlier = ::Indices::Board.assemble(user, on: baseline, as_of: baseline)
        change, count = delta(now, earlier)
        [ user, now, change, count ]
      end
      ranks = competition_ranks(built.to_h { |user, _, change, _| [ user.id, change ] }, better: :high)
      built.map do |user, now, change, count|
        build_row(
          user:, rank: ranks[user.id], value: change, deviation: nil,
          value_text: change.nil? ? "不排名" : format_delta(change),
          note: trend_note(now, change, count), progress: progress_for(user)
        )
      end
    end

    def fresh_rows
      built = members.map do |user|
        rows = measurement_rows[user.id]
        count = rows.count { |row| %i[early due settled].include?(row.status) }
        [ user, count, fresh_note(rows) ]
      end
      ranks = competition_ranks(built.to_h { |user, count, _| [ user.id, count ] }, better: :high)
      built.map do |user, count, note|
        build_row(
          user:, rank: ranks[user.id], value: count, deviation: nil,
          value_text: "#{count}/7", note:, progress: progress_for(user)
        )
      end
    end

    def badge_rows
      built = members.map { |user| [ user, progress_for(user) ] }
      ranks = competition_ranks(built.to_h { |user, progress| [ user.id, progress.earned_count ] }, better: :high, zero_unranked: true)
      built.map do |user, progress|
        count = progress.earned_count
        build_row(
          user:, rank: ranks[user.id], value: count, deviation: nil,
          value_text: ranks[user.id] ? "#{count} 枚" : "不排名",
          note: "累计 #{progress.total_records} 条记录", progress:
        )
      end
    end

    def build_row(user:, rank:, value:, value_text:, note:, progress:, deviation:)
      Row.new(
        user:, rank:, value:, value_text:, note:, streak: progress.streak, deviation:, kind: @board.key,
        nudge_count: 0, nudgeable: measurement_rows[user.id].any? { |row| row.status == :overdue }, nudged_today: false
      )
    end

    def delta(now, earlier)
      return [ nil, 0 ] unless now.compare? && earlier.compare?

      keys = now.scored.map(&:key) & earlier.scored.map(&:key)
      return [ nil, 0 ] if keys.empty?

      [ mean_of(earlier, keys) - mean_of(now, keys), keys.size ]
    end

    def mean_of(board, keys)
      readings = board.scored.select { |reading| keys.include?(reading.key) }
      readings.sum(&:deviation) / readings.size
    end

    def trend_note(now, change, count)
      return "比较了 #{count} 项" unless change.nil?
      return "未满 6 岁，不参与排名" if now.years && now.years < 6

      now.years ? "本周开始时算不出" : "填写出生日期后才能排名"
    end

    def fresh_note(rows)
      overdue = rows.select { |row| row.status == :overdue }.map { |row| row.entry.label }
      missing = rows.select { |row| row.status == :never }.map { |row| row.entry.label }
      return "七项都在时效内" if overdue.empty? && missing.empty?

      parts = []
      parts << "#{overdue.join("、")}已过期" if overdue.any?
      parts << "#{missing.join("、")}未记" if missing.any?
      parts.join("，")
    end

    def format_delta(value)
      rounded = value.round(2)
      return "0" if rounded.zero?
      return "+#{format("%.2f", rounded)}" if rounded.positive?

      format("%.2f", rounded).tr("-", "−")
    end

    def competition_ranks(values, better:, zero_unranked: false)
      pool = values.reject { |_id, value| value.nil? }
      pool = pool.select { |_id, value| value.positive? } if zero_unranked
      ordered = pool.sort_by { |id, value| [ better == :high ? -value : value, id ] }
      ranks = {}
      last = nil
      rank = 0
      ordered.each_with_index do |(id, value), index|
        key = value.is_a?(Float) ? value.round(6) : value
        rank = index + 1 if key != last
        last = key
        ranks[id] = rank
      end
      ranks
    end

    def attach_nudges(rows)
      counts = @group.nudges.where(resolved_at: nil).group(:subject_id).count
      today = if @actor
        @group.nudges.where(actor: @actor, nudged_on: @on).pluck(:subject_id)
      else
        []
      end
      rows.map do |row|
        row.with(nudge_count: counts[row.user.id] || 0, nudged_today: today.include?(row.user.id))
      end
    end
  end
end
