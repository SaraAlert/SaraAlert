class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.has_role? :enroller
      redirect_to patients_url
    elsif current_user.has_role? :monitor
      redirect_to monitor_dashboard_url
    elsif current_user.has_role? :admin
      redirect_to admin_index_url
    end
  end

end
