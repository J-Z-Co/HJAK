module Groups
  class YearChart
    def self.for(group, on: Time.zone.today)
      start = Week.start_on(on)
      mondays = (0..51).map { |weeks_ago| start - (51 - weeks_ago) * 7 }
      cutoff = mondays.last - 1
      users = group.users.order(:id).to_a
      measurements = Measurement.where(user_id: users.map(&:id), recorded_on: ..cutoff)
        .order(recorded_on: :desc, recorded_at: :desc)
        .group_by(&:user_id)

      members = users.map do |user|
        list = measurements[user.id] || []
        values = mondays.map do |monday|
          board = ::Indices::Board.from_latest(user, latest_on(list, monday - 1), on: monday - 1)
          board.compare? ? board.mean : nil
        end
        { name: user.display_name, values: }
      end

      { mondays: mondays.map(&:iso8601), members: }
    end

    def self.latest_on(list, day)
      found = {}
      list.each do |measurement|
        next if measurement.recorded_on > day

        found[measurement.metric_type] ||= measurement
      end
      found
    end
    private_class_method :latest_on
  end
end
