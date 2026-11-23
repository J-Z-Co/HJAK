module Api
  module V1
    class IndicesController < BaseController
      # GET /api/v1/indices
      def index
        board = ::Indices::Board.assemble(current_api_user)
        brief = ::Indices::Brief.for(board)
        render json: { board: Api::Serializer.board(board), brief: Api::Serializer.brief(brief) }
      end

      # GET /api/v1/indices/overview
      def overview
        board = ::Indices::Board.assemble(current_api_user)
        render json: { board: Api::Serializer.board(board) }
      end

      # GET /api/v1/indices/:key?range=7d|30d|365d
      def show
        board = ::Indices::Board.assemble(current_api_user)
        reading = board.readings.find { |candidate| candidate.key == params[:key] }
        return render json: { error: "没有这项指数" }, status: :not_found unless reading

        unless reading.clickable
          return render json: { reading: Api::Serializer.reading(reading), series: nil, explanation: nil }
        end

        series = ::Indices::Series.call(user: current_api_user, key: reading.key, range: params[:range])
        explanation = ::Indices::Assessment.explanation(reading.key, years: board.years)
        render json: { reading: Api::Serializer.reading(reading), series: series, explanation: explanation }
      end
    end
  end
end
