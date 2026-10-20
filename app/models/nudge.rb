class Nudge < ApplicationRecord
  belongs_to :group
  belongs_to :actor, class_name: "User"
  belongs_to :subject, class_name: "User"

  validates :nudged_on, presence: true

  def self.resolve_for!(user)
    now = Time.current
    where(subject_id: user.id, resolved_at: nil).update_all(resolved_at: now, updated_at: now)
  end
end
