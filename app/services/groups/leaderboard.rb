module Groups
  # 群组里可以切换的几张排行榜。
  # 「综合」沿用 Groups::Ranking 的偏离分，越小越好，未满 6 岁不排；
  # 其余三张只看记录习惯，越大越好，所有成员都参加，0 不给名次。
  class Leaderboard
    Board = Data.define(:key, :label, :hint, :unit)
    Row = Data.define(:user, :rank, :value, :value_text, :note, :streak, :deviation)

    BOARDS = [
      Board.new(key: "health", label: "综合", hint: "综合分越小越接近健康区", unit: nil),
      Board.new(key: "streak", label: "连续", hint: "连续记录的天数，今天还没记不算断", unit: "天"),
      Board.new(key: "week", label: "本周", hint: "最近 7 天里有记录的天数", unit: "天"),
      Board.new(key: "badges", label: "徽章", hint: "已经点亮的徽章数", unit: "枚")
    ].freeze

    def self.board(key)
      BOARDS.find { |board| board.key == key.to_s } || BOARDS.first
    end

    def self.for(group, board: "health", on: Time.zone.today)
      new(group, board: self.board(board), on:).rows
    end

    def initialize(group, board:, on:)
      @group = group
      @board = board
      @on = on
    end

    def rows
      ranking = ::Groups::Ranking.for(@group, on: @on)
      progress = ranking.to_h { |row| [ row.user.id, ::Gamification::Progress.for(row.user, on: @on) ] }
      @board.key == "health" ? health_rows(ranking, progress) : habit_rows(ranking, progress)
    end

    private

    def health_rows(ranking, progress)
      ranking.map do |row|
        Row.new(
          user: row.user, rank: row.rank, value: row.score,
          value_text: row.score ? format("%.2f", row.score) : "不排名",
          note: row.basis, streak: progress[row.user.id].streak, deviation: row.score
        )
      end
    end

    def habit_rows(ranking, progress)
      values = ranking.to_h { |row| [ row.user.id, habit_value(progress[row.user.id]) ] }
      ranks = competition_ranks(values)
      ranking.map do |row|
        value = values[row.user.id]
        Row.new(
          user: row.user, rank: ranks[row.user.id], value:,
          value_text: "#{value} #{@board.unit}", note: habit_note(progress[row.user.id]),
          streak: progress[row.user.id].streak, deviation: nil
        )
      end.sort_by { |row| [ row.rank || 1_000_000, -row.value, row.user.id ] }
    end

    def habit_value(progress)
      case @board.key
      when "streak" then progress.streak
      when "week" then progress.week_days
      when "badges" then progress.earned_count
      end
    end

    def habit_note(progress)
      case @board.key
      when "streak" then "最长连续 #{progress.best_streak} 天"
      when "week" then "今天已记 #{progress.today_done} 项"
      when "badges" then "累计 #{progress.total_records} 条记录"
      end
    end

    # 并列同名次，下一名跳过；0 不给名次
    def competition_ranks(values)
      ranks = {}
      last_value = nil
      last_rank = 0
      values.select { |_id, value| value.positive? }.sort_by { |id, value| [ -value, id ] }.each_with_index do |(id, value), index|
        last_rank = index + 1 if value != last_value
        last_value = value
        ranks[id] = last_rank
      end
      ranks
    end
  end
end
