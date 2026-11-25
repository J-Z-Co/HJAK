# 开发库手测账号。口令都是 seed-password。
# 重复执行会清掉这四个账号自己的测量再写入下面的序列，不会改动其他用户，也不会把他们移出群组。
# docker compose exec web bin/rails db:seed

if Rails.env.development?
PASSWORD = "seed-password"
TODAY = Time.zone.today

def seed_user(email:, display_name:, sex:, birth_date:)
  user = User.find_or_initialize_by(email:)
  user.display_name = display_name
  user.sex = sex
  user.birth_date = birth_date
  user.password = PASSWORD if user.new_record?
  user.save!
  user.measurements.delete_all
  user
end

def seed_measurement(user, metric_type, days_ago, value, value_secondary: nil)
  recorded_on = TODAY - days_ago
  key = Digest::UUID.uuid_v5(Digest::UUID::URL_NAMESPACE, "phoenixlist-seed:v2:#{user.email}:#{metric_type}:#{days_ago}")
  row = Measurement.find_or_initialize_by(idempotency_key: key, metric_type:)
  row.user = user
  row.recorded_on = recorded_on
  row.recorded_at = Time.zone.local(recorded_on.year, recorded_on.month, recorded_on.day, 8, 0, 0)
  row.value = value
  row.value_secondary = value_secondary
  row.save!
end

def seed_points(user, metric_type, points)
  points.each do |days_ago, value, secondary|
    seed_measurement(user, metric_type, days_ago, value, value_secondary: secondary)
  end
end

self_user = seed_user(email: "seed-self@example.com", display_name: "自己", sex: :male, birth_date: Date.new(1990, 1, 1))
mate = seed_user(email: "seed-mate@example.com", display_name: "队友", sex: :female, birth_date: Date.new(1992, 6, 1))
student = seed_user(email: "seed-student@example.com", display_name: "学生", sex: :male, birth_date: 10.years.ago.to_date)
child = seed_user(email: "seed-child@example.com", display_name: "幼儿", sex: :male, birth_date: 5.years.ago.to_date)

# 自己：一年里从健康区上沿回到健康区。腰围停在 6 天前，记录页仍是时效外。
seed_points(self_user, "height", [ [ 360, 175 ], [ 0, 175 ] ])
seed_points(self_user, "weight", [ [ 360, 76 ], [ 300, 75 ], [ 240, 74 ], [ 180, 73 ], [ 120, 72 ], [ 60, 71 ], [ 21, 70.6 ], [ 14, 70.4 ], [ 6, 70.2 ], [ 3, 70.1 ], [ 1, 70 ], [ 0, 70 ] ])
seed_points(self_user, "waist", [ [ 360, 88 ], [ 270, 86 ], [ 180, 84 ], [ 90, 82 ], [ 40, 81 ], [ 20, 80.5 ], [ 6, 80 ] ])
seed_points(self_user, "hip", [ [ 360, 98 ], [ 0, 98 ] ])
seed_points(self_user, "neck", [ [ 360, 38 ], [ 0, 38 ] ])
seed_points(self_user, "blood_pressure", [ [ 360, 128, 84 ], [ 180, 124, 80 ], [ 60, 120, 78 ], [ 14, 119, 77 ], [ 6, 118, 76 ], [ 0, 118, 76 ] ])
seed_points(self_user, "resting_heart_rate", [ [ 360, 76 ], [ 180, 72 ], [ 60, 70 ], [ 14, 69 ], [ 6, 68 ], [ 3, 68 ], [ 1, 68 ], [ 0, 68 ] ])

# 队友：一年里从健康区走向警告界。近 7 天、1 个月、1 年都有多个点。
seed_points(mate, "height", [ [ 360, 164 ] ])
seed_points(mate, "weight", [ [ 360, 64 ], [ 300, 65 ], [ 240, 66 ], [ 180, 67 ], [ 120, 68 ], [ 60, 69 ], [ 30, 69.5 ], [ 14, 69.8 ], [ 7, 70 ], [ 5, 70.1 ], [ 3, 70 ], [ 1, 70.2 ], [ 0, 70 ] ])
seed_points(mate, "waist", [ [ 360, 76 ], [ 270, 78 ], [ 180, 80 ], [ 120, 81 ], [ 60, 82 ], [ 30, 83 ], [ 14, 83.5 ], [ 7, 83.8 ], [ 3, 84 ], [ 0, 84 ] ])
seed_points(mate, "hip", [ [ 360, 90 ], [ 180, 91 ], [ 30, 92 ], [ 0, 92 ] ])
seed_points(mate, "neck", [ [ 360, 32 ], [ 90, 33 ], [ 0, 33 ] ])
seed_points(mate, "blood_pressure", [ [ 360, 118, 74 ], [ 180, 122, 76 ], [ 60, 126, 80 ], [ 21, 128, 81 ], [ 7, 129, 82 ], [ 3, 130, 82 ], [ 0, 130, 82 ] ])
seed_points(mate, "resting_heart_rate", [ [ 360, 72 ], [ 180, 84 ], [ 60, 96 ], [ 21, 104 ], [ 7, 108 ], [ 3, 110 ], [ 0, 110 ] ])

# 学生：10 岁。身高体重腰围都有变化，BMI 从超重线下沿走到超重和肥胖之间。
# 体重、腰围停在几天前（已逾期），方便群主用「催催」测试提醒。
seed_points(student, "height", [ [ 360, 136 ], [ 180, 138 ], [ 0, 140 ] ])
seed_points(student, "weight", [ [ 360, 34 ], [ 180, 37 ], [ 90, 38.5 ], [ 30, 39.5 ], [ 14, 40 ], [ 7, 40.1 ], [ 5, 40.2 ] ])
seed_points(student, "waist", [ [ 360, 62 ], [ 180, 64 ], [ 60, 66 ], [ 14, 67 ], [ 7, 68 ] ])

# 幼儿：5 岁。有走势，但图上不铺色带。体重也停在几天前（已逾期）。
seed_points(child, "height", [ [ 180, 106 ], [ 60, 108 ], [ 0, 110 ] ])
seed_points(child, "weight", [ [ 180, 16.5 ], [ 60, 17.2 ], [ 14, 17.6 ], [ 7, 17.8 ], [ 5, 18 ] ])
seed_points(child, "waist", [ [ 180, 48 ], [ 60, 49 ], [ 7, 50 ] ])

group = Group.find_or_initialize_by(public_id: "FAMLY234")
group.name = "家里"
group.save!

[ [ self_user, :owner ], [ mate, :member ], [ student, :member ], [ child, :member ] ].each do |user, role|
  membership = Membership.find_or_initialize_by(group:, user:)
  membership.role = role
  membership.joined_at ||= Time.current
  membership.save!
end
end
