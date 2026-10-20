class Users::SessionsController < Devise::SessionsController
  def destroy
    cookies.delete(:phoenix_cache)
    super
  end
end
