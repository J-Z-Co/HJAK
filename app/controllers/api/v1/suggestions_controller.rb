module Api
  module V1
    class SuggestionsController < BaseController
      # GET /api/v1/suggestions
      def index
        suggestions = Suggestion.roots.includes(:user, replies: :user).order(created_at: :desc)
        render json: { suggestions: suggestions.map { |suggestion| Api::Serializer.suggestion(suggestion, replies: true) } }
      end

      # POST /api/v1/suggestions  { body:, parent_id? }
      def create
        parent = Suggestion.roots.find(params[:parent_id]) if params[:parent_id].present?
        suggestion = current_api_user.suggestions.build(body: params[:body], parent: parent)
        if suggestion.save
          render json: { suggestion: Api::Serializer.suggestion(suggestion) }, status: :created
        else
          render json: { errors: suggestion.errors.to_hash }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/suggestions/:id/vote  { choice: "reasonable" | "wrong" }
      def vote
        suggestion = Suggestion.find_by(id: params[:id])
        return render json: { error: "没有这条建议" }, status: :not_found unless suggestion

        column = { "reasonable" => :reasonable_count, "wrong" => :wrong_count }[params[:choice].to_s]
        return render json: { error: "invalid choice" }, status: :unprocessable_entity if column.nil?

        Suggestion.increment_counter(column, suggestion.id)
        suggestion.reload
        render json: { reasonable_count: suggestion.reasonable_count, wrong_count: suggestion.wrong_count }
      end

      # DELETE /api/v1/suggestions/:id
      def destroy
        suggestion = current_api_user.suggestions.find_by(id: params[:id])
        return render json: { error: "只能删除自己的建议" }, status: :forbidden unless suggestion

        suggestion.destroy!
        render json: { notice: "已删除" }
      end
    end
  end
end
