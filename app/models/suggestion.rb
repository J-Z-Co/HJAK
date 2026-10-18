class Suggestion < ApplicationRecord
  BODY_MAX = 1000

  belongs_to :user
  belongs_to :parent, class_name: "Suggestion", optional: true
  has_many :replies, -> { order(created_at: :asc) },
    class_name: "Suggestion", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent

  scope :roots, -> { where(parent_id: nil) }

  before_validation { self.body = body.to_s.strip }

  validates :body, presence: true, length: { maximum: BODY_MAX }
  validate :parent_is_a_suggestion

  private

  def parent_is_a_suggestion
    return if parent_id.blank?
    return if parent&.parent_id.blank?

    errors.add(:parent, "只能写在一条建议下面")
  end
end
