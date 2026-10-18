class MembershipsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    group = Group.find_by(public_id: params[:public_id])
    actor = group&.memberships&.find_by(user: current_user)
    unless group && actor
      redirect_to groups_path, alert: "你不在这个群组", status: :see_other
      return
    end

    target = if params[:user_id].present?
      unless actor.owner?
        redirect_to group_path(group), alert: "只有群主可以移除成员", status: :see_other
        return
      end
      group.memberships.find_by(user_id: params[:user_id])
    else
      actor
    end

    unless target
      redirect_to group_path(group), alert: "没有这个成员", status: :see_other
      return
    end

    if target.owner? && group.memberships.where.not(id: target.id).exists?
      redirect_to group_path(group), alert: "群里还有别人，群主不能退出", status: :see_other
      return
    end

    leaving_self = target.user_id == current_user.id
    target.destroy!
    if leaving_self
      redirect_to groups_path, notice: "已退出#{group.name}", status: :see_other
    else
      redirect_to group_path(group), notice: "已移除成员", status: :see_other
    end
  end
end
