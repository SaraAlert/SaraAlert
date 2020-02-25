class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.has_role?(:enroller)
      redirect_to patients_url
    elsif current_user.has_role?(:public_health) || current_user.has_role?(:public_health_enroller)
      redirect_to public_health_url
    elsif current_user.has_role?(:analyst)
      redirect_to analytics_url
    elsif current_user.has_role?(:admin)
      redirect_to admin_index_url
    end
  end

end
