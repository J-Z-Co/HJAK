class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :sex, { male: 0, female: 1 }

  has_many :measurements, dependent: :destroy
  has_many :suggestions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships

  validates :display_name, presence: true

  def age_years_on(date)
    return unless birth_date

    years = date.year - birth_date.year
    years -= 1 if date.month < birth_date.month || (date.month == birth_date.month && date.day < birth_date.day)
    years
  end

  # 实足整月折成半岁档。6 岁整到未满 6 岁 6 个月是 6.0。
  def bmi_half_year_on(date)
    months = completed_months_on(date)
    return unless months

    years = months / 12
    (years + ((months % 12) >= 6 ? 0.5 : 0)).to_f
  end

  def completed_months_on(date)
    return unless birth_date

    months = (date.year * 12 + date.month) - (birth_date.year * 12 + birth_date.month)
    months -= 1 if date.day < birth_date.day
    months
  end
end
