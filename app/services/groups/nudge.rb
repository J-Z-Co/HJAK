module Groups
  class Nudge
    Result = Data.define(:notice, :alert)

    def self.call(group:, actor:, subject:)
      return Result.new(notice: nil, alert: "对方不在这个群组") if subject.nil? || !group.users.exists?(id: subject.id)
      return Result.new(notice: nil, alert: "不能催自己") if subject == actor

      overdue = ::Measurements::Row.build(subject).any? { |row| row.status == :overdue }
      return Result.new(notice: nil, alert: "对方没有过期的测量") unless overdue

      record = group.nudges.find_or_initialize_by(actor:, subject:, nudged_on: Time.zone.today)
      return Result.new(notice: "今天已经催过", alert: nil) if record.persisted?

      record.save!
      Result.new(notice: "已催#{subject.display_name}", alert: nil)
    rescue ActiveRecord::RecordNotUnique
      Result.new(notice: "今天已经催过", alert: nil)
    end
  end
end
