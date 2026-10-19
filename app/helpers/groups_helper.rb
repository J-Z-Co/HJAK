module GroupsHelper
  # 前三名：金、银、铜实心徽章；其余灰底
  def rank_badge_class(rank)
    case rank
    when 1 then "bg-gradient-to-br from-amber-300 to-yellow-500 text-amber-950 shadow-[0_4px_12px_-4px_rgba(234,179,8,0.8)]"
    when 2 then "bg-gradient-to-br from-slate-200 to-slate-400 text-slate-800"
    when 3 then "bg-gradient-to-br from-orange-300 to-amber-700 text-white"
    else "bg-stone-100 text-stone-500"
    end
  end

  def podium_step_class(rank)
    case rank
    when 1 then "h-16 bg-amber-100 text-amber-700"
    when 2 then "h-11 bg-slate-100 text-slate-600"
    else "h-8 bg-orange-100 text-orange-700"
    end
  end

  # 综合榜用偏离色；习惯榜统一用群组的橙色
  def leaderboard_value_style(row)
    if row.deviation
      "color: #{::Indices::Palette.css(row.deviation)}"
    elsif row.rank
      "color: #ea580c"
    end
  end
end
