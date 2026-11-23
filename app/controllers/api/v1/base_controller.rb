module Api
  module V1
    # API 控制器继承 ActionController::API，而非 ApplicationController，
    # 因此自动没有 CSRF 校验、allow_browser、cookie 会话等浏览器专属行为。
    class BaseController < ActionController::API
      before_action :authenticate_api_user!

      rescue_from ActiveRecord::RecordNotFound do |_error|
        render json: { error: "not_found" }, status: :not_found
      end

      private

      def authenticate_api_user!
        token = request.headers["Authorization"].to_s.delete_prefix("Bearer ").strip
        @current_api_user = User.find_by(api_token: token) if token.present?
        return if @current_api_user

        render json: { error: "unauthorized" }, status: :unauthorized
      end

      def current_api_user
        @current_api_user
      end
    end
  end
end
