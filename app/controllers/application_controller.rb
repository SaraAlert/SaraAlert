class ApplicationController < ActionController::Base
  before_action :new_users_must_change_password
  def new_users_must_change_password
    if current_user && current_user.force_password_change
      # Redirect unless we're already at the change password page
      unless request.url == edit_user_registration_url || request.url == user_registration_url
        redirect_to edit_user_registration_url
      end
    end
  end
end
