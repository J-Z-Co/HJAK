module GroupsHelper
  def rank_ring(rank)
    case rank
    when 1 then "border-[#E6C878]"
    when 2 then "border-[#D4D4D8]"
    when 3 then "border-[#D2A679]"
    else "border-stone-300"
    end
  end
end
