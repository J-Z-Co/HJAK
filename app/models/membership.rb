class Membership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  enum :role, { owner: 0, member: 1 }

  validates :joined_at, presence: true
  validates :user_id, uniqueness: { scope: :group_id }
end
