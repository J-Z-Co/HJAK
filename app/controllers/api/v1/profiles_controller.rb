module Api
  module V1
    class ProfilesController < BaseController
      # GET /api/v1/me
      def show
        progress = ::Gamification::Progress.for(current_api_user)
        render json: { user: Api::Serializer.user(current_api_user), progress: Api::Serializer.progress(progress) }
      end

      # PATCH /api/v1/me  { display_name:, sex:, birth_date: }
      def update
        attributes = params.permit(:display_name, :sex, :birth_date).to_h
        attributes["sex"] = nil if attributes["sex"].blank?

        if current_api_user.update(attributes)
          progress = ::Gamification::Progress.for(current_api_user)
          render json: { user: Api::Serializer.user(current_api_user), progress: Api::Serializer.progress(progress) }
        else
          render json: { errors: current_api_user.errors.to_hash }, status: :unprocessable_entity
        end
      end
    end
  end
end
