require "net/http"
require "json"

# 小程序 wx.login 的 code 换 openid/session_key。
# AppID / AppSecret 只存在后端（credentials 或环境变量），绝不进小程序代码。
class WechatClient
  JSCODE2SESSION_URL = "https://api.weixin.qq.com/sns/jscode2session"

  class Error < StandardError; end

  def self.jscode2session(code)
    uri = URI(JSCODE2SESSION_URL)
    uri.query = URI.encode_www_form(
      appid: fetch(:appid),
      secret: fetch(:secret),
      js_code: code,
      grant_type: "authorization_code"
    )

    response = Net::HTTP.get_response(uri)
    raise Error, "wechat jscode2session http #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def self.fetch(key)
    ENV["WECHAT_#{key.to_s.upcase}"].presence ||
      Rails.application.credentials.dig(:wechat, key) ||
      raise(Error, "missing WeChat #{key}")
  end
  private_class_method :fetch
end
