# frozen_string_literal: true

# HomeController: redirects based on role
class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.enroller?
      redirect_to patients_url
    elsif current_user.public_health? || current_user.public_health_enroller? || current_user.contact_tracer? || current_user.super_user?
      redirect_to public_health_url
    elsif current_user.analyst?
      redirect_to analytics_url
    elsif current_user.admin?
      redirect_to admin_index_url
    end
  end
end
