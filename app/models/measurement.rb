class Measurement < ApplicationRecord
  belongs_to :user

  validates :metric_type, :recorded_on, :recorded_at, :value, :idempotency_key, presence: true
end
