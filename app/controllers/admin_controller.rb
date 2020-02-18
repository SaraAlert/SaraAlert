class AdminController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def create_user
    byebug
  end

end
