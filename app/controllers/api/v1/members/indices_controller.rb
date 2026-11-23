module Api
  module V1
    module Members
      class IndicesController < BaseController
        before_action :load_pair

        # GET /api/v1/groups/:public_id/members/:user_id/indices
        def index
          board = ::Indices::Board.assemble(@member)
          brief = ::Indices::Brief.for(board)
          render json: {
            member: Api::Serializer.user(@member),
            board: Api::Serializer.board(board),
            brief: Api::Serializer.brief(brief)
          }
        end

        # GET /api/v1/groups/:public_id/members/:user_id/indices/:key
        def show
          board = ::Indices::Board.assemble(@member)
          reading = board.readings.find { |candidate| candidate.key == params[:key] }
          return render json: { error: "没有这项指数" }, status: :not_found unless reading

          unless reading.clickable
            return render json: { member: Api::Serializer.user(@member), reading: Api::Serializer.reading(reading), series: nil, explanation: nil }
          end

          series = ::Indices::Series.call(user: @member, key: reading.key, range: params[:range])
          explanation = ::Indices::Assessment.explanation(reading.key, years: board.years)
          render json: {
            member: Api::Serializer.user(@member),
            reading: Api::Serializer.reading(reading),
            series: series,
            explanation: explanation
          }
        end

        private

        def load_pair
          @group = Group.find_by(public_id: params[:public_id])
          @member = User.find_by(id: params[:user_id])
          return if @group && @member && shares_group?

          render json: { error: "只能查看同组成员" }, status: :forbidden
        end

        def shares_group?
          Membership.where(group: @group, user: current_api_user).exists? &&
            Membership.where(group: @group, user: @member).exists?
        end
      end
    end
  end
end
