module Freshness
  def self.etag(*parts)
    Digest::SHA256.hexdigest(parts.map { |part| part.respond_to?(:iso8601) ? part.iso8601(6) : part.to_s }.join("|"))
  end

  def self.for_user(user)
    etag(user.id, user.updated_at, user.measurements.maximum(:updated_at))
  end

  def self.for_group(group)
    user_ids = group.memberships.pluck(:user_id)
    etag(
      group.id,
      group.updated_at,
      group.memberships.maximum(:updated_at),
      Measurement.where(user_id: user_ids).maximum(:updated_at),
      group.nudges.maximum(:updated_at)
    )
  end

  def self.for_groups(user)
    etag(user.id, user.groups.maximum(:updated_at), user.memberships.maximum(:updated_at))
  end
end
