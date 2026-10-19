class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_progress, only: %i[show update]

  def show
  end

  def update
    if current_user.update(profile_params)
      redirect_to me_path, notice: "已保存", status: :see_other
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def load_progress
    @progress = ::Gamification::Progress.for(current_user)
  end

  def profile_params
    permitted = params.require(:user).permit(:display_name, :sex, :birth_date)
    permitted[:sex] = nil if permitted[:sex].blank?
    permitted
  end
end
