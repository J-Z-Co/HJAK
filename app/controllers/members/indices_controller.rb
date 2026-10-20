class Members::IndicesController < ApplicationController
  helper IndicesHelper

  before_action :authenticate_user!
  before_action :load_pair

  def index
    @board = ::Indices::Board.assemble(@member)
    @brief = ::Indices::Brief.for(@board)
    return if respond_to_revalidation(::Freshness.for_user(@member))
  end

  def show
    @board = ::Indices::Board.assemble(@member)
    @reading = @board.readings.find { |reading| reading.key == params[:key] }
    unless @reading
      redirect_to group_member_indices_path(@group, @member), alert: "没有这项指数", status: :see_other
      return
    end
    unless @reading.clickable
      redirect_to group_member_indices_path(@group, @member), alert: @reading.note.presence || "这项不单独画图", status: :see_other
      return
    end

    @series = ::Indices::Series.call(user: @member, key: @reading.key, range: params[:range])
    @explanation = ::Indices::Assessment.explanation(@reading.key, years: @board.years)
    return if respond_to_revalidation(::Freshness.for_user(@member), template: "indices/show")

    render "indices/show"
  end

  private

  def load_pair
    # 嵌套资源会给自定义 param 加上资源名前缀，顶层的 public_id / user_id 在这里是空的。
    @group = Group.find_by(public_id: params[:group_public_id])
    @member = User.find_by(id: params[:member_user_id])
    return if @group && @member && shares_group?

    redirect_to groups_path, alert: "只能查看同组成员", status: :see_other
  end

  def shares_group?
    Membership.where(group: @group, user: current_user).exists? && Membership.where(group: @group, user: @member).exists?
  end
end
