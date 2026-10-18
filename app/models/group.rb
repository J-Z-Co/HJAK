class Group < ApplicationRecord
  ALPHABET = (("A".."Z").to_a - %w[I O] + ("2".."9").to_a).freeze

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  validates :name, :public_id, presence: true
  validates :public_id, format: { with: /\A[A-HJ-NP-Z2-9]{8}\z/ }

  before_validation :assign_public_id, on: :create

  def to_param
    public_id
  end

  private

  def assign_public_id
    return if public_id.present?

    10.times do
      candidate = Array.new(8) { ALPHABET.sample }.join
      next if Group.exists?(public_id: candidate)

      self.public_id = candidate
      return
    end
  end
end
