class Users::RegistrationsController < Devise::RegistrationsController
  def sign_up(resource_name, resource)
    resource.remember_me = true
    super
  end

  def build_resource(hash = {})
    super
    resource.registering = true
  end

  def sign_up_params
    permitted = super
    permitted[:sex] = nil if permitted[:sex].blank?
    permitted
  end
end
