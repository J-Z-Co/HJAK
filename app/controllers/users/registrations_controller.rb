class Users::RegistrationsController < Devise::RegistrationsController
  def sign_up(resource_name, resource)
    resource.remember_me = true
    super
  end
end
