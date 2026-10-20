class Membership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  enum :role, { owner: 0, member: 1 }

  validates :joined_at, presence: true
  validates :user_id, uniqueness: { scope: :group_id }

  after_destroy :clear_nudges

  private

  def clear_nudges
    Nudge.where(group_id:).where("actor_id = :id OR subject_id = :id", id: user_id).delete_all
  end
end
