module IndicesHelper
  def reading_href(reading)
    if controller_path == "members/indices"
      group_member_index_path(@group, @member, reading.key)
    else
      index_path(reading.key)
    end
  end

  def chart_back_path
    if controller_path == "members/indices"
      group_member_indices_path(@group, @member)
    else
      indices_path
    end
  end

  def chart_back_label
    controller_path == "members/indices" ? "返回" : "返回指数"
  end

  def chart_range_path(key, range)
    if controller_path == "members/indices"
      group_member_index_path(@group, @member, key, range:)
    else
      index_path(key, range:)
    end
  end

  def freshness_badge(reading)
    return if reading.group == :inapplicable
    return "未点亮" if reading.group == :missing || (reading.numeric.nil? && reading.value_text.blank?)
    return "时效外" if reading.stale_text.present?

    "时效内"
  end

  def index_card_style(reading)
    return unless reading.deviation

    "background-color: #{::Indices::Palette.background(reading.deviation)}"
  end

  def index_name_style(reading)
    return "color: #1c1917" unless reading.deviation

    "color: #{::Indices::Palette.css(reading.deviation)}"
  end

  def freshness_badge_class(badge)
    case badge
    when "时效内" then "border-transparent bg-[#DCFCE7] text-green-900"
    when "时效外" then "border-transparent bg-[#FEF9C3] text-amber-900"
    else "text-stone-500"
    end
  end
end
