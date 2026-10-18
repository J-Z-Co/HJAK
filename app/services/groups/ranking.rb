module Groups
  class Ranking
    Row = Data.define(:user, :board, :score, :rank, :basis)

    def self.for(group, on: Time.zone.today)
      built = group.memberships.includes(:user).map { |membership| build(membership.user, on) }
      ranks = competition_ranks(built)
      built.map { |row| row.with(rank: ranks[row.user.id]) }
        .sort_by { |row| [ row.rank || 1_000_000, row.user.id ] }
    end

    def self.build(user, on)
      board = ::Indices::Board.assemble(user, on:)
      if board.compare?
        Row.new(user:, board:, score: board.mean, rank: nil, basis: board.basis)
      else
        basis = board.years && board.years < 6 ? "未满 6 岁，不参与排名" : "填写出生日期后才能排名"
        Row.new(user:, board:, score: nil, rank: nil, basis:)
      end
    end

    def self.competition_ranks(rows)
      ranks = {}
      last_score = nil
      last_rank = 0
      rows.select { |row| row.score }.sort_by { |row| [ row.score, row.user.id ] }.each_with_index do |row, index|
        last_rank = index + 1 if last_score.nil? || row.score.round(6) != last_score
        last_score = row.score.round(6)
        ranks[row.user.id] = last_rank
      end
      ranks
    end
    private_class_method :build, :competition_ranks
  end
end
