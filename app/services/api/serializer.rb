module Api
  module Serializer
    def self.user(user)
      return nil if user.nil?

      {
        id: user.id,
        display_name: user.display_name,
        sex: user.sex,
        birth_date: user.birth_date&.iso8601
      }
    end

    def self.metric_entry(entry)
      {
        key: entry.key,
        label: entry.label,
        unit: entry.unit,
        interval_days: entry.interval_days,
        min: entry.min,
        max: entry.max,
        secondary_min: entry.secondary_min,
        secondary_max: entry.secondary_max,
        blood_pressure: entry.blood_pressure?
      }
    end

    def self.measurement(measurement)
      return nil if measurement.nil?

      {
        id: measurement.id,
        metric_type: measurement.metric_type,
        recorded_on: measurement.recorded_on&.iso8601,
        recorded_at: measurement.recorded_at&.iso8601,
        value: measurement.value.to_f,
        value_secondary: measurement.value_secondary&.to_f
      }
    end

    def self.measurement_row(row)
      {
        key: row.key,
        label: row.entry.label,
        unit: row.entry.unit,
        min: row.entry.min,
        max: row.entry.max,
        secondary_min: row.entry.secondary_min,
        secondary_max: row.entry.secondary_max,
        blood_pressure: row.entry.blood_pressure?,
        status: row.status.to_s,
        caption: row.caption,
        background: row.background,
        latest: measurement(row.latest),
        history: row.history.map { |m| measurement(m) },
        submitted_value: row.submitted_value,
        submitted_secondary: row.submitted_secondary,
        error: row.error
      }
    end

    def self.reading(reading)
      return nil if reading.nil?

      {
        key: reading.key,
        label: reading.label,
        position: reading.position,
        value_text: reading.value_text,
        numeric: reading.numeric,
        deviation: reading.deviation,
        group: reading.group.to_s,
        note: reading.note,
        note_anchor: reading.note_anchor,
        profile_fields: reading.profile_fields.map(&:to_s),
        stale_text: reading.stale_text,
        clickable: reading.clickable,
        chart: reading.chart&.to_s,
        bounds: reading.bounds
      }
    end

    def self.board(board)
      {
        years: board.years,
        banner: board.banner,
        basis: board.basis,
        mean: board.mean,
        compare: board.compare?,
        readings: board.readings.map { |item| reading(item) }
      }
    end

    def self.brief_group(group)
      {
        title: group.title,
        status: group.status,
        note: group.note,
        aside: group.aside,
        readings: group.readings.map { |item| reading(item) }
      }
    end

    def self.brief(brief)
      {
        lines: brief.lines,
        groups: brief.groups.map { |group| brief_group(group) }
      }
    end

    def self.badge(badge)
      {
        key: badge.key,
        title: badge.title,
        hint: badge.hint,
        icon: badge.icon.to_s,
        earned: badge.earned
      }
    end

    def self.progress(progress)
      {
        streak: progress.streak,
        best_streak: progress.best_streak,
        week_days: progress.week_days,
        today_done: progress.today_done,
        today_total: progress.today_total,
        today_complete: progress.today_complete?,
        total_records: progress.total_records,
        earned_count: progress.earned_count,
        badges: progress.badges.map { |item| badge(item) }
      }
    end

    def self.leaderboard_row(row)
      {
        user: user(row.user),
        rank: row.rank,
        value: row.value,
        value_text: row.value_text,
        note: row.note,
        streak: row.streak,
        deviation: row.deviation,
        kind: row.kind,
        nudge_count: row.nudge_count,
        nudgeable: row.nudgeable,
        nudged_today: row.nudged_today
      }
    end

    def self.leaderboard_board(board)
      { key: board.key, label: board.label, hint: board.hint, unit: board.unit }
    end

    def self.suggestion(item, replies: false)
      result = {
        id: item.id,
        body: item.body,
        author: user(item.user),
        reasonable_count: item.reasonable_count,
        wrong_count: item.wrong_count,
        created_at: item.created_at&.iso8601
      }
      result[:replies] = item.replies.map { |reply| suggestion(reply) } if replies
      result
    end

    def self.group(group, membership: nil)
      {
        id: group.id,
        name: group.name,
        public_id: group.public_id,
        role: membership&.role,
        member_count: group.memberships.size
      }
    end
  end
end
