module SuggestionsHelper
  def suggestion_date(suggestion)
    time = suggestion.created_at.in_time_zone
    "#{time.month} 月 #{time.day} 日"
  end
end
