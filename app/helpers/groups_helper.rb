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
end
