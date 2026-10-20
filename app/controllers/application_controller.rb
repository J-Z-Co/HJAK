class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :sync_cache_partition

  protected

  def respond_to_revalidation(token, template: nil)
    @phoenix_etag = token
    return false unless request.headers["X-Phoenix-Revalidate"] == "1"

    incoming = request.headers["If-None-Match"].to_s.sub(/\AW\//, "").delete('"')
    if incoming == token
      head :not_modified
    else
      html = render_to_string(template || action_name, formats: [ :html ], layout: false)
      render turbo_stream: turbo_stream.replace("phoenix-page", html: view_context.tag.div(id: "phoenix-page") { html.html_safe })
    end
    true
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :display_name, :sex, :birth_date ])
  end

  private

  def sync_cache_partition
    if user_signed_in?
      cookies[:phoenix_cache] = { value: current_user.id.to_s, same_site: :lax, secure: Rails.env.production? }
    elsif cookies[:phoenix_cache]
      cookies.delete(:phoenix_cache)
    end
  end
end
