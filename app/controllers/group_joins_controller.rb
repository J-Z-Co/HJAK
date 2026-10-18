class GroupJoinsController < ApplicationController
  before_action :authenticate_user!

  def new
    @parsed = GroupCode.parse(params[:code])
    @group = Group.find_by(public_id: @parsed) if @parsed.present?
    @error = "没有这个群组" if @parsed.present? && @group.nil?
  end

  def create
    @parsed = GroupCode.parse(params[:code])
    @group = Group.find_by(public_id: @parsed) if @parsed.present?
    unless @group
      @error = "没有这个群组"
      render :new, status: :unprocessable_content
      return
    end

    if @group.memberships.exists?(user: current_user)
      redirect_to group_path(@group), status: :see_other
      return
    end

    @group.memberships.create!(user: current_user, role: :member, joined_at: Time.current)
    redirect_to group_path(@group), notice: "已加入#{@group.name}", status: :see_other
  end
end
