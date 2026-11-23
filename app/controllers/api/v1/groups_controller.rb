module Api
  module V1
    class GroupsController < BaseController
      # GET /api/v1/groups
      def index
        memberships = current_api_user.memberships.includes(group: :memberships).order(created_at: :asc)
        groups = memberships.map do |membership|
          Api::Serializer.group(membership.group, membership: membership)
        end
        render json: { groups: groups }
      end

      # POST /api/v1/groups  { name: }
      def create
        group = Group.new(name: params[:name])
        if group.name.blank?
          return render json: { errors: { name: [ "请填写群组名称" ] } }, status: :unprocessable_entity
        end

        Group.transaction do
          group.save!
          group.memberships.create!(user: current_api_user, role: :owner, joined_at: Time.current)
        end
        membership = group.memberships.find_by(user: current_api_user)
        render json: { group: Api::Serializer.group(group, membership: membership) }, status: :created
      rescue ActiveRecord::RecordInvalid
        render json: { errors: group.errors.to_hash }, status: :unprocessable_entity
      end

      # POST /api/v1/groups/join  { code: "ABCD1234" 或分享链接 }
      def join
        code = GroupCode.parse(params[:code])
        group = Group.find_by(public_id: code) if code.present?
        return render json: { error: "没有这个群组" }, status: :unprocessable_entity unless group

        membership = group.memberships.find_by(user: current_api_user)
        if membership
          return render json: { group: Api::Serializer.group(group, membership: membership), already_joined: true }
        end

        membership = group.memberships.create!(user: current_api_user, role: :member, joined_at: Time.current)
        render json: { group: Api::Serializer.group(group, membership: membership), notice: "已加入#{group.name}" }, status: :created
      end

      # GET /api/v1/groups/:public_id?board=health|trend|fresh|badges
      def show
        group = visible_group
        return unless group

        board = ::Groups::Leaderboard.board(params[:board])
        rows = ::Groups::Leaderboard.for(group, board: board.key, actor: current_api_user)
        membership = group.memberships.find_by(user: current_api_user)
        render json: {
          group: Api::Serializer.group(group, membership: membership),
          boards: ::Groups::Leaderboard::BOARDS.map { |candidate| Api::Serializer.leaderboard_board(candidate) },
          board: board.key,
          rows: rows.map { |row| Api::Serializer.leaderboard_row(row) }
        }
      end

      # GET /api/v1/groups/:public_id/year
      def year
        group = visible_group
        return unless group

        render json: ::Groups::YearChart.for(group)
      end

      # POST /api/v1/groups/:public_id/nudge  { subject_id: }
      def nudge
        group = visible_group
        return unless group

        subject = group.users.find_by(id: params[:subject_id])
        result = ::Groups::Nudge.call(group: group, actor: current_api_user, subject: subject)
        status = result.alert.present? ? :unprocessable_entity : :ok
        render json: { notice: result.notice, alert: result.alert }, status: status
      end

      # DELETE /api/v1/groups/:public_id/membership （自己退出）
      def leave
        group = visible_group
        return unless group

        target = group.memberships.find_by(user: current_api_user)
        return render json: { error: "你不在这个群组" }, status: :forbidden unless target

        if target.owner? && group.memberships.where.not(id: target.id).exists?
          return render json: { error: "群里还有别人，群主不能退出" }, status: :unprocessable_entity
        end

        target.destroy!
        render json: { notice: "已退出#{group.name}" }
      end

      # DELETE /api/v1/groups/:public_id/members/:user_id/membership （群主移除成员）
      def remove_member
        group = visible_group
        return unless group

        actor = group.memberships.find_by(user: current_api_user)
        return render json: { error: "只有群主可以移除成员" }, status: :forbidden unless actor&.owner?

        target = group.memberships.find_by(user_id: params[:user_id])
        return render json: { error: "没有这个成员" }, status: :not_found unless target

        target.destroy!
        render json: { notice: "已移除成员" }
      end

      # DELETE /api/v1/groups/:public_id
      def destroy
        group = visible_group
        return unless group

        membership = group.memberships.find_by(user: current_api_user)
        return render json: { error: "只有群主可以删除群组" }, status: :forbidden unless membership&.owner?

        group.destroy!
        render json: { notice: "已删除群组" }
      end

      private

      def visible_group
        group = Group.find_by(public_id: params[:public_id])
        if group.nil? || !group.memberships.exists?(user: current_api_user)
          render json: { error: "你不在这个群组" }, status: :not_found
          return
        end
        group
      end
    end
  end
end
