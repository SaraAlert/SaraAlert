class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.has_role? :enroller
      redirect_to patients_url
    end
  end

end
