module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_api_user!, only: :login

      # POST /api/v1/auth/wechat  { code: "wx.login 返回的 code", display_name?, sex?, birth_date? }
      def login
        code = params[:code].to_s.strip
        return render json: { error: "missing code" }, status: :unprocessable_entity if code.blank?

        response = WechatClient.jscode2session(code)
        openid = response["openid"]
        return render json: { error: response["errmsg"].presence || "登录失败" }, status: :unprocessable_entity if openid.blank?

        user = User.find_or_initialize_by(openid: openid)
        new_user = user.new_record?
        if new_user
          # Devise 仍要求 email/password，这里用占位值，用户实际只通过微信登录。
          user.email = "#{openid}@wechat.local"
          user.password = SecureRandom.hex(16)
          user.display_name = params[:display_name].presence || "微信用户"
          user.sex = params[:sex].presence
          user.birth_date = params[:birth_date].presence
          user.save!
        end

        user.regenerate_api_token

        render json: {
          token: user.api_token,
          new_user: new_user,
          user: Api::Serializer.user(user)
        }
      end
    end
  end
end
