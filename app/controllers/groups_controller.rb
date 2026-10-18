class GroupsController < ApplicationController
  before_action :authenticate_user!

  def index
    @groups = current_user.groups.order(:name)
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(name: group_params[:name])
    unless @group.name.present?
      @group.errors.add(:name, "请填写群组名称")
      render :new, status: :unprocessable_content
      return
    end

    Group.transaction do
      @group.save!
      @group.memberships.create!(user: current_user, role: :owner, joined_at: Time.current)
    end
    redirect_to group_path(@group), notice: "已创建#{@group.name}", status: :see_other
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_content
  end

  def show
    @group = visible_group
    return unless @group

    @rows = ::Groups::Ranking.for(@group)
    @membership = @group.memberships.find_by(user: current_user)
  end

  def share
    @group = visible_group
    return unless @group

    url = join_group_url(code: @group.public_id)
    @qr = RQRCode::QRCode.new(url).as_svg(module_size: 4, use_path: true, viewbox: true)
  end

  def destroy
    @group = visible_group
    return unless @group

    membership = @group.memberships.find_by(user: current_user)
    unless membership&.owner?
      redirect_to group_path(@group), alert: "只有群主可以删除群组", status: :see_other
      return
    end

    @group.destroy!
    redirect_to groups_path, notice: "已删除群组", status: :see_other
  end

  private

  def group_params
    params.fetch(:group, {}).permit(:name)
  end

  def visible_group
    group = Group.find_by(public_id: params[:public_id])
    if group.nil? || !group.memberships.exists?(user: current_user)
      redirect_to groups_path, alert: "你不在这个群组", status: :see_other
      return
    end
    group
  end
end
