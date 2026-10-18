module ApplicationHelper
  def tab_class(name)
    base = "flex min-h-11 items-center justify-center border-t-2 text-sm transition-colors hover:bg-stone-100 active:bg-stone-200"
    if current_tab == name
      "#{base} border-stone-900 font-semibold text-stone-900"
    else
      "#{base} border-transparent text-stone-500"
    end
  end

  def current_tab
    case controller_path
    when "measurements" then :record
    when "indices" then :indices
    when "groups", "group_joins", "memberships", "members/indices" then :groups
    when "profiles", "corrections", "correction_entries" then :me
    end
  end
end
