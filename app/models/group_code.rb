class GroupCode
  def self.parse(input)
    text = input.to_s.strip
    return if text.empty?

    if text.include?("://")
      query = URI.parse(text).query
      return if query.blank?

      URI.decode_www_form(query).to_h["code"].presence
    else
      # 分享页把代号排成两组四位，照着输入时会带空格
      text.gsub(/\s+/, "").upcase
    end
  end
end
